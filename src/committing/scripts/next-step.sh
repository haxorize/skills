#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# next-step.sh — print the landing order this repo's `Landing:` key sets, and
# the one next act for the tree as it stands: commit, review, fix pass, or
# push. `implement`, `address-findings` and `feedback-loops` close on its
# `next:` line, so the order lives here once instead of in four places.
#
#   next-step.sh                 the order and the next act, from the repo here
#
# Output, one `key: value` per line, `next:` always last:
#   review:  required | not required   (the `Review required:` line)
#   tree:    <12-hex>, <n> dirty path(s) | <12-hex>, clean
#   receipt: stamped by <report> | HEAD's tree stamped by <report>, not the
#            <n> uncommitted path(s) | none of <n> report(s) stamps it
#   ahead:   <n> of <upstream>[, <m> behind] | ? (no upstream) |
#            ? (detached HEAD) | ? (no remote)
#   order:   the whole landing order for this repo
#   next:    the one act, a literal `/command <args>` where one exists
#
# It reads what the review-receipt hook reads, by the same means, so it never
# says "push" where the hook blocks: the `Review required:` line of the repo
# top's CLAUDE.md alone, never a subdirectory's, through tree-stamp.sh
# --review-required, the one opt-in and fence reader the hook calls too
# (next-step-selftest.sh's parity section runs both on one fixture); the review reports `landing.sh list --kind review` prints, from
# the zones `landing.sh zones` owns (a zone landing.sh refuses fails `list`,
# and this script exits 4 with landing.sh's reason); and their
# `Reviewed-tree` lines through tree-stamp.sh --reviewed-trees, the one stamp reader,
# skipping a report it cannot read (exit 4) as the hook does. A round is
# running when that same top CLAUDE.md carries a `Deferrals register:` line
# (the `## Round` block's key, read the same way, never from a subdirectory's
# CLAUDE.md); then an unreviewed
# close's next act is the batch's commit, since one review covers everything
# unpushed before the push (ADR-0112). A report
# answers when it stamps the working-tree stamp (HEAD's tree when the tree is
# clean, and the tree a commit of the whole tree reproduces when it is not),
# or HEAD's tree, which is what a bare `git push` sends: the commits then
# push, and the uncommitted paths are named as left out. Where nothing stamps
# it, the newest report is taken as this branch's unaddressed review, and the
# next act is `/address-findings <it>`, only when all of these hold: it
# carries one stamp (every fix pass appends one, its close marker, so a second
# means the pass ran and an edit after it is a new review), and that stamp is
# not the upstream tip's tree; it names at least one `F<n>` finding at the
# start of a line outside a fence; and its `Reviewed-head:` is HEAD, or an
# ancestor of HEAD that is the upstream tip or is not reachable from the
# upstream (with no upstream, any ancestor of HEAD) — so a report from
# another branch, or one whose head the upstream has moved past, is not.
# Anything else falls through to `/review-changes`. "push" is said only with
# an upstream to push to and nothing behind it: no remote, a detached HEAD, no
# upstream, and a diverged branch each get their own act.
#
# The two scripts it runs, tree-stamp.sh (review-changes) and landing.sh
# (handoff), are found the way the hook finds them: from this script's own
# resolved path, `<owner>/scripts/` two levels up from its directory, with no
# second place to look. Run through the installed link
# ~/.claude/skills/committing/ (ADR-0108), that is the owner's one copy
# beside it, which a symlinked install resolves into the checkout; so this
# script and the hook in the same checkout read the same two files, and a
# missing one exits 4 here as it holds the push there.
#
# Why a script: the order was prose in implement, feedback-loops, handoff and
# scripts/README.md, and agents retyped the second command of fixed pairs
# 24 of 50 times (2026-10-12 round, Batch 10).
#
# Exit: 0 printed · 3 usage error · 4 never ran (not inside a git work tree,
# or tree-stamp.sh or landing.sh missing or failing).
set -uo pipefail
unset CDPATH   # an exported CDPATH makes `cd` print the path into the captured value

usage() {
  sed -n '8p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed; 3 usage; 4 never ran (no repo, or tree-stamp.sh or landing.sh failed)."
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) echo "next-step.sh: unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "next-step.sh: not inside a git work tree" >&2; exit 4; }
# the two scripts, from this script's own resolved path, as the hook resolves its
# own (header): <owner>/scripts/ beside committing/ here
here_real="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
stamp="$here_real/../../review-changes/scripts/tree-stamp.sh"
landing="$here_real/../../handoff/scripts/landing.sh"
[ -f "$stamp" ] || { echo "next-step.sh: stamp script not found at $stamp" >&2; exit 4; }
[ -f "$landing" ] || { echo "next-step.sh: landing.sh not found at $landing" >&2; exit 4; }

# unfenced <file>: the file outside its fences, by tree-stamp.sh's one fence rule
unfenced() { bash "$stamp" --unfenced "$1" 2>/dev/null; }
top_phys="$(cd "$top" && pwd -P)"

ROUND='^[-* >]*\**`?Deferrals register:`?\**[[:space:]]*[^[:space:]]'
# both keys from the repo top's CLAUDE.md alone, never a subdirectory's: the
# `Landing:` and `## Round` blocks are the repo's (header)
required="" round=""
if [ -f "$top_phys/CLAUDE.md" ]; then
  bash "$stamp" --review-required "$top_phys/CLAUDE.md" 2>/dev/null && required=1
  round="$(unfenced "$top_phys/CLAUDE.md" | grep -iE "$ROUND" | head -1)"
fi

# untracked files counted whatever status.showUntrackedFiles says, as the stamp
# counts them; read NUL-separated, so a rename names its new path and a path
# git would C-quote prints as it is
paths=()
skip_from=""
while IFS= read -r -d '' e; do
  if [ -n "$skip_from" ]; then skip_from=""; continue; fi   # a rename's or copy's source path
  case "${e:0:2}" in R?|?R|C?|?C) skip_from=1 ;; esac
  paths+=("${e:3}")
done < <(git -C "$top" status --porcelain -z --untracked-files=normal 2>/dev/null)
dirty="${#paths[@]}"
tree="$(cd "$top" && bash "$stamp")" || { echo "next-step.sh: tree-stamp.sh failed" >&2; exit 4; }
head_tree="$(git -C "$top" rev-parse --verify -q 'HEAD^{tree}' 2>/dev/null || true)"
treeline="${tree:0:12}, $dirty dirty path(s)"
[ "$dirty" -gt 0 ] || treeline="${tree:0:12}, clean"

branch="$(git -C "$top" symbolic-ref --short -q HEAD 2>/dev/null || true)"
remotes="$(git -C "$top" remote 2>/dev/null || true)"
remote="$(printf '%s\n' "$remotes" | grep -qx origin && echo origin || printf '%s\n' "$remotes" | head -1)"
up="$(git -C "$top" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || up=""
ahead="?" behind=0 up_tree=""
if [ -n "$up" ]; then
  lr="$(git -C "$top" rev-list --left-right --count "$up...HEAD" 2>/dev/null)" || lr=""
  if [ -n "$lr" ]; then behind="${lr%%[[:space:]]*}" ahead="${lr##*[[:space:]]}"; fi
  up_tree="$(git -C "$top" rev-parse --verify -q "$up^{tree}" 2>/dev/null || true)"
  aheadline="$ahead of $up"
  [ "$behind" -gt 0 ] && aheadline="$aheadline, $behind behind"
elif [ -z "$remotes" ]; then aheadline="? (no remote)"
elif [ -z "$branch" ]; then aheadline="? (detached HEAD)"
else aheadline="? (no upstream)"; fi

# push_act: the push itself, as the remote and the upstream allow it
push_act() {
  if [ -n "$up" ]; then
    if [ "$behind" -gt 0 ]; then echo "pull first: $up has $behind commit(s) HEAD lacks (git pull --rebase), then push"
    else echo "push"; fi
  elif [ -z "$remotes" ]; then echo "none (no remote)"
  elif [ -z "$branch" ]; then echo "none until HEAD is on a branch: it is detached (git switch -c <name>)"
  else echo "git push -u $remote $branch"; fi
}

# --- the receipt: every report for this repo, as the hook finds them ---------
repo="$(basename "$top")"
# a zone landing.sh refuses exits 4 there, its reason on stderr above this line
list="$(bash "$landing" list --kind review --repo "$repo")" || { echo "next-step.sh: landing.sh list failed (exit $?)" >&2; exit 4; }
reports=0 stamped_by="" head_by="" newest="" newest_stamps=""
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  if [ ! -r "$f" ]; then echo "next-step.sh: skipping unreadable report $f" >&2; continue; fi
  found="$(bash "$stamp" --reviewed-trees "$f" 2>/dev/null)"
  rc=$?
  case $rc in
    0|2) ;;
    4) echo "next-step.sh: skipping report tree-stamp.sh --reviewed-trees could not read (exit 4): $f" >&2; continue ;;   # as the hook skips it
    *) echo "next-step.sh: tree-stamp.sh --reviewed-trees failed on $f (exit $rc)" >&2; exit 4 ;;
  esac
  reports=$((reports + 1))
  if [ -n "$tree" ] && [ -z "$stamped_by" ] && printf '%s\n' "$found" | grep -qx "$tree"; then
    stamped_by="$f"
  fi
  if [ -n "$head_tree" ] && [ -z "$head_by" ] && printf '%s\n' "$found" | grep -qx "$head_tree"; then
    head_by="$f"
  fi
  if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f" newest_stamps="$found"; fi
done <<< "$list"
left_out=""
[ "$dirty" -gt 0 ] && left_out="${paths[*]:0:5}"
[ "$dirty" -gt 5 ] && left_out="$left_out and $((dirty - 5)) more"
if [ -n "$stamped_by" ]; then
  receiptline="stamped by $stamped_by"
elif [ -n "$head_by" ]; then
  receiptline="HEAD's tree stamped by $head_by, not the $dirty uncommitted path(s)"
else
  receiptline="none of $reports report(s) stamps it"
fi

# addressable <report>: the report holds this branch's unaddressed findings —
# an `F<n>` line, and a Reviewed-head that is HEAD, or an ancestor of HEAD that
# is the upstream tip or that the upstream has not reached (header above)
addressable() {
  local body h hc head_c up_c
  body="$(unfenced "$1")"
  printf '%s\n' "$body" | grep -qE '^[[:space:]#>*|-]*F[0-9]+([^0-9A-Za-z_]|$)' || return 1
  h="$(printf '%s\n' "$body" | sed -n -E 's/^Reviewed-head: ([0-9a-f]{4,40})[[:space:]]*$/\1/p' | head -1)"
  [ -n "$h" ] || return 1
  hc="$(git -C "$top" rev-parse --verify -q "$h^{commit}" 2>/dev/null)" || return 1
  head_c="$(git -C "$top" rev-parse --verify -q HEAD 2>/dev/null)" || return 1
  [ "$hc" = "$head_c" ] && return 0
  git -C "$top" merge-base --is-ancestor "$hc" "$head_c" 2>/dev/null || return 1
  [ -n "$up" ] || return 0
  up_c="$(git -C "$top" rev-parse --verify -q "$up^{commit}" 2>/dev/null)" || return 0
  [ "$hc" = "$up_c" ] && return 0
  ! git -C "$top" merge-base --is-ancestor "$hc" "$up_c" 2>/dev/null
}

# --- the order and the next act -----------------------------------------------
if [ -z "$required" ]; then
  reviewline="not required"
  order="commit, then push"
  if [ "$dirty" -gt 0 ]; then next="commit (or /ship for a split or a PR)"
  elif [ "$ahead" = 0 ]; then next="none, nothing to land"
  else next="$(push_act)"; fi
else
  reviewline="required"
  if [ -n "$round" ]; then
    order="commit at the end of every batch, then one /review-changes and /address-findings over everything unpushed, then push; the last Reviewed-tree must equal the tree pushed, so an edit after it needs a fresh stamp (a round is running)"
  else
    order="commit when you like, then one /review-changes and /address-findings over everything unpushed, then push; the last Reviewed-tree must equal the tree pushed, so an edit after it needs a fresh stamp"
  fi
  n_stamps="$(printf '%s' "$newest_stamps" | grep -c . || true)"
  if [ -n "$stamped_by" ]; then
    if [ "$dirty" -gt 0 ]; then next="commit the whole tree, then $(push_act)"
    elif [ "$ahead" = 0 ]; then next="none, nothing to land"
    else next="$(push_act)"; fi
  elif [ -n "$head_by" ] && [ "$ahead" != 0 ]; then
    next="$(push_act); it sends the stamped commits, not the uncommitted path(s), which need their own review: $left_out"
  elif [ "$dirty" -eq 0 ] && [ "$ahead" = 0 ]; then
    next="none, nothing to land"
  elif [ -n "$newest" ] && [ "$n_stamps" -eq 1 ] && [ "$newest_stamps" != "$up_tree" ] && addressable "$newest"; then
    next="/address-findings $newest"
  elif [ "$dirty" -gt 0 ] && [ -n "$round" ]; then
    next="commit this batch"
  elif [ -n "$round" ]; then
    next="the next batch, or /review-changes over everything unpushed before the push"
  elif [ "$dirty" -gt 0 ]; then
    next="commit when you like; /review-changes before the push"
  else
    next="/review-changes"
  fi
fi

printf 'review: %s\ntree: %s\nreceipt: %s\nahead: %s\norder: %s\nnext: %s\n' \
  "$reviewline" "$treeline" "$receiptline" "$aheadline" "$order" "$next"
