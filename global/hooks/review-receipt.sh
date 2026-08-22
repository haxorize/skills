#!/usr/bin/env bash
# review-receipt — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks `git push` into a repo that asks for review before landing, unless a
# review report for that repo sits in the landing zone and is at least as new
# as the oldest commit the push would send. The report is the receipt:
# `review-changes` writes `<repo>-<date>-<slug>.review.md` to the landing zone
# the `handoff` skill defines (its "Where to write it" section:
# `claude-handoffs/` under the platform temp dir), and nothing else produces
# one — an in-session subagent review that wrote no file is not a review this
# hook can see, on purpose. `<repo>` is the basename of the work tree, so two
# checkouts with one basename share receipts; the date segment keeps
# `skills-archive-…` from answering for `skills`.
#
# Which repo: the directory the push runs in, not merely the session's cwd —
# a leading `cd <dir> &&`, `pushd <dir> &&`, `git -C <dir>`, or a `GIT_DIR=`
# assignment moves it, and the walk starts there. A `cd` to a value the hook
# cannot expand (`cd "$X"`) or to a directory that does not exist falls back
# to the payload's `cwd`. A push from inside `.git` resolves to its work tree.
#
# Opt-in by repo: walking from that directory up to the repo top, the nearest
# `CLAUDE.md` carrying a `Review required:` line decides — `yes` gates the
# push, `no` does not (so a package can opt out under a gated root). The line
# is read anywhere in the file outside a fenced block, not only inside the
# `Landing:` block it belongs in; bold, backticks, or a list marker around the
# key or the value are fine; `yes (…)` is not yes. A repo with no such line is
# never gated; outside a git work tree the hook allows with a breadcrumb.
#
# Which range: `<remote>/<dst>..HEAD` when the command names a remote (as an
# argument or `--repo`) and the refspec's destination (`HEAD:main`), else
# `@{upstream}..HEAD`, else `origin/<branch>..HEAD`. The newest matching
# report's mtime is compared with the committer time of the OLDEST commit in
# that range: a report not older than that commit passes (fix-up commits made
# after the review are newer than the report and pass); a report older than
# the oldest unpushed commit reviewed a different tree and blocks. With nothing
# to push, or no ref to compare against, the command runs with a breadcrumb.
# A push that sends no branch commits — a delete (`--delete`, `:dst`) or a
# tag — runs with a breadcrumb too.
#
# Order matters: the receipt must be at least as new as the oldest unpushed
# commit, so the flow is commit, then `/review-changes`, then fix-up commits,
# then push. A report written before the commits it covers were made is older
# than all of them and blocks; a rebase rewrites committer times and has the
# same effect (ADR-0059 records both).
#
# What it does not see: edits made after the review and folded into an
# already-reviewed range (`review-changes`' reviewed-head stamp and
# `committing`'s "N commits since" line carry that in prose); a push run
# through a program it does not treat as a wrapper (the list is in the
# scanner); a push the user runs themselves (`! git push` in the prompt, or
# any terminal), which never passes through a tool hook — that is the one
# skip path, and it is the user's. A `~/.gitconfig` alias is outside the
# contract; an alias built on the command line (`git -c alias.p=push p`) is not.
#
# `git push --dry-run` / `-n` (as a flag, before `--` and any refspec) is a
# read of the remote and passes. Command lines are tokenised the way a shell
# would: a string handed to `bash -c` / `-lc`, `eval`, `env -S`, `xargs git`,
# a shell-fed heredoc, a backtick or `$(…)` substitution, or a literal string
# piped into `bash` is scanned in turn; a variable assigned in the same
# command (`p=push; git $p`) is followed, and so is `$(which git)`; a
# `# comment` starts only at the beginning of a word outside quotes; `{ git
# push; }` and `if …; then git push; fi` are still pushes. `git push` inside
# a quoted message, an echo, or a heredoc no shell consumes is text. A string
# another program builds (`base64 -d | bash`, `python3 -c "os.system(…)"`) is
# not scanned.
#
# Fail-open, each with a one-line stderr breadcrumb: a malformed payload, a
# missing python3 or git, a scanner error (an unterminated quote, nesting
# deeper than four shells), a push outside a git work tree, a CLAUDE.md the
# opt-in walk cannot read, a repo with no ref to compare against, a receipt
# whose mtime cannot be read, or any error computing the range. A safety hook
# that blocks on its own errors trains the user to disable it. Silent exits
# (no breadcrumb): the command is not a push, or the repo is not opted in.
#
# REVIEW_RECEIPT_DIR, when set, replaces the landing-zone search (the selftest
# uses it; a user with a non-standard temp dir can too).
#
# The payload parse and the segment scan are copied from commit-bypass.sh and
# extended (comment and brace handling, cwd tracking); the shared hook-lib.sh
# extraction ADR-0054 scheduled for the third hook is deferred again, with the
# rename-safety tokeniser port (ADR-0059 records why).
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/review-receipt.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# review-receipt-selftest.sh beside this file builds throwaway repos and runs
# the expect/reject table; run it after changing a rule.
#
# Depends: committing (its "reviewed" claim row names the report as the
# evidence in a `Review required: yes` repo; this hook is that row's mechanical
# half at the push). The landing zone it reads is `handoff`'s definition — a
# consumer relation, not a dependant.

set -u

allow() { echo "review-receipt: $1, allowing" >&2; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow "empty payload"

command -v python3 >/dev/null 2>&1 || allow "python3 not found"
command -v git >/dev/null 2>&1 || allow "git not found"

parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    cmd = ti.get("command") if isinstance(ti, dict) else None
    cwd = d.get("cwd") or ""
    if isinstance(cmd, str) and cmd:
        print(cwd if isinstance(cwd, str) else "")
        print(cmd)
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$parsed" ] || allow "payload has no tool_input.command"
cwd="${parsed%%$'\n'*}"
cmd="${parsed#*$'\n'}"
[ -d "$cwd" ] || cwd="$PWD"

# --- the push record: a live `git push`, and where it runs ---------------------
# Prints "kind<US>dir<US>remote<US>refspec" (US = 0x1f) on a match — kind is
# `push` or `delete`; dir/remote/refspec may be empty — nothing otherwise. Any
# non-zero exit is a scanner failure.
record="$(printf '%s' "$cmd" | python3 -c '
import os, re, shlex, sys

s = sys.stdin.read()

SHELL = re.compile(r"(^|[;&|(\s])(bash|sh|zsh|dash|ksh|eval|source|\.)(\s|$)")
HEREDOC = re.compile(r"<<-?\s*[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?[^\n]*\n.*?\n\t*\1(?=\n|$)", re.S)
def drop(m):
    line = re.sub(r"\\\n", " ", s[:m.start()]).rsplit("\n", 1)[-1]
    head = m.group(0).split("\n", 1)[0]
    if SHELL.search(line + head):
        body = m.group(0).split("\n", 1)[1].rsplit("\n", 1)[0]
        return head + "\n" + body + "\n"
    return head + "\n"
s = HEREDOC.sub(drop, s)
s = re.sub(r"\\\n", " ", s)

SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
WRAPPERS = {"env", "command", "exec", "nohup", "time", "sudo", "nice", "ionice",
            "caffeinate", "stdbuf", "timeout", "doas"}
TAKES_ONE = {"timeout"}            # one positional (the duration) before the command
WRAPPER_VALUE_OPTS = {             # options whose value is skipped, not scanned
    "exec": {"-a"}, "nice": {"-n"}, "ionice": {"-c", "-n", "-p"},
    "sudo": {"-u", "-g", "-p", "-C", "-D", "-h", "-r", "-t", "-T", "-U"},
    "doas": {"-u", "-C"}, "timeout": {"-k", "-s"}, "stdbuf": {"-i", "-o", "-e"},
    "env": {"-u", "-C"},
}
SEPS = {";", "&&", "||", "|", "&", "(", ")", "\n", "{", "}",
        "then", "do", "else", "elif", "fi", "done", "esac"}
GIT_VALUE_OPTS = {"-c", "--git-dir", "--work-tree", "--namespace", "--exec-path",
                  "--super-prefix", "--config-env"}
PUSH_VALUE_OPTS = {"-o", "--push-option", "--receive-pack", "--exec", "--repo"}
DRYRUN = re.compile(r"^(--dry-run|-[A-Za-z]*n[A-Za-z]*)$")
DELETE = re.compile(r"^(--delete|-[A-Za-z]*d[A-Za-z]*)$")
ALIAS = re.compile(r"^alias\.([^=\s]+)=push(\s|$)")
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", re.S)
VAR = re.compile(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?")
VARS = {}

def strip_comments(text):
    """Drop `# …` to end of line where `#` begins a word outside quotes — the
    shell rule; a `#` inside quotes or mid-word is text."""
    out, i, n, q, word_start = [], 0, len(text), None, True
    while i < n:
        c = text[i]
        if q:
            if c == "\\" and q == "\"" and i + 1 < n:
                out.append(c); i += 1; c = text[i]
            elif c == q:
                q = None
            out.append(c); i += 1
            continue
        if c == "\\" and i + 1 < n:
            out.append(c); out.append(text[i + 1]); i += 2; word_start = False
            continue
        if c in "\x27\"":
            q = c; out.append(c); i += 1; word_start = False
            continue
        if c == "#" and word_start:
            j = text.find("\n", i)
            if j < 0:
                break
            i = j
            continue
        out.append(c)
        word_start = c in " \t\r\n;&|(){}"
        i += 1
    return "".join(out)

def tokens(text):
    text = strip_comments(text)
    text = re.sub(r"\$(\x27(?:[^\x27\\]|\\.)*\x27)", lambda m: m.group(1), text)   # ANSI-C $\x27…\x27 quoting
    text = re.sub(r"\$\((?:which|command -v|type -P)\s+git\)", "git", text)
    text = re.sub(r"`(?:which|command -v|type -P)\s+git`", "git", text)
    text = re.sub(r"`([^`]*)`", r"( \1 )", text)                                # a backtick body runs
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace_split = True
    lex.whitespace = " \t\r"
    lex.commenters = ""
    out = []
    for t in lex:
        if all(c in ";&|()\n" for c in t):
            out.extend(re.findall(r"&&|\|\||[;&|()\n]", t))
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

def subst(seg):
    """Replace $name / ${name} with a value assigned earlier in this command."""
    out = []
    for t in seg:
        n = VAR.sub(lambda m: VARS.get(m.group(1), m.group(0)), t)
        if n == t:
            out.append(t)
        else:
            try:
                out.extend(shlex.split(n))
            except ValueError:
                out.append(n)
    return out

def expand(path):
    if path.startswith("~"):
        return os.path.expanduser(path)
    if "$" in path or "`" in path:
        return None                 # cannot expand; caller falls back to cwd
    return path

def joined(base, path):
    if path is None:
        return None
    if base is None:
        return None if not os.path.isabs(path) else path
    return path if os.path.isabs(path) else os.path.join(base, path)

def check_git(args, curdir):
    """args = tokens after the git word. Returns (kind, dir, remote, refspec) or None."""
    d = curdir
    alias = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-C" and i + 1 < len(args):
            d = joined(d, expand(args[i + 1]))
            i += 2
            continue
        if a in GIT_VALUE_OPTS and i + 1 < len(args):
            m = ALIAS.match(args[i + 1]) if a == "-c" else None
            if m:
                try:
                    alias = (m.group(1), shlex.split(args[i + 1].split("=", 1)[1])[1:])
                except ValueError:
                    alias = (m.group(1), [])
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        if alias and a == alias[0]:
            args = args[:i] + ["push"] + alias[1] + args[i + 1:]
            a = "push"
        if a != "push":
            return None
        rest = args[i + 1:]
        kind, remote, refspec, flags_done = "push", "", "", False
        j = 0
        while j < len(rest):
            r = rest[j]
            if r == "--":
                flags_done = True
                j += 1
                continue
            if not flags_done and r.startswith("-"):
                if r in PUSH_VALUE_OPTS:
                    if r == "--repo" and j + 1 < len(rest):
                        remote = rest[j + 1]
                    j += 2
                    continue
                if r.startswith("--repo="):
                    remote = r.split("=", 1)[1]
                    j += 1
                    continue
                if r.startswith("-o") and not r.startswith("--"):
                    j += 1              # -o<value>: an attached push option
                    continue
                if DRYRUN.match(r):
                    return None         # a read of the remote
                if DELETE.match(r):
                    kind = "delete"
                j += 1
                continue
            if not remote:
                remote = r
            elif not refspec:
                refspec = r
            j += 1
        return (kind, d, remote, refspec)
    return None

def scan(text, curdir, depth=0):
    if depth > 4:
        raise RuntimeError("nesting deeper than four shells")
    prev = None
    for seg in segments(tokens(text)):
        seg = subst(seg)
        # assignments at the head of a segment (or after `export`) are followed
        k = 1 if seg and seg[0] == "export" else 0
        while k < len(seg) and ASSIGN.match(seg[k]):
            name, value = ASSIGN.match(seg[k]).groups()
            VARS[name] = value
            if name == "GIT_DIR":
                curdir = joined(curdir, expand(value))
            k += 1
        seg = seg[k:]
        head = seg[0].rsplit("/", 1)[-1] if seg else ""
        if head in ("cd", "pushd"):
            rest = [t for t in seg[1:] if t == "-" or not t.startswith("-")]
            target = rest[0] if rest else None
            curdir = joined(curdir, expand(target)) if target and target != "-" else None
            prev = seg
            continue
        hit = scan_segment(seg, prev, curdir, depth)
        if hit:
            return hit
        prev = seg
    return None

def scan_segment(seg, prev, curdir, depth):
    # assignments after a wrapper (env FOO=bar git …) — `scan` took the leading ones
    j = 0
    while j < len(seg) and ASSIGN.match(seg[j]):
        j += 1
    seg = seg[j:]
    if not seg:
        return None
    head = seg[0].rsplit("/", 1)[-1]
    if head in WRAPPERS:
        vals = WRAPPER_VALUE_OPTS.get(head, set())
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            if head == "env" and seg[k] == "-S" and k + 1 < len(seg):
                return scan(seg[k + 1], curdir, depth + 1)
            k += 2 if seg[k] in vals else 1
        if head in TAKES_ONE:
            k += 1
        return scan_segment(seg[k:], prev, curdir, depth)
    if head == "xargs":
        k = 1
        while k < len(seg) and seg[k].startswith("-"):
            k += 1
        fed = list(prev or [])
        if fed and fed[0].rsplit("/", 1)[-1] in ("echo", "printf"):
            fed = [t for t in fed[1:] if not t.startswith("-")]
        if k < len(seg) and is_git(seg[k]):
            return check_git(seg[k + 1:] + fed, curdir)
        return scan_segment(seg[k:], prev, curdir, depth)
    if head in SHELLS:
        for k, t in enumerate(seg):
            if re.match(r"^-[A-Za-z]*c[A-Za-z]*$", t) and k + 1 < len(seg):
                return scan(seg[k + 1], curdir, depth + 1)
        # no -c: a string piped in from the previous segment runs here
        for t in (prev or []):
            hit = scan(t.replace("\\n", "\n"), curdir, depth + 1)
            if hit:
                return hit
        return None
    if head == "eval":
        return scan(" ".join(seg[1:]), curdir, depth + 1)
    if is_git(seg[0]):
        return check_git(seg[1:], curdir)
    return None

try:
    hit = scan(s, "")
except Exception:
    sys.exit(3)
if hit:
    kind, d, remote, refspec = hit
    sys.stdout.write("%s\x1f%s\x1f%s\x1f%s" % (kind, d or "", remote, refspec))
' 2>/dev/null)"
rc=$?
[ "$rc" -eq 0 ] || allow "shape scan failed (rc=$rc)"
[ -n "$record" ] || exit 0

IFS=$'\x1f' read -r kind pushdir remote refspec <<< "$record"
[ "$kind" = "delete" ] && allow "a delete sends no commits"
case "$refspec" in :*) allow "a delete refspec sends no commits" ;; esac

start="$cwd"
if [ -n "$pushdir" ]; then
  case "$pushdir" in
    /*) start="$pushdir" ;;
    *)  start="$cwd/$pushdir" ;;
  esac
  [ -d "$start" ] || start="$cwd"
fi

top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$top" ]; then
  # inside `.git`, or a GIT_DIR= pointed at one: the work tree is the git dir's parent
  common="$(git -C "$start" rev-parse --git-common-dir 2>/dev/null || true)"
  if [ -n "$common" ]; then
    top="$(cd "$start" 2>/dev/null && cd "$common" 2>/dev/null && cd .. && pwd -P)"
    [ -e "$top/.git" ] || top=""
  fi
fi
[ -n "$top" ] || allow "not inside a git work tree"
repo="$(basename "$top")"

# --- opt-in: the nearest CLAUDE.md carrying the line, from the push directory up ---
OPT_IN='^[-* >]*\**`?Review required:`?\**[[:space:]]*\**`?(yes|no)`?\**[[:space:]]*$'
gated=""
dir="$(cd "$start" && pwd -P)"
top_phys="$(cd "$top" && pwd -P)"
while :; do
  if [ -f "$dir/CLAUDE.md" ]; then
    unfenced="$(awk '
      /^[[:space:]]*```/ { fence = !fence; next }
      fence { next }
      { print }' "$dir/CLAUDE.md" 2>/dev/null)" || allow "could not read $dir/CLAUDE.md"
    line="$(printf '%s\n' "$unfenced" | grep -iE "$OPT_IN" | head -1; exit "${PIPESTATUS[1]}")"
    grc=$?
    [ "$grc" -le 1 ] || allow "could not scan $dir/CLAUDE.md (grep rc=$grc)"
    if [ -n "$line" ]; then
      # the nearest CLAUDE.md that carries the line decides, either value
      printf '%s\n' "$line" | grep -qi 'yes' && gated=1
      break
    fi
  fi
  [ "$dir" = "$top_phys" ] || [ "$dir" = "/" ] && break
  dir="$(dirname "$dir")"
done
[ -n "$gated" ] || exit 0

# --- the range the push would send --------------------------------------------
branch="$(git -C "$top" symbolic-ref --short -q HEAD 2>/dev/null || true)"
dst=""
if [ -n "$refspec" ]; then
  case "$refspec" in *:*) dst="${refspec#*:}" ;; *) dst="$refspec" ;; esac
fi
[ -n "$dst" ] || dst="$branch"
dst="${dst#refs/heads/}"

if [ -n "$dst" ] \
   && ! git -C "$top" rev-parse --verify -q "refs/heads/$dst" >/dev/null 2>&1 \
   && git -C "$top" rev-parse --verify -q "refs/tags/$dst" >/dev/null 2>&1; then
  allow "a tag push sends no branch commits"
fi

range=""
if [ -n "$remote" ] && [ -n "$dst" ] && git -C "$top" rev-parse --verify -q "$remote/$dst" >/dev/null 2>&1; then
  range="$remote/$dst..HEAD"
elif git -C "$top" rev-parse --verify -q '@{upstream}' >/dev/null 2>&1; then
  range='@{upstream}..HEAD'
elif [ -n "$branch" ] && git -C "$top" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
  range="origin/$branch..HEAD"
fi
[ -n "$range" ] || allow "no remote ref to compare against"

oldest="$(git -C "$top" log --reverse --format='%ct %h' "$range" 2>/dev/null | head -1 || true)"
[ -n "$oldest" ] || allow "nothing to push on this branch"
oldest_ts="${oldest%% *}"
oldest_sha="${oldest#* }"
case "$oldest_ts" in ''|*[!0-9]*) allow "could not read the committer time of $oldest_sha" ;; esac
count="$(git -C "$top" rev-list --count "$range" 2>/dev/null || echo '?')"

# --- the receipt ---------------------------------------------------------------
zones=()
if [ -n "${REVIEW_RECEIPT_DIR:-}" ]; then
  zones=("$REVIEW_RECEIPT_DIR")
else
  [ -n "${TMPDIR:-}" ] && zones+=("${TMPDIR%/}/claude-handoffs")
  zones+=("/tmp/claude-handoffs")
fi

newest_ts=0
newest_file=""
for zone in "${zones[@]}"; do
  [ -d "$zone" ] || continue
  for f in "$zone"/"$repo"-[0-9][0-9][0-9][0-9]-*.review.md; do
    [ -f "$f" ] || continue
    ts="$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)" || allow "could not read the mtime of $f"
    case "$ts" in ''|*[!0-9]*) allow "could not read the mtime of $f" ;; esac
    if [ "$ts" -gt "$newest_ts" ]; then
      newest_ts="$ts"
      newest_file="$f"
    fi
  done
done

if [ "$newest_ts" -ge "$oldest_ts" ]; then
  exit 0
fi

{
  echo "review-receipt: blocked a push from $repo — no review report covers the $count unpushed commit(s) in $range."
  echo "  command: $cmd"
  if [ -n "$newest_file" ]; then
    echo "  newest report: $newest_file (older than the oldest unpushed commit $oldest_sha)"
  else
    echo "  no $repo-<date>-*.review.md in: ${zones[*]}"
  fi
  echo "  This repo's Landing key says 'Review required: yes'. Ask the user to run /review-changes"
  echo "  (it writes the report to the landing zone) and then /address-findings — both are"
  echo "  user-invoked — and push after that. Report this as a blocked action; the user can push"
  echo "  unreviewed work from their own terminal."
} >&2
exit 2
