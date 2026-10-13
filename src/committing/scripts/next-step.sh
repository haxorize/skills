#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# next-step.sh — print the landing order this repo's `Landing:` key sets, and
# the one next act for the tree as it stands: commit, review, fix pass, or
# push. Every orchestrator's close ends on its `next:` line, so the order lives
# here once instead of in four skill bodies that drifted apart.
#
#   next-step.sh                 the order and the next act, from the repo here
#   next-step.sh --mid-family    this close does not end a `## Round` batch
#                                family, so under a `Review cadence:` line the
#                                next act is the batch's commit, not a review
#
# Output, one `key: value` per line, `next:` always last:
#   review:  required | not required   (the `Review required:` line)
#   tree:    <12-hex>, <n> dirty path(s) | <12-hex>, clean
#   receipt: stamped by <report> | none of <n> report(s) stamps it
#   ahead:   <n> of <upstream> | ? (no upstream)
#   order:   the whole landing order for this repo
#   next:    the one act, a literal `/command <args>` where one exists
#
# It reads what the review-receipt hook reads, by the same means, so it cannot
# say "push" where the hook blocks: the nearest CLAUDE.md carrying a
# `Review required:` line, walking from here up to the repo top (the hook's
# pattern, copied with its anchors); the `<repo>-YYYY-*.review.md` reports in
# $REVIEW_RECEIPT_DIR, else `claude-handoffs/` under $TMPDIR and /tmp (the
# hook's zones); and their `Reviewed-tree` lines through tree-stamp.sh
# --stamps, the one stamp reader. The tree compared is the working-tree
# stamp: HEAD's tree when the tree is clean, and the tree a commit of the
# whole tree reproduces when it is not. Where nothing stamps it and the newest report carries one
# stamp, not the tree of the upstream tip, that report's findings are taken as
# unaddressed and the next act is `/address-findings <it>`; a second stamp is
# the fix pass's, so an edit after it is a new review.
#
# Why a script: the order was prose in implement, feedback-loops, handoff and
# address-findings, and agents retyped the second command of fixed pairs
# 24 of 50 times (2026-10-12 round, Batch 10).
#
# Exit: 0 printed · 3 usage error · 4 never ran (not inside a git work tree,
# or the stamp script missing or failing).
set -uo pipefail

usage() {
  sed -n '8,11p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed; 3 usage; 4 never ran (no repo, or the stamp script failed)."
}

mid=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mid-family) mid=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "next-step.sh: unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "next-step.sh: not inside a git work tree" >&2; exit 4; }
here_real="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
stamp="$here_real/../../review-changes/scripts/tree-stamp.sh"
[ -f "$stamp" ] || { echo "next-step.sh: stamp script not found at $stamp" >&2; exit 4; }

# unfenced <file>: the file without its ``` blocks, as the hook scans it
unfenced() { awk '/^[[:space:]]*```/ { fence = !fence; next } fence { next } { print }' "$1" 2>/dev/null; }

OPT_IN='^[-* >]*\**`?Review required:`?\**[[:space:]]*\**`?(yes|no)`?\**[[:space:]]*$'
required=""
dir="$(pwd -P)"
top_phys="$(cd "$top" && pwd -P)"
while :; do
  if [ -f "$dir/CLAUDE.md" ]; then
    line="$(unfenced "$dir/CLAUDE.md" | grep -iE "$OPT_IN" | head -1)"
    if [ -n "$line" ]; then
      printf '%s\n' "$line" | grep -qi 'yes' && required=1
      break
    fi
  fi
  { [ "$dir" = "$top_phys" ] || [ "$dir" = "/" ]; } && break
  dir="$(dirname "$dir")"
done
cadence=""
[ -f "$top/CLAUDE.md" ] && cadence="$(unfenced "$top/CLAUDE.md" | sed -n 's/^[-* ]*Review cadence:[[:space:]]*//p' | head -1)"

dirty="$(git -C "$top" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
tree="$(cd "$top" && bash "$stamp")" || { echo "next-step.sh: tree-stamp.sh failed" >&2; exit 4; }
treeline="${tree:0:12}, $dirty dirty path(s)"
[ "$dirty" -gt 0 ] || treeline="${tree:0:12}, clean"

up="$(git -C "$top" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || up=""
if [ -n "$up" ]; then
  ahead="$(git -C "$top" rev-list --count "$up..HEAD" 2>/dev/null || echo '?')"
  up_tree="$(git -C "$top" rev-parse --verify -q "$up^{tree}" 2>/dev/null || true)"
  aheadline="$ahead of $up"
else
  ahead="?" up_tree="" aheadline="? (no upstream)"
fi

# --- the receipt: every report for this repo, as the hook finds them ---------
repo="$(basename "$top")"
zones=()
if [ -n "${REVIEW_RECEIPT_DIR:-}" ]; then
  zones=("$REVIEW_RECEIPT_DIR")
else
  [ -n "${TMPDIR:-}" ] && zones+=("${TMPDIR%/}/claude-handoffs")
  [ "${zones[0]:-}" = "/tmp/claude-handoffs" ] || zones+=("/tmp/claude-handoffs")
fi
reports=0 stamped_by="" newest="" newest_stamps=""
for zone in "${zones[@]}"; do
  [ -d "$zone" ] || continue
  for f in "$zone"/"$repo"-[0-9][0-9][0-9][0-9]-*.review.md; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    found="$(bash "$stamp" --stamps "$f" 2>/dev/null)"
    case $? in
      0|2) ;;
      *) continue ;;
    esac
    found="$(printf '%s\n' "$found" | sed -n 's/^Reviewed-tree \([0-9a-f]\{40\}\)$/\1/p')"
    reports=$((reports + 1))
    if [ -n "$tree" ] && [ -z "$stamped_by" ] && printf '%s\n' "$found" | grep -qx "$tree"; then
      stamped_by="$f"
    fi
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f" newest_stamps="$found"; fi
  done
done
if [ -n "$stamped_by" ]; then
  receiptline="stamped by $stamped_by"
else
  receiptline="none of $reports report(s) stamps it"
fi

# --- the order and the next act -----------------------------------------------
if [ -z "$required" ]; then
  reviewline="not required"
  order="commit, then push"
  if [ "$dirty" -gt 0 ]; then next="commit (or /ship for a split or a PR)"
  elif [ "$ahead" = 0 ]; then next="none, nothing to land"
  else next="push"; fi
else
  reviewline="required"
  order="commit when you like, then /review-changes and /address-findings, then push; the last Reviewed-tree must equal the tree pushed, so an edit after it needs a fresh stamp"
  [ -n "$cadence" ] && order="$order (Review cadence: $cadence)"
  n_stamps="$(printf '%s' "$newest_stamps" | grep -c . || true)"
  if [ -n "$mid" ] && [ -n "$cadence" ]; then
    if [ "$dirty" -gt 0 ]; then next="commit this batch"; else next="the next batch; the cadence reviews at the family's end"; fi
  elif [ -n "$stamped_by" ]; then
    if [ "$dirty" -gt 0 ]; then next="commit the whole tree, then push"
    elif [ "$ahead" = 0 ]; then next="none, nothing to land"
    else next="push"; fi
  elif [ "$dirty" -eq 0 ] && [ "$ahead" = 0 ]; then
    next="none, nothing to land"
  elif [ -n "$newest" ] && [ "$n_stamps" -eq 1 ] && [ "$newest_stamps" != "$up_tree" ]; then
    next="/address-findings $newest"
  elif [ "$dirty" -gt 0 ]; then
    next="commit when you like; /review-changes before the push"
  else
    next="/review-changes"
  fi
fi

printf 'review: %s\ntree: %s\nreceipt: %s\nahead: %s\norder: %s\nnext: %s\n' \
  "$reviewline" "$treeline" "$receiptline" "$aheadline" "$order" "$next"
