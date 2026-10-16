#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# landing.sh — print the landing zone `handoff` § Where to write it defines, a
# path in it, the files of a kind there, or the zones they are searched in. The
# filename contract and the kinds are references/landing-zone.md beside this
# directory; this file is how the paths are built and found, so the lookup
# lives once instead of in every pickup and every reader.
#
#   landing.sh dir                         the landing zone, created
#   landing.sh path <slug> [--kind <k>]    <zone>/<repo>-<date>-<slug>[.<k>].md
#   landing.sh latest [--kind <k>]         the newest such file for this repo
#   landing.sh list [--kind <k>]           every such file for this repo
#   landing.sh zones                       the zone searched (none if not private)
#   --kind   review | audit; none means a handoff (no kind segment)
#   --repo <name>   the <repo> segment, for a run outside a git work tree
#
# The zone, one of three: $REVIEW_RECEIPT_DIR when it is set; else
# `claude-handoffs/` under $TMPDIR when that is set; else /tmp/claude-handoffs.
# A shared /tmp is never searched beside a private $TMPDIR. A zone counts only
# when it is owned by `id -u` and neither group- nor world-writable, and a
# report only on the same terms: anyone else's file in a shared temp dir would
# otherwise be read as this user's review, and its `next:` line become the
# agent's next command. `zones` prints the zone as written, unless it exists
# and fails that check (a note on stderr, nothing printed), and creates
# nothing. The landing zone is that zone: `dir`, `path` and `latest` create it
# (`mkdir -m 700`; an existing zone's mode is left alone), refuse one that
# fails the check, and print it as `cd … && pwd` resolves it. `list` creates
# nothing and refuses a zone that exists and fails the check, exiting 4 as the
# others do, so a reader cannot take a refused zone for an empty one. `latest`
# and `list` search the zone, print each file under it resolved the same way,
# and skip a file that fails the check. <repo> is the
# basename of `git rev-parse --show-toplevel`; the audit kind takes the fixed
# word `skills`, so `--kind audit` with `--repo` is a usage error. <date> is
# today, YYYY-MM-DD. A file of a kind is `<repo>-YYYY-MM-DD-<slug>` plus `.md`
# with no --kind (a handoff is the kind with no kind segment) or `.<kind>.md`
# with one, where <slug> is not empty and carries no `.`; `latest` picks the
# newest of them by modification time, `list` prints them all. A
# questionnaire and a design-review report share the shape but land
# elsewhere, so they are not kinds here.
#
# Readers: the review-receipt hook (global/hooks/) and committing's
# next-step.sh take their zones and their review reports from `zones` and
# `list --kind review`, so the push gate, the next-act advice and the writers
# cannot disagree about where a report lives or what its name looks like.
#
# Why a script: agents built these paths by hand about 456 times and ran
# `echo $TMPDIR` 192 times in 16 days (2026-10-12 round, TE-3), and once wrote
# to /private/tmp.
#
# Exit: 0 printed (`list` with no file prints nothing) · 2 `latest` found no
# file of that kind · 3 usage error (bad subcommand or flag, a slug with `/`
# or `.` or a leading `-`, an unknown kind, --repo with the audit kind, no repo
# and no --repo) · 4 the zone could not be created, or is not this user's
# alone (owned by another uid, or group- or world-writable) — for `list` too,
# whose zone it does not create; `zones` alone prints nothing and exits 0.
set -uo pipefail
unset CDPATH   # an exported CDPATH makes `cd` print the path into the captured value

usage() {
  sed -n '9,15p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 printed; 2 latest found none; 3 usage; 4 the zone could not be created, or is not this user's alone."
}
die_usage() { echo "landing.sh: $1" >&2; usage >&2; exit 3; }

[ $# -ge 1 ] || die_usage "a subcommand is required"
case "$1" in
  -h|--help) usage; exit 0 ;;
  dir|path|latest|list|zones) cmd="$1"; shift ;;
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
case "$cmd" in dir|zones) [ -n "$kind$repo" ] && die_usage "$cmd takes no flags" ;; esac
case "$kind" in ""|review|audit) ;; *) die_usage "unknown kind '$kind' (review, audit, or none for a handoff)" ;; esac
[ "$kind" = audit ] && [ -n "$repo" ] && die_usage "--kind audit takes the fixed repo word 'skills'; drop --repo"

# The zone policy, in one place: the hook, next-step.sh and the writers all read it here.
if [ -n "${REVIEW_RECEIPT_DIR:-}" ]; then zone="$REVIEW_RECEIPT_DIR"
elif [ -n "${TMPDIR:-}" ]; then zone="${TMPDIR%/}/claude-handoffs"
else zone="/tmp/claude-handoffs"; fi
uid="$(id -u)"
# private <path>: owned by this uid, the path itself and what it points to, and
# neither group- nor world-writable
private() {
  [ -n "$(find "$1" -maxdepth 0 -user "$uid" -print 2>/dev/null)" ] &&
    [ -n "$(find -H "$1" -maxdepth 0 -user "$uid" ! -perm -020 ! -perm -002 -print 2>/dev/null)" ]
}
refuse_note() { echo "landing.sh: skipping $1: not owned by uid $uid alone (another owner, or group- or world-writable)" >&2; }
if [ "$cmd" = zones ]; then
  if [ -e "$zone" ] && ! private "$zone"; then refuse_note "$zone"; exit 0; fi
  printf '%s\n' "$zone"
  exit 0
fi

if [ "$cmd" != list ]; then
  given="$zone"
  if ! { [ -d "$zone" ] || mkdir -p -m 700 "$zone" 2>/dev/null; } || ! zone="$(cd "$zone" 2>/dev/null && pwd)"; then
    echo "landing.sh: cannot create the landing zone $given (TMPDIR=${TMPDIR:-unset}, REVIEW_RECEIPT_DIR=${REVIEW_RECEIPT_DIR:-unset})" >&2
    exit 4
  fi
  if ! private "$given"; then
    echo "landing.sh: the landing zone $given is not this user's alone (owner other than uid $uid, or group- or world-writable); fix or remove it" >&2
    exit 4
  fi
  [ "$cmd" = dir ] && { printf '%s\n' "$zone"; exit 0; }
fi

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

# latest and list: every file of the shape in the zone, when it exists and is private
best=""
if [ -d "$zone" ]; then
  if ! private "$zone"; then
    echo "landing.sh: the landing zone $zone is not this user's alone (owner other than uid $uid, or group- or world-writable); fix or remove it" >&2
    exit 4
  elif zr="$(cd "$zone" 2>/dev/null && pwd)"; then
    for f in "$zr/$repo"-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*"$suffix"; do
      [ -f "$f" ] || continue
      name="${f##*/}"
      rest="${name#"$repo"-????-??-??-}"
      rest="${rest%"$suffix"}"
      case "$rest" in ""|*.*) continue ;; esac
      private "$f" || { refuse_note "$f"; continue; }
      if [ "$cmd" = list ]; then printf '%s\n' "$f"; continue; fi
      if [ -z "$best" ] || [ "$f" -nt "$best" ]; then best="$f"; fi
    done
  fi
fi
[ "$cmd" = list ] && exit 0
if [ -z "$best" ]; then
  echo "landing.sh: no ${kind:-handoff} file for $repo in $zone" >&2
  exit 2
fi
printf '%s\n' "$best"
