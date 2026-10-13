#!/usr/bin/env bash
# staged-secrets — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks the agent's own `git commit` when what it would commit holds a
# token-shaped string or a key-shaped file. A credential that reaches a commit
# is in every clone and reflog; deleting it later un-leaks nothing.
#
# What it reads, at the moment the commit command is about to run:
#   - the staged diff's added lines (`git diff --cached -U0`);
#   - with `git commit -a`/`--all`, or a `git add` earlier in the same command,
#     the unstaged added lines of tracked files too (`git diff -U0`, limited to
#     the add's pathspecs) — the add has not run yet when this hook fires;
#   - with a `git add` in the same command, the untracked, non-ignored files
#     its pathspecs name (`-A`, `--all`, `.` name them all), read whole.
#
# Content shapes, chosen for near-zero false positives (the table is
# CONTENT_RULES below; it grows only on a miss):
#   aws-key        AKIA/ASIA followed by 16 upper-case letters or digits
#   github-token   ghp_ or gho_ followed by 36+ characters, or github_pat_
#   slack-token    xoxa-, xoxb-, xoxp-, xoxr-
#   private-key    a -----BEGIN … PRIVATE KEY----- line
#   jwt            eyJ….eyJ….<signature>
#   azure-sas      a sig= query parameter of 20+ characters (a signed URL)
# Path shapes (PATH_RULES): .env and .env.* (not .env.example, .env.sample,
# .env.template), *.pem, and an SSH private key id_rsa / id_ecdsa / id_ed25519
# (not its .pub). A deletion of such a path is not a hit.
#
# The escape: a line carrying `secret-scan: allow` is not scanned — a test
# fixture marks its fake token that way. A path hit has no escape here: a
# fixture key file is committed by the user in their own terminal.
#
# The report names the file, the line, and the shape — never the matched
# value, so the secret does not enter the conversation.
#
# What it does not see: a commit the user runs in a terminal (a per-repo git
# pre-commit hook is the place for that, and none is installed), pathspecs
# given to `git commit` itself (`git commit -m x f.txt`), `git commit
# --amend`'s already-committed lines, a `git add` whose pathspec the scanner
# cannot expand (`git add "$F"`), and binary or 1 MB+ untracked files.
#
# How the commit may reach git — a quoted flag, a `bash -c` string, a wrapper,
# a compound statement — is hook-lib.sh / hook-lib.py beside this file; this
# file holds only the commit and add shapes and the patterns.
#
# Fail-open: a malformed payload, a missing python3 or git, a tokeniser error,
# or a directory that is not a git work tree lets the command through, with a
# one-line stderr breadcrumb. A safety hook that blocks on its own errors
# trains the user to disable it.
#
# Install note: always on — no opt-in.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/staged-secrets.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# staged-secrets-selftest.sh beside this file builds its token fixtures at run
# time, so this repo never holds a token-shaped string; run it after changing
# a rule.
#
# Depends: committing (its rotate-first rule is the remedy this hook names).

set -u
hook_name="staged-secrets"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload
export STAGED_SECRETS_CWD="$cwd"   # the scanner resolves the commit directory against the payload cwd
command -v git >/dev/null 2>&1 || hook_allow "git not found"

# --- commit shape, then the scan --------------------------------------------
# on_command records each `git add` and returns at the first `git commit`;
# emit runs the scan in the commit's directory and prints one finding a line.
hook_scan '
import os, subprocess
BASE = os.environ.get("STAGED_SECRETS_CWD") or os.getcwd()
ADDS = []
ALLOW = "secret-scan: allow"
CONTENT_RULES = [
    ("aws-key",      re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("github-token", re.compile(r"\bgh[po]_[A-Za-z0-9]{36,}|\bgithub_pat_[A-Za-z0-9_]{22,}")),
    ("slack-token",  re.compile(r"\bxox[abpr]-[A-Za-z0-9-]{10,}")),
    ("private-key",  re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("jwt",          re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}")),
    ("azure-sas",    re.compile(r"[?&]sig=[A-Za-z0-9%/+=]{20,}")),
]
PATH_RULES = [
    ("env-file",     re.compile(r"^\.env(\..+)?$"), re.compile(r"^\.env\.(example|sample|template)$")),
    ("pem-file",     re.compile(r"\.pem$"), None),
    ("ssh-key-file", re.compile(r"^id_(rsa|ecdsa|ed25519)"), re.compile(r"\.pub$")),
]
GLOBAL_VALUE_OPTS = {"-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"}

def split_git(args, curdir):
    """(directory, subcommand, args after it) for a git command line."""
    d = joined(BASE, curdir) if curdir is not None else BASE
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-C" and i + 1 < len(args):
            d = joined(d, expand(args[i + 1])) or d
            i += 2
            continue
        if a in GLOBAL_VALUE_OPTS:
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        return d, a, args[i + 1:]
    return d, None, []

def on_command(seg, curdir):
    args = git_args(seg)
    if args is None:
        return None
    d, sub, rest = split_git(args, curdir)
    if sub == "add":
        specs, all_ = [], False
        for a in rest:
            if a in ("-A", "--all", "."):
                all_ = True
            elif a == "--" or a.startswith("-"):
                continue
            else:
                p = expand(a)
                if p is None:
                    continue
                specs.append(p)
        ADDS.append((d, specs, all_))
        return None
    if sub == "commit":
        return (d, any(commits_all(a) for a in rest))
    return None

def commits_all(a):
    """`-a`/`--all`, or `a` in a short-option cluster before an option that
    takes the rest of the word as its value (`-am msg` is all, `-ma` is not)."""
    if a in ("-a", "--all"):
        return True
    if not re.match(r"^-[A-Za-z]+$", a):
        return False
    for ch in a[1:]:
        if ch == "a":
            return True
        if ch in "mFCctS":
            return False
    return False

def git(d, *argv):
    r = subprocess.run(["git", "-C", d] + list(argv), capture_output=True)
    if r.returncode != 0:
        raise OSError("git %s failed" % argv[0])
    return r.stdout.decode("utf-8", "replace")

def added_lines(diff):
    """(path, line number in the new file, text) for each added line."""
    path, n = None, 0
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else None
        elif line.startswith("@@"):
            m = re.match(r"^@@ -\S+ \+(\d+)", line)
            n = int(m.group(1)) if m else 0
        elif line.startswith("+") and path:
            yield path, n, line[1:]
            n += 1

def content_hits(path, n, text):
    if ALLOW in text:
        return
    for name, rx in CONTENT_RULES:
        if rx.search(text):
            yield "%s:%d %s" % (path, n, name)
            return

def path_hit(path):
    base = os.path.basename(path)
    for name, rx, unless in PATH_RULES:
        if rx.search(base) and not (unless and unless.search(base)):
            return "%s %s" % (path, name)
    return None

def emit(hit):
    try:
        scan_commit(*hit)
    except (OSError, ValueError) as e:
        sys.stdout.write(str(e))
        sys.exit(4)

def scan_commit(d, commit_all):
    r = subprocess.run(["git", "-C", d, "rev-parse", "--is-inside-work-tree"], capture_output=True)
    if r.stdout.strip() != b"true":
        sys.stdout.write("NOTREE:" + d)
        return
    top = git(d, "rev-parse", "--show-toplevel").strip()
    diff_opts = ["-U0", "--no-color", "--no-ext-diff", "--no-renames"]
    out = []
    paths = set(git(top, "diff", "--cached", "--name-only", "--diff-filter=d", "-z").split("\0")) - {""}
    diffs = [git(top, "diff", "--cached", *diff_opts)]
    if commit_all:
        diffs.append(git(top, "diff", *diff_opts))
        paths |= set(git(top, "diff", "--name-only", "--diff-filter=d", "-z").split("\0")) - {""}
    for ad, specs, all_ in ADDS:
        pre = git(ad, "rev-parse", "--show-prefix").strip()
        spec = [] if all_ or not specs else ["--"] + specs
        diffs.append(git(ad, "diff", *diff_opts, *spec))
        for p in git(ad, "diff", "--name-only", "--diff-filter=d", "-z", *spec).split("\0"):
            if p:
                paths.add(p)
        for p in git(ad, "ls-files", "--others", "--exclude-standard", "-z", *spec).split("\0"):
            if not p:
                continue
            full = os.path.join(ad, p)
            rel = os.path.join(pre, p)
            paths.add(rel)
            try:
                if os.path.getsize(full) > 1 << 20:
                    continue
                data = open(full, "rb").read()
            except OSError:
                continue
            if b"\0" in data:
                continue
            for i, text in enumerate(data.decode("utf-8", "replace").splitlines(), 1):
                out.extend(content_hits(rel, i, text))
    for diff in diffs:
        for path, n, text in added_lines(diff):
            out.extend(content_hits(path, n, text))
    for p in sorted(paths):
        h = path_hit(p)
        if h:
            out.append(h)
    seen = []
    for h in out:
        if h not in seen:
            seen.append(h)
    sys.stdout.write("\n".join(seen))
'
findings="$hook_result"
[ -n "$findings" ] || exit 0
case "$findings" in NOTREE:*) hook_allow "not a git work tree (${findings#NOTREE:})" ;; esac

{
  echo "staged-secrets: blocked a git commit — what it would commit holds a credential shape."
  printf '%s\n' "$findings" | sed 's/^/  /'
  echo "  The value is not shown here. Unstage it (git restore --staged <path>) and move it"
  echo "  to an environment variable or the secret store. If it was ever pushed, shared or"
  echo "  committed before, it is leaked: ask the user to rotate it first (committing's"
  echo "  rotate-first rule). A fake value in a test fixture takes a 'secret-scan: allow'"
  echo "  comment on its line."
} >&2
exit 2
