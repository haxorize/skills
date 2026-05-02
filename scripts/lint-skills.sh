#!/usr/bin/env bash
# Lint skill files against repo conventions encoded in src/write-skill/SKILL.md:
#   - SKILL.md and references/*.md must be <= 200 lines.
#   - Frontmatter `description:` must be <= 1024 chars and contain no unquoted
#     `: ` separator (use em-dashes — GitHub's strict YAML preview chokes on
#     mid-value colons).
#
# Exit code 0 if clean, 1 if any check fails. List all failures, don't bail
# on first hit.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail=0

shopt -s nullglob

for f in src/*/SKILL.md src/*/references/*.md; do
  lines=$(wc -l < "$f" | tr -d ' ')
  if [ "$lines" -gt 200 ]; then
    echo "FAIL: $f exceeds 200-line cap ($lines lines)"
    fail=1
  fi
done

for f in src/*/SKILL.md; do
  desc=$(awk '
    /^---$/ { c++; next }
    c == 1 && /^description:[[:space:]]/ {
      sub(/^description:[[:space:]]*/, "")
      print
      exit
    }
  ' "$f")

  if [ -z "$desc" ]; then
    echo "FAIL: $f has no description in frontmatter"
    fail=1
    continue
  fi

  len=${#desc}
  if [ "$len" -gt 1024 ]; then
    echo "FAIL: $f description exceeds 1024 chars ($len)"
    fail=1
  fi

  # Strip backtick-quoted spans (`like this`) before scanning for `: ` —
  # colons inside code spans are fine in prose, and the YAML parser already
  # ate the outer value as a single string by this point. The risk is a
  # bare `: ` in prose, which earlier versions of GitHub's preview misparsed.
  stripped=$(printf '%s' "$desc" | sed 's/`[^`]*`//g')
  if printf '%s' "$stripped" | grep -qE ': '; then
    echo "FAIL: $f description has unquoted ': ' (use em-dash) — $desc"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
