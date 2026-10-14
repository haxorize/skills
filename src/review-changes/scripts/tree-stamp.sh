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
# One reader, read_stamps below, finds the stamp lines for --stamps and
# --verify alike, and the review-receipt hook reads a report through --stamps,
# accepting only the `Reviewed-tree` lines, so there is no second parser. A
# stamp line is the label (`Reviewed-tree:` or `Measured-tree:`), a list
# marker, bold or backticks allowed around it, the hash, nothing after it. A
# line inside a fenced block (a fence is a line starting, after optional
# whitespace, with ``` or ~~~, and closes only on the marker that opened it)
# is a quotation, never a stamp, and one behind
# `>` fails the pattern's start. Any stamp in the report matching passes
# --verify, since a fix pass appends one per stamping.
#
# Exit: 0 stamp printed, --verify matched, or --stamps found a stamp · 1
# --verify found stamps and none matched · 2 --verify or --stamps found no
# stamp line in the report · 3 usage error (bad flag, missing --verify report,
# unknown rev, --stamps with another flag) · 4 not inside a git work tree, no
# usable temp directory, or a report the reader could not read.
set -uo pipefail

usage() {
  sed -n '9,16p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed, matched, or stamps listed; 1 no stamp matched; 2 no stamp line;"
  echo "3 usage; 4 never ran (no repo, no temp directory, or an unreadable report)."
}

# The one stamp-line reader (header: "One reader"). Prints `<label> <hash>`
# per stamp outside a fence and returns awk's status.
read_stamps() {
  awk '
    match($0, /^[[:space:]]*(```|~~~)/) {
      marker = substr($0, RSTART + RLENGTH - 3, 3)
      if (fence == "") { fence = marker; next }
      if (marker == fence) { fence = ""; next }
    }
    fence != "" { next }
    /^[-*]*[[:space:]]*\**`?(Reviewed|Measured)-tree:`?\**[[:space:]]*`?[0-9a-f]{40}`?[[:space:]]*$/ {
      label = ($0 ~ /Reviewed-tree:/) ? "Reviewed-tree" : "Measured-tree"
      if (match($0, /[0-9a-f]{40}/)) print label " " substr($0, RSTART, RLENGTH)
    }
  ' "$1"
}

committed=""
report=""
stamps_of=""
while [ $# -gt 0 ]; do
  case "$1" in
    --committed)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: --committed needs a revision" >&2; exit 3; }
      committed="$2"; shift 2 ;;
    --verify)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: --verify needs a report path" >&2; exit 3; }
      report="$2"; shift 2 ;;
    --stamps)
      [ $# -ge 2 ] || { echo "tree-stamp.sh: --stamps needs a report path" >&2; exit 3; }
      stamps_of="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "tree-stamp.sh: unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done

if [ -n "$stamps_of" ]; then
  if [ -n "$report" ] || [ -n "$committed" ]; then
    echo "tree-stamp.sh: --stamps takes no other flag" >&2
    exit 3
  fi
  if [ ! -f "$stamps_of" ] || [ ! -r "$stamps_of" ]; then
    echo "tree-stamp.sh: cannot read report $stamps_of — no stamps read" >&2
    exit 4
  fi
  if ! found="$(read_stamps "$stamps_of")"; then
    echo "tree-stamp.sh: awk failed reading $stamps_of — no stamps read" >&2
    exit 4
  fi
  if [ -z "$found" ]; then
    echo "tree-stamp.sh: no Reviewed-tree: or Measured-tree: line in $stamps_of" >&2
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
