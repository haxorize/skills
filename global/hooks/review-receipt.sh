#!/usr/bin/env bash
# review-receipt — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks `git push` into a repo that asks for review before landing, unless a
# review report for that repo in the landing zone carries a `Reviewed-tree:`
# stamp equal to the tree of the commit the push would send. The report is the
# receipt: `review-changes` writes `<repo>-<date>-<slug>.review.md` to the
# landing zone `handoff` defines (its "Where to write it" section:
# `claude-handoffs/` under the platform temp dir) and stamps it with the tree
# hash of the work tree it reviewed; `address-findings` appends a fresh stamp
# when its fix pass closes; nothing else produces one — an in-session subagent
# review that wrote no file is not a review this hook can see, on purpose.
# `<repo>` is the basename of the work tree, so two checkouts with one basename
# share receipts; the date segment keeps `skills-archive-…` from answering for
# `skills`.
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
# Which tree: EVERY source the push would send, because git sends them all.
# For refspecs, each one's source (`feat:main`, `HEAD:main`, a bare `main`, a
# leading `+` dropped) — a second refspec is gated exactly like the first —
# else `HEAD`. For `--all`, `--mirror`, or a wildcard refspec, every local
# branch that is new on the remote or ahead of it. Each source's tree hash
# (`git rev-parse <src>^{tree}`) must equal a stamp in some matching report,
# and one unstamped source blocks the whole command; the block message names
# the first source that failed. The stamp is the line `Reviewed-tree: <40
# hex>` (a list marker, bold, or backticks around it are fine), read
# anywhere in the file EXCEPT
# inside a fenced block or behind a blockquote `>` — a report quotes hashes,
# including this hook's own contract, and a quotation is not a receipt; the
# opt-in scan strips fences the same way. A report may carry several stamps,
# one per stamping, and any of them matches. The work-tree
# hash `review-changes` and `address-findings` write is
#   T="$(mktemp -u)"; GIT_INDEX_FILE="$T" git read-tree HEAD 2>/dev/null; GIT_INDEX_FILE="$T" git add -A :/ && GIT_INDEX_FILE="$T" git write-tree; rm -f "$T"
# (a throwaway index seeded from HEAD, so the real one is untouched and a
# tracked-but-ignored file still counts); it equals the tree of a commit that
# takes every tracked change and every untracked file `.gitignore` does not
# exclude, so a commit of the whole reviewed tree matches and a partial commit
# does not. An untracked file that must not land is deleted or ignored before
# the stamp is taken, not committed to satisfy the gate. Content, not time:
# review the dirty tree, fix, commit, push; a message-only amend keeps the
# tree and passes; a rebase that changes no content keeps the tree and passes;
# any edit after the last stamp — a fix-up, a typo — is a new tree and blocks
# until re-stamped (`address-findings` stamps when its pass closes, or
# `/review-changes` again).
#
# Which range, for "nothing to push": only for a single-source push —
# `<remote>/<dst>..<src>` when the command names a remote (as an argument or
# `--repo`) and the refspec's destination, else `@{upstream}..HEAD`, else
# `origin/<branch>..<src>`. With nothing to push, or no ref to compare
# against, the command runs with a breadcrumb. A multi-refspec or `--all`
# push skips this shortcut: "is anything being sent" is already answered by
# whether any branch is ahead, and applying one branch's range to all of them
# is what let every unreviewed branch out before. A
# push that sends no branch commits — a delete (`--delete`, `:dst`) or a tag —
# runs with a breadcrumb too.
#
# What it does not see: whether `review-changes` wrote the stamp — a hash
# typed into a file by hand matches as well as one the review computed, and
# that is a fabricated receipt `committing`'s claims rule fails, not this
# hook; a push run through a program it does not treat as a wrapper (the list
# is in the scanner); a push the user runs themselves (`! git push` in the
# prompt, or any terminal), which never passes through a tool hook — that is
# the one skip path, and it is the user's. A `~/.gitconfig` alias is outside
# the contract; an alias built on the command line (`git -c alias.p=push p`)
# is not.
#
# `git push --dry-run` / `-n` (as a flag, before `--` and any refspec) is a
# read of the remote and passes. `git push` inside a quoted message, an echo,
# or a heredoc no shell consumes is text. How a push may be spelled — a `bash
# -c` string, `eval`, a shell-fed heredoc, a variable, a wrapper, a compound
# statement, `xargs git`, a `-c alias.p=push` built on the command line, and
# how `cd`/`pushd`/`GIT_DIR=` move the directory it runs in — is hook-lib.sh /
# hook-lib.py beside this file; the lib's header is that part of the contract.
# `git -C <dir>` is this hook's own. This file holds only the push shape and
# the receipt check.
#
# Fail-open, each with a one-line stderr breadcrumb: a malformed payload, a
# missing python3 or git, a tokeniser error (an unterminated quote, more
# than four nested shells), a push outside a git work tree, a CLAUDE.md the
# opt-in walk cannot read, a repo with no ref to compare against, a source ref
# whose tree cannot be resolved, or any error counting the commits in the
# range. A safety hook that blocks on its own errors trains the user to
# disable it. A report that cannot be read is NOT a fail-open: it is skipped
# with a breadcrumb and the remaining reports still decide, because an
# unreadable file can carry no stamp and failing open on one would let a
# planted `chmod 000` file disable the gate. Silent exits (no breadcrumb):
# the command is not a push, or the repo is not opted in.
#
# REVIEW_RECEIPT_DIR, when set, replaces the landing-zone search (the selftest
# uses it; a user with a non-standard temp dir can too).
#
# Install note: opt a repo in with a 'Review required: yes' line in its CLAUDE.md Landing: block (nearest CLAUDE.md wins; 'no' opts a directory out).
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
hook_name="review-receipt"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload
command -v git >/dev/null 2>&1 || hook_allow "git not found"

# --- the push record: a live `git push`, and where it runs ---------------------
# Prints "kind<US>dir<US>remote<US>refspec<US>extra-refspecs<US>all" (US =
# 0x1f, extras RS-separated) on a match — kind is `push` or `delete`; `all` is
# set for --all/--mirror; any field may be empty — nothing otherwise.
hook_scan '
PUSH_VALUE_OPTS = {"-o", "--push-option", "--receive-pack", "--exec", "--repo"}
DRYRUN = re.compile(r"^(--dry-run|-[A-Za-z]*n[A-Za-z]*)$")
DELETE = re.compile(r"^(--delete|-[A-Za-z]*d[A-Za-z]*)$")

def check_git(args, curdir):
    """args = tokens after the git word. Returns (kind, dir, remote, refspec) or None."""
    d = curdir
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-C" and i + 1 < len(args):
            d = joined(d, expand(args[i + 1]))
            i += 2
            continue
        if a in GIT_VALUE_OPTS and i + 1 < len(args):
            i += 2
            continue
        if a.startswith("-"):
            i += 1
            continue
        if a != "push":
            return None
        rest = args[i + 1:]
        kind, remote, refspec, flags_done = "push", "", "", False
        refspecs, pushall = [], ""
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
                if r in ("--all", "--mirror"):
                    pushall = "1"     # sends every branch; no refspec appears
                j += 1
                continue
            if "<" in r or ">" in r:
                j += 1                 # a redirection the segment split left behind
                continue
            if not remote:
                remote = r
            else:
                refspecs.append(r)     # every refspec, not just the first
            j += 1
        return (kind, d, remote, refspecs[0] if refspecs else "",
                "\x1e".join(refspecs[1:]), pushall)
    return None


def on_command(seg, curdir):
    args = git_args(seg)
    return check_git(args, curdir) if args is not None else None

def emit(hit):
    kind, d, remote, refspec, extras, pushall = hit
    sys.stdout.write("%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s"
                     % (kind, d or "", remote, refspec, extras, pushall))
'
record="$hook_result"
[ -n "$record" ] || exit 0

IFS=$'\x1f' read -r kind pushdir remote refspec extras pushall <<< "$record"
[ "$kind" = "delete" ] && hook_allow "a delete sends no commits"
case "$refspec" in :*) hook_allow "a delete refspec sends no commits" ;; esac

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
[ -n "$top" ] || hook_allow "not inside a git work tree"
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
      { print }' "$dir/CLAUDE.md" 2>/dev/null)" || hook_allow "could not read $dir/CLAUDE.md"
    line="$(printf '%s\n' "$unfenced" | grep -iE "$OPT_IN" | head -1; exit "${PIPESTATUS[1]}")"
    grc=$?
    [ "$grc" -le 1 ] || hook_allow "could not scan $dir/CLAUDE.md (grep rc=$grc)"
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
  hook_allow "a tag push sends no branch commits"
fi

# the commit the push would send: the refspec's source, else HEAD
src=""
if [ -n "$refspec" ]; then
  case "$refspec" in *:*) src="${refspec%%:*}" ;; *) src="$refspec" ;; esac
  src="${src#+}"
fi
[ -n "$src" ] || src="HEAD"

# Every source the push would send, not only the first refspec. A second refspec,
# `--all`/`--mirror`, and a wildcard refspec each reached the remote ungated
# before (2026-08-22 review): the gate derived everything from one token.
wide=""
case "$refspec" in *'*'*) wide=1 ;; esac
srcs=()
if [ -n "$pushall" ] || [ -n "$wide" ]; then
  wide=1
  # every local branch the push would actually change: new on the remote, or ahead of it
  rname="${remote:-origin}"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    if git -C "$top" rev-parse --verify -q "$rname/$b" >/dev/null 2>&1; then
      ahead="$(git -C "$top" rev-list --count "$rname/$b..$b" 2>/dev/null || echo '?')"
      case "$ahead" in ''|0) continue ;; *[!0-9]*) hook_allow "could not count the commits on $b" ;; esac
    fi
    srcs+=("$b")
  done < <(git -C "$top" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
  [ "${#srcs[@]}" -gt 0 ] || hook_allow "no branch is ahead of $rname"
else
  srcs=("$src")
  if [ -n "$extras" ]; then
    while IFS= read -r extra || [ -n "$extra" ]; do
      [ -n "$extra" ] || continue
      case "$extra" in :*) continue ;; esac          # a delete refspec sends no commits
      case "$extra" in *:*) es="${extra%%:*}" ;; *) es="$extra" ;; esac
      es="${es#+}"
      [ -n "$es" ] && srcs+=("$es")
    done < <(printf '%s' "$extras" | tr '\036' '\n')
  fi
fi

range=""
if [ -n "$remote" ] && [ -n "$dst" ] && git -C "$top" rev-parse --verify -q "$remote/$dst" >/dev/null 2>&1; then
  range="$remote/$dst..$src"
elif [ "$src" = "HEAD" ] && git -C "$top" rev-parse --verify -q '@{upstream}' >/dev/null 2>&1; then
  range="@{upstream}..HEAD"
elif [ -n "$branch" ] && git -C "$top" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
  range="origin/$branch..$src"
fi
count="?"
if [ "${#srcs[@]}" -eq 1 ] && [ -z "$wide" ]; then
  [ -n "$range" ] || hook_allow "no remote ref to compare against"
  count="$(git -C "$top" rev-list --count "$range" 2>/dev/null || echo '?')"
  case "$count" in
    ''|0)       hook_allow "nothing to push on this branch" ;;
    *[!0-9]*)   hook_allow "could not count the commits in $range" ;;
  esac
fi

# --- the tree(s) the push would send ---------------------------------------------
# Every source must be stamped; one unstamped source blocks the whole command,
# because git sends them all.
trees=()
for s in "${srcs[@]}"; do
  t="$(git -C "$top" rev-parse --verify -q "$s^{tree}" 2>/dev/null || true)"
  [ -n "$t" ] || hook_allow "could not resolve the tree of $s"
  trees+=("$t")
done
tree="${trees[0]}"

# --- the receipt ---------------------------------------------------------------
zones=()
if [ -n "${REVIEW_RECEIPT_DIR:-}" ]; then
  zones=("$REVIEW_RECEIPT_DIR")
else
  [ -n "${TMPDIR:-}" ] && zones+=("${TMPDIR%/}/claude-handoffs")
  [ "${zones[0]:-}" = "/tmp/claude-handoffs" ] || zones+=("/tmp/claude-handoffs")
fi

STAMP='^[-*]*[[:space:]]*\**`?Reviewed-tree:`?\**[[:space:]]*`?[0-9a-f]{40}`?[[:space:]]*$'
reports=0
stamps=""
stamp_files=""
for zone in "${zones[@]}"; do
  [ -d "$zone" ] || continue
  for f in "$zone"/"$repo"-[0-9][0-9][0-9][0-9]-*.review.md; do
    [ -f "$f" ] || continue
    if [ ! -r "$f" ]; then
      echo "review-receipt: skipping unreadable report $f" >&2
      continue
    fi
    reports=$((reports + 1))
    found="$(awk '
      /^[[:space:]]*```/ { fence = !fence; next }
      fence { next }
      { print }' "$f" 2>/dev/null | grep -E "$STAMP" | grep -oE '[0-9a-f]{40}' || true)"
    if [ -n "$found" ]; then
      stamps="$stamps
$found"
      while IFS= read -r h; do
        [ -n "$h" ] && stamp_files="$stamp_files
$h $f"
      done <<< "$found"
    fi
  done
done

unstamped=""
for i in "${!trees[@]}"; do
  printf '%s\n' "$stamps" | grep -qx "${trees[$i]}" && continue
  unstamped="${srcs[$i]}"
  tree="${trees[$i]}"
  break
done
[ -n "$unstamped" ] || exit 0
src="$unstamped"

{
  echo "review-receipt: blocked a push from $repo — no review report stamps the tree the push would send ($src^{tree} = ${tree:0:12}; $count unpushed commit(s) in $range)."
  echo "  command: $cmd"
  if [ "$reports" -gt 0 ]; then
    last_line="$(printf '%s\n' "$stamp_files" | grep -E '^[0-9a-f]{40} ' | tail -1)"
    if [ -n "$last_line" ]; then
      last="${last_line%% *}"
      echo "  $reports $repo report(s) in ${zones[*]}; the last stamp read (${last:0:12}, in $(basename "${last_line#* }")) is a different tree —"
      echo "  something changed after the last stamp (an edit, a fix-up, a file left uncommitted), or the commit is partial."
      if git -C "$top" cat-file -e "$last^{tree}" 2>/dev/null; then
        echo "  how the two trees differ:"
        git -C "$top" diff --stat "$last" "$tree" 2>/dev/null | sed 's/^/    /' | head -12
      fi
      echo "  A scratch file folded into the stamped tree has to be committed, or deleted and the tree"
      echo "  re-stamped — deleting or gitignoring it is the move; committing it to satisfy the gate is not."
    else
      echo "  $reports $repo report(s) in ${zones[*]}, none carrying a 'Reviewed-tree:' stamp."
    fi
  else
    echo "  no $repo-<date>-*.review.md in: ${zones[*]}"
  fi
  echo "  This repo's Landing key says 'Review required: yes'. Ask the user to run /review-changes"
  echo "  (it writes and stamps the report) or, after a fix pass, /address-findings (it re-stamps) —"
  echo "  both are user-invoked — and push after that. Report this as a blocked action; the user"
  echo "  can push unreviewed work from their own terminal."
} >&2
exit 2
