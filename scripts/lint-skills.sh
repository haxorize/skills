#!/usr/bin/env bash
# Lint skill files against repo conventions encoded in src/write-skill/SKILL.md:
#   - SKILL.md and references/*.md must be <= 200 lines.
#   - Frontmatter `description:` must be <= 1024 chars and contain no unquoted
#     `: ` separator (use em-dashes — GitHub's strict YAML preview chokes on
#     mid-value colons).
#   - Invocation axis (ADR-0015): a user-invoked skill carries
#     `disable-model-invocation: true` and its description must be human-facing
#     (a one-line summary, no "Use when…" trigger list — the model never sees
#     it). A model-invoked skill (no such flag) must keep trigger phrasing so
#     auto-invocation can fire. write-skill makes "Use when/after/only" the
#     normative trigger marker (see "Writing the description"); this check
#     enforces that stated rule by keying on that opener.
#   - ADR-0007 sibling reference files must stay byte-identical. Symlink-per-
#     skill install means we duplicate `domain-format.md` and `adr-format.md`
#     across the skills that need them; ADR-0007 records this with mitigation
#     "editorial discipline." This check turns the discipline into mechanism.
#   - Declared dependencies (ADR-0016): an orchestrator names the behaviors it
#     needs in a frontmatter `requires:` line (comma-separated skill names).
#     Each named dep must exist as a skill AND be model-invoked — prose
#     invocation can only reach model-invoked skills, so a user-invoked dep
#     could never be resolved at runtime.
#   - Skill bodies must not cite repo ADRs by number (write-skill: "Skill
#     bodies don't cite repo ADRs"). Skills symlink into ~/.claude/skills/ and
#     run in the user's project, where this repo's docs/adr/ does not exist, so
#     a bare "ADR-0007" points at nothing. Lineage runs ADR -> skill (each ADR
#     names the skills it shapes); the reverse pointer is banned. Match is
#     case-insensitive on a word-boundaried `ADR-<digit>` token (`\bADR-[0-9]`),
#     so `adr-0023` and `Adr-7` are caught too. `docs/adr/` paths put a slash
#     after `adr` (not a hyphen) so they stay legal, as do digitless
#     placeholders ("ADR-N" — `N` isn't a digit).
#   - Router coverage (CLAUDE.md "Keep the router honest"): every skill under
#     src/ must be mentioned by name in src/which-skill/SKILL.md, so the router
#     never silently omits a skill. Stale-routing accuracy stays editorial.
#
# Exit code 0 if clean, 1 if any check fails. List all failures, don't bail
# on first hit.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

# The description caps below are character-based (<=1024 chars, no bare ': ').
# bash's ${#var} and grep count bytes under LC_ALL=C or an unset locale, which
# would mis-measure the Unicode-rich (em-dash) descriptions. Force a UTF-8
# ctype unless one is already active, so the checks match their stated contract.
case "${LC_ALL:-}${LC_CTYPE:-}" in
  *UTF-8* | *utf8* | *UTF8*) : ;;
  *) export LC_ALL=; export LC_CTYPE="UTF-8" ;;
esac

fail=0

shopt -s nullglob

# Print "true" if a skill file is user-invoked — its frontmatter (block 1,
# between the first two `---` fences) carries `disable-model-invocation: true`.
# Empty output means model-invoked. Shared by the own-skill and dependency checks.
is_user_invoked() {
  awk '
    /^---$/ { c++; next }
    c == 1 && /^disable-model-invocation:[[:space:]]*true[[:space:]]*$/ { print "true"; exit }
  ' "$1"
}

# Per-body checks over every shipped skill file: the 200-line cap and the ban
# on citing repo ADRs by number (see header for both). A find sweep (rather than
# a fixed-depth glob) covers nested reference files (references/sub/*.md) too.
while IFS= read -r f; do
  lines=$(awk 'END { print NR }' "$f")
  if [ "$lines" -gt 200 ]; then
    echo "FAIL: $f exceeds 200-line cap ($lines lines)"
    fail=1
  fi

  adr_hits=$(grep -niE '\bADR-[0-9]' "$f")
  if [ -n "$adr_hits" ]; then
    badlines=$(printf '%s\n' "$adr_hits" | cut -d: -f1 | tr '\n' ' ')
    echo "FAIL: $f cites a repo ADR by number (line(s) ${badlines}) — skill bodies must not (write-skill: 'Skill bodies don't cite repo ADRs'); lineage is ADR -> skill"
    fail=1
  fi
done < <(find src -type f -name '*.md' | sort)

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

  # Scan for a bare `: ` in the description, which earlier versions of GitHub's
  # preview misparsed. Two cases are already safe and must not be flagged:
  #   - the whole value wrapped in matching YAML quotes (the ': ' is quoted), or
  #   - a colon inside a backtick code-span.
  case "$desc" in
    \"*\" | \'*\') : ;;  # quoted YAML scalar — any ': ' inside is safe
    *)
      stripped=$(printf '%s' "$desc" | sed 's/`[^`]*`//g')
      if printf '%s' "$stripped" | grep -qE ': '; then
        echo "FAIL: $f description has unquoted ': ' (use em-dash) — $desc"
        fail=1
      fi
      ;;
  esac

  # Invocation axis (ADR-0015). A skill is user-invoked iff its frontmatter
  # carries `disable-model-invocation: true`. The trigger marker is the
  # normative "Use when/after/only" opener write-skill mandates (leading
  # word-start avoids matching "reuse"); user-invoked must lack it,
  # model-invoked must have it.
  dmi=$(is_user_invoked "$f")

  if printf '%s' "$desc" | grep -qE '(^| )[Uu]se (this skill |this |the )?(when|after|only)'; then
    has_trigger=1
  else
    has_trigger=0
  fi

  if [ "$dmi" = "true" ]; then
    if [ "$has_trigger" -eq 1 ]; then
      echo "FAIL: $f is user-invoked (disable-model-invocation: true) but its description carries a 'Use when…' trigger list — make it human-facing (the model never sees it)"
      fail=1
    fi
  else
    if [ "$has_trigger" -eq 0 ]; then
      echo "FAIL: $f is model-invoked but its description has no 'Use when…' trigger phrasing — auto-invocation needs it (or set disable-model-invocation: true)"
      fail=1
    fi
  fi
done

sibling_groups=(
  "src/grill-and-record/references/adr-format.md|src/backfill-adrs/references/adr-format.md|src/adr/references/adr-format.md"
  "src/to-bug/references/naming-drift-queue.md|src/to-feature/references/naming-drift-queue.md|src/to-story/references/naming-drift-queue.md|src/to-tasks/references/naming-drift-queue.md"
  "src/to-bug/references/tracker-resolution.md|src/to-feature/references/tracker-resolution.md|src/to-story/references/tracker-resolution.md|src/to-tasks/references/tracker-resolution.md|src/improve-design/references/tracker-resolution.md"
  "src/improve-design/references/finding-discipline.md|src/review-changes/references/finding-discipline.md"
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

# Declared dependencies (ADR-0016): every name in a `requires:` line must
# resolve to a skill that exists and is model-invoked.
for f in src/*/SKILL.md; do
  reqs=$(awk '
    /^---$/ { c++; next }
    c == 1 && /^requires:[[:space:]]/ {
      sub(/^requires:[[:space:]]*/, "")
      gsub(/,/, " ")
      print
      exit
    }
  ' "$f")
  [ -z "$reqs" ] && continue
  for dep in $reqs; do
    depfile="src/$dep/SKILL.md"
    if [ ! -f "$depfile" ]; then
      echo "FAIL: $f requires '$dep' but src/$dep/SKILL.md does not exist"
      fail=1
      continue
    fi
    dep_dmi=$(is_user_invoked "$depfile")
    if [ "$dep_dmi" = "true" ]; then
      echo "FAIL: $f requires '$dep', but '$dep' is user-invoked — prose invocation can only reach model-invoked behaviors"
      fail=1
    fi
  done
done

# Router coverage (see header). The boundary classes keep a name from
# matching inside a longer slug (`adr` never matches `backfill-adrs`).
router="src/which-skill/SKILL.md"
for f in src/*/SKILL.md; do
  name=${f#src/}; name=${name%/SKILL.md}
  [ "$name" = "which-skill" ] && continue
  if ! grep -qE "(^|[^a-z0-9-])${name}([^a-z0-9-]|$)" "$router"; then
    echo "FAIL: $router never mentions skill '$name' — route it or list it as standalone (CLAUDE.md: 'Keep the router honest')"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
