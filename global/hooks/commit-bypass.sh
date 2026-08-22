#!/usr/bin/env bash
# commit-bypass — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks the git command-line shapes that skip the repo's hooks: `--no-verify`
# (or a unique prefix git accepts, `--no-veri`) on any git subcommand, the `-n`
# short form on `git commit` (alone or in a cluster such as `-an`), and
# `-c core.hooksPath=...` (any letter case) on a git subcommand that runs
# hooks. A pre-commit hook is how a project's warnings reach the person
# landing the change; an agent has no legitimate reason to step around one,
# so there is no directory opt-in — the check is always on.
#
# What it does not see: `git config core.hooksPath ...` writes (setup-hooks.sh
# is a legitimate caller), `GIT_CONFIG_*` environment overrides, and edits to
# `.git/hooks/` itself. Those are config and filesystem acts, not a bypass
# flag on a command line; the contract is the three shapes above.
#
# The command is tokenised the way a shell would (`shlex`), so a quoted flag
# (`"--no-verify"`) is still the flag, and a string handed to `bash -c`,
# `sh -c`, `eval`, or a shell-fed heredoc is tokenised in turn. A flag that
# only appears inside a commit message, a note, a grep pattern, or a heredoc
# no shell consumes is text and passes. A variable assigned a bypass value
# in the same command (`x=--no-verify; git commit $x`) blocks. A
# backslash-newline continuation is joined first, so `git commit \<newline>
# --no-verify` is still `git commit --no-verify`.
#
# Fail-open: a malformed payload, a missing python3, or a tokeniser error
# lets the command through, with a one-line stderr breadcrumb. A safety hook
# that blocks on its own errors trains the user to disable it.
#
# The payload parse and the heredoc handling are copied from rename-safety.sh
# rather than shared through a library: two hooks is one short of the third
# caller that justifies the extraction. The quote handling differs on purpose
# (rename-safety strips quoted text; this hook tokenises it) — see the
# selftest's quoted-flag rows for why.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/commit-bypass.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# commit-bypass-selftest.sh beside this file runs the expect/reject payload
# table; run it after changing a rule.
#
# Depends: committing (its blocked-action protocol names this hook as the
# mechanical half of "a failing hook is a blocked action, never a bypass").

set -u

allow() { echo "commit-bypass: $1, allowing" >&2; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow "empty payload"

command -v python3 >/dev/null 2>&1 || allow "python3 not found"

cmd="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    cmd = ti.get("command") if isinstance(ti, dict) else None
    if isinstance(cmd, str) and cmd:
        print(cmd)
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$cmd" ] || allow "payload has no tool_input.command"

# --- shape check ------------------------------------------------------------
# Prints the shape name on a match, nothing otherwise. Exit 3 = tokeniser
# error (fail-open below).
shape="$(printf '%s' "$cmd" | python3 -c '
import re, shlex, sys

s = sys.stdin.read()

# Heredoc bodies are text unless a shell consumes them (bash <<EOF ...).
SHELL = re.compile(r"(^|[;&|(\s])(bash|sh|zsh|dash|ksh|eval|source|\.)(\s|$)")
HEREDOC = re.compile(r"<<-?\s*[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?[^\n]*\n.*?\n\t*\1(?=\n|$)", re.S)
def drop(m):
    line = re.sub(r"\\\n", " ", s[:m.start()]).rsplit("\n", 1)[-1]
    head = m.group(0).split("\n", 1)[0]
    if SHELL.search(line + head):
        body = m.group(0).split("\n", 1)[1].rsplit("\n", 1)[0]
        return head + "\n" + body + "\n"   # a shell runs the body: keep it as lines
    return head + "\n"                      # anything else: the body is text
s = HEREDOC.sub(drop, s)
s = re.sub(r"\\\n", " ", s)

SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
NOVERIFY = {"--no-verify", "--no-verif", "--no-veri"}
HOOKSPATH = re.compile(r"^core\.hookspath=", re.I)
READONLY = {"log", "diff", "status", "show", "rev-parse", "ls-files", "ls-tree",
            "blame", "describe", "config", "remote", "branch", "tag", "cat-file",
            "rev-list", "shortlog", "grep", "reflog", "var", "help", "version"}
COMMIT_ARG_OPTS = set("mFCctS")   # short options of `git commit` that take a value
SEPS = {";", "&&", "||", "|", "&", "(", ")", "\n"}

def tokens(text):
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace_split = True
    lex.whitespace = " \t\r"       # newline is a separator, not whitespace
    lex.commenters = ""
    out = []
    for t in lex:
        if all(c in ";&|()\n" for c in t):
            for piece in re.findall(r"&&|\|\||[;&|()\n]", t):
                out.append(piece)
        else:
            out.append(t)
    return out

def segments(toks):
    seg = []
    for t in toks:
        if t in SEPS:
            if seg:
                yield seg
            seg = []
        else:
            seg.append(t)
    if seg:
        yield seg

def is_git(tok):
    return tok.rsplit("/", 1)[-1] == "git"

def check_git(args):
    """args = tokens after the git word. Returns a shape name or None."""
    sub = None
    i = 0
    while i < len(args):
        a = args[i]
        if a in NOVERIFY:
            return "--no-verify"
        if sub is None:
            if a == "-c" and i + 1 < len(args) and HOOKSPATH.match(args[i + 1]):
                sub = find_sub(args[i + 2:])
                return None if sub in READONLY else "-c core.hooksPath="
            if a.startswith("-c") and HOOKSPATH.match(a[2:]):
                sub = find_sub(args[i + 1:])
                return None if sub in READONLY else "-c core.hooksPath="
            if a == "-c" or a == "-C":
                i += 2
                continue
            if a.startswith("-"):
                i += 1
                continue
            sub = a
            i += 1
            continue
        if a == "--":
            i = next((j for j in range(i + 1, len(args)) if args[j] in NOVERIFY), len(args))
            return "--no-verify" if i < len(args) else None
        if sub == "commit" and re.match(r"^-[A-Za-z]+$", a):
            for ch in a[1:]:
                if ch == "n":
                    return "git commit -n"
                if ch in COMMIT_ARG_OPTS:
                    break
        i += 1
    return None

def find_sub(args):
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("-c", "-C"):
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        return a
    return None

def scan(text, depth=0):
    if depth > 4:
        return None
    toks = tokens(text)
    # A variable assigned a bypass value anywhere in the command.
    for t in toks:
        m = re.match(r"^[A-Za-z_][A-Za-z0-9_]*=(.*)$", t)
        if m and m.group(1) in NOVERIFY:
            return "--no-verify"
    prev = None
    for seg in segments(toks):
        shape = scan_segment(seg, prev, depth)
        if shape:
            return shape
        prev = seg
    return None

def scan_segment(seg, prev, depth):
    # Leading assignments (FOO=bar git ...) and env wrappers.
    j = 0
    while j < len(seg) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", seg[j]):
        j += 1
    seg = seg[j:]
    if not seg:
        return None
    head = seg[0].rsplit("/", 1)[-1]
    if head in ("env", "command", "exec", "nohup", "time"):
        return scan_segment(seg[1:], prev, depth)
    if head in ("sudo", "xargs"):
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            k += 1
        inner = scan_segment(seg[k:], prev, depth)
        if inner:
            return inner
        # xargs: the feeding segment supplies the arguments.
        if head == "xargs" and prev and k < len(seg) and is_git(seg[k]):
            return check_git(seg[k + 1:] + prev)
        return None
    if head in SHELLS:
        for k, t in enumerate(seg):
            if t == "-c" and k + 1 < len(seg):
                return scan(seg[k + 1], depth + 1)
        return None
    if head == "eval":
        return scan(" ".join(seg[1:]), depth + 1)
    if is_git(seg[0]):
        return check_git(seg[1:])
    return None

try:
    shape = scan(s)
except Exception:
    sys.exit(3)
if shape:
    sys.stdout.write(shape)
' 2>/dev/null)"
rc=$?
[ "$rc" -ne 3 ] || allow "tokeniser error"
[ -n "$shape" ] || exit 0

{
  echo "commit-bypass: blocked a git command that skips the repo's hooks ($shape)."
  echo "  command: $cmd"
  echo "  A pre-commit hook is how the project's warnings reach the person landing"
  echo "  the change. Run the command without the bypass; if a hook fails, fix what"
  echo "  it reports or report the failure verbatim as a blocked action."
} >&2
exit 2
