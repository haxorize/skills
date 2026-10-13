#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# landing.sh — print the landing zone `handoff` § Where to write it defines, a
# path in it, or the newest file of a kind there. The filename contract and the
# kinds are references/landing-zone.md beside this directory; this file is how
# the paths are built, so the lookup lives once instead of in every pickup.
#
#   landing.sh dir                         the landing zone, created
#   landing.sh path <slug> [--kind <k>]    <zone>/<repo>-<date>-<slug>[.<k>].md
#   landing.sh latest [--kind <k>]         the newest such file for this repo
#   --kind   review | audit; none means a handoff (no kind segment)
#   --repo <name>   the <repo> segment, for a run outside a git work tree
#
# The zone is `claude-handoffs/` under $TMPDIR, else /tmp, created (`mkdir -p`)
# on every subcommand and printed as `cd … && pwd` resolves it. <repo> is the basename of
# `git rev-parse --show-toplevel`; the audit kind takes the fixed word `skills`.
# <date> is today, YYYY-MM-DD. `latest` picks by modification time among
# `<repo>-YYYY-MM-DD-<slug>.md` files: with no --kind, only a slug with no `.`
# counts (a handoff is the kind with no kind segment); with --kind, only
# `.<kind>.md` files. A questionnaire and a design-review report share the
# shape but land elsewhere, so they are not kinds here.
#
# Why a script: agents built these paths by hand about 456 times and ran
# `echo $TMPDIR` 192 times in 16 days (2026-10-12 round, TE-3), and once wrote
# to /private/tmp. The review-receipt hook resolves the zone in its own code
# (TMPDIR, else /tmp); its selftest builds its report path with this script,
# which is what pins the two equal.
#
# Exit: 0 printed · 2 `latest` found no file of that kind · 3 usage error (bad
# subcommand or flag, a slug with `/` or `.`, an unknown kind, no repo and no
# --repo) · 4 the zone could not be created.
set -uo pipefail

usage() {
  sed -n '8,12p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed; 2 latest found none; 3 usage; 4 the zone could not be created."
}
die_usage() { echo "landing.sh: $1" >&2; usage >&2; exit 3; }

[ $# -ge 1 ] || die_usage "a subcommand is required"
case "$1" in
  -h|--help) usage; exit 0 ;;
  dir|path|latest) cmd="$1"; shift ;;
  *) die_usage "unknown subcommand '$1'" ;;
esac

slug="" kind="" repo=""
if [ "$cmd" = path ]; then
  [ $# -ge 1 ] && [ "${1#-}" = "$1" ] || die_usage "path needs a <slug>"
  slug="$1"; shift
  case "$slug" in */*|*.*|"") die_usage "a slug carries no '/' or '.': '$slug'" ;; esac
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) [ $# -ge 2 ] || die_usage "--kind needs a value"; kind="$2"; shift 2 ;;
    --repo) [ $# -ge 2 ] || die_usage "--repo needs a value"; repo="$2"; shift 2 ;;
    *) die_usage "unknown argument '$1'" ;;
  esac
done
[ "$cmd" = dir ] && [ -n "$kind$repo" ] && die_usage "dir takes no flags"
case "$kind" in ""|review|audit) ;; *) die_usage "unknown kind '$kind' (review, audit, or none for a handoff)" ;; esac

base="${TMPDIR:-/tmp}"
zone="${base%/}/claude-handoffs"
if ! mkdir -p "$zone" 2>/dev/null || ! zone="$(cd "$zone" 2>/dev/null && pwd)"; then
  echo "landing.sh: cannot create the landing zone ${base%/}/claude-handoffs (TMPDIR=${TMPDIR:-unset})" >&2
  exit 4
fi
[ "$cmd" = dir ] && { printf '%s\n' "$zone"; exit 0; }

if [ "$kind" = audit ]; then
  repo="skills"
elif [ -z "$repo" ]; then
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || die_usage "not inside a git work tree; pass --repo <name>"
  repo="$(basename "$top")"
fi
suffix=".md"
[ -n "$kind" ] && suffix=".$kind.md"

if [ "$cmd" = path ]; then
  printf '%s/%s-%s-%s%s\n' "$zone" "$repo" "$(date +%Y-%m-%d)" "$slug" "$suffix"
  exit 0
fi

best=""
for f in "$zone/$repo"-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*"$suffix"; do
  [ -f "$f" ] || continue
  name="${f##*/}"
  rest="${name#"$repo"-????-??-??-}"
  rest="${rest%"$suffix"}"
  case "$rest" in ""|*.*) continue ;; esac
  if [ -z "$best" ] || [ "$f" -nt "$best" ]; then best="$f"; fi
done
if [ -z "$best" ]; then
  echo "landing.sh: no ${kind:-handoff} file for $repo in $zone" >&2
  exit 2
fi
printf '%s\n' "$best"
