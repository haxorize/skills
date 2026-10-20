#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# tree-stamp.sh — print, or check, the 40-hex tree stamp a review report
# (`Reviewed-tree:`) or a measured report (`Measured-tree:`) carries. The stamp
# contract is references/tree-stamp.md beside this directory; this file is how
# the stamp is taken, so the command lives once instead of in every skill that
# names it.
#
#   tree-stamp.sh                      the working tree's stamp
#   tree-stamp.sh --committed <rev>    <rev>'s tree (`git rev-parse <rev>^{tree}`)
#   tree-stamp.sh --verify <report> [--committed <rev>]
#                                      does any stamp line in <report> equal the
#                                      tree now (or <rev>'s tree)?
#   tree-stamp.sh --stamps <report>    every stamp line in <report>, one per line
#                                      as `Reviewed-tree <hash>` or
#                                      `Measured-tree <hash>`; needs no repo
#   tree-stamp.sh --reviewed-trees <report>
#                                      the hash of each `Reviewed-tree` stamp
#                                      alone, one per line; needs no repo
#   tree-stamp.sh --review-required <CLAUDE.md>
#                                      exit 0 when its opt-in line says yes,
#                                      1 when it says no or there is none
#   tree-stamp.sh --unfenced <file>    <file> with its fenced blocks dropped
#
# Run from anywhere inside the repo; it stamps the repo root. The working-tree
# stamp seeds a throwaway index from HEAD and adds everything, so uncommitted
# and untracked non-ignored files count and a tracked-but-ignored file still
# counts. The real index and every open file are untouched; the run adds
# unreachable blobs and one tree to the object store, which `git gc` collects.
#
# Why a script and not the one-line command the skills used to inline: agents
# retyped that command about 230 to 293 times in 16 days from six copies
# nothing kept in sync, and the work machine's sandbox refuses every construct
# in it (`$(...)`, `&&`, `;`, `VAR=... cmd`). Why the skills still name it in
# their bodies rather than only in the reference: the plausible wrong answer,
# `git rev-parse HEAD^{tree}`, arrives faster than a lookup (ADR-0075, the
# 2026-08-30 fix-pass entry, which this replaces as the reason's home).
# ADR-0075 is a frozen round record (ADR-0107), so its "the stamp one-liner is
# inline in the rule" line and its pointer to the address-findings sibling are
# historical and stay unedited; this header is where the reason now lives.
#
# One reader, read_stamps below, finds the stamp lines for --stamps,
# --reviewed-trees and --verify alike, and the review-receipt hook reads a
# report through --reviewed-trees, which keeps only the `Reviewed-tree` lines,
# so there is no second parser. A
# stamp line is the label (`Reviewed-tree:` or `Measured-tree:`), a list
# marker, bold or backticks allowed around it, the hash, nothing after it. A
# line inside a fenced block (a fence opens on a line starting, after optional
# whitespace, with a run of three or more ` or ~, and closes only on a run of
# the same character at least as long, as CommonMark has it) is a quotation,
# never a stamp, and one behind
# `>` fails the pattern's start. Any stamp in the report matching passes
# --verify, since a fix pass appends one per stamping.
#
# The fence rule (FENCE_AWK) and the `Review required:` opt-in pattern
# (OPT_IN) live here alone. global/hooks/review-receipt.sh and
# src/committing/scripts/next-step.sh read a CLAUDE.md's opt-in through
# --review-required, a file outside its fences through --unfenced, and a
# report's receipts through --reviewed-trees, so the push gate and the
# script that predicts it hold no copy of either rule to drift. lint-skills.sh's
# FENCE_AWK is a different, older rule (any ``` toggles; ~~~ is not a fence)
# over skill bodies, and does not read through here.
#
# Exit: 0 stamp printed, --verify matched, a read mode found what it reads, or
# --review-required read yes · 1 --verify found stamps and none matched, or
# --review-required read no or no opt-in line · 2 --verify, --stamps or
# --reviewed-trees found no such stamp line in the report · 3 usage error (bad
# flag, missing --verify report, unknown rev, a read mode with another flag) ·
# 4 not inside a git work tree, no usable temp directory, or a file the reader
# could not read.
set -uo pipefail

usage() {
  sed -n '9,24p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed, matched, read, or opted in; 1 no stamp matched, or not opted in;"
  echo "2 no stamp line; 3 usage; 4 never ran (no repo, no temp directory, or an unreadable file)."
}

# The one fence rule (header): prepend to an awk program, and every line
# inside a fence is skipped before the program sees it.
FENCE_AWK='
    match($0, /^[[:space:]]*(```+|~~~+)/) {
      run = substr($0, RSTART, RLENGTH); sub(/^[[:space:]]*/, "", run)
      if (fence == "") { fence = run; next }
      if (substr(run, 1, 1) == substr(fence, 1, 1) && length(run) >= length(fence)) { fence = ""; next }
    }
    fence != "" { next }
'
# The one opt-in pattern (header), matched case-blind against unfenced lines;
# `yes (…)` fails it, and the first matching line decides.
OPT_IN='^[-* >]*\**`?Review required:`?\**[[:space:]]*\**`?(yes|no)`?\**[[:space:]]*$'

# The one stamp-line reader (header: "One reader"). Prints `<label> <hash>`
# per stamp outside a fence and returns awk's status.
read_stamps() {
  awk "$FENCE_AWK"'
    /^[-*]*[[:space:]]*\**`?(Reviewed|Measured)-tree:`?\**[[:space:]]*`?[0-9a-f]{40}`?[[:space:]]*$/ {
      label = ($0 ~ /Reviewed-tree:/) ? "Reviewed-tree" : "Measured-tree"
      if (match($0, /[0-9a-f]{40}/)) print label " " substr($0, RSTART, RLENGTH)
    }
  ' "$1"
}

committed=""
report=""
read_mode=""
read_path=""
while [ $# -gt 0 ]; do
  case "$1" in
    --committed)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: --committed needs a revision" >&2; exit 3; }
      committed="$2"; shift 2 ;;
    --verify)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: --verify needs a report path" >&2; exit 3; }
      report="$2"; shift 2 ;;
    --stamps|--reviewed-trees|--review-required|--unfenced)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: $1 needs a file path" >&2; exit 3; }
      [ -z "$read_mode" ] || { echo "tree-stamp.sh: $read_mode and $1 are two read modes; give one" >&2; exit 3; }
      read_mode="$1" read_path="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "tree-stamp.sh: unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done

if [ -n "$read_mode" ]; then
  if [ -n "$report" ] || [ -n "$committed" ]; then
    echo "tree-stamp.sh: $read_mode takes no other flag" >&2
    exit 3
  fi
  if [ ! -f "$read_path" ] || [ ! -r "$read_path" ]; then
    echo "tree-stamp.sh: cannot read $read_path — nothing read" >&2
    exit 4
  fi
  case "$read_mode" in
    --unfenced)
      awk "$FENCE_AWK"'{ print }' "$read_path" \
        || { echo "tree-stamp.sh: awk failed reading $read_path — nothing read" >&2; exit 4; }
      exit 0 ;;
    --review-required)
      if ! body="$(awk "$FENCE_AWK"'{ print }' "$read_path")"; then
        echo "tree-stamp.sh: awk failed reading $read_path — opt-in not read" >&2
        exit 4
      fi
      line="$(printf '%s\n' "$body" | grep -iE "$OPT_IN" | head -1; exit "${PIPESTATUS[1]}")"
      grc=$?
      if [ "$grc" -gt 1 ]; then
        echo "tree-stamp.sh: grep failed scanning $read_path (rc=$grc) — opt-in not read" >&2
        exit 4
      fi
      printf '%s\n' "$line" | grep -qi 'yes' && exit 0
      exit 1 ;;
  esac
  if ! found="$(read_stamps "$read_path")"; then
    echo "tree-stamp.sh: awk failed reading $read_path — no stamps read" >&2
    exit 4
  fi
  if [ "$read_mode" = --reviewed-trees ]; then
    found="$(printf '%s\n' "$found" | sed -n 's/^Reviewed-tree //p')"
    if [ -z "$found" ]; then
      echo "tree-stamp.sh: no Reviewed-tree: line in $read_path" >&2
      exit 2
    fi
  elif [ -z "$found" ]; then
    echo "tree-stamp.sh: no Reviewed-tree: or Measured-tree: line in $read_path" >&2
    exit 2
  fi
  printf '%s\n' "$found"
  exit 0
fi

if [ -n "$report" ] && [ ! -f "$report" ]; then
  echo "tree-stamp.sh: no report at $report" >&2
  exit 3
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)" || root=""
if [ -z "$root" ]; then
  echo "tree-stamp.sh: not inside a git work tree — nothing stamped" >&2
  exit 4
fi

if [ -n "$committed" ]; then
  if ! tree="$(git -C "$root" rev-parse --verify --quiet "${committed}^{tree}")"; then
    echo "tree-stamp.sh: no tree for revision: $committed" >&2
    exit 3
  fi
else
  # Temp-file template: scripts/README.md § Temp files. A directory, not a
  # file: git refuses an empty file as an index, so the index path must not
  # exist until read-tree writes it. A relative TMPDIR is made absolute
  # against the caller's directory first, since git -C resolves a relative
  # GIT_INDEX_FILE against the repo root instead.
  case "${TMPDIR:-}" in
    ""|/*) ;;
    *) TMPDIR="$PWD/$TMPDIR" ;;
  esac
  if ! tmp="$(mktemp -d "${TMPDIR:-/tmp}/tree-stamp.XXXXXX")" || [ ! -d "$tmp" ]; then
    echo "tree-stamp.sh: mktemp -d \"\${TMPDIR:-/tmp}/tree-stamp.XXXXXX\" gave no directory (TMPDIR=${TMPDIR:-unset}) — nothing stamped" >&2
    exit 4
  fi
  trap 'rm -rf "$tmp"' EXIT
  idx="$tmp/index"
  # read-tree fails only where HEAD does not exist yet (an unborn branch);
  # the empty index it leaves stamps every file as new, which is the tree.
  GIT_INDEX_FILE="$idx" git -C "$root" read-tree HEAD 2>/dev/null
  if ! GIT_INDEX_FILE="$idx" git -C "$root" add -A :/ \
     || ! tree="$(GIT_INDEX_FILE="$idx" git -C "$root" write-tree)"; then
    echo "tree-stamp.sh: git add or write-tree failed — nothing stamped" >&2
    exit 4
  fi
fi

if [ -z "$report" ]; then
  printf '%s\n' "$tree"
  exit 0
fi

if ! stamps="$(read_stamps "$report")"; then
  echo "tree-stamp.sh: awk failed reading $report — nothing compared" >&2
  exit 4
fi
stamps="$(sed 's/^[A-Za-z-]* //' <<< "$stamps")"

if [ -z "$stamps" ]; then
  echo "tree-stamp.sh: no Reviewed-tree: or Measured-tree: line in $report — nothing to compare (tree now: $tree)"
  exit 2
fi
if grep -qxF -- "$tree" <<< "$stamps"; then
  echo "tree-stamp.sh: MATCH $tree"
  exit 0
fi
echo "tree-stamp.sh: NO MATCH tree now $tree; the report's last stamp is $(tail -n 1 <<< "$stamps")"
exit 1
