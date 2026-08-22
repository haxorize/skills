#!/usr/bin/env bash
# security.sh — heuristic scan of a skill directory for prompt-injection and
# malicious patterns. Reports; never blocks, never deletes.
#
# Vendored 2026-08-22 from khendzel/skills-janitor `scripts/security.sh`
# (MIT, Krzysztof Hendzel; upstream 4a4c013), with the installed-scope walk
# removed: this copy scans only the directories it is handed. Consumers are
# the reads over ~/code/lib during a mining round and the install of any
# external skill — an external skill is a dependency with agent execution
# rights, so its directory is scanned before install and its SKILL.md is
# read as data.
#
# What it flags (heuristics, not proof — a finding means "read this before
# trusting it"):
#   - injection phrases ("ignore previous instructions", "do not tell the user")
#   - imperative text hidden in HTML comments; zero-width / bidi unicode
#   - large decodable base64 blobs in markdown (payload smuggling)
#   - scripts that pipe the network into a shell, decode-and-exec, read
#     credential stores, call URL shorteners or plain HTTP, eval variables,
#     read shell or agent history
# Verdict per directory: RISK (any HIGH), REVIEW (any MEDIUM), PASS.
#
# Usage:
#   security.sh --path <dir> [--path <dir> ...]   # one verdict per directory
#   security.sh --json ...                         # machine-readable
#   security.sh --each <parent>                    # every child directory of <parent>
#
# Needs bash 3.2+ and python3; no network, nothing installed.
# scripts/security-selftest.sh runs it against scripts/lint-fixtures/security/.

set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }

JSON_OUTPUT=false
TARGETS_TSV=$(mktemp -t security-scan.XXXXXX)
trap 'rm -f "$TARGETS_TSV"' EXIT

add_target() {
  if [ ! -d "$1" ]; then
    echo "ERROR: not a directory: $1" >&2
    exit 1
  fi
  printf '%s\t%s\n' "$(basename "$1")" "$1" >> "$TARGETS_TSV"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --path) add_target "$2"; shift 2 ;;
    --each)
      [ -d "$2" ] || { echo "ERROR: not a directory: $2" >&2; exit 1; }
      for d in "$2"/*; do [ -d "$d" ] && add_target "$d"; done
      shift 2 ;;
    -h|--help) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ ! -s "$TARGETS_TSV" ]; then
  echo "ERROR: nothing to scan — pass --path <dir> or --each <parent>" >&2
  exit 1
fi

export TARGETS_TSV JSON_OUTPUT

python3 <<'PYEOF'
import base64
import json
import os
import re
import sys

JSON_OUTPUT = os.environ.get("JSON_OUTPUT", "false") == "true"
TARGETS = os.environ.get("TARGETS_TSV", "")

MD_EXT = {".md", ".markdown", ".txt"}
SCRIPT_EXT = {".sh", ".bash", ".zsh", ".py", ".js", ".mjs", ".ts", ".rb", ".pl"}
MAX_FILE_BYTES = 1_000_000
MAX_FILES_PER_SKILL = 200

R = re.compile
MD_RULES = [
    ("inj-ignore", "HIGH", R(r"(ignore|disregard|forget)\s+(all\s+|any\s+)?(previous|prior|above|earlier)\s+(instructions?|prompts?|rules?)", re.I),
     "Instruction-override phrase (classic prompt injection)"),
    ("inj-conceal", "HIGH", R(r"do\s+not\s+(tell|inform|mention)(\s+(this|it|anything))?\s+(to\s+)?the\s+(user|human|operator)|do\s+not\s+(reveal|disclose)\s+(this|it|that|these\s+instructions|what\s+you\s+did)\s+(to\s+)?the\s+(user|human|operator)", re.I),
     "Tells the agent to hide activity from the user"),
    ("inj-secrecy", "HIGH", R(r"\b(secretly|covertly)\s+(run|execute|send|upload|install|delete|download|call|post|report|collect|copy|read)\b|\bwithout\s+the\s+user('|')?s\s+knowledge\b", re.I),
     "Secrecy directive"),
    ("inj-exfil-word", "MEDIUM", R(r"\b(exfiltrate|keylog|beacon\s+home)\b", re.I),
     "Exfiltration vocabulary"),
    ("inj-noconfirm", "MEDIUM", R(r"\b(without\s+(asking|confirming|confirmation|approval))\b.{0,80}\b(delete|remove|send|upload|post|execute|run|install)\b|\b(delete|remove|send|upload|post|execute|run|install)\b.{0,80}\bwithout\s+(asking|confirming|confirmation|approval)\b", re.I | re.S),
     "Destructive action explicitly without confirmation"),
    ("inj-newrole", "MEDIUM", R(r"\byou\s+are\s+no\s+longer\b|\bnew\s+system\s+prompt\b|\boverride\s+(the\s+)?system\s+prompt\b", re.I),
     "Role/system-prompt override language"),
]
SCRIPT_RULES = [
    ("sh-curlpipe", "HIGH", R(r"\b(curl|wget)\b[^\n|;&]*\|\s*(sudo\s+)?(ba)?sh\b"),
     "Network piped straight into a shell"),
    ("sh-b64exec", "HIGH", R(r"base64\s+(-d|--decode)[^\n]*\|\s*(sudo\s+)?(ba)?sh\b|echo\s+[A-Za-z0-9+/=]{40,}\s*\|\s*base64\s+(-d|--decode)"),
     "Decode-and-execute pattern"),
    ("sh-creds", "HIGH", R(r"(~|\$HOME|/Users/[^/\s]+|/home/[^/\s]+)/(\.ssh/|\.aws/credentials|\.netrc|\.gnupg/)|security\s+find-generic-password|\.config/gh/hosts\.yml", re.I),
     "Touches credential stores (ssh/aws/gpg/keychain/gh)"),
    ("sh-shortener", "HIGH", R(r"https?://(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly|rb\.gy)/", re.I),
     "URL shortener (destination hidden)"),
    ("sh-http", "MEDIUM", R(r"\b(curl|wget)\b[^\n]*\bhttp://(?!localhost|127\.0\.0\.1|0\.0\.0\.0)"),
     "Plain-HTTP network call (no TLS)"),
    ("sh-postout", "MEDIUM", R(r"\bcurl\b[^\n]*(-d|--data|--data-binary|-F|--form|-T|--upload-file)[^\n]*\$"),
     "Uploads variable data to the network"),
    ("sh-eval", "MEDIUM", R(r"\beval\s+[\"']?\$"),
     "eval on variable content"),
    ("sh-history", "MEDIUM", R(r"(~|\$HOME)/\.(bash_history|zsh_history|claude/history\.jsonl|claude\.json)\b"),
     "Reads shell/agent history files"),
]
# U+200C/U+200D are legitimate inside emoji sequences and some scripts — they
# only count as hidden when sandwiched between plain ASCII.
UNI_ALWAYS = R("[\u200b\u2060\u202a-\u202e\ufeff]")
UNI_ZWJ_ASCII = R("[\x20-\x7e][\u200c\u200d]+[\x20-\x7e]")

HTML_COMMENT = R(r"<!--(.*?)-->", re.S)
IMPERATIVE = R(r"\b(curl|wget|send\s+to|upload|post\s+to|do\s+not\s+(tell|mention|inform)|ignore\s+(all|previous|prior)|delete\s+(all|the\s+user))\b", re.I)
B64_BLOB = R(r"[A-Za-z0-9+/]{120,}={0,2}")
CODE_FENCE = R(r"```.*?```", re.S)

def scan_file(path, rel, is_md, findings):
    try:
        if os.path.getsize(path) > MAX_FILE_BYTES:
            return
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except OSError:
        return

    def add(rule_id, sev, title, snippet):
        findings.append({"rule": rule_id, "severity": sev, "title": title,
                         "file": rel, "evidence": snippet.strip()[:160]})

    m = UNI_ALWAYS.search(text) or UNI_ZWJ_ASCII.search(text)
    if m:
        ctx = text[max(0, m.start()-40):m.start()+40]
        add("uni-hidden", "HIGH", "Zero-width or bidi-control unicode (hidden text)", repr(ctx))

    if is_md:
        prose = CODE_FENCE.sub("", text)
        for rule_id, sev, rx, title in MD_RULES:
            m = rx.search(prose)
            if m:
                add(rule_id, sev, title, prose[max(0, m.start()-30):m.end()+30])
        for m in HTML_COMMENT.finditer(text):
            body = m.group(1)
            if len(body) > 20 and IMPERATIVE.search(body):
                add("md-htmlcomment", "MEDIUM",
                    "HTML comment contains imperative instructions (invisible when rendered)", body)
                break
        for m in B64_BLOB.finditer(text):
            blob = m.group(0)
            try:
                decoded = base64.b64decode(blob + "=" * (-len(blob) % 4), validate=False)
                printable = sum(1 for b in decoded if 32 <= b < 127 or b in (9, 10, 13))
                if printable / max(1, len(decoded)) > 0.85:
                    add("md-b64", "MEDIUM", "Large decodable base64 blob in markdown", blob[:60] + "...")
                    break
            except Exception:
                pass
    else:
        for rule_id, sev, rx, title in SCRIPT_RULES:
            m = rx.search(text)
            if m:
                line_start = text.rfind("\n", 0, m.start()) + 1
                line_end = text.find("\n", m.end())
                add(rule_id, sev, title, text[line_start:line_end if line_end > 0 else None])

def scan_dir(path):
    findings = []
    n = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
        for fn in files:
            if n >= MAX_FILES_PER_SKILL:
                break
            fp = os.path.join(root, fn)
            if os.path.islink(fp):
                continue
            ext = os.path.splitext(fn)[1].lower()
            rel = os.path.relpath(fp, path)
            if ext in MD_EXT:
                scan_file(fp, rel, True, findings)
                n += 1
            elif ext in SCRIPT_EXT:
                scan_file(fp, rel, False, findings)
                n += 1
    return findings

results = []
with open(TARGETS) as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 2:
            continue
        name, path = parts
        findings = scan_dir(path)
        sevs = {x["severity"] for x in findings}
        verdict = "RISK" if "HIGH" in sevs else ("REVIEW" if "MEDIUM" in sevs else "PASS")
        results.append({"name": name, "path": path, "verdict": verdict, "findings": findings})

results.sort(key=lambda s: ({"RISK": 0, "REVIEW": 1, "PASS": 2}[s["verdict"]], s["name"]))
risk = [s for s in results if s["verdict"] == "RISK"]
review = [s for s in results if s["verdict"] == "REVIEW"]

if JSON_OUTPUT:
    print(json.dumps({"scanned": len(results), "risk": len(risk), "review": len(review),
                      "passed": len(results) - len(risk) - len(review), "skills": results}, indent=2))
    sys.exit(0)

print(f"Scanned: {len(results)} | RISK: {len(risk)} | REVIEW: {len(review)} | PASS: {len(results)-len(risk)-len(review)}")
print("Findings are heuristics: read the file before trusting the directory; nothing is blocked or deleted.")
print()
for s in risk + review:
    print(f"[{s['verdict']}] {s['name']} ({s['path']})")
    for fnd in s["findings"]:
        print(f"    {fnd['severity']:<6} {fnd['rule']}: {fnd['title']}")
        print(f"           {fnd['file']}: {fnd['evidence'][:110]}")
    print()
if not risk and not review:
    print("No suspicious patterns found.")
PYEOF
