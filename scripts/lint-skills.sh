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
#     skill install means we duplicate shared reference files (`adr-format.md`,
#     `tracker-resolution.md`, and the other sibling groups below) across the
#     skills that need them; ADR-0007 records this with mitigation
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
#   - Platform-true spec limits (ADR-0030): `name` <= 64 chars and no angle
#     brackets in `description` — the two agent-skills-spec caps Claude Code
#     shares. The rest of the spec (its closed frontmatter key set) deliberately
#     does not bind this repo; `requires:` and `disable-model-invocation` stay.
#   - Required `name` (write-skill template): every SKILL.md carries a `name:`
#     line whose value matches the enclosing src/<dir> slug.
#   - Load-gate placement (write-skill "Load gate vs none"): the gate's marker
#     phrase — a "Launching skill:" line — may appear only in user-invoked
#     orchestrators, where the human who typed the command watches the load
#     line. A model-invoked skill has no watcher, so a miss must degrade
#     gracefully ("Never gate inside a model-invoked skill"); its body and
#     references must not carry the phrase.
#   - Router coverage (CLAUDE.md "Keep the router honest"): every skill under
#     src/ must appear as a backticked code-span (`name` or `/name`) in
#     src/which-skill/SKILL.md. Requiring the backtick keeps incidental prose
#     (the gerund "grilling") from satisfying the check, so the router can't
#     silently omit a skill. Stale-routing accuracy stays editorial. README.md
#     is held to the same coverage rule — its skill map is a second router.
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
# Locale names differ per OS (bare "UTF-8" is Darwin-only; glibc wants
# "C.UTF-8"), so probe candidates and keep the first whose charmap is UTF-8.
case "${LC_ALL:-}${LC_CTYPE:-}" in
  *UTF-8* | *utf8* | *UTF8*) : ;;
  *)
    export LC_ALL=
    for ctype in C.UTF-8 en_US.UTF-8 UTF-8; do
      if [ "$(LC_CTYPE=$ctype locale charmap 2>/dev/null)" = "UTF-8" ]; then
        export LC_CTYPE="$ctype"
        break
      fi
    done
    ;;
esac

fail=0

shopt -s nullglob

# Print the value of a `<key>: value` line from frontmatter (block 1, between
# the first two `---` fences), trailing whitespace trimmed; empty if absent.
frontmatter_value() {
  awk -v key="$2" '
    /^---$/ { c++; next }
    c == 1 && $0 ~ "^" key ":" {
      sub("^" key ":[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$1"
}

# Print "true" if a skill file is user-invoked — its frontmatter carries
# `disable-model-invocation: true`. Empty output means model-invoked. Shared by
# the own-skill and dependency checks.
is_user_invoked() {
  [ "$(frontmatter_value "$1" disable-model-invocation)" = "true" ] && echo true
}

# Per-body checks over every shipped skill file: the 200-line cap and the ban
# on citing repo ADRs by number (see header for both). A find sweep (rather than
# a fixed-depth glob) covers nested reference files (references/sub/*.md) too.
while IFS= read -r f; do
  lines=$(awk 'END { print NR }' "$f")
  if [ "$lines" -gt 200 ]; then
    echo "FAIL: $f exceeds 200-line cap ($lines lines) — cut or move detail into references/; never raise the cap"
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
  desc=$(frontmatter_value "$f" description)

  if [ -z "$desc" ]; then
    echo "FAIL: $f has no description in frontmatter — add 'description:' to the YAML block"
    fail=1
    continue
  fi

  len=${#desc}
  if [ "$len" -gt 1024 ]; then
    echo "FAIL: $f description exceeds 1024 chars ($len) — trim triggers; collapse synonym branches"
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

  # Required name (write-skill template): `name:` must exist and mirror the
  # skill's directory. Platform-true spec limits (ADR-0030): Claude Code
  # truncates/chokes on the same two caps the packaging spec enforces; the
  # spec's other rules don't apply.
  name_val=$(frontmatter_value "$f" name)
  dir_slug=${f#src/}; dir_slug=${dir_slug%/SKILL.md}
  if [ -z "$name_val" ]; then
    echo "FAIL: $f has no name in frontmatter (write-skill template requires name: $dir_slug)"
    fail=1
  else
    if [ "${#name_val}" -gt 64 ]; then
      echo "FAIL: $f name exceeds 64 chars (${#name_val})"
      fail=1
    fi
    if [ "$name_val" != "$dir_slug" ]; then
      echo "FAIL: $f name '$name_val' does not match its directory '$dir_slug' (write-skill template: name mirrors the skill-name/ directory)"
      fail=1
    fi
  fi
  case "$desc" in
    *[\<\>]*)
      echo "FAIL: $f description contains angle brackets (< or >) — disallowed in the description field"
      fail=1
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

# Load-gate placement (see header): the "Launching skill" marker phrase must
# not appear anywhere in a model-invoked skill — body or references.
for f in src/*/SKILL.md; do
  [ "$(is_user_invoked "$f")" = "true" ] && continue
  while IFS= read -r body; do
    gate_hits=$(grep -n 'Launching skill' "$body")
    if [ -n "$gate_hits" ]; then
      badlines=$(printf '%s\n' "$gate_hits" | cut -d: -f1 | tr '\n' ' ')
      echo "FAIL: $body carries a load gate ('Launching skill', line(s) ${badlines}) inside a model-invoked skill — no watcher, a miss must degrade gracefully (write-skill: 'Never gate inside a model-invoked skill')"
      fail=1
    fi
  done < <(find "${f%/SKILL.md}" -type f -name '*.md' | sort)
done

sibling_groups=(
  "src/grill-and-record/references/adr-format.md|src/backfill-adrs/references/adr-format.md|src/adr/references/adr-format.md"
  "src/to-bug/references/naming-drift-queue.md|src/to-feature/references/naming-drift-queue.md|src/to-story/references/naming-drift-queue.md|src/to-tasks/references/naming-drift-queue.md"
  "src/to-bug/references/tracker-resolution.md|src/to-feature/references/tracker-resolution.md|src/to-story/references/tracker-resolution.md|src/to-tasks/references/tracker-resolution.md|src/improve-design/references/tracker-resolution.md|src/chart-course/references/tracker-resolution.md"
  "src/improve-design/references/finding-discipline.md|src/review-changes/references/finding-discipline.md"
  "src/to-bug/references/github-sub-issues.md|src/to-story/references/github-sub-issues.md|src/to-tasks/references/github-sub-issues.md|src/chart-course/references/github-sub-issues.md"
  "src/to-bug/references/work-item-tags.md|src/to-feature/references/work-item-tags.md|src/to-story/references/work-item-tags.md|src/to-tasks/references/work-item-tags.md|src/chart-course/references/work-item-tags.md"
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

# Sibling-group membership: any reference basename that exists under two or
# more skills must be governed by a group above — an unlisted copy sits outside
# the byte-identity check and drifts silently, the exact failure that check
# exists to prevent. A deliberate variant needs a distinct name (or its own
# group entry).
grouped_basenames=$(printf '%s|' "${sibling_groups[@]}" | tr '|' '\n' | awk -F/ 'NF { print $NF }' | sort -u)
while IFS= read -r base; do
  if ! printf '%s\n' "$grouped_basenames" | grep -qxF "$base"; then
    echo "FAIL: reference file '$base' exists in multiple skills but no sibling group covers it — add it to sibling_groups in scripts/lint-skills.sh, or rename the deliberate variant"
    fail=1
  fi
done < <(find src -path '*/references/*' -type f -name '*.md' | awk -F/ '{ print $NF }' | sort | uniq -d)

# Declared dependencies (ADR-0016): every name in a `requires:` line must
# resolve to a skill that exists and is model-invoked.
for f in src/*/SKILL.md; do
  reqs=$(frontmatter_value "$f" requires | tr ',' ' ')
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

# Router coverage (see header); the trailing class keeps a name from
# matching inside a longer slug (`adr` never matches `backfill-adrs`).
router="src/which-skill/SKILL.md"
for f in src/*/SKILL.md; do
  name=${f#src/}; name=${name%/SKILL.md}
  [ "$name" = "which-skill" ] && continue
  if ! grep -qE "\`/?${name}([^a-z0-9-]|$)" "$router"; then
    echo "FAIL: $router has no backticked mention of skill '$name' — route it or list it as standalone (CLAUDE.md: 'Keep the router honest')"
    fail=1
  fi
done

# README roster coverage: README.md's skill map is a second router — every
# skill must appear there as a backticked code-span, same rule as above, so an
# added, renamed, or removed skill can't leave the README lying. Blurb accuracy
# stays editorial.
readme="README.md"
for f in src/*/SKILL.md; do
  name=${f#src/}; name=${name%/SKILL.md}
  if ! grep -qE "\`/?${name}([^a-z0-9-]|$)" "$readme"; then
    echo "FAIL: $readme has no backticked mention of skill '$name' — list it in the README skill map (CLAUDE.md: 'Keep the router honest')"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
