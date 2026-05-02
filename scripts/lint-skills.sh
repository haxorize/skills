#!/usr/bin/env bash
# Lint skill files against repo conventions encoded in src/write-skill/SKILL.md:
#   - SKILL.md and references/*.md must be <= 200 lines.
#   - Frontmatter `description:` must be <= 1024 chars and contain no unquoted
#     `: ` separator (use em-dashes — GitHub's strict YAML preview chokes on
#     mid-value colons).
#   - ADR-0007 sibling reference files must stay byte-identical. Symlink-per-
#     skill install means we duplicate `domain-format.md` and `adr-format.md`
#     across the skills that need them; ADR-0007 records this with mitigation
#     "editorial discipline." This check turns the discipline into mechanism.
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

sibling_groups=(
  "src/grill-and-record/references/domain-format.md|src/harden-domain/references/domain-format.md"
  "src/grill-and-record/references/adr-format.md|src/backfill-adrs/references/adr-format.md"
)

for group in "${sibling_groups[@]}"; do
  IFS='|' read -ra files <<< "$group"
  ref="${files[0]}"
  if [ ! -f "$ref" ]; then
    echo "FAIL: sibling reference $ref is missing"
    fail=1
    continue
  fi
  for other in "${files[@]:1}"; do
    if [ ! -f "$other" ]; then
      echo "FAIL: sibling reference $other is missing"
      fail=1
    elif ! cmp -s "$ref" "$other"; then
      echo "FAIL: $other drifted from $ref (per ADR-0007 these must stay byte-identical)"
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
