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
#   - injection phrases ("ignore previous instructions", "do not tell the
#     user"), read in the raw text, code fences included — a fence is a
#     rendering convention; a session loading the body reads through it
#   - imperative text hidden in HTML comments; zero-width / bidi unicode
#   - large decodable base64 blobs in markdown, whether the decode is text
#     (hidden instructions) or not (a smuggled payload)
#   - scripts that pipe the network into a shell, decode-and-exec, read
#     credential stores (ssh/aws/gpg/keychain/gh/npmrc — `~`, `$HOME`, the
#     quoted and braced forms, and a literal home path), call URL shorteners
#     or plain HTTP off the private ranges, eval variables, read shell or
#     agent history
#   - scripts carrying a hex-encoded blob, a drop-site URL (paste sites, file
#     drops, tunnels, request bins, chat webhooks, a telegram bot, a raw IP in
#     dotted, decimal, hex or IPv6 form — private and loopback ranges
#     exempt), a download-then-chmod sequence in either order (`-o`, a
#     redirect, or `tee`; a symbolic or numeric mode; `install -m`), or a
#     line over 5,000 characters (minified)
#   - a manifest (package.json) whose `scripts` block carries an install-time
#     lifecycle hook, or whose pnpm block builds dependencies; the manifest
#     text is then scanned by every script rule too, so a payload in the hook
#     command is read
#   - a compiled binary anywhere in the directory (ELF, Mach-O, PE magic)
#   - instructions that fetch a URL "fresh"/"before each run" and apply what
#     comes back — a skill whose rules change under the installer with no
#     commit (the Vercel guidelines wrapper shape; read inside code fences,
#     since that is where the URL sits)
#   - a scan that could not be whole: a file over 1 MB, a directory past the
#     200-file cap, or a file the scanner could not open is a finding of its
#     own, so an incomplete scan never renders as PASS
# What is a script: a file with a script extension, a `#!` first line, an
# executable mode, or the basename Makefile/Dockerfile/Justfile/Rakefile.
# Verdict per directory: RISK (any HIGH), REVIEW (any MEDIUM), PASS.
# The 2026-08-29 additions (hex blob, drop site, download-then-exec,
# minified, npmrc, install hook, binary, remote instructions) follow the
# pattern classes in the openhonest/honest-skills sweep skill (Apache-2.0,
# swept at 2397865; ADR-0034 keeps the lineage), rewritten here.
# Not read: a domain assembled from a variable, a manifest other than npm's
# (setup.py, pyproject.toml, Cargo.toml, Makefile targets are scanned as
# scripts, never as manifests), and anything under .git, node_modules, or
# __pycache__. A symlink inside the directory is skipped; the directory
# handed on the command line is followed if it is itself a symlink.
#
# Usage:
#   security.sh --path <dir> [--path <dir> ...]   # one verdict per directory
#   security.sh --json ...                         # machine-readable
#   security.sh --each <parent>                    # every child directory of <parent>
# Example:
#   bash scripts/security.sh --path ~/code/lib/some-skill
#
# stdout carries the verdicts and findings alone; the advisory line and
# every error go to stderr.
# Exit codes: 0 scanned (whatever the verdicts) · 2 nothing scanned (a --path
# that is not a directory) · 3 usage error (no target, an unknown option,
# python3 missing, a path holding a tab or newline).
# Needs bash 3.2+ and python3; no network, nothing installed.
# scripts/security-selftest.sh runs it against scripts/lint-fixtures/security/.

set -euo pipefail

# --help prints the header above: line 2 to the first blank line, so a header
# edit never leaves the help truncated mid-sentence.
usage() { sed -n '2,/^$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

JSON_OUTPUT=false
TARGETS_TSV=$(mktemp -t security-scan.XXXXXX)
trap 'rm -f "$TARGETS_TSV"' EXIT

add_target() {
  case "$1" in
    *$'\t'*|*$'\n'*)
      echo "ERROR: path holds a tab or newline and cannot be listed: $1 — rename it, or scan its parent with --each" >&2; exit 3 ;;
  esac
  if [ ! -d "$1" ]; then
    echo "ERROR: not a directory: $1 — nothing scanned; pass the skill's directory, not a file" >&2
    exit 2
  fi
  printf '%s\n' "$1" >> "$TARGETS_TSV"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --path) [ $# -ge 2 ] || { echo "ERROR: --path needs a directory — run with --help" >&2; exit 3; }; add_target "$2"; shift 2 ;;
    --each)
      [ $# -ge 2 ] || { echo "ERROR: --each needs a directory — run with --help" >&2; exit 3; }
      [ -d "$2" ] || { echo "ERROR: not a directory: $2 — nothing scanned; --each takes the parent of the skill directories" >&2; exit 2; }
      for d in "$2"/*; do [ -d "$d" ] && add_target "$d"; done
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1 — run with --help for the flags" >&2; exit 3 ;;
  esac
done

if [ ! -s "$TARGETS_TSV" ]; then
  echo "ERROR: nothing to scan — pass --path <dir> or --each <parent>" >&2
  exit 3
fi
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required — install it; the scanner is a python program driven from bash" >&2; exit 3; }

export TARGETS_TSV JSON_OUTPUT

python3 <<'PYEOF'
import base64
import json
import os
import re
import stat
import sys

JSON_OUTPUT = os.environ.get("JSON_OUTPUT", "false") == "true"
TARGETS = os.environ.get("TARGETS_TSV", "")

MD_EXT = {".md", ".markdown", ".txt"}
SCRIPT_EXT = {".sh", ".bash", ".zsh", ".py", ".js", ".mjs", ".cjs", ".ts", ".mts", ".cts", ".rb", ".pl"}
SCRIPT_NAMES = {"Makefile", "makefile", "GNUmakefile", "Dockerfile", "Justfile", "justfile", "Rakefile"}
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
_HOME = r"(~|[\"']?\$\{?HOME\}?[\"']?|/Users/[^/\s]+|/home/[^/\s]+)"
# Private, link-local and loopback ranges are exempt from the raw-IP rule: a
# health check against a container gateway is not a drop site.
_PRIVATE_IP = r"(?!127\.|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|169\.254\.)"
_DROP_HOSTS = (
    r"pastebin\.com|paste\.ee|hastebin\.com|dpaste\.(com|org)|ghostbin\.[a-z]+|rentry\.co|"
    r"transfer\.sh|0x0\.st|file\.io|anonfiles\.com|gofile\.io|catbox\.moe|"
    r"[a-z0-9-]+\.ngrok(-free)?\.(io|app|dev)|[a-z0-9-]+\.trycloudflare\.com|[a-z0-9-]+\.loca\.lt|[a-z0-9-]+\.serveo\.net|"
    r"webhook\.site|requestbin\.(com|net)|[a-z0-9-]+\.pipedream\.net|[a-z0-9-]+\.requestcatcher\.com|"
    r"discord(app)?\.com/api/webhooks|hooks\.slack\.com|[a-z0-9-]+\.webhook\.office\.com|api\.telegram\.org/bot"
)
_RAW_IP = _PRIVATE_IP + r"\d{1,3}(\.\d{1,3}){3}|\d{8,10}|0x[0-9a-f]{8}|\[[0-9a-f:]{3,}\]"
SCRIPT_RULES = [
    ("sh-curlpipe", "HIGH", R(r"\b(curl|wget)\b[^\n|;&]*\|\s*(sudo\s+)?(ba)?sh\b"),
     "Network piped straight into a shell"),
    ("sh-b64exec", "HIGH", R(r"base64\s+(-d|--decode)[^\n]*\|\s*(sudo\s+)?(ba)?sh\b|echo\s+[A-Za-z0-9+/=]{40,}\s*\|\s*base64\s+(-d|--decode)"),
     "Decode-and-execute pattern"),
    ("sh-creds", "HIGH", R(_HOME + r"/(\.ssh/|\.aws/credentials|\.netrc|\.npmrc|\.gnupg/)|security\s+find-generic-password|\.config/gh/hosts\.yml", re.I),
     "Touches credential stores (ssh/aws/gpg/keychain/gh/npmrc)"),
    ("sh-dropsite", "HIGH", R(r"https?://(" + _DROP_HOSTS + r"|" + _RAW_IP + r")(?![\w.-])", re.I),
     "Drop-site URL (paste site, file drop, tunnel, request bin, chat webhook, telegram bot, or raw IP)"),
    ("sh-dlexec", "HIGH", R(
        r"\b(curl|wget)\b[^\n]*(\s-[oO]\s|--output(-document)?[ =]|>>?\s*\S|\|\s*tee\b)[^\n]*(\n[^\n]*){0,5}?\b(chmod\s+[+ugoa]*x|chmod\s+0?[0-7]*[1357][0-7]{0,2}\b|install\s+-m\s*0?[0-7]*[1357])"
        r"|\b(chmod\s+[+ugoa]*x|chmod\s+0?[0-7]*[1357][0-7]{0,2}\b|install\s+-m\s*0?[0-7]*[1357])[^\n]*(\n[^\n]*){0,5}?\b(curl|wget)\b[^\n]*(\s-[oO]\s|--output(-document)?[ =]|>>?\s*\S|\|\s*tee\b)"),
     "Download-then-execute (fetches a file and makes it executable, in either order)"),
    ("sh-hexblob", "MEDIUM", R(r"(\\x[0-9a-fA-F]{2}){20,}|(?<![0-9a-fA-F])[0-9a-fA-F]{200,}"),
     "Hex-encoded blob (obfuscated payload)"),
    ("sh-shortener", "HIGH", R(r"https?://(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly|rb\.gy)/", re.I),
     "URL shortener (destination hidden)"),
    ("sh-http", "MEDIUM", R(r"\b(curl|wget)\b[^\n]*\bhttp://(?!localhost)" + _PRIVATE_IP),
     "Plain-HTTP network call (no TLS)"),
    ("sh-postout", "MEDIUM", R(r"\bcurl\b[^\n]*(-d|--data|--data-binary|-F|--form|-T|--upload-file)[^\n]*\$"),
     "Uploads variable data to the network"),
    ("sh-eval", "MEDIUM", R(r"\beval\s+[\"']?\$"),
     "eval on variable content"),
    ("sh-history", "MEDIUM", R(_HOME + r"/\.(bash_history|zsh_history|claude/history\.jsonl|claude\.json)\b"),
     "Reads shell/agent history files"),
]
# U+200C/U+200D are legitimate inside emoji sequences and some scripts — they
# only count as hidden when sandwiched between plain ASCII.
UNI_ALWAYS = R("[\u200b\u2060\u202a-\u202e\ufeff]")
UNI_ZWJ_ASCII = R("[\x20-\x7e][\u200c\u200d]+[\x20-\x7e]")

# npm lifecycle names that run on install or publish; pnpm's build allow-list
# is the same class. Read only under the manifest's `scripts` (or `pnpm`) key.
MANIFEST_HOOKS = {"preinstall", "install", "postinstall", "prepare", "preprepare", "postprepare",
                  "prepublish", "prepublishOnly", "prepack", "postpack", "dependencies"}
MANIFEST_HOOK_FALLBACK = R(r"\"scripts\"\s*:\s*\{[^}]*\"(" + "|".join(sorted(MANIFEST_HOOKS)) + r")\"\s*:", re.S)
BINARY_MAGIC = (b"\x7fELF", b"MZ", b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xce", b"\xfe\xed\xfa\xcf", b"\xca\xfe\xba\xbe")
# `latest` is deliberately not a cue: "fetch the latest release notes before a
# major upgrade" is ordinary reference prose and drew a false positive on the
# clean fixture; the per-run cues below are what mark rules that change under
# the installer. The 2026-08-29 review (F19) asked for the object of the fetch
# — guidelines, rules, instructions — as the distinguishing signal instead;
# that widening is a judgment call recorded beside this comment, not made.
_CUE = r"(fresh|always|before\s+(each|every)|on\s+(each|every)|(each|every)\s+(run|time|review|session|invocation|use))"
_VERB = r"(fetch|fetches|download|downloads|curl|wget|webfetch|pull|pulls|read|reads|load|loads|apply|applies)"
REMOTE_INSTR = R(r"\b" + _VERB + r"\b[^\n]{0,80}\b" + _CUE + r"\b[\s\S]{0,400}?https?://\S+|\b" + _CUE + r"\b[^\n]{0,80}\b" + _VERB + r"\b[\s\S]{0,400}?https?://\S+", re.I)
HTML_COMMENT = R(r"<!--(.*?)-->", re.S)
IMPERATIVE = R(r"\b(curl|wget|send\s+to|upload|post\s+to|do\s+not\s+(tell|mention|inform)|ignore\s+(all|previous|prior)|delete\s+(all|the\s+user))\b", re.I)
B64_BLOB = R(r"[A-Za-z0-9+/]{120,}={0,2}")


def finding(findings, rule_id, sev, title, rel, snippet):
    findings.append({"rule": rule_id, "severity": sev, "title": title,
                     "file": rel, "evidence": snippet.strip()[:160]})


def line_at(text, m):
    line_start = text.rfind("\n", 0, m.start()) + 1
    line_end = text.find("\n", m.end())
    return text[line_start:line_end if line_end > 0 else None]


def scan_text(text, rel, is_md, findings):
    m = UNI_ALWAYS.search(text) or UNI_ZWJ_ASCII.search(text)
    if m:
        ctx = text[max(0, m.start()-40):m.start()+40]
        finding(findings, "uni-hidden", "HIGH", "Zero-width or bidi-control unicode (hidden text)", rel, repr(ctx))

    if is_md:
        m = REMOTE_INSTR.search(text)
        if m:
            finding(findings, "md-remote-instructions", "MEDIUM",
                    "Fetches instructions from a URL on each run and applies them (rules change under the installer with no commit)",
                    rel, m.group(0))
        for rule_id, sev, rx, title in MD_RULES:
            m = rx.search(text)
            if m:
                finding(findings, rule_id, sev, title, rel, text[max(0, m.start()-30):m.end()+30])
        for m in HTML_COMMENT.finditer(text):
            body = m.group(1)
            if len(body) > 20 and IMPERATIVE.search(body):
                finding(findings, "md-htmlcomment", "MEDIUM",
                        "HTML comment contains imperative instructions (invisible when rendered)", rel, body)
                break
        for m in B64_BLOB.finditer(text):
            blob = m.group(0)
            try:
                decoded = base64.b64decode(blob + "=" * (-len(blob) % 4), validate=False)
            except Exception:
                continue
            if not decoded:
                continue
            printable = sum(1 for b in decoded if 32 <= b < 127 or b in (9, 10, 13)) / len(decoded)
            if printable > 0.85:
                finding(findings, "md-b64", "MEDIUM", "Large base64 blob in markdown that decodes to text (hidden instructions)", rel, blob[:60] + "...")
                break
            if printable < 0.5 and len(decoded) >= 64:
                finding(findings, "md-b64", "MEDIUM", "Large base64 blob in markdown that decodes to non-text (smuggled payload)", rel, blob[:60] + "...")
                break
    else:
        longest = max((len(l) for l in text.split("\n")), default=0)
        if longest > 5000:
            finding(findings, "sh-minified", "MEDIUM", f"Minified or single-line script (a line of {longest} chars)", rel, text[:80])
        for rule_id, sev, rx, title in SCRIPT_RULES:
            m = rx.search(text)
            if m:
                finding(findings, rule_id, sev, title, rel, line_at(text, m))


def read_text(path, rel, findings):
    """The file's text, or None with a finding saying why the scan is not whole."""
    try:
        size = os.path.getsize(path)
        if size > MAX_FILE_BYTES:
            finding(findings, "scan-skipped", "MEDIUM", f"File over {MAX_FILE_BYTES:,} bytes was not scanned ({size:,} bytes) — read it by hand", rel, "")
            return None
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError as e:
        finding(findings, "scan-error", "MEDIUM", "File could not be read, so nothing here was checked", rel, str(e))
        return None


def manifest_hooks(text):
    """Lifecycle hooks under `scripts`, and pnpm's build allow-list, as (key, command) pairs."""
    try:
        data = json.loads(text)
    except ValueError:
        m = MANIFEST_HOOK_FALLBACK.search(text)
        return [(m.group(1), "(manifest is not valid JSON; matched by text)")] if m else []
    hits = []
    scripts = data.get("scripts") if isinstance(data, dict) else None
    if isinstance(scripts, dict):
        for k, v in scripts.items():
            if k in MANIFEST_HOOKS:
                hits.append((k, str(v)))
    pnpm = data.get("pnpm") if isinstance(data, dict) else None
    if isinstance(pnpm, dict) and pnpm.get("onlyBuiltDependencies"):
        hits.append(("pnpm.onlyBuiltDependencies", json.dumps(pnpm["onlyBuiltDependencies"])))
    return hits


def looks_like_script(fp, fn, ext):
    if ext in SCRIPT_EXT or fn in SCRIPT_NAMES or fn == ".pnpmfile.cjs":
        return True
    try:
        if os.stat(fp).st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH):
            return True
        with open(fp, "rb") as fh:
            return fh.read(2) == b"#!"
    except OSError:
        return False


def scan_dir(path):
    findings = []
    n = 0
    capped = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
        for fn in files:
            fp = os.path.join(root, fn)
            if os.path.islink(fp):
                continue
            rel = os.path.relpath(fp, path)
            if n >= MAX_FILES_PER_SKILL:
                capped += 1
                continue
            n += 1
            ext = os.path.splitext(fn)[1].lower()
            try:
                with open(fp, "rb") as fh:
                    head = fh.read(4)
            except OSError as e:
                finding(findings, "scan-error", "MEDIUM", "File could not be read, so nothing here was checked", rel, str(e))
                continue
            if any(head.startswith(magic) for magic in BINARY_MAGIC):
                finding(findings, "bin-compiled", "HIGH", "Compiled binary present (ELF/Mach-O/PE magic)", rel, head.hex())
                continue
            if fn == "package.json":
                text = read_text(fp, rel, findings)
                if text is None:
                    continue
                for key, cmd in manifest_hooks(text):
                    finding(findings, "manifest-hook", "HIGH", "Install-time script hook in a manifest (runs on npm install, before anyone reads it)", rel, f"{key}: {cmd}")
                scan_text(text, rel, False, findings)
                continue
            if ext in MD_EXT:
                is_md = True
            elif looks_like_script(fp, fn, ext):
                is_md = False
            else:
                continue
            text = read_text(fp, rel, findings)
            if text is not None:
                scan_text(text, rel, is_md, findings)
    if capped:
        finding(findings, "scan-skipped", "MEDIUM", f"{capped} file(s) past the {MAX_FILES_PER_SKILL}-file cap were not scanned — read them by hand", ".", "")
    return findings


results = []
with open(TARGETS) as f:
    for line in f:
        path = line.rstrip("\n")
        if not path:
            continue
        name = os.path.basename(path.rstrip("/")) or path
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

print("Findings are heuristics: read the file before trusting the directory; nothing is blocked or deleted.", file=sys.stderr)
print(f"Scanned: {len(results)} | RISK: {len(risk)} | REVIEW: {len(review)} | PASS: {len(results)-len(risk)-len(review)}")
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
