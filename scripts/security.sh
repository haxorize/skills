#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
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
#   - scripts that reach the cloud instance-metadata endpoint (169.254.169.254,
#     the one link-local address the private-range exemption does not cover,
#     and its IPv6 form fd00:ec2::254, since one GET there returns the
#     instance role's credentials), name an agent's configuration outside a
#     comment (a
#     ~/.claude, ~/.codex or ~/.gemini directory, a .credentials.json, an
#     mcp.json, a peer skill's SKILL.md by a ../ or skills/ path — a mention
#     is a hit, a read verb is not required), persist past the session
#     (crontab other than -l/-r, launchctl load or bootstrap, a write into
#     LaunchAgents or a systemd user unit directory, a redirect or tee into a
#     shell rc file, systemctl enable), turn TLS verification off (curl -k in
#     curl's own command, --no-check-certificate,
#     verify=False, rejectUnauthorized: false, the node and git env switches),
#     or serialise the whole environment (JSON.stringify(process.env),
#     dict(os.environ), env piped to a network tool or an encoder)
#   - a Latin-lookalike letter from another script (Cyrillic or Greek) in a
#     run of ASCII letters — a homoglyph — anywhere in markdown or script
#     text; a whole foreign word, an accented name, CJK beside ASCII, a run of
#     one ASCII letter and one lookalike (a regex range a-zА-Я, a unit εr),
#     and the ASCII tail of a backslash escape (\nОтвет) never count, and an
#     accent elsewhere in the same token does not hide a hit
#   - shipped Python bytecode (.pyc/.pyo, __pycache__ included), flagged by
#     name — a decoy source can sit beside compiled code — and then read like
#     any other file, so a script renamed .pyc still draws the script rules;
#     bytecode does not count against the file cap
#   - a scan that could not be whole: a file over 1 MB (its first 1 MB is
#     still scanned), a directory past the 200-file cap, a file that is not
#     UTF-8 or UTF-16/32 text, or a file the scanner could not open is a
#     finding of its own, so an incomplete scan never renders as PASS.
#     The cap bounds files SCANNED, not files touched: every file in the tree
#     is stat'd and opened for a four-byte header read before the cap is
#     charged, so the work of walking a directory is unbounded and only the
#     text scanning is capped
# What is a script: a file with a script extension (sh, bash, zsh, fish, ksh,
# py, js/mjs/cjs/jsx, ts/mts/cts/tsx, rb, pl, php, lua, ps1/psm1, bat, cmd —
# whitespace around the name ignored), a `#!` first line, an executable mode,
# the basename Makefile/Dockerfile/Justfile/Rakefile, or a config file (.json,
# .toml, .yaml/.yml) — read as script text, so a hook command in
# .claude/settings.json, a server command in .mcp.json, or a [tool] command in
# pyproject.toml is scanned; package.json is also read as a manifest.
# Verdict per directory: RISK (any HIGH), REVIEW (any MEDIUM), PASS. A rule
# reports once per matching line, not once per file; the text output shows
# five findings per rule and file (per rule and directory for a finding with
# no line) and counts the rest, --json carries every one.
# The 2026-08-29 additions (hex blob, drop site, download-then-exec,
# minified, npmrc, install hook, binary, remote instructions) follow the
# pattern classes in zcaceres/skills' investigate-repo skill (MIT, swept at
# b7213839; ADR-0034 keeps the lineage — the openhonest/honest-skills
# attribution this header carried until 2026-09-04 was wrong), rewritten
# here; the same day's second set (metadata endpoint, agent config,
# persistence, TLS off,
# environment dump, homoglyph, bytecode) follows nvidia/skillspector and
# DataDog/guarddog (both Apache-2.0; ADR-0075 records the round), rewritten
# here with a homoglyph table of our own.
# Not read: a file that is neither markdown (.md, .markdown, .txt) nor
# script-like as defined above (.html, .rst, .env, .csv, a data file) is not
# opened at all; the injection-phrase rules run over markdown only, so a
# config file is read for the shell patterns, never for injection wording; a
# generated lock file (package-lock.json, pnpm-lock.yaml, *-lock.json) is
# never opened; a domain assembled from a variable; a manifest other than
# npm's (setup.py, pyproject.toml, Cargo.toml, Makefile targets are scanned
# as scripts, never as manifests); a body that asks for a credential or a
# person's data in ordinary prose without the flagged vocabulary
# (inj-exfil-word catches "exfiltrate", "keylog", "beacon home" and nothing
# else — that read is the skill-security-review.md lens's, in write-skill);
# and anything under .git or node_modules. A symlink inside the directory is
# skipped, and so is a symlinked subdirectory, with no finding (ADR-0075's
# batch-1 amendment records this as an accepted boundary, alongside the absence
# of a per-file time budget; the third boundary that amendment named — the cap
# applied in walk order, so padding hid a payload behind it — is fixed, the cap
# now being charged after classification and only on files the walk opens);
# the directory handed on the command line is followed if it is itself a
# symlink.
#
# Usage:
#   security.sh --path <dir> [--path <dir> ...]   # one verdict per directory
#   security.sh --json ...                         # machine-readable
#   security.sh --each <parent>                    # every child directory of <parent>
#   security.sh --fail-on risk|review ...          # non-zero exit at or past the threshold
# Example:
#   bash scripts/security.sh --path ~/code/lib/some-skill
#
# stdout carries the verdicts and findings alone; the advisory line and
# every error go to stderr.
# Exit codes: 0 scanned (whatever the verdicts, unless --fail-on turned them
# into the status) · 1 the scanner crashed (no findings were produced; the
# traceback is on stderr) · 2 nothing scanned (a --path that is not a
# directory) · 3 usage error (no target, an unknown option, a --fail-on value
# other than risk or review, python3 missing, a path holding a tab or newline)
# · 4 the --fail-on threshold was met: with risk, some scanned target graded
# RISK; with review, some target graded REVIEW or RISK. The scan still
# completed and the summary and findings still printed — the flag only turns
# the verdict into a status a caller can gate on
# (`security.sh --fail-on risk --path X && install`); without it the verdicts
# never move the exit code.
# Needs bash 3.2+ and python3; no network, nothing installed.
# scripts/security-selftest.sh runs it against scripts/lint-fixtures/security/.

set -euo pipefail

# --help prints the header above: line 2 to the first blank line, so a header
# edit never leaves the help truncated mid-sentence.
usage() { sed -n '2,/^$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

JSON_OUTPUT=false
FAIL_ON=""
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
      # Three globs, so a dot-named child (bash 3.2 has no dotglob) is scanned too.
      for d in "$2"/* "$2"/.[!.]* "$2"/..?*; do [ -d "$d" ] && add_target "$d"; done
      shift 2 ;;
    --fail-on)
      [ $# -ge 2 ] || { echo "ERROR: --fail-on needs a threshold: risk or review — run with --help" >&2; exit 3; }
      case "$2" in
        risk|review) FAIL_ON="$2" ;;
        *) echo "ERROR: --fail-on takes risk or review, not: $2 — run with --help for the flags" >&2; exit 3 ;;
      esac
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

export TARGETS_TSV JSON_OUTPUT FAIL_ON

python3 <<'PYEOF'
import base64
import json
import os
import re
import stat
import sys
import unicodedata
from collections import namedtuple

JSON_OUTPUT = os.environ.get("JSON_OUTPUT", "false") == "true"
FAIL_ON = os.environ.get("FAIL_ON", "")
TARGETS = os.environ.get("TARGETS_TSV", "")

MD_EXT = {".md", ".markdown", ".txt"}
SCRIPT_EXT = {".sh", ".bash", ".zsh", ".fish", ".ksh", ".py", ".js", ".mjs", ".cjs", ".jsx", ".ts", ".mts", ".cts", ".tsx",
              ".rb", ".pl", ".php", ".lua", ".ps1", ".psm1", ".bat", ".cmd"}
SCRIPT_NAMES = {"Makefile", "makefile", "GNUmakefile", "Dockerfile", "Justfile", "justfile", "Rakefile"}
# Config files are read as script text: a command inside one runs the same.
CONFIG_EXT = {".json", ".toml", ".yaml", ".yml"}
BYTECODE_EXT = {".pyc", ".pyo"}
MAX_FILE_BYTES = 1_000_000
MAX_FILES_PER_SKILL = 200
MAX_LINES_PER_RULE_FILE = 5  # text output only: past this, one rule in one file prints "+N more"

R = re.compile
# Generated lock files are data, routinely over the size cap, and never opened.
LOCK_FILE = R(r"^(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|.*[.-]lock\.(json|yaml|yml|toml))$")
# A rule is (id, severity, pattern, title); the tables below keep the tuple
# shape and are wrapped at load, so a table row and a one-off rule share one
# definition.
Rule = namedtuple("Rule", "id sev rx title")
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
    r"discord(app)?\.com/api/webhooks|hooks\.slack\.com|[a-z0-9-]+\.webhook\.office\.com|api\.telegram\.org/bot[\w:-]*"
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
    # 169.254.169.254 sits inside the link-local range _PRIVATE_IP exempts, so
    # it is its own rule rather than a drop-site hit.
    ("sh-imds", "HIGH", R(r"169\.254\.169\.254|fd00:ec2::254"),
     "Cloud instance-metadata endpoint (one unauthenticated GET returns the instance role's credentials)"),
    # history.jsonl is sh-history's; every other read under an agent's
    # directory lands here.
    # A line that is only a comment names nothing the shell reads, so the rule
    # starts past a leading `#` or `//`; a trailing comment still counts.
    ("sh-agentcfg", "HIGH", R(r"(?m)^(?![ \t]*(#|//))[^\n]*?(" + _HOME + r"/\.(claude|codex|gemini)(/(?!history\.jsonl\b)|(?![\w./-]))|\.credentials\.json\b|\bmcp\.json\b|(\.\./|\bskills/)[^\s\"']*SKILL\.md\b)"),
     "Names agent configuration (an agent's config directory, its credentials file, mcp.json, or a peer skill's body)"),
    # `crontab -l` and `crontab -r` list and delete; every other operand
    # installs. The two path alternatives need a write beside them (a
    # redirect, tee, cp, mv, ln, install), so a mention is not a hit.
    ("sh-persist", "HIGH", R(r"\bcrontab\s+(?!-[lr]\b)\S|\blaunchctl\s+(load|bootstrap)\b|(>>?|\b(tee|cp|mv|ln|install)\b)[^\n]*?(Library/LaunchAgents/|\.config/systemd/user/)|(>>?|\|\s*tee(\s+-a)?)\s*[\"']?" + _HOME + r"/\.(zshrc|bashrc|bash_profile|profile|zprofile)(?![\w.])|\bsystemctl\s+(--user\s+)?enable\b"),
     "Persists beyond the session (cron, launchd, a shell-rc write, or a systemd user unit)"),
    # curl's -k must sit in curl's own command: before any pipe or separator.
    ("sh-noverify", "MEDIUM", R(r"\bcurl\b[^\n|;&]*\s(-[a-zA-Z]*k[a-zA-Z]*|--insecure)\b|--no-check-certificate|\bverify\s*=\s*False\b|rejectUnauthorized\s*:\s*false|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*[\"']?0|GIT_SSL_NO_VERIFY\s*=\s*[\"']?(?i:1|true)"),
     "TLS verification disabled"),
    ("sh-envdump", "MEDIUM", R(r"JSON\.stringify\(\s*process\.env\s*\)|\bdict\(\s*os\.environ\s*\)|\b(printenv|env)\b\s*\|[^\n]*\b(curl|wget|nc|ncat|base64|openssl)\b"),
     "Serialises or pipes the whole environment (a credential harvest)"),
]
MD_RULES = [Rule(*r) for r in MD_RULES]
SCRIPT_RULES = [Rule(*r) for r in SCRIPT_RULES]
# Latin-lookalike letters from other scripts — the homoglyph set, hand-listed
# here rather than copied from Unicode's confusables.txt: Cyrillic and Greek,
# both cases where the lookalike holds in both. A token is split into runs at
# `.`, `-`, `_` and at any non-ASCII letter outside this set; a run holding an
# ASCII letter and one of these is a hit. So a whole Cyrillic or Greek word,
# an accented Latin name, or CJK beside ASCII is never a hit, and an accent
# elsewhere in the token (`café.reаd`) does not switch the rule off;
# `reаd_data` with a Cyrillic а is a hit.
CONFUSABLE = "аеорсухіјѕһԁԛԝАВЕКМНОРСТХІЈЅΟοΑΒΕΖΗΙΚΜΝΡΤΥΧαερτυχνικ"
# `\w` plus dot and hyphen: a dotted or hyphenated span is one token, so the
# evidence shows the whole identifier; the run split above decides the hit.
CONFUSABLE_TOKEN = R(r"[\w.-]+")
RUN_SPLIT = R(r"[._-]")
ESCAPE_TAIL = R(r"(u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}|x[0-9a-fA-F]{2}|[A-Za-z0-9])?")
# U+200C/U+200D are legitimate inside emoji sequences and some scripts — they
# only count as hidden when sandwiched between plain ASCII.
UNI_HIDDEN = R("[\u200b\u2060\u202a-\u202e\ufeff]|[\x20-\x7e][\u200c\u200d]+[\x20-\x7e]")
# Control characters in a hostile file name or evidence line are rendered as
# escapes, so a scanned directory cannot rewrite the terminal it is reported on.
CONTROL = R(r"[\x00-\x1f\x7f]")

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
# A hex digest (sha512, blake2b) is base64-shaped and decodes to noise; it is
# a checksum, not a payload.
HEX_ONLY = R(r"^[0-9a-fA-F]+$")


def finding(findings, rule, rel, snippet, line=None):
    """Append one finding. At most one per (rule, file, line): a line a
    pattern hits twice is reported once. A finding with no line (a walk-level
    rule — a manifest hook, a binary) is never deduplicated."""
    key = (rule.id, rel, line)
    if line is not None:
        if key in findings.seen:
            return
        findings.seen.add(key)
    findings.append({"rule": rule.id, "severity": rule.sev, "title": rule.title,
                     "file": rel, "line": line, "evidence": snippet.strip()[:160]})


class Findings(list):
    """The findings of one directory, with the dedupe set beside them."""
    def __init__(self):
        super().__init__()
        self.seen = set()


def esc(s):
    """Text-output rendering of hostile text: control characters as escapes."""
    return CONTROL.sub(lambda m: f"\\x{ord(m.group(0)):02x}", s)


def line_no(text, pos):
    return text.count("\n", 0, pos) + 1


def line_at(text, m):
    line_start = text.rfind("\n", 0, m.start()) + 1
    line_end = text.find("\n", m.end())
    return text[line_start:line_end if line_end > 0 else None]


def report_each(findings, rule, rel, text, evidence=line_at):
    """One finding per line the pattern hits — never only the first — so every
    instance in a file is reported and a fixture annotation can name its line."""
    for m in rule.rx.finditer(text):
        finding(findings, rule, rel, evidence(text, m), line_no(text, m.start()))


def confusable_runs(text):
    """(match, token, confusables) for every token holding a run — letters
    between `.`, `-`, `_` or a non-ASCII letter outside CONFUSABLE — that
    mixes ASCII letters with confusable ones. Two boundaries, measured over
    ~/code/lib on 2026-08-29 (115,739 files): a run of exactly one ASCII
    letter and one lookalike is not a hit (a regex range `a-zА-Я`, a unit
    `εr`), and a token right after a backslash drops its escape prefix
    (`\nОтвет`, `\u0442о`, `\bслово` in Russian-language scripts)."""
    for m in CONFUSABLE_TOKEN.finditer(text):
        tok = m.group(0)
        if tok.isascii():
            continue
        start = 0
        if m.start() > 0 and text[m.start() - 1] == "\\":
            start = ESCAPE_TAIL.match(tok).end()
        ascii_n, conf = 0, []
        for c in tok[start:]:
            foreign = c.isalpha() and not c.isascii() and c not in CONFUSABLE
            if RUN_SPLIT.match(c) or foreign:
                if ascii_n + len(conf) > 2 and ascii_n and conf:
                    break
                ascii_n, conf = 0, []
            elif c.isalpha():
                if c.isascii():
                    ascii_n += 1
                elif c in CONFUSABLE:
                    conf.append(c)
        if ascii_n + len(conf) > 2 and ascii_n and conf:
            yield m, tok, conf


UNI_CONFUSABLE = Rule("uni-confusable", "MEDIUM", None, "Latin-lookalike letter from another script inside an ASCII identifier (homoglyph)")
UNI_HIDDEN_RULE = Rule("uni-hidden", "HIGH", UNI_HIDDEN, "Zero-width or bidi-control unicode (hidden text)")
MD_REMOTE_RULE = Rule("md-remote-instructions", "MEDIUM", REMOTE_INSTR, "Fetches instructions from a URL on each run and applies them (rules change under the installer with no commit)")
MD_HTMLCOMMENT = Rule("md-htmlcomment", "MEDIUM", None, "HTML comment contains imperative instructions (invisible when rendered)")
MD_B64_TEXT = Rule("md-b64", "MEDIUM", None, "Large base64 blob in markdown that decodes to text (hidden instructions)")
MD_B64_PAYLOAD = Rule("md-b64", "MEDIUM", None, "Large base64 blob in markdown that decodes to non-text (smuggled payload)")
SH_MINIFIED = Rule("sh-minified", "MEDIUM", None, "Minified or single-line script")
SCAN_SKIPPED = Rule("scan-skipped", "MEDIUM", None, "Part of the directory was not scanned — read it by hand")
SCAN_ERROR = Rule("scan-error", "MEDIUM", None, "File could not be read, so nothing here was checked")
BIN_BYTECODE = Rule("bin-bytecode", "MEDIUM", None, "Python bytecode shipped (a decoy source can sit beside compiled code); its content is classified like any other file's")
BIN_COMPILED = Rule("bin-compiled", "HIGH", None, "Compiled binary present (ELF/Mach-O/PE magic)")
MANIFEST_HOOK = Rule("manifest-hook", "HIGH", None, "Install-time script hook in a manifest (runs on npm install, before anyone reads it)")


def scan_confusables(text, rel, findings):
    """Every token of the text, markdown body and frontmatter alike."""
    for m, tok, conf in confusable_runs(text):
        points = ", ".join(f"U+{ord(c):04X} {unicodedata.name(c, '?')}" for c in dict.fromkeys(conf))
        finding(findings, UNI_CONFUSABLE, rel, f"{tok} ({points})", line_no(text, m.start()))


def scan_text(text, rel, is_md, findings):
    scan_confusables(text, rel, findings)
    report_each(findings, UNI_HIDDEN_RULE, rel, text, lambda t, m: repr(t[max(0, m.start()-40):m.start()+40]))

    if is_md:
        report_each(findings, MD_REMOTE_RULE, rel, text, lambda t, m: m.group(0))
        for rule in MD_RULES:
            report_each(findings, rule, rel, text, lambda t, m: t[max(0, m.start()-30):m.end()+30])
        for m in HTML_COMMENT.finditer(text):
            body = m.group(1)
            if len(body) > 20 and IMPERATIVE.search(body):
                finding(findings, MD_HTMLCOMMENT, rel, body, line_no(text, m.start()))
        for m in B64_BLOB.finditer(text):
            blob = m.group(0)
            if HEX_ONLY.match(blob):
                continue
            try:
                decoded = base64.b64decode(blob + "=" * (-len(blob) % 4), validate=False)
            except Exception:
                continue
            if not decoded:
                continue
            printable = sum(1 for b in decoded if 32 <= b < 127 or b in (9, 10, 13)) / len(decoded)
            if printable > 0.85:
                finding(findings, MD_B64_TEXT, rel, blob[:60] + "...", line_no(text, m.start()))
            elif printable < 0.5 and len(decoded) >= 64:
                finding(findings, MD_B64_PAYLOAD, rel, blob[:60] + "...", line_no(text, m.start()))
    else:
        lines = text.split("\n")
        longest = max((len(l) for l in lines), default=0)
        if longest > 5000:
            ln = next(i for i, l in enumerate(lines, 1) if len(l) == longest)
            finding(findings, SH_MINIFIED._replace(title=f"Minified or single-line script (a line of {longest} chars)"), rel, text[:80], ln)
        for rule in SCRIPT_RULES:
            report_each(findings, rule, rel, text)


def decode(raw):
    """The file's text. UTF-16/32 with a byte-order mark is decoded as such;
    a NUL-dense file with no mark is not text this scanner reads."""
    for bom, enc in ((b"\xff\xfe\x00\x00", "utf-32"), (b"\x00\x00\xfe\xff", "utf-32"), (b"\xff\xfe", "utf-16"), (b"\xfe\xff", "utf-16")):
        if raw.startswith(bom):
            return raw.decode(enc, errors="replace")
    if raw and raw[:4096].count(0) > len(raw[:4096]) // 10:
        return None
    return raw.decode("utf-8", errors="replace")


def read_text(path, rel, findings):
    """The file's text, or None with a finding saying why the scan is not whole.
    A file over the size cap is scanned to the cap and flagged, so the prefix
    still draws whatever it holds."""
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            raw = f.read(MAX_FILE_BYTES)
        if size > MAX_FILE_BYTES:
            finding(findings, SCAN_SKIPPED._replace(title=f"File over {MAX_FILE_BYTES:,} bytes: only its first {MAX_FILE_BYTES:,} were scanned ({size:,} bytes) — read it by hand"), rel, "")
        text = decode(raw)
        if text is None:
            finding(findings, SCAN_SKIPPED._replace(title="File is not UTF-8 or UTF-16/32 text and was not scanned — read it by hand"), rel, "")
        return text
    except OSError as e:
        finding(findings, SCAN_ERROR, rel, str(e))
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
    if ext in SCRIPT_EXT or ext in CONFIG_EXT or fn in SCRIPT_NAMES or fn == ".pnpmfile.cjs":
        return True
    try:
        if os.stat(fp).st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH):
            return True
        with open(fp, "rb") as fh:
            return fh.read(2) == b"#!"
    except OSError:
        return False


def scan_dir(path):
    findings = Findings()
    n = 0
    capped = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules")]
        for fn in files:
            fp = os.path.join(root, fn)
            if os.path.islink(fp):
                continue
            rel = os.path.relpath(fp, path)
            # Whitespace around the name is not part of the extension.
            ext = os.path.splitext(fn.strip())[1].lower()
            if ext in BYTECODE_EXT:
                # Named as bytecode, and still classified below by what it
                # holds — a script renamed .pyc draws the script rules too.
                # Not counted against the file cap: a build leaves hundreds.
                finding(findings, BIN_BYTECODE, rel, fn)
            try:
                with open(fp, "rb") as fh:
                    head = fh.read(4)
            except OSError as e:
                finding(findings, SCAN_ERROR, rel, str(e))
                continue
            if any(head.startswith(magic) for magic in BINARY_MAGIC):
                finding(findings, BIN_COMPILED, rel, head.hex())
                continue
            if LOCK_FILE.match(fn.strip()):
                continue
            manifest = fn == "package.json"
            if manifest:
                is_md = False
            elif ext in MD_EXT:
                is_md = True
            elif looks_like_script(fp, fn, ext):
                is_md = False
            else:
                continue
            # The cap is charged HERE, on the files this walk actually reads.
            # Charged before the classification it counted every file the walk
            # touched — a lock file, an image, a CSV, anything neither markdown
            # nor script-like — so a directory padded with data files spent the
            # budget on files that were never going to be opened and pushed the
            # real scripts past it, with the SCAN_SKIPPED finding pointing at
            # the padding rather than at them. The bytecode branch above states
            # the intent for its own class; it is the same intent here.
            if ext not in BYTECODE_EXT:
                if n >= MAX_FILES_PER_SKILL:
                    capped += 1
                    continue
                n += 1
            text = read_text(fp, rel, findings)
            if text is None:
                continue
            if manifest:
                for key, cmd in manifest_hooks(text):
                    finding(findings, MANIFEST_HOOK, rel, f"{key}: {cmd}")
            scan_text(text, rel, is_md, findings)
    if capped:
        finding(findings, SCAN_SKIPPED._replace(title=f"{capped} scannable file(s) past the {MAX_FILES_PER_SKILL}-file scan cap were not read — read them by hand. The cap bounds files scanned, not files walked"), ".", "")
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

# --fail-on's gate: the one place the verdicts reach the exit code. Both output
# paths exit through EXIT_CODE, so the summary and findings always print first.
EXIT_CODE = 4 if (FAIL_ON == "risk" and risk) or (FAIL_ON == "review" and (risk or review)) else 0

if JSON_OUTPUT:
    print(json.dumps({"scanned": len(results), "risk": len(risk), "review": len(review),
                      "passed": len(results) - len(risk) - len(review), "skills": results}, indent=2))
    sys.exit(EXIT_CODE)

print("Findings are heuristics: read the file before trusting the directory; nothing is blocked or deleted.", file=sys.stderr)
print(f"Scanned: {len(results)} | RISK: {len(risk)} | REVIEW: {len(review)} | PASS: {len(results)-len(risk)-len(review)}")
print()
for s in risk + review:
    print(f"[{s['verdict']}] {esc(s['name'])} ({esc(s['path'])})")
    shown = {}
    for fnd in s["findings"]:
        # A hostile file can hit one rule ten thousand times, and a build can
        # leave hundreds of bytecode files in one directory; the text report
        # shows the first few per rule and file (per rule and directory, for
        # a finding with no line) and counts the rest, so the distinguishing
        # finding is never buried. --json carries every one.
        k = (fnd["rule"], fnd["file"] if fnd["line"] else os.path.dirname(fnd["file"]) + "/")
        shown[k] = shown.get(k, 0) + 1
        if shown[k] > MAX_LINES_PER_RULE_FILE:
            continue
        print(f"    {fnd['severity']:<6} {fnd['rule']}: {fnd['title']}")
        where = f"{fnd['file']}:{fnd['line']}" if fnd["line"] else fnd["file"]
        print(f"           {esc(where)}: {esc(fnd['evidence'][:110])}")
    for (rule, rel), count in shown.items():
        if count > MAX_LINES_PER_RULE_FILE:
            print(f"           {esc(rel)}: +{count - MAX_LINES_PER_RULE_FILE} more {rule} line(s) not shown")
    print()
if not risk and not review:
    print("No suspicious patterns found.")
sys.exit(EXIT_CODE)
PYEOF
