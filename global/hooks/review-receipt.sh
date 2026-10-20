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
# `skills`. The zone searched, the filename shape, and which zone and report
# count as this user's (owned by `id -u`, neither group- nor world-writable)
# are src/handoff/scripts/landing.sh's: this hook reads `landing.sh zones` and
# `landing.sh list --kind review --repo <repo>`, the lookup the writers use,
# so a zone landing.sh refuses fails `zones` and `list` (exit 4) and the push
# holds, carrying landing.sh's own reason in the block message.
#
# Which repo: the directory the push runs in, not merely the session's cwd —
# a leading `cd <dir> &&`, `pushd <dir> &&`, `git -C <dir>`, `--git-dir`,
# `--work-tree`, or a `GIT_DIR=` assignment moves it (hook-lib's split_git),
# and the repo is the work tree that directory sits in. A `cd` to a value the
# hook cannot expand (`cd "$X"`) or to a directory that does not exist falls back
# to the payload's `cwd`. A push from inside `.git` resolves to its work tree.
#
# Opt-in by repo: the repo top's `CLAUDE.md` alone decides — a `Review
# required: yes` line gates the push, `no` or no line does not. A push sends
# the whole branch, so a `CLAUDE.md` in a subdirectory never opts out. The line
# is read anywhere in the file outside a fenced block, not only inside the
# `Landing:` block it belongs in; bold, backticks, or a list marker around the
# key or the value are fine; `yes (…)` is not yes. A repo with no such line is
# never gated; outside a git work tree the hook allows with a breadcrumb.
#
# Which push: EVERY `git push` in the command — `git push origin :old; git
# push origin main` is two pushes, and each is judged; one that blocks blocks
# the command.
#
# Which tree: EVERY source the push would send, because git sends them all.
# For refspecs, each one's source (`feat:main`, `HEAD:main`, a bare `main`, a
# leading `+` dropped) — a second refspec is gated exactly like the first —
# else `HEAD`. A negative refspec (`^…`) sends nothing and is dropped. For
# `--all`, `--mirror`, or a wildcard refspec, every local branch that is new
# on the remote or ahead of it; for the matching refspec `:` (or `+:`), every
# local branch the named remote also has and that is ahead of it (to a URL or
# an unconfigured remote, every local branch); beside either, each other
# refspec's source as well. Each source's tree hash
# (`git rev-parse <src>^{tree}`) must equal a stamp in some matching report,
# and one unstamped source blocks the whole command; the block message names
# the first source that failed. The stamp is a `Reviewed-tree: <40 hex>` line
# as `src/review-changes/scripts/tree-stamp.sh --reviewed-trees` reads it — that
# script's header owns the line shape (a list marker, bold, or backticks
# around it; nothing inside a ``` or ~~~ fenced block or behind a blockquote
# `>`, since a report quotes hashes, this hook's own contract included, and a
# quotation is not a receipt), and it is the same reader `--verify` uses, so
# the push gate and a fix pass cannot disagree about a line. That mode
# keeps only the `Reviewed-tree` lines: a `Measured-tree:` line stamps a
# measured report, not a review. The script is found from this hook's own
# resolved path (`<checkout>/src/review-changes/scripts/`), and landing.sh
# the same way (`<checkout>/src/handoff/scripts/`). The opt-in line is read
# by that script too (`--review-required`), which owns its pattern and the
# fence rule; a CLAUDE.md that never says `review required` (any case) is
# not opted in without calling it. A report
# may carry several stamps, one per stamping,
# and any of them matches. The work-tree
# hash `review-changes` and `address-findings` write is the one
# src/review-changes/scripts/tree-stamp.sh prints
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
# `<remote>/<dst>..<src>` when the command names a configured remote (as an
# argument or `--repo`) and the refspec's destination, else
# `@{upstream}..HEAD`, else `origin/<branch>..<src>`. With nothing to push the
# command runs with a breadcrumb. With no ref to compare against — a push to a
# URL (any remote argument that is not a configured remote name, whatever the
# upstream says), a branch's first push, a repo with no remote — there is no
# range and no shortcut: the receipt decides, since every commit is new there. A multi-refspec or `--all`
# push skips this shortcut: "is anything being sent" is already answered by
# whether any branch is ahead, and applying one branch's range to all of them
# is what let every unreviewed branch out before. A refspec that sends no
# branch commits — a delete (`:dst`, never the bare matching refspec `:` or
# `+:`, which sends every matching branch) or a tag — is dropped from the sources,
# not taken as the whole push's answer; a push left with no refspec, and a
# `--delete` push, runs with a breadcrumb. A refspec is a tag push when its
# source is a tag (`refs/tags/…`, or a name that is a tag and not a branch)
# and its destination is absent or under `refs/tags/`; the destination's name
# alone never decides, so `wip:v1` is a branch push where a tag `v1` exists,
# and a tag source sent to a branch (`v1:main`) is gated like any other.
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
# This file holds only the push shape and the receipt check.
#
# Fail-open, each with a one-line stderr breadcrumb: a malformed payload, a
# missing python3 or git, a tokeniser error (an unterminated quote, more
# than four nested shells), a push outside a git work tree, or any error
# counting the commits in the range. A safety hook that blocks on its own
# errors trains the user to disable it.
# Fail-closed, three holds. First, before the opt-in is known: a top-level
# CLAUDE.md the hook cannot read or scan, since an unreadable opt-in line must
# not ungate a repo, and one naming `review required` anywhere whose stamp
# reader is missing or fails, since that reader decides the opt-in. Then, in
# an opted-in repo only: a source whose tree git
# cannot resolve (a push git would refuse anyway, and allowing it let a
# negative refspec ungate the rest); and the stamp reader or landing.sh
# missing from beside the checkout, or either failing (a reader failing on a
# report it could read, `zones` printing no zone or `zones` or `list` exiting
# non-zero, landing.sh's stderr carried into the block) — a copy of this
# directory made outside the checkout would otherwise ungate every push with
# only a breadcrumb, which is a broken install, not an error in the hook, and
# a zone landing.sh refuses is the user's to fix. A report that cannot be read, or
# that the stamp reader exits 4 on, is NOT a fail-open: it is skipped
# with a breadcrumb and the remaining reports still decide, because an
# unreadable file can carry no stamp and failing open on one would let a
# planted `chmod 000` file disable the gate; skipping can only drop stamps, so
# it never lets a push through that reading would have held, and holding on
# it instead would let the same planted file block every push. next-step.sh
# skips such a report too. Silent exits (no breadcrumb):
# the command is not a push, or the repo is not opted in.
#
# REVIEW_RECEIPT_DIR, when set, replaces the landing-zone search (the selftest
# uses it; a user with a non-standard temp dir can too); landing.sh's header
# owns that zone policy.
#
# Install note: opt a repo in with a 'Review required: yes' line in its top-level CLAUDE.md Landing: block.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/review-receipt.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# review-receipt-selftest.sh beside this file builds throwaway repos and runs
# the expect/reject table; run it after changing a rule. committing's
# src/committing/scripts/next-step.sh reads this same contract (the opt-in
# line of the repo top's CLAUDE.md, the landing zones, the Reviewed-tree
# stamps) through the same two scripts to say whether a push would pass, and
# next-step-selftest.sh's parity section runs both on one fixture to catch
# the two drifting.
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

# --- the push records: every live `git push` in the command, and where each runs ---
# Prints one "kind<US>dir<US>remote<US>refspec<US>extra-refspecs<US>all<GS>"
# record per push (US = 0x1f, GS = 0x1d, extras RS-separated) — kind is `push`
# or `delete`; `all` is set for --all/--mirror; any field may be empty —
# nothing otherwise. on_command collects each push and returns no hit, so the
# scan runs to the end of the command instead of stopping at its first push
# (`git push origin other && git push origin main` is two pushes); finish()
# hands the list to emit as the one hit, and an empty list emits nothing.
hook_scan '
PUSH_VALUE_OPTS = {"-o", "--push-option", "--receive-pack", "--exec", "--repo"}
DRYRUN = re.compile(r"^(--dry-run|-[A-Za-z]*n[A-Za-z]*)$")
DELETE = re.compile(r"^(--delete|-[A-Za-z]*d[A-Za-z]*)$")

def check_git(args, curdir):
    """args = tokens after the git word. Returns (kind, dir, remote, refspec,
    extra refspecs, all) or None. dir is where the repo is: the --git-dir when
    the command names one, else the --work-tree, else where git runs."""
    d, sub, rest, gd, wt = split_git(args, curdir)
    if sub != "push":
        return None
    d = gd or wt or d
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
        if REDIR.match(r) and not REDIR.match(r).group(2):
            j += 2                 # `> out.txt`: the operator and the target after it (REDIR is hook-lib.py)
            continue
        if "<" in r or ">" in r:
            j += 1                 # `>out.txt`, `2>&1`: a redirection in one word
            continue
        if not remote:
            remote = r
        else:
            refspecs.append(r)     # every refspec, not just the first
        j += 1
    return (kind, d, remote, refspecs[0] if refspecs else "",
            "\x1e".join(refspecs[1:]), pushall)


PUSHES = []

def on_command(seg, curdir):
    args = git_args(seg)
    hit = check_git(args, curdir) if args is not None else None
    if hit:
        PUSHES.append(hit)
    return None                    # no hit: the scan goes on to the next push

def finish():
    return list(PUSHES)            # every push, as one hit; empty means none

def emit(pushes):
    for kind, d, remote, refspec, extras, pushall in pushes:
        sys.stdout.write("%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1d"
                         % (kind, d or "", remote, refspec, extras, pushall))
'
records=()
while IFS= read -r -d $'\x1d' rec; do records+=("$rec"); done < <(printf '%s' "$hook_result")
[ "${#records[@]}" -gt 0 ] || exit 0

# The two scripts this hook reads, located from its real path in the checkout:
# tree-stamp.sh, the one stamp reader (the same script address-findings'
# --verify uses, so the two cannot disagree about a line), and handoff's
# landing.sh, which owns the zones and the report filename shape.
hook_real="$(cd "$hook_dir" 2>/dev/null && pwd -P)"
stamp_reader="$hook_real/../../src/review-changes/scripts/tree-stamp.sh"
landing="$hook_real/../../src/handoff/scripts/landing.sh"

# rec_allow <why>: this push passes. One push in the command allows as
# hook_allow does; with several, each pass is named and the next is judged.
rec_allow() {
  if [ "${#records[@]}" -gt 1 ]; then
    echo "$hook_name: push $ri of ${#records[@]}: $1, allowing that push" >&2
  else
    echo "$hook_name: $1, allowing" >&2
  fi
}

# hold <why> [<remedy>]: the three fail-closed holds the header names — a top
# CLAUDE.md it cannot read (called before the opt-in is known), and, in an
# opted-in repo, a source tree or a receipt it cannot check. The remedy
# defaults to the broken-install one.
hold() {
  {
    echo "review-receipt: blocked a push from $repo — $1, so the receipt cannot be checked."
    echo "  command: $cmd"
    if [ -n "${2:-}" ]; then
      printf '%s\n' "$2" | sed 's/^/  /'
    else
      echo "  This repo's Landing key says 'Review required: yes'. The hook reads its stamp reader and"
      echo "  landing.sh from the skills checkout it lives in (global/hooks/ beside src/); run it from that"
      echo "  checkout (scripts/install.sh wires it), or push from your own terminal."
    fi
  } >&2
  exit 2
}

# landing_call <args>: runs landing.sh once and returns its status, leaving its
# stdout in landing_out and its stderr, on one line, in landing_why — its
# reason for refusing a zone, which the hold carries rather than blaming the
# install. Its stderr lines are tagged with RS (0x1e) inside the one capture
# and split out after, so no second run is needed to recover them.
landing_call() {
  local all rc
  all="$("${BASH:-bash}" "$landing" "$@" 2> >(sed $'s/^/\x1e/'))"; rc=$?
  landing_out="$(printf '%s\n' "$all" | grep -v $'^\x1e')"
  landing_why="$(printf '%s\n' "$all" | sed -n $'s/^\x1e//p' | tr '\n' ' ' | sed 's/ *$//')"
  return "$rc"
}
landing_fix="landing.sh gives its reason above. A landing zone it refuses (owned by another uid, or
group- or world-writable) is fixed or removed, then the review report written again; or push from
your own terminal."

# refspec_parts <refspec>: the one place a refspec is split. rs_src is its
# source with the force `+` dropped; rs_dst its destination as written, ""
# when the refspec has no `:` (git then updates the source's own name).
refspec_parts() {
  local r="${1#+}"
  case "$r" in *:*) rs_src="${r%%:*}" rs_dst="${r#*:}" ;; *) rs_src="$r" rs_dst="" ;; esac
}

# is_tag <refspec>: the refspec sends a tag, not branch commits — its source
# is a tag (refs/tags/…, or a name that is a tag and not a branch) and its
# destination is absent or under refs/tags/. The destination's name never
# decides alone: `wip:v1` sends a branch even where a tag v1 exists.
is_tag() {
  refspec_parts "$1"
  case "$rs_dst" in ""|refs/tags/*) ;; *) return 1 ;; esac
  case "$rs_src" in refs/tags/?*) return 0 ;; refs/*|"") return 1 ;; esac
  ! git -C "$top" rev-parse --verify -q "refs/heads/$rs_src" >/dev/null 2>&1 \
    && git -C "$top" rev-parse --verify -q "refs/tags/$rs_src" >/dev/null 2>&1
}

# resolve_repo <push dir>: top (the work tree the push runs in) and repo (its
# name); returns 1 outside a work tree. The push dir is `git -C`'s, resolved
# from the payload cwd, which stands in when it is not a directory.
resolve_repo() {
  local start="$cwd" common
  if [ -n "$1" ]; then
    case "$1" in
      /*) start="$1" ;;
      *)  start="$cwd/$1" ;;
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
  [ -n "$top" ] || return 1
  repo="$(basename "$top")"
}

# review_required: true when the top's CLAUDE.md says 'Review required: yes',
# as tree-stamp.sh --review-required reads it (header). The phrase check first
# is a necessary condition, not a second rule: a file without it has no
# opt-in line however the reader parses one.
review_required() {
  local optin="$top/CLAUDE.md" grc
  [ -e "$optin" ] || return 1
  grep -qi 'review required' "$optin" 2>/dev/null
  grc=$?
  [ "$grc" -le 1 ] || hold "could not read $optin" "Make $optin readable, or push from your own terminal."
  [ "$grc" -eq 0 ] || return 1
  [ -f "$stamp_reader" ] || hold "the stamp reader is not at $stamp_reader"
  "${BASH:-bash}" "$stamp_reader" --review-required "$optin" 2>/dev/null
  case $? in
    0) return 0 ;;
    1) return 1 ;;
    4) hold "could not read $optin" "Make $optin readable, or push from your own terminal." ;;
    *) hold "the stamp reader failed on $optin" ;;
  esac
}

# sources <remote> <pushall> <refspec>…: every source the push would send —
# srcs, and src (the first refspec's source, else HEAD), dst (its
# destination, else the current branch), branch, wide (several branches) and
# url_push (the remote is not a configured one). Returns 1 when the push
# passes, having said why. A second refspec, `--all`/`--mirror`, and a
# wildcard refspec each reached the remote ungated before (2026-08-22
# review): the gate derived everything from one token. A remote argument
# that is not a configured remote is a URL (or a remote this repo does not
# know): it has no remote-tracking refs, so no range.
sources() {
  local remote="$1" pushall="$2" r b ahead rname only_matching matching=""
  shift 2
  branch="$(git -C "$top" symbolic-ref --short -q HEAD 2>/dev/null || true)"
  refspec_parts "${1:-}"
  src="${rs_src:-HEAD}"
  dst="${rs_dst:-$rs_src}"
  [ -n "$dst" ] || dst="$branch"
  dst="${dst#refs/heads/}"
  url_push=""
  if [ -n "$remote" ] && ! git -C "$top" remote 2>/dev/null | grep -qxF -- "$remote"; then url_push=1; fi
  wide=""
  for r in "$@"; do
    case "$r" in :|+:) matching=1 ;; *'*'*) wide=1 ;; esac
  done
  srcs=()
  if [ -z "$pushall" ] && [ -z "$wide" ] && [ -z "$matching" ]; then
    for r in "$@"; do
      refspec_parts "$r"
      srcs+=("${rs_src:-HEAD}")
    done
    [ "${#srcs[@]}" -gt 0 ] || srcs=("HEAD")
    return 0
  fi
  # every local branch the push would actually change: new on the remote, or
  # ahead of it — for the matching refspec alone, only a branch the remote has
  rname="${remote:-origin}"
  only_matching=""
  [ -n "$matching" ] && [ -z "$pushall" ] && [ -z "$wide" ] && [ -z "$url_push" ] && only_matching=1
  wide=1
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    if [ -z "$url_push" ] && git -C "$top" rev-parse --verify -q "$rname/$b" >/dev/null 2>&1; then
      ahead="$(git -C "$top" rev-list --count "$rname/$b..$b" 2>/dev/null || echo '?')"
      case "$ahead" in ''|0) continue ;; *[!0-9]*) rec_allow "could not count the commits on $b"; return 1 ;; esac
    elif [ -n "$only_matching" ]; then
      continue
    fi
    srcs+=("$b")
  done < <(git -C "$top" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
  # the other refspecs beside it send their own sources, ahead or not
  for r in "$@"; do
    case "$r" in :|+:|*'*'*) continue ;; esac
    refspec_parts "$r"
    [ -n "$rs_src" ] && srcs+=("$rs_src")
  done
  [ "${#srcs[@]}" -gt 0 ] || { rec_allow "no branch is ahead of $rname"; return 1; }
}

# measure <remote>: trees (one per source; every source must be stamped,
# because git sends them all), range (what the push sends, "" when there is
# no ref to compare against) and count. Trees resolve before the range, so a
# source git cannot resolve holds here rather than failing open on the
# count. Returns 1 when the push passes, having said why.
measure() {
  local remote="$1" s t
  trees=()
  for s in "${srcs[@]}"; do
    t="$(git -C "$top" rev-parse --verify -q "$s^{tree}" 2>/dev/null || true)"
    [ -n "$t" ] || hold "git cannot resolve the tree of $s" "Check the refspec (git would refuse a source it cannot resolve), or push from your own terminal."
    trees+=("$t")
  done
  range=""
  if [ -n "$url_push" ]; then
    :   # a URL: no remote-tracking ref, whatever the upstream says
  elif [ -n "$remote" ] && [ -n "$dst" ] && git -C "$top" rev-parse --verify -q "$remote/$dst" >/dev/null 2>&1; then
    range="$remote/$dst..$src"
  elif [ "$src" = "HEAD" ] && git -C "$top" rev-parse --verify -q '@{upstream}' >/dev/null 2>&1; then
    range="@{upstream}..HEAD"
  elif [ -n "$branch" ] && git -C "$top" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
    range="origin/$branch..$src"
  fi
  # no range (a URL, a branch's first push, no remote): every commit is new
  # there, so there is no "nothing to push" shortcut and the receipt decides
  count="?"
  if [ "${#srcs[@]}" -eq 1 ] && [ -z "$wide" ] && [ -n "$range" ]; then
    count="$(git -C "$top" rev-list --count "$range" 2>/dev/null || echo '?')"
    case "$count" in
      ''|0)       rec_allow "nothing to push on this branch"; return 1 ;;
      *[!0-9]*)   rec_allow "could not count the commits in $range"; return 1 ;;
    esac
  fi
}

# stamps_for <repo>: zones, reports (the readable review reports), stamps
# (one Reviewed-tree a line) and stamp_files ("<tree> <report>" a line), read
# once per repo: a second push from the same repo reuses them. The zones and
# the report list are landing.sh's; a reader that is missing or fails holds
# the push rather than waving it through.
stamps_repo=""
stamps_for() {
  local f h found
  [ "$stamps_repo" = "$1" ] && return 0
  [ -f "$landing" ] || hold "landing.sh is not at $landing"
  landing_call zones || hold "landing.sh zones failed${landing_why:+ ($landing_why)}" "${landing_why:+$landing_fix}"
  zones=()
  while IFS= read -r f; do [ -n "$f" ] && zones+=("$f"); done <<< "$landing_out"
  [ "${#zones[@]}" -gt 0 ] || hold "landing.sh zones printed no zone${landing_why:+ ($landing_why)}" "${landing_why:+$landing_fix}"
  landing_call list --kind review --repo "$1" \
    || hold "landing.sh list --kind review failed${landing_why:+ ($landing_why)}" "${landing_why:+$landing_fix}"
  reports=0 stamps="" stamp_files=""
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    if [ ! -r "$f" ]; then
      echo "review-receipt: skipping unreadable report $f" >&2
      continue
    fi
    found="$("${BASH:-bash}" "$stamp_reader" --reviewed-trees "$f" 2>/dev/null)"
    case $? in
      0) ;;
      2) found="" ;;
      4) echo "review-receipt: skipping unreadable report $f" >&2; continue ;;
      *) hold "the stamp reader failed on $f" ;;
    esac
    reports=$((reports + 1))
    if [ -n "$found" ]; then
      stamps="$stamps
$found"
      while IFS= read -r h; do
        [ -n "$h" ] && stamp_files="$stamp_files
$h $f"
      done <<< "$found"
    fi
  done <<< "$landing_out"
  stamps_repo="$1"
}

# block_unstamped <source> <tree>: exits 2, naming the unstamped tree, the
# last stamp read and how the two differ.
block_unstamped() {
  local src="$1" tree="$2" sent last_line last
  sent="$count unpushed commit(s) in $range"
  [ -n "$range" ] || sent="no remote ref to compare against, so every commit is new there"
  [ -z "$wide" ] || sent="one of the branches the push would change"
  {
    echo "review-receipt: blocked a push from $repo — no review report stamps the tree the push would send ($src^{tree} = ${tree:0:12}; $sent)."
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
}

# judge <record>: returns when this push passes, exits 2 when it is blocked.
judge() {
  local kind pushdir remote refspec extras pushall r i dropped="" rs=() kept=() pushed=()
  IFS=$'\x1f' read -r kind pushdir remote refspec extras pushall <<< "$1"
  [ "$kind" = "delete" ] && { rec_allow "a delete sends no commits"; return 0; }

  # every refspec, the first and the extras; a delete refspec (`:dst`) sends no
  # commits, and a negative one (`^…`) excludes refs rather than sending one;
  # the bare `:` / `+:` is the matching refspec and sends every matching branch
  [ -n "$refspec" ] && rs+=("$refspec")
  if [ -n "$extras" ]; then
    while IFS= read -r r || [ -n "$r" ]; do [ -n "$r" ] && rs+=("$r"); done < <(printf '%s' "$extras" | tr '\036' '\n')
  fi
  for r in ${rs[@]+"${rs[@]}"}; do
    case "$r" in :|+:) ;; :*|+:*) dropped=1; continue ;; esac   # `:` alone is the matching refspec, not a delete
    case "$r" in ^*) continue ;; esac
    kept+=("$r")
  done
  [ -n "$dropped" ] && [ "${#kept[@]}" -eq 0 ] && { rec_allow "a delete refspec sends no commits"; return 0; }

  resolve_repo "$pushdir" || { rec_allow "not inside a git work tree"; return 0; }
  review_required || return 0

  # a tag refspec sends no branch commits
  for r in ${kept[@]+"${kept[@]}"}; do is_tag "$r" && continue; pushed+=("$r"); done
  [ "${#kept[@]}" -eq 0 ] || [ "${#pushed[@]}" -gt 0 ] || { rec_allow "a tag push sends no branch commits"; return 0; }

  sources "$remote" "$pushall" ${pushed[@]+"${pushed[@]}"} || return 0
  measure "$remote" || return 0
  stamps_for "$repo"
  for i in "${!trees[@]}"; do
    printf '%s\n' "$stamps" | grep -qx "${trees[$i]}" || block_unstamped "${srcs[$i]}" "${trees[$i]}"
  done
}

for ri in "${!records[@]}"; do
  ri=$((ri + 1))
  judge "${records[$((ri - 1))]}"
done
exit 0
