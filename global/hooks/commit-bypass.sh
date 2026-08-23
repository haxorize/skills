#!/usr/bin/env bash
# commit-bypass — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks the git command-line shapes that skip the repo's hooks: `--no-verify`
# (or a unique prefix git accepts, `--no-veri`) on any git subcommand, the `-n`
# short form on `git commit` (alone or in a cluster such as `-an`), and
# `-c core.hooksPath=...` or `--config-env=core.hooksPath=...` (any letter
# case) on a git subcommand that runs hooks. A pre-commit hook is how a
# project's warnings reach the person landing the change; an agent has no
# legitimate reason to step around one, so there is no directory opt-in — the
# check is always on.
#
# What it does not see: `git config core.hooksPath ...` writes (setup-hooks.sh
# is a legitimate caller), `GIT_CONFIG_*` environment overrides, and edits to
# `.git/hooks/` itself. Those are config and filesystem acts, not a bypass
# flag on a command line; the contract is the three shapes above. A flag that
# only appears inside a commit message, a note, a grep pattern, or a heredoc
# no shell consumes is text and passes.
#
# How the flag may reach git — a quoted flag, a `bash -c` string, `eval`, a
# shell-fed heredoc, a variable assigned in the same command, a wrapper, a
# compound statement, `find -exec`, `xargs`, a `-c alias.X=…` built on the
# command line — is hook-lib.sh / hook-lib.py beside this file; the lib's
# header is that part of the contract. This file holds only the git shapes.
#
# Fail-open: a malformed payload, a missing python3, or a tokeniser error
# lets the command through, with a one-line stderr breadcrumb. A safety hook
# that blocks on its own errors trains the user to disable it.
#
# Install note: always on — no opt-in.
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
hook_name="commit-bypass"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload

# --- shape check ------------------------------------------------------------
# on_command sees each program that runs; a git segment (alias expanded by the
# lib) is checked for the three shapes. emit prints the shape name.
hook_scan '
NOVERIFY = {"--no-verify", "--no-verif", "--no-veri"}
HOOKSPATH = re.compile(r"^core\.hookspath=", re.I)
CONFIG_ENV = re.compile(r"^--config-env=core\.hookspath=", re.I)
READONLY = {"log", "diff", "status", "show", "rev-parse", "ls-files", "ls-tree",
            "blame", "describe", "config", "remote", "branch", "tag", "cat-file",
            "rev-list", "shortlog", "grep", "reflog", "var", "help", "version"}
COMMIT_ARG_OPTS = set("mFCctS")   # short options of `git commit` that take a value

def check_git(args):
    """args = tokens after the git word. Returns a shape name or None."""
    sub = None
    i = 0
    while i < len(args):
        a = args[i]
        if a in NOVERIFY:
            return "--no-verify"
        if sub is None:
            if a in ("-c", "--config-env") and i + 1 < len(args) and HOOKSPATH.match(args[i + 1]):
                sub = find_sub(args[i + 2:])
                return None if sub in READONLY else a + " core.hooksPath="
            if a.startswith("-c") and HOOKSPATH.match(a[2:]):
                sub = find_sub(args[i + 1:])
                return None if sub in READONLY else "-c core.hooksPath="
            if CONFIG_ENV.match(a):
                sub = find_sub(args[i + 1:])
                return None if sub in READONLY else "--config-env core.hooksPath="
            if a in ("-c", "-C", "--config-env"):
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
        if a in ("-c", "-C", "--config-env"):
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        return a
    return None

def on_command(seg, curdir):
    args = git_args(seg)
    return check_git(args) if args is not None else None

def emit(shape):
    sys.stdout.write(shape)
'
shape="$hook_result"
[ -n "$shape" ] || exit 0

{
  echo "commit-bypass: blocked a git command that skips the repo's hooks ($shape)."
  echo "  command: $cmd"
  echo "  A pre-commit hook is how the project's warnings reach the person landing"
  echo "  the change. Run the command without the bypass; if a hook fails, fix what"
  echo "  it reports or report the failure verbatim as a blocked action."
} >&2
exit 2
