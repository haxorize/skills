#!/usr/bin/env bash
# skill-usage.sh — per skill, how often a human typed it and how often the
# model loaded it, read from the two files that record each, never recalled.
#
# The two sources, and the two traps this script exists to close:
#   - typed:  ~/.claude/history.jsonl, one line per user prompt; a typed
#             invocation is a `display` that starts with `/<skill>` followed by
#             a space or the end of the value. `/tdd-extra` is not `/tdd`.
#   - loaded: every *.jsonl under ~/.claude/projects/ (subagent transcripts
#             included — a load inside a subagent is a load); a load is an
#             assistant `tool_use` block whose `name` is "Skill" and whose
#             `input.skill` names the skill. Nothing else counts: a
#             "Launching skill: X" line is skill-body gate text the model
#             printed, and a bare `"skill":"X"` string is written by other
#             tools too (a StructuredOutput probe was the case that mis-shaped
#             a hand count). Both were counted as loads in earlier window
#             records, by hand, twice.
#
# A file that cannot be fully parsed — a line cut mid-write when the session
# died — is counted as far as it parses, and every count from that source
# carries a trailing `+`: the number is a floor, not a total. The typed and the
# loaded side each carry their own marker, so a truncated history never
# discredits a whole transcript set or the reverse. stderr names each such
# file by its basename (the full path under --projects is a list of every
# project directory this machine has opened, which a pasted stderr should not
# carry); a run that met one exits 2, not 0.
#
# The counts are one machine's: this file and the transcripts under
# --projects are the ones on the machine running the script. A typist who
# works from two machines is read by running it on each and adding.
#
# Usage:
#   scripts/skill-usage.sh [--since YYYY-MM-DD] [--until YYYY-MM-DD]
#                          [--skills a,b,c | --skills all | --skills-from DIR]
#                          [--history FILE] [--projects DIR]
#                          [--exclude-session ID] [--json] [--help]
# Example:
#   bash scripts/skill-usage.sh --since 2026-08-01 --skills-from ~/.claude/skills
#
#   --since / --until   inclusive calendar bounds (UTC) on both sources
#   --skills a,b,c      count these names; `all` counts every name seen, which
#                       includes built-ins like /clear on the typed side
#   --skills-from DIR   count the directories under DIR (default: src/ beside
#                       this script's repo root, when it exists; else all)
#   --history FILE      default ~/.claude/history.jsonl
#   --projects DIR      default ~/.claude/projects
#   --exclude-session   drop one session id from both sources — the session
#                       doing the measuring, usually
#   --json              a JSON array instead of TSV
#
# Output on stdout, TSV with a header row:
#   skill  typed  loaded  last_typed  last_loaded
# Everything else is on stderr. A loaded name is kept only when it has the
# shape a skill name can have (`[a-z0-9][a-z0-9-]*`); anything else in a
# transcript's `input.skill` is dropped, never printed.
#
# Exit codes: 0 counted · 2 nothing to count (no history file and no
# transcripts under --projects), or not everything counted (a file did not
# fully parse and a `+` marks its column) · 3 usage error.
#
# Needs bash 3.2+ and jq. scripts/skill-usage-selftest.sh proves the shapes
# above are the ones counted, against scripts/lint-fixtures/usage/.

set -uo pipefail

# --help prints the header above: line 2 to the first blank line, so a header
# edit never leaves the help truncated mid-sentence.
usage() { sed -n '2,/^$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
since=""; until=""; skills=""; skills_from=""; json=0
history_file="${HOME}/.claude/history.jsonl"
projects_dir="${HOME}/.claude/projects"
exclude=""

need_arg() { [ $# -ge 2 ] || { echo "skill-usage.sh: $1 needs a value" >&2; exit 3; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --since) need_arg "$@"; since="$2"; shift 2 ;;
    --until) need_arg "$@"; until="$2"; shift 2 ;;
    --skills) need_arg "$@"; skills="$2"; shift 2 ;;
    --skills-from) need_arg "$@"; skills_from="$2"; shift 2 ;;
    --history) need_arg "$@"; history_file="$2"; shift 2 ;;
    --projects) need_arg "$@"; projects_dir="$2"; shift 2 ;;
    --exclude-session) need_arg "$@"; exclude="$2"; shift 2 ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "skill-usage.sh: unknown argument '$1' — run with --help for the flags" >&2; exit 3 ;;
  esac
done
for d in "$since" "$until"; do
  if [ -n "$d" ] && ! printf '%s' "$d" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    echo "skill-usage.sh: dates are YYYY-MM-DD, got '$d'" >&2; exit 3
  fi
done
command -v jq >/dev/null 2>&1 || { echo "skill-usage.sh: jq is required" >&2; exit 3; }

# The skill roster. Names outside it are dropped from both sides, which is
# what keeps /clear and /compact out of the typed column.
roster=""
if [ -n "$skills" ] && [ -n "$skills_from" ]; then
  echo "skill-usage.sh: pass --skills or --skills-from, not both" >&2; exit 3
elif [ -n "$skills" ]; then
  [ "$skills" = all ] || roster="$skills"
elif [ -n "$skills_from" ]; then
  [ -d "$skills_from" ] || { echo "skill-usage.sh: --skills-from '$skills_from' is not a directory" >&2; exit 3; }
  roster=$(find "$skills_from" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd, -)
elif [ -d "$repo_root/src" ]; then
  roster=$(find "$repo_root/src" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd, -)
fi

have_history=0; [ -s "$history_file" ] && have_history=1
transcripts=""
[ -d "$projects_dir" ] && transcripts=$(find "$projects_dir" -type f -name '*.jsonl' | sort)
if [ "$have_history" -eq 0 ] && [ -z "$transcripts" ]; then
  echo "skill-usage.sh: nothing to count — no history at $history_file and no *.jsonl under $projects_dir; pass --history and --projects" >&2
  exit 2
fi

events=$(mktemp -t skill-usage.XXXXXX 2>/dev/null)
if [ -z "$events" ] || [ ! -f "$events" ]; then
  echo "skill-usage.sh: mktemp gave no usable file — nothing counted; check TMPDIR" >&2
  exit 2
fi
trap 'rm -f "$events"' EXIT
typed_partial=0; loaded_partial=0

# typed: kind, date, session, skill. The date is the ms timestamp's UTC day.
if [ "$have_history" -eq 1 ]; then
  if ! jq -r '
      select((.display // "") | test("^/[a-z0-9][a-z0-9-]*( |$)"))
      | [ "typed",
          ((.timestamp // 0) / 1000 | todate | .[0:10]),
          (.sessionId // ""),
          ((.display | capture("^/(?<n>[a-z0-9][a-z0-9-]*)")) .n) ]
      | @tsv' "$history_file" >> "$events" 2>/dev/null; then
    echo "skill-usage.sh: $(basename "$history_file") did not fully parse — typed counts are a floor" >&2
    typed_partial=1
  fi
fi

# loaded: one jq per file, so a truncated file is named and the rest still count.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if ! jq -r '
      select(.type == "assistant")
      | (.timestamp // "")[0:10] as $d
      | (.sessionId // "") as $s
      | .message.content[]?
      | select(.type == "tool_use" and .name == "Skill")
      | (.input.skill // "") as $n
      | select($n | test("^[a-z0-9][a-z0-9-]*$"))
      | [ "loaded", $d, $s, $n ]
      | @tsv' "$f" >> "$events" 2>/dev/null; then
    echo "skill-usage.sh: $(basename "$f") (under $projects_dir) did not fully parse — loaded counts are a floor" >&2
    loaded_partial=1
  fi
done <<< "$transcripts"

# Aggregate. A row survives when its skill is on the roster (or there is no
# roster), its date is inside the window, and its session is not excluded.
awk -F'\t' -v since="$since" -v until="$until" -v exclude="$exclude" \
    -v roster="$roster" -v typed_partial="$typed_partial" -v loaded_partial="$loaded_partial" -v json="$json" '
  BEGIN {
    n = split(roster, r, ",")
    for (i = 1; i <= n; i++) if (r[i] != "") { keep[r[i]] = 1; have_roster = 1; order[++m] = r[i] }
  }
  {
    kind = $1; d = $2; s = $3; name = $4
    if (name == "") next
    if (have_roster && !(name in keep)) next
    if (since != "" && d < since) next
    if (until != "" && d > until) next
    if (exclude != "" && s == exclude) next
    if (!(name in seen)) { seen[name] = 1; if (!have_roster) order[++m] = name }
    if (kind == "typed") { typed[name]++; if (d > last_t[name]) last_t[name] = d }
    else { loaded[name]++; if (d > last_l[name]) last_l[name] = d }
  }
  END {
    for (i = 1; i <= m; i++) for (j = i + 1; j <= m; j++) if (order[j] < order[i]) { t = order[i]; order[i] = order[j]; order[j] = t }
    tsuf = typed_partial ? "+" : ""; lsuf = loaded_partial ? "+" : ""
    if (json) printf "["
    else print "skill\ttyped\tloaded\tlast_typed\tlast_loaded"
    first = 1
    for (i = 1; i <= m; i++) {
      name = order[i]
      if (i > 1 && order[i] == order[i-1]) continue
      t = typed[name] + 0; l = loaded[name] + 0
      lt = (name in last_t) ? last_t[name] : "-"; ll = (name in last_l) ? last_l[name] : "-"
      if (json) {
        printf "%s{\"skill\":\"%s\",\"typed\":%d,\"typed_is_floor\":%s,\"loaded\":%d,\"loaded_is_floor\":%s,\"last_typed\":%s,\"last_loaded\":%s}", (first ? "" : ","), name, t, (typed_partial ? "true" : "false"), l, (loaded_partial ? "true" : "false"), (lt == "-" ? "null" : "\"" lt "\""), (ll == "-" ? "null" : "\"" ll "\"")
        first = 0
      } else {
        printf "%s\t%d%s\t%d%s\t%s\t%s\n", name, t, tsuf, l, lsuf, lt, ll
      }
    }
    if (json) print "]"
  }
' "$events"
# Not everything counted is the taxonomy's 2, the same code
# lint-skills-selftest.sh uses for a partial: a caller reading the status alone
# can tell a floor from a total.
if [ "$typed_partial" -ne 0 ] || [ "$loaded_partial" -ne 0 ]; then
  exit 2
fi
exit 0
