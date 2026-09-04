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
#   - an invocation-time shell command in markdown: a !`cmd` span or a ```!
#     (or ~~~!) fence in a SKILL.md runs before the model reads the body,
#     with no permission prompt. Reported as md-shell-inline (MEDIUM), and
#     the command text is read by every script rule, so a curl piped to sh
#     in one draws that rule's HIGH on the same line. The span's ! must open
#     a token: prose quoting `fixup!` and then another span is not a command
#   - an injection phrase concealed from the phrase rules: letters spaced out
#     (i g n o r e), a declared marker spliced between letters ("remove the
#     marker XYZ from the text", then igXYZnore), or HTML entity encoding
#     (&#105;gnore). Each line is normalized and the phrase rules re-run over
#     it; a hit the raw text did not already draw is inj-obfuscated, at the
#     severity of the phrase it reads as — concealment never lowers one.
#     Past three declared markers the scanner stops stripping and reports the
#     count instead, so the cap fails closed. A declaration is recognised by
#     a fixed noun list (marker, token, tag, string, sequence, placeholder,
#     characters) — a known bound, not a claim of coverage — and a marker is
#     stripped only inside a word, never as a word of its own
#   - an archive — a .skill bundle, a zip (an Office document, a wheel or a
#     jar included), a tar, a gzipped tar or a gzipped single file, by
#     extension or by magic (zip, gzip, or tar's ustar) — is unpacked to a
#     temporary directory and its members scanned as files of the skill, one
#     level deep, with nothing pruned inside it (a node_modules/ or .git/
#     member is the author's choice). Every way the
#     unpack can be partial is a scan-skipped finding, never PASS: a member
#     that is itself an archive, an archive over 200 members or over 10 MB
#     by its declared sizes, a member whose content does not match its
#     declared size (each read is bounded to the cap, so a lying header
#     cannot drive memory either), a member that is not a regular file, a
#     member whose path escapes the archive, two members on one path (the
#     first is scanned), a binary member with no extension, an archive that
#     will not open, or a container the scanner has no bounded reader for
#     (xz, bz2, zstd, 7z, rar — by extension or magic). A member under a
#     name the classifier declines (an Office document's XML, a gzipped
#     file under a foreign name, an executable with no extension — the
#     stored mode is not applied) is read as text under the markdown and
#     the script rules both; a binary member under a data extension (an
#     image) is the same boundary as outside an archive. An
#     archive whose extension hides what it is (zip, gzip or tar magic under
#     another name) is bin-archive (MEDIUM). In --json a finding under an
#     archive carries the archive's path in its `archive` key (null
#     otherwise) and names the member as <archive>/<member> in `file` — a
#     path that no longer exists on disk once the scan ends
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
# b7213839; ADR-0034 keeps the lineage), rewritten
# here; the same day's second set (metadata endpoint, agent config,
# persistence, TLS off,
# environment dump, homoglyph, bytecode) follows nvidia/skillspector and
# DataDog/guarddog (both Apache-2.0; ADR-0075 records the round), rewritten
# here with a homoglyph table of our own. The 2026-09-04 additions:
# md-shell-inline follows dbreunig/drskill's observation (MIT), inj-obfuscated
# follows nvidia/skillspector's concealment class (Apache-2.0), both written
# here; the archive walk and bin-archive are the scanner's own. ADR-0081
# records the three admissions and their licences.
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
#   security.sh --fail-on risk|review|incomplete   # non-zero exit at or past the threshold
# Example:
#   bash scripts/security.sh --path ~/code/lib/some-skill
#
# stdout carries the verdicts and findings alone; the advisory line and
# every error go to stderr.
# Exit codes: 0 scanned (whatever the verdicts, unless --fail-on turned them
# into the status) · 1 the scanner crashed (no findings were produced; the
# traceback is on stderr) · 2 nothing scanned (a --path that is not a
# directory) · 3 usage error (no target, an unknown option, a --fail-on value
# other than risk, review or incomplete, python3 missing, a path holding a
# tab or newline) · 4 the --fail-on threshold was met: with risk, some
# scanned target graded RISK; with review, some target graded REVIEW or RISK;
# with incomplete, some target graded RISK or carries a scan-skipped or
# scan-error finding — the scan was not whole, whatever its verdict, so a
# bundle padded past a cap cannot buy its way under the gate. The scan still
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
      [ $# -ge 2 ] || { echo "ERROR: --fail-on needs a threshold: risk, review or incomplete — run with --help" >&2; exit 3; }
      case "$2" in
        risk|review|incomplete) FAIL_ON="$2" ;;
        *) echo "ERROR: --fail-on takes risk, review or incomplete, not: $2 — run with --help for the flags" >&2; exit 3 ;;
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
import contextlib
import gzip
import html
import json
import os
import re
import stat
import sys
import tarfile
import tempfile
import unicodedata
import zipfile
import zlib
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
# An archive is unpacked and its members scanned as files of the skill. By
# name: these extensions and `.tar.gz`. By magic: zip, gzip, or tar (the
# `ustar` at byte 257), whatever the name — and a name that hides the magic
# is a finding of its own. So the set does two things: `.tar` is the one
# entry that OPENS something the magic would not, and every other entry
# names a format whose honest name is not flagged as hiding its magic.
# Office documents and the Python and Java package formats are zips under
# an honest name, so they are opened, not flagged; their XML members are
# neither markdown nor script and draw nothing, while a wheel or a jar can
# carry a script that does. A browser extension, an Android package, an
# e-book, a NuGet or VS Code package is not something a skill ships, so
# each is a hidden archive (bin-archive) like any other renamed zip.
ARCHIVE_EXT = {".skill", ".zip", ".tar", ".tgz", ".gz", ".docx", ".xlsx", ".pptx", ".xlam", ".odt", ".ods", ".odp",
               ".jar", ".whl", ".egg"}
GZIP_MAGIC = b"\x1f\x8b"
ARCHIVE_MAGIC = (b"PK\x03\x04", GZIP_MAGIC)
TAR_MAGIC_AT = (257, b"ustar")
HEAD_BYTES = 262                # enough for every magic above, the tar one included
# A container the scanner does not open (no size trailer to bound the read,
# or no stdlib reader): reported, never PASS, never opened.
CONTAINER_EXT = {".xz", ".bz2", ".zst", ".7z", ".rar"}
CONTAINER_MAGIC = (b"\xfd7zXZ\x00", b"BZh", b"\x28\xb5\x2f\xfd", b"7z\xbc\xaf\x27\x1c", b"Rar!")
MAX_ARCHIVE_BYTES = 10_000_000  # unpacked: the members' declared sizes summed, and each read bounded to it
MAX_ARCHIVE_DEPTH = 1           # an archive inside an archive is reported, never opened
# The errors the stdlib raises on a malformed, truncated, encrypted, or
# unsupported archive. Anything else is a scanner bug and reaches the bash
# wrapper as a crash (exit 1), never a finding attributed to the archive.
ARCHIVE_ERRORS = (OSError, EOFError, ValueError, zlib.error, zipfile.BadZipFile, tarfile.TarError, RuntimeError, NotImplementedError)
MAX_MARKERS = 3                 # declared concealment markers stripped per file; past it, a finding
MAX_FILE_BYTES = 1_000_000
MAX_FILES_PER_SKILL = 200
MAX_LINES_PER_RULE_FILE = 5  # text output only: past this, one rule in one file prints "+N more"

R = re.compile
# Generated lock files are data, routinely over the size cap, and never opened.
LOCK_FILE = R(r"^(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|.*[.-]lock\.(json|yaml|yml|toml))$")
# Two rule shapes, told apart by depth: a PatternRule is one table row whose
# regex reaches every call site by itself, and a FindingKind is an id, a
# severity and a title for a detection written by hand (a walk-level check,
# a derived view, a partial scan) — it carries no pattern, so adding one
# means writing the detection and its selftest rows, not a row in a table.
# The tables below keep the tuple shape and are wrapped at load.
PatternRule = namedtuple("PatternRule", "id sev rx title")
FindingKind = namedtuple("FindingKind", "id sev title")
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
MD_RULES = [PatternRule(*r) for r in MD_RULES]
SCRIPT_RULES = [PatternRule(*r) for r in SCRIPT_RULES]
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
# An invocation-time command in markdown: the !`cmd` span, and the ```! or
# ~~~! fence. The span's `!` must open a token — line start, whitespace, or
# an open bracket before it — so a `!` closing one code span (`fixup!`) with
# another span later on the line is prose, not a command. Fences are read
# in order with the open one tracked (shell_fences below), so a ```! fence
# quoted inside another fence is that fence's content, not a command.
MD_SHELL_SPAN = R(r"(?<![^\s(\[])!`(?P<span>[^`\n]+)`")
FENCE_LINE = R(r"^[ \t]*(?P<mark>`{3,}|~{3,})(?P<info>.*)$")
# Concealment the phrase rules cannot see through, undone per line before a
# second pass: a run of single letters separated by one space, dot, hyphen or
# underscore (i g n o r e, d o   n o t) is joined; a marker the text declares ("remove the
# marker XYZ from the following text") is stripped wherever it appears; an
# HTML entity is decoded. Newlines are kept, so a hit maps to its raw line.
# A marker is quoted, or is not a plain lowercase word: "remove all
# characters except ASCII" declares nothing, `remove the marker XYZ` does.
# A declaration is recognised by this noun list and no other: a text that
# says "placeholder" is read, one that says "glyph" or "infix" is not — the
# list is a known bound, not a claim of coverage. A marker is stripped only
# where it sits inside a word (IgQZXnore), never as a word of its own, so a
# quoted common word declared as a marker cannot rewrite ordinary prose.
MARKER_DECL = R(r"\b(remove|strip|delete|drop|ignore)\s+(the\s+|every\s+|all\s+)?(marker|token|tag|string|sequence|placeholder|characters?)\s+([\"'`])?([^\s\"'`,.;:]{2,12})(?(4)[\"'`])", re.I)
PLAIN_WORD = R(r"[a-z]+")
BLANK_LINE = R(r"\n[ \t]*\n")
# One separator kind per run, so `d.o n.o.t` joins into two words, not one.
SPACED = R(r"(?<!\w)\w(?:([ ._-])\w)(?:\1\w)*(?!\w)")
SPACER = R(r"[ ._-]")


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
                     "file": rel, "line": line, "evidence": snippet.strip()[:160],
                     "archive": findings.archive})


def skipped(findings, rel, why, snippet="", what="it"):
    """A scan-skipped finding: `why` opens on a literal, and the title always
    closes by sending the reader to the file, so an incomplete scan never
    renders PASS and never leaves the reader without the next step."""
    finding(findings, SCAN_SKIPPED._replace(title=f"{why} — read {what} by hand"), rel, snippet)


class Findings(list):
    """The findings of one directory, with the dedupe set beside them, and
    the archive whose members are being walked (None outside one) — the
    `archive` key every finding carries, so a `file` of the form
    <archive>/<member> is never mistaken for a path on disk."""
    def __init__(self):
        super().__init__()
        self.archive = None
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


UNI_CONFUSABLE = FindingKind("uni-confusable", "MEDIUM", "Latin-lookalike letter from another script inside an ASCII identifier (homoglyph)")
UNI_HIDDEN_RULE = PatternRule("uni-hidden", "HIGH", UNI_HIDDEN, "Zero-width or bidi-control unicode (hidden text)")
MD_REMOTE_RULE = PatternRule("md-remote-instructions", "MEDIUM", REMOTE_INSTR, "Fetches instructions from a URL on each run and applies them (rules change under the installer with no commit)")
MD_HTMLCOMMENT = FindingKind("md-htmlcomment", "MEDIUM", "HTML comment contains imperative instructions (invisible when rendered)")
MD_B64_TEXT = FindingKind("md-b64", "MEDIUM", "Large base64 blob in markdown that decodes to text (hidden instructions)")
MD_B64_PAYLOAD = FindingKind("md-b64", "MEDIUM", "Large base64 blob in markdown that decodes to non-text (smuggled payload)")
SH_MINIFIED = FindingKind("sh-minified", "MEDIUM", "Minified or single-line script")
SCAN_SKIPPED = FindingKind("scan-skipped", "MEDIUM", "Part of the directory was not scanned — read it by hand")
SCAN_ERROR = FindingKind("scan-error", "MEDIUM", "File could not be read, so nothing here was checked")
BIN_BYTECODE = FindingKind("bin-bytecode", "MEDIUM", "Python bytecode shipped (a decoy source can sit beside compiled code); its content is classified like any other file's")
BIN_COMPILED = FindingKind("bin-compiled", "HIGH", "Compiled binary present (ELF/Mach-O/PE magic)")
MANIFEST_HOOK = FindingKind("manifest-hook", "HIGH", "Install-time script hook in a manifest (runs on npm install, before anyone reads it)")
MD_SHELL_RULE = FindingKind("md-shell-inline", "MEDIUM", "Invocation-time shell command in markdown (runs before the body is read, with no permission prompt); its text was read by the script rules")
INJ_OBFUSCATED = FindingKind("inj-obfuscated", "MEDIUM", "Injection phrase concealed by spacing, a declared marker, or entity encoding")
BIN_ARCHIVE = FindingKind("bin-archive", "MEDIUM", "Archive whose extension hides it (zip, gzip or tar magic under another name); its members were unpacked and scanned")


def deobfuscate(text):
    """(normalized text, declared-marker count). Line count is preserved: a
    decoded entity that is itself a newline becomes a space."""
    markers = [m.group(5) for m in MARKER_DECL.finditer(text) if m.group(4) or not PLAIN_WORD.fullmatch(m.group(5))]
    strip = markers if len(markers) <= MAX_MARKERS else []  # past the cap: report, never guess
    out = []
    for line in text.split("\n"):
        if "&" in line:
            line = html.unescape(line).replace("\n", " ")
        for mk in strip:
            line = re.sub(r"(?<=\w)" + re.escape(mk) + r"(?=\w)", "", line)
        line = SPACED.sub(lambda m: SPACER.sub("", m.group(0)), line)
        out.append(line)
    return "\n".join(out), len(markers)


def derived_view(findings, rel, view, rules, line_of, attribute, novel_only=False):
    """One rule table over a transformed view of a file's text — the seam
    every second-look pass shares, so the two questions a reader has of such
    a pass are answered by its arguments, never by its body. `view` is the
    transformed text and `line_of(m)` maps a hit in it back to the raw file's
    line. `attribute(rule)` is the rule the finding is reported under — the
    matched rule itself (a command read as a script keeps the script rule's
    id and severity), or a view-level kind borrowing the matched rule's
    severity (a normalized phrase is inj-obfuscated at the severity of the
    phrase it reads as; concealment never lowers one). With `novel_only`, a
    hit the raw pass already drew on that line under the matched rule is not
    repeated, and a hit assembled across a paragraph break is dropped."""
    for rule in rules:
        for m in rule.rx.finditer(view):
            ln = line_of(m)
            if novel_only:
                if (rule.id, rel, ln) in findings.seen:
                    continue
                if BLANK_LINE.search(m.group(0)):
                    continue  # a phrase assembled across a paragraph break is prose, not a hit
            finding(findings, attribute(rule), rel, line_at(view, m), ln)


def scan_obfuscated(text, rel, findings):
    """The phrase rules over the normalized text; only a hit the raw text did
    not already draw on that line is reported, under inj-obfuscated."""
    norm, nmark = deobfuscate(text)
    if nmark > MAX_MARKERS:
        first = next(m for m in MARKER_DECL.finditer(text) if m.group(4) or not PLAIN_WORD.fullmatch(m.group(5)))
        finding(findings, INJ_OBFUSCATED._replace(title=f"Declared concealment markers past the cap: {nmark}, where the scanner strips at most {MAX_MARKERS} — read it by hand"), rel, line_at(text, first), line_no(text, first.start()))
    if norm == text:
        return
    # The raw pass has already run over this file; the normalization keeps
    # line count, so a hit maps to its raw line by position.
    derived_view(findings, rel, norm, MD_RULES, lambda m: line_no(norm, m.start()),
                 lambda rule: INJ_OBFUSCATED._replace(sev=rule.sev, title=f"{INJ_OBFUSCATED.title} (reads as: {rule.title})"),
                 novel_only=True)


def shell_fences(text):
    """(offset of the opening line, offset of the body, body) for every ```!
    or ~~~! fence. Fences are read in order and the open one is tracked: a
    fence line while one is open is content unless it closes the open fence
    (same mark character, at least as long, nothing after it), so a ```!
    quoted as documentation inside an outer fence is never a command."""
    open_mark, is_shell, body, at, body_at, pos = None, False, [], 0, 0, 0
    for line in text.split("\n"):
        m = FENCE_LINE.match(line)
        if m and open_mark is None:
            open_mark, is_shell, body, at, body_at = m.group("mark"), m.group("info").startswith("!"), [], pos, pos + len(line) + 1
        elif m and m.group("mark")[0] == open_mark[0] and len(m.group("mark")) >= len(open_mark) and not m.group("info").strip():
            if is_shell:
                yield at, body_at, "\n".join(body) + "\n"
            open_mark = None
        elif open_mark is not None:
            body.append(line)
        pos += len(line) + 1


def scan_shell(text, rel, findings):
    """Invocation-time commands: each is reported, then read as a script
    would be, so a hit keeps the script rule's own id and severity on the
    raw line the command text sits in."""
    commands = [(m.start(), m.start("span"), m.group("span")) for m in MD_SHELL_SPAN.finditer(text)]
    commands += list(shell_fences(text))
    for at, body_at, cmd in sorted(commands):
        finding(findings, MD_SHELL_RULE, rel, cmd, line_no(text, at))
        derived_view(findings, rel, cmd, SCRIPT_RULES, lambda h: line_no(text, body_at + h.start()), lambda rule: rule)


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
        scan_obfuscated(text, rel, findings)
        scan_shell(text, rel, findings)
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


def read_text(path, rel, findings, report_binary=True):
    """The file's text, or None with a finding saying why the scan is not whole.
    A file over the size cap is scanned to the cap and flagged, so the prefix
    still draws whatever it holds. With report_binary False a file that is
    not text returns None and draws nothing — the caller owns that call."""
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            raw = f.read(MAX_FILE_BYTES)
        if size > MAX_FILE_BYTES:
            skipped(findings, rel, f"File over {MAX_FILE_BYTES:,} bytes: only its first {MAX_FILE_BYTES:,} were scanned ({size:,} bytes)")
        text = decode(raw)
        if text is None and report_binary:
            skipped(findings, rel, "File is not UTF-8 or UTF-16/32 text and was not scanned")
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


# What a file is to the walk — a closed set, one row per kind, each carrying
# its policy: `reads` says the walk opens the file as text (and charges the
# file cap for it, bytecode aside), and `binary_is` says what a file of this
# kind that turns out not to be text draws — a finding, or nothing (the
# documented boundary for a data file the walk never meant to read).
Kind = namedtuple("Kind", "name reads binary_is")
BINARY = Kind("binary", False, None)          # compiled: ELF, Mach-O, PE
CONTAINER = Kind("container", False, None)    # xz, bz2, zstd, 7z, rar: reported, never opened
ARCHIVE = Kind("archive", False, None)        # zip, gzip, tar: unpacked and walked
LOCK = Kind("lock", False, None)              # a generated lock file: data, never opened
UNREAD = Kind("unread", False, None)          # the documented boundary: neither markdown nor script-like
MANIFEST = Kind("manifest", True, "skipped")  # package.json: hooks, then the script rules
MARKDOWN = Kind("markdown", True, "skipped")
SCRIPT = Kind("script", True, "skipped")
MEMBER = Kind("member", True, "silent")       # inside an archive, a name the classifier declines: read under both rule sets
Classified = namedtuple("Classified", "kind hidden evidence")


def classify(fn, ext, head, executable, depth):
    """What the walk does with one file, from its name, its first HEAD_BYTES
    and its mode alone — no I/O, no findings, so the order of the checks is
    stated once, here, and a reader can see which kind wins. In order:
    compiled magic; a container format; an archive by name or magic (this
    preempts every kind below it, so a .json or .md holding zip magic is
    scanned as its members and never as config or markdown — `hidden` says
    the name did not admit the magic, and `evidence` names the magic); a
    lock file; the npm manifest; markdown; a script by extension, config
    extension, basename, mode or shebang; inside an archive, anything else
    is a member (read anyway — the author chose to ship it); outside one,
    anything else is the documented unread boundary."""
    if any(head.startswith(magic) for magic in BINARY_MAGIC):
        return Classified(BINARY, False, head[:4].hex())
    if ext in CONTAINER_EXT or any(head.startswith(magic) for magic in CONTAINER_MAGIC):
        return Classified(CONTAINER, False, head[:8].hex())
    is_archive_name = ext in ARCHIVE_EXT or fn.strip().lower().endswith(".tar.gz")
    is_tar_magic = head[TAR_MAGIC_AT[0]:TAR_MAGIC_AT[0] + len(TAR_MAGIC_AT[1])] == TAR_MAGIC_AT[1]
    is_archive_magic = any(head.startswith(magic) for magic in ARCHIVE_MAGIC) or is_tar_magic
    if is_archive_name or is_archive_magic:
        return Classified(ARCHIVE, is_archive_magic and not is_archive_name, "ustar at byte 257" if is_tar_magic else head[:4].hex())
    if LOCK_FILE.match(fn.strip()):
        return Classified(LOCK, False, None)
    if fn == "package.json":
        return Classified(MANIFEST, False, None)
    if ext in MD_EXT:
        return Classified(MARKDOWN, False, None)
    if ext in SCRIPT_EXT or ext in CONFIG_EXT or fn in SCRIPT_NAMES or fn == ".pnpmfile.cjs" or executable or head.startswith(b"#!"):
        return Classified(SCRIPT, False, None)
    if depth > 0:
        return Classified(MEMBER, False, None)
    return Classified(UNREAD, False, None)


@contextlib.contextmanager
def open_archive(fp, head):
    """Yields (members, dropped) for a zip, a tar, or a gzipped single file,
    and closes the archive on exit — the readers are good only inside the
    block. A member is (name, declared size, stored mode, reader); the reader
    returns (bytes, short), reading at most MAX_ARCHIVE_BYTES + 1 and
    setting `short` when the archive held more than the declared size let it
    read. The mode is reported, never applied: an executable member with no
    extension is read as an unclassified member by the walk, which covers
    it without trusting the archive's mode bits. `dropped` counts the
    members that are not regular files (symlinks, devices, fifos —
    directories aside), which are never unpacked. Raises one of
    ARCHIVE_ERRORS when the file is none of the three."""
    if zipfile.is_zipfile(fp):
        with zipfile.ZipFile(fp) as zf:
            def read_zip(i):
                # The declared size ends the read, so a central directory
                # that understates it hides the rest: the read is short when
                # the deflate stream did not finish, a stored member's two
                # sizes disagree, a "zero-byte" member carries compressed
                # data, or the CRC fails over what the declared size let
                # through (a CRC lie beside the size lie).
                with zf.open(i) as fh:
                    try:
                        data = fh.read(MAX_ARCHIVE_BYTES + 1)
                    except zipfile.BadZipFile as e:
                        if "CRC" not in str(e):
                            raise
                        return b"", True
                    dec = getattr(fh, "_decompressor", None)
                    short = ((dec is not None and not getattr(dec, "eof", True))
                             or (i.compress_type == zipfile.ZIP_STORED and i.compress_size != i.file_size)
                             or (i.file_size == 0 and i.compress_size > 2))
                    return data, short
            members, dropped = [], 0
            for i in zf.infolist():
                if i.is_dir():
                    continue
                if (i.external_attr >> 16) & 0o170000 == 0o120000:
                    dropped += 1
                    continue
                members.append((i.filename, i.file_size, (i.external_attr >> 16) & 0o777, (lambda i=i: read_zip(i))))
            yield members, dropped
        return
    try:
        tf = tarfile.open(fp)
    except tarfile.ReadError:
        if not head.startswith(GZIP_MAGIC):
            raise
        tf = None
    if tf is not None:
        with tf:
            members = [(m.name, m.size, m.mode, (lambda m=m: (tf.extractfile(m).read(MAX_ARCHIVE_BYTES + 1), False)))
                       for m in tf.getmembers() if m.isfile()]
            dropped = sum(1 for m in tf.getmembers() if not m.isfile() and not m.isdir())
            yield members, dropped
        return
    # A gzipped single file (notes.md.gz): one member named by the stem, its
    # size read from the gzip trailer, the read bounded by the cap either way.
    with open(fp, "rb") as fh:
        fh.seek(-4, os.SEEK_END)
        declared = int.from_bytes(fh.read(4), "little")
    # Under a name that does not end in .gz the member takes the bare stem
    # (payload.tgz -> payload), which the walk reads as an unclassified member.
    stem = os.path.basename(fp)[:-3] if fp.lower().endswith(".gz") else os.path.splitext(os.path.basename(fp))[0]
    def read_gz():
        data = gzip.open(fp).read(MAX_ARCHIVE_BYTES + 1)
        return data, len(data) > MAX_ARCHIVE_BYTES
    yield [(stem, declared, 0o644, read_gz)], 0


def safe_member(name):
    """The member's path relative to the unpack root, or None when it would
    land outside it (absolute, a drive, or a `..` component)."""
    parts = [p for p in name.replace("\\", "/").split("/") if p not in ("", ".")]
    if not parts or name.startswith(("/", "\\")) or ":" in parts[0] or ".." in parts:
        return None
    return os.path.join(*parts)


def scan_archive(fp, rel, depth, head, scan):
    """Unpack one archive and walk it as part of the skill. Every way the
    unpack can be partial is a scan-skipped finding, so an archive never
    hides what the scanner did not read: the depth cap, an archive that will
    not open, more members than the file cap, more declared bytes than the
    size cap, a member that is not a regular file, a member whose path
    escapes, two members on one path, and a member whose content does not
    match its declared size. Findings under the archive carry it in their
    `archive` key and name the member as <archive>/<member>."""
    findings = scan.findings
    if depth >= MAX_ARCHIVE_DEPTH:
        skipped(findings, rel, f"Archive inside an archive was not opened (depth cap {MAX_ARCHIVE_DEPTH})")
        return
    try:
        with open_archive(fp, head) as (members, dropped):
            if len(members) > MAX_FILES_PER_SKILL:
                skipped(findings, rel, f"Archive holds {len(members):,} members, over the {MAX_FILES_PER_SKILL}-member cap, and was not opened")
                return
            total = sum(size for _, size, _, _ in members)
            if total > MAX_ARCHIVE_BYTES:
                skipped(findings, rel, f"Archive unpacks to {total:,} bytes, over the {MAX_ARCHIVE_BYTES:,}-byte cap, and was not opened")
                return
            if dropped:
                skipped(findings, rel, f"Archive members that are not regular files (symlinks, devices) were not unpacked: {dropped}", what="the archive")
            # A finding on the archive itself names the archive as its file
            # (a path that exists) and carries no `archive` key; from here on
            # every finding is under a member and carries one.
            for name, _, _, _ in members:
                if safe_member(name) is None:
                    skipped(findings, rel, "Archive member path escapes the archive and was not unpacked", name, what="the archive")
            outer, findings.archive = findings.archive, rel
            try:
                with tempfile.TemporaryDirectory(prefix="security-scan-archive.") as td:
                    written = set()
                    for name, size, _, read in members:
                        safe = safe_member(name)
                        if safe is None:
                            continue
                        dest = os.path.join(td, safe)
                        if dest in written:
                            skipped(findings, f"{rel}/{safe}", "Archive member shares its path with an earlier member and was not unpacked; only the first was scanned, and an extractor may keep either", name)
                            continue
                        try:
                            data, short = read()
                            if len(data) > MAX_ARCHIVE_BYTES:
                                skipped(findings, f"{rel}/{safe}", f"Archive member is over the {MAX_ARCHIVE_BYTES:,}-byte cap and was not unpacked")
                                continue
                            if short or len(data) != size:
                                skipped(findings, f"{rel}/{safe}", f"Archive member content does not match its declared size ({size:,} declared, {len(data):,} read) and was not unpacked")
                                continue
                            os.makedirs(os.path.dirname(dest), exist_ok=True)
                            with open(dest, "wb") as fh:
                                fh.write(data)
                            written.add(dest)
                        except ARCHIVE_ERRORS as e:
                            finding(findings, SCAN_ERROR, f"{rel}/{safe}", f"{e.__class__.__name__}: {e}")
                    walk(td, rel + "/", depth + 1, scan)
            finally:
                findings.archive = outer
    except ARCHIVE_ERRORS as e:
        skipped(findings, rel, "Archive could not be opened, so nothing in it was checked", f"{e.__class__.__name__}: {str(e).splitlines()[0] if str(e) else e}")


class Scan:
    """One directory's findings and the file-cap counters the walk shares
    with every archive it opens."""
    def __init__(self):
        self.findings = Findings()
        self.n = 0
        self.capped = 0


def scan_dir(path):
    scan = Scan()
    walk(path, "", 0, scan)
    if scan.capped:
        skipped(scan.findings, ".", f"Scannable files past the {MAX_FILES_PER_SKILL}-file scan cap were not read: {scan.capped}. The cap bounds files scanned, not files walked", what="them")
    return scan.findings


def walk(path, prefix, depth, scan):
    """Classify and scan every file under `path`, one directory's worth of
    the skill. `prefix` is what a finding's `file` opens with — "" for the
    skill's own tree, "<archive>/" for an unpacked archive's — and `depth` is
    the archive nesting (0 outside one). The call mutates `scan.n` and
    `scan.capped`, shared across every archive the directory opens, so the
    file cap is one budget for the skill and its bundles together."""
    findings = scan.findings
    for root, dirs, files in os.walk(path):
        if depth == 0:
            # A real checkout's .git and node_modules are not the skill's.
            # Inside an archive every path is the author's choice, so
            # nothing is pruned there.
            dirs[:] = [d for d in dirs if d not in (".git", "node_modules")]
        for fn in files:
            fp = os.path.join(root, fn)
            if os.path.islink(fp):
                continue
            rel = prefix + os.path.relpath(fp, path)
            # Whitespace around the name is not part of the extension.
            ext = os.path.splitext(fn.strip())[1].lower()
            if ext in BYTECODE_EXT:
                # Named as bytecode, and still classified below by what it
                # holds — a script renamed .pyc draws the script rules too.
                # Not counted against the file cap: a build leaves hundreds.
                finding(findings, BIN_BYTECODE, rel, fn)
            try:
                with open(fp, "rb") as fh:
                    head = fh.read(HEAD_BYTES)
                executable = bool(os.stat(fp).st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))
            except OSError as e:
                finding(findings, SCAN_ERROR, rel, str(e))
                continue
            kind, hidden, evidence = classify(fn, ext, head, executable, depth)
            if kind is BINARY:
                finding(findings, BIN_COMPILED, rel, evidence)
            elif kind is CONTAINER:
                skipped(findings, rel, "Archive in a format the scanner does not open (xz, bz2, zstd, 7z, rar) and nothing in it was checked", evidence)
            elif kind is ARCHIVE:
                if hidden:
                    finding(findings, BIN_ARCHIVE, rel, evidence)
                scan_archive(fp, rel, depth, head, scan)
            if not kind.reads:
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
                if scan.n >= MAX_FILES_PER_SKILL:
                    scan.capped += 1
                    continue
                scan.n += 1
            text = read_text(fp, rel, findings, report_binary=kind.binary_is == "skipped")
            if text is None:
                # A member under a name the classifier declines: text draws
                # both rule sets (below); a binary with no extension is
                # reported here; a binary under a data extension (an image,
                # a font) is the same boundary as outside an archive.
                if kind is MEMBER and ext == "":
                    skipped(findings, rel, "Archive member is binary, has no extension, and is not a kind the scanner reads, so it was not scanned")
                continue
            READERS[kind](text, rel, findings)


def scan_manifest(text, rel, findings):
    for key, cmd in manifest_hooks(text):
        finding(findings, MANIFEST_HOOK, rel, f"{key}: {cmd}")
    scan_text(text, rel, False, findings)


def scan_member(text, rel, findings):
    """Inside an archive, a file the classifier declined: something the
    author chose to ship under a name the walk would not read outside one,
    so it draws the markdown rules and the script rules both."""
    scan_text(text, rel, True, findings)
    for rule in SCRIPT_RULES:
        report_each(findings, rule, rel, text)


# The dispatch: one reader per kind the walk opens. A kind added to the set
# above without a row here is a KeyError on its first file, never a silent
# skip.
READERS = {
    MANIFEST: scan_manifest,
    MARKDOWN: lambda text, rel, findings: scan_text(text, rel, True, findings),
    SCRIPT: lambda text, rel, findings: scan_text(text, rel, False, findings),
    MEMBER: scan_member,
}


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
# A target is incomplete when any part of it went unread: the two partial-scan
# kinds are an axis of their own beside the verdict, which is what the third
# threshold gates on.
incomplete = [s for s in results if any(f["rule"] in (SCAN_SKIPPED.id, SCAN_ERROR.id) for f in s["findings"])]

# --fail-on's gate: the one place the verdicts reach the exit code. Both output
# paths exit through EXIT_CODE, so the summary and findings always print first.
EXIT_CODE = 4 if (FAIL_ON == "risk" and risk) or (FAIL_ON == "review" and (risk or review)) or (FAIL_ON == "incomplete" and (risk or incomplete)) else 0

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
