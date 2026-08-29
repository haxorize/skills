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
#   - Declared dependencies (ADR-0016): an orchestrator names the disciplines it
#     needs in a frontmatter `requires:` line (comma-separated skill names).
#     Each named dep must exist as a skill AND be model-invoked — prose
#     invocation can only reach model-invoked skills, so a user-invoked dep
#     could never be resolved at runtime.
#     The check runs both ways: a body that calls a model-invoked skill by the
#     Skill-tool form (``Call the Skill tool with `<name>` ``) must declare it,
#     and a declared dep must be named in the body — a `requires:` line nobody
#     reads is drift the installer still links. Calling the Skill tool with a
#     *user-invoked* skill fails outright: its description is hidden from the
#     model, so the call does nothing at runtime.
#     The slash-on-model-invoked check is the mirror image, and file-local
#     rather than per-skill: `/<name>` naming a model-invoked skill fails,
#     because the slash form is what a human types and it hides the call from
#     the scan above. Needing no `requires:` line, it sweeps every markdown
#     file the repo ships as instructions — `src/**`, `.claude/skills/**`,
#     `DOMAIN.md`, `README.md` — not just `src/*/SKILL.md`.
#     Before every scan, double-quoted spans, parenthesised asides containing
#     an arrow (`→`, the example form), and fenced code blocks are stripped,
#     so an authoring guide can quote the form it teaches without declaring
#     the example. Scope, stated so a pass isn't read as more than it is: a
#     use is the ``Call the Skill tool with `<name>` `` clause, imperative or
#     gerund, and every backticked name in it — a bare "run the X skill" is
#     invisible, and so is a call whose clause wraps a line, since every scan
#     here is line-based. "Named in the body" means SKILL.md — a dep consumed
#     only from a reference file must still be named once in the body.
#   - Skill bodies must not cite repo ADRs by number (write-skill: "Skill
#     bodies don't cite repo ADRs"). Skills symlink into ~/.claude/skills/ and
#     run in the user's project, where this repo's docs/adr/ does not exist, so
#     a bare "ADR-0007" points at nothing. Lineage runs ADR -> skill (each ADR
#     names the skills it shapes); the reverse pointer is banned. Match is
#     case-insensitive on a word-boundaried `ADR-<digit>` token (`\bADR-[0-9]`),
#     so `adr-0023` and `Adr-7` are caught too. `docs/adr/` paths put a slash
#     after `adr` (not a hyphen) so they stay legal, as do digitless
#     placeholders ("ADR-N" — `N` isn't a digit).
#   - Rich-text transport: a skill body passes converted HTML to a tracker CLI
#     as `@<file>`, never through the shell — `$(cat x.html)`, an inline
#     `"<html>"` string, or prose prescribing "temp file plus command
#     substitution" all fail (publishing.md '## Transport safety'). A shell
#     string mangles the body, and the two forms fail differently on a
#     missing file (loud vs a stored literal `@path`), so they must not coexist.
#   - Reference-link resolution: an inline `[text](path.md)` link with a
#     relative target must resolve to a real file, relative to the linking
#     file's own directory. A `SKILL.md` promising `references/foo.md` that
#     isn't there degrades silently — the agent follows the pointer, finds
#     nothing, and proceeds on whatever it already had. Fenced code blocks
#     (opened and closed by a triple-backtick line) and backtick code spans
#     of any run length are exempt because they hold deliberate placeholders
#     (the template's `references/topic.md`, adr-format's
#     `[ADR N](N-slug.md)`).
#     Scope, stated so a pass isn't read as more than it is: this covers the
#     inline link form alone, on the `.md` extension alone. Reference-style
#     (`[text][label]`), titled (`[text](path.md "Title")`), angle-bracketed,
#     percent-encoded, and paren-bearing targets are not extracted, so a
#     broken one passes unflagged. Resolution is the filesystem's, so a link
#     escaping the skill directory (`../../docs/...`) passes here while
#     breaking once the skill is symlinked into ~/.claude/skills/, and a
#     case-only mismatch passes on a case-insensitive volume and fails on a
#     case-sensitive one. The sibling-group check below covers the same
#     ground for the paths registered there.
#
# scripts/lint-skills-selftest.sh runs this file against a deliberately-bad fixture
# tree and fails if any check stops firing (or starts firing on the exempt
# forms). Run it after changing a check here.
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
#   - Scope: the skill checks walk src/*/SKILL.md (and references beneath);
#     the global-rules checks below walk global/rules/, the hook-selftest
#     check global/hooks/, the script-selftest check scripts/. The repo-local skills
#     under .claude/skills/ are deliberately outside both walks: they never hoist, so the router-coverage
#     and requires checks would demand mentions that do not belong, and they
#     legitimately cite this repo's paths. Their size and frontmatter are the
#     author's to keep; a pass here says nothing about them.
#   - Global rules (ADR-0053): every global/rules/*.md carries a `Depends:`
#     line naming at least one existing skill under src/ — the admission rule
#     in global/README.md (only rules a skill depends on). A rule with no
#     resolvable dependant has lost its reason to load on every turn. Each
#     named dependant must also cite the rule by name somewhere under
#     src/<dep>/ (SKILL.md or a reference): the path `~/.claude/rules/<stem>.md`
#     or the backticked stem (`large-write-chunking`). A bare mention of the
#     rules directory does not count — it cannot say which rule is leaned on —
#     and neither does the stem as an unmarked word (`evidence` in prose) or a
#     citation inside a fenced block. The
#     200-line cap and the ADR-citation ban above also run over global/rules/,
#     since those files are hoisted into ~/.claude/rules/ the same way skills
#     are hoisted.
#   - Single-line description (CLAUDE.md § Linting; write-skill "Writing the
#     description"): `description:` is a plain scalar on its own line. A block
#     indicator (`>`, `|`, with any chomping or indentation suffix) is the
#     whole value a one-line reader sees, and a plain scalar continued on an
#     indented next line loses its tail — every consumer here reads one line.
#   - Re-attach byte WARN (write-skill § Size constraints): a SKILL.md over
#     15,000 bytes draws a WARN, never a FAIL — the platform figure it converts
#     is dated in the block below. Reference files are not measured: they are
#     read on demand, never re-attached.
#   - Hook selftest (CLAUDE.md § Linting: "one selftest per hook, which
#     `lint-skills.sh` enforces"): every global/hooks/*.sh whose header carries
#     an `# Install note:` line — the marker install.sh and post-merge derive
#     the hook roster from, so all three answer "what is a hook" the same way —
#     has an executable global/hooks/<name>-selftest.sh beside it. A file with
#     no marker is a library or a selftest and owes nothing.
#   - Script selftest (ADR-0068: every selftest is `<script>-selftest.sh`):
#     every scripts/<name>.sh that is not itself a selftest, a `*-lib.sh`, or
#     one of the two installers (install.sh, setup-hooks.sh) has an executable
#     scripts/<name>-selftest.sh beside it, so a gate landing without one is
#     named here rather than silently ungated. scripts/git-hooks/ is the git
#     hooks' directory and post-merge derives its roster there.
#   - Router coverage (CLAUDE.md "Keep the router honest"): every skill under
#     src/ must appear as a backticked code-span (`name` or `/name`) in
#     src/which-skill/SKILL.md. Requiring the backtick keeps incidental prose
#     (the gerund "grilling") from satisfying the check, so the router can't
#     silently omit a skill. Stale-routing accuracy stays editorial. README.md
#     is held to the same coverage rule — its skill map is a second router.
#
# Limits this file enforces that are not this repo's own, with where each
# was verified and when — a cap attributed to a platform is re-checked at the
# spec text, not recalled (re-verify and re-date these when a release moves):
#   - `name` <= 64 chars, `description` <= 1024 chars, non-empty: the Agent
#     Skills specification (agentskills.io/specification, frontmatter table),
#     verified 2026-08-29; Claude Code shares both (ADR-0030).
#   - 5,000 tokens per re-attached skill inside a 25,000-token budget after
#     auto-compaction: code.claude.com/docs/en/skills, "Auto-compaction
#     carries invoked skills forward within a token budget … keeping the first
#     5,000 tokens of each", verified 2026-08-29. The WARN below converts it to
#     bytes at 3 bytes/token, measured 2026-08-29 on this repo's four largest
#     bodies through `claude -p` usage deltas (2.97–3.10 bytes/token; the
#     earlier 4-bytes/token estimate undercounted by a quarter).
#   - The 200-line caps are this repo's own (write-skill § Size constraints), a
#     loaded-context proxy, not a platform limit.
#
# Usage: scripts/lint-skills.sh [--help]. No other argument is accepted;
# LINT_ROOT=<dir> points the whole sweep at another tree (the selftest's
# fixture roots). Exit 0 clean, 1 if any check FAILs (every failure is listed;
# no bail on first hit), 2 if LINT_ROOT names no directory (nothing checked),
# 3 on an unknown argument. WARN lines never change the exit code.

set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/lint-skills.sh [--help]

Lints src/*/SKILL.md, their references, global/rules/, global/hooks/ (one selftest per
hook), scripts/ (one selftest per script), and the two routers against the conventions in
src/write-skill/SKILL.md. The header of this file lists every check and what each does
not reach. Takes no argument but --help.

  LINT_ROOT=<dir>   point the whole sweep at another tree; unset in normal use
                    (scripts/lint-skills-selftest.sh sets it to the fixture roots)

Exit codes: 0 clean · 1 at least one FAIL · 2 LINT_ROOT is not a directory (nothing
checked) · 3 usage error. WARN lines never change the exit code.
USAGE
}
if [ $# -gt 1 ]; then
  echo "lint-skills.sh: got $# arguments — this script takes no argument but --help" >&2; exit 3
fi
case "${1:-}" in
  "") [ $# -eq 0 ] || { echo "lint-skills.sh: an empty argument — this script takes no argument but --help" >&2; exit 3; } ;;
  -h|--help) usage; exit 0 ;;
  *) echo "lint-skills.sh: unknown argument '$1' — this script takes no argument but --help" >&2; exit 3 ;;
esac

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

# The one fence-stripping awk fragment every text check starts with: a line
# inside a ``` block is never read. `fence` resets per file so an unclosed
# fence in one file cannot hide (or expose) lines in the next file of an
# `-exec … +` batch; an indented fence counts as a fence. Prepend to an awk
# program: awk "$FENCE_AWK"'{ … }'.
FENCE_AWK='FNR == 1 { fence = 0 }
/^[[:space:]]*```/ { fence = !fence; next }
fence { next }
'

# LINT_ROOT points the whole sweep at another tree, so scripts/lint-skills-selftest.sh
# can run every check below against a fixture repo whose failures are known in
# advance. Unset in normal use, which lints this repo.
scan_root="$repo_root"
if [ -n "${LINT_ROOT:-}" ]; then
  if ! scan_root="$(cd "$repo_root" && cd "$LINT_ROOT" 2>/dev/null && pwd)"; then
    echo "lint-skills.sh: LINT_ROOT='$LINT_ROOT' is not a directory (relative to $repo_root) — nothing checked" >&2
    exit 2
  fi
fi
cd "$scan_root"

# The description caps below are character-based (<=1024 chars, no bare ': ' and no bare ' #' — both end an unquoted YAML scalar early).
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

  # Rich-text transport (see header): converted HTML reaches the tracker CLI
  # as `@<file>`, never through the shell.
  shell_hits=$(grep -nE '\$\(cat [^)]*\.html\)|--description "<html>"|=<html>"|temp file plus command substitution' "$f")
  if [ -n "$shell_hits" ]; then
    badlines=$(printf '%s\n' "$shell_hits" | cut -d: -f1 | tr '\n' ' ')
    echo "FAIL: $f passes HTML through the shell (line(s) ${badlines}) — write the converted HTML to a file and pass its path as \`@<file>\` (publishing.md '## Transport safety'); a shell string mangles the body and hides a missing file"
    fail=1
  fi

  # Reference-link resolution (see header). Fenced blocks and backtick code
  # spans are stripped first: both hold illustrative paths (the SKILL.md
  # template's `references/topic.md`, adr-format's `[ADR N](N-slug.md)`) that
  # name no real file by design. Spans are stripped by matching a backtick run
  # against the next run of the same length, not by a fixed one-backtick
  # pattern — `` `x` `` and ``code with a ` inside`` are spans too, and a
  # one-backtick pattern reads their delimiters as an empty span and leaves the
  # contents exposed.
  # The extractor's own exit status is checked: an awk that dies mid-sweep
  # prints nothing, which is indistinguishable from a file with no broken
  # links. Reading that silence as a pass is the failure this check exists to
  # prevent, one level up.
  dir=$(dirname "$f")
  if ! link_targets=$(awk '
    # Delete every backtick-delimited span: take a run of N backticks as an
    # opener and the next run of the same length as its closer. An unclosed run
    # leaves the rest of the line intact, so a stray backtick never hides a
    # real link. (`shut` rather than `close` — `close` is a built-in name and
    # awk rejects it as a parameter.)
    function strip_spans(s,   out, run, rest, shut) {
      out = ""
      while (match(s, /`+/)) {
        out = out substr(s, 1, RSTART - 1)
        run = substr(s, RSTART, RLENGTH)
        rest = substr(s, RSTART + RLENGTH)
        shut = index(rest, run)
        if (shut == 0) return out rest
        s = substr(rest, shut + length(run))
      }
      return out s
    }
  '"$FENCE_AWK"'
    {
      line = strip_spans($0)
      while (match(line, /\]\([^)]+\)/)) {
        t = substr(line, RSTART + 2, RLENGTH - 3)
        if (t ~ /\.md$/ || t ~ /\.md#/) print NR "\t" t
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$f"); then
    echo "FAIL: $f — the reference-link extractor errored, so no link in this file was checked; fix the awk block in scripts/lint-skills.sh"
    fail=1
    link_targets=""
  fi

  while IFS=$'\t' read -r lineno target; do
    [ -z "$target" ] && continue
    case "$target" in
      *://* | /* | \#*) continue ;;
    esac
    if [ ! -f "$dir/${target%%#*}" ]; then
      echo "FAIL: $f links to '$target' (line $lineno), which resolves to no file — create $dir/${target%%#*}, fix the path, or drop the link; a pointer to a missing reference silently loads nothing at runtime"
      fail=1
    fi
  done <<< "$link_targets"
done < <({ find src -type f -name '*.md'; [ -d global/rules ] && find global/rules -type f -name '*.md'; } | sort)

for f in src/*/SKILL.md; do
  desc=$(frontmatter_value "$f" description)

  if [ -z "$desc" ]; then
    echo "FAIL: $f has no description in frontmatter — add 'description:' to the YAML block"
    fail=1
    continue
  fi

  # (see header) Re-attach bound, as bytes. A WARN, not a FAIL: the cap is the
  # platform's and moves with it; what the author owes is ordering — the rules
  # a body cannot afford to lose sit early — or a smaller body. Measured before
  # the description checks so a body with a broken description is still measured.
  bytes=$(wc -c < "$f" | tr -d ' ')
  if [ "$bytes" -gt 15000 ]; then
    echo "WARN: $f is $bytes bytes (~$((bytes / 3)) tokens at 3 bytes/token) — past the 5,000-token re-attach bound Claude Code keeps per skill after auto-compaction, so its tail is what a re-attach drops; put its hard stops and close-out steps above its long sections, or move detail into references/"
  fi

  # Single-line scalar (see header): frontmatter_value reads one line, and so
  # does every consumer that truncates. A block indicator — `>` or `|` with
  # any chomping, indentation, or comment suffix — is the whole value it would
  # read; a plain scalar continued on an indented line loses its tail.
  case "$desc" in
    '>'* | '|'*)
      echo "FAIL: $f description is a YAML block scalar ('$desc') — read one line at a time, the description is the indicator alone; write the value on the 'description:' line itself"
      fail=1
      continue
      ;;
  esac
  if awk '/^---$/ { c++; next }
          c == 1 && found && /^[[:space:]]+[^[:space:]]/ { hit = 1; exit }
          c == 1 && found { exit }
          c == 1 && /^description:/ { found = 1 }
          END { exit !hit }' "$f"; then
    echo "FAIL: $f description continues onto an indented next line — only its first line is read, so the rest is silently dropped; write the value on one line"
    fail=1
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
      # A ' #' in an unquoted scalar starts a YAML comment: the loaded
      # description ends there, silently. Same exemptions as the colon check.
      if printf '%s' "$stripped" | grep -qE '(^|[[:space:]])#'; then
        echo "FAIL: $f description has unquoted ' #' (YAML comment — the description is truncated there) — $desc"
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
  "src/grill-me/references/adr-format.md|src/backfill-adrs/references/adr-format.md|src/adr/references/adr-format.md"
  "src/to-bug/references/tracker-resolution.md|src/to-feature/references/tracker-resolution.md|src/to-story/references/tracker-resolution.md|src/to-tasks/references/tracker-resolution.md|src/improve-design/references/tracker-resolution.md|src/chart-course/references/tracker-resolution.md|src/from-ticket/references/tracker-resolution.md|src/ship/references/tracker-resolution.md|src/backfill-adrs/references/tracker-resolution.md"
  "src/to-bug/references/publishing.md|src/to-feature/references/publishing.md|src/to-story/references/publishing.md|src/to-tasks/references/publishing.md|src/chart-course/references/publishing.md"
  "src/review-changes/references/subagent-brief.md|src/improve-design/references/subagent-brief.md|src/chart-course/references/subagent-brief.md|src/handoff/references/subagent-brief.md|src/work-item-shape/references/subagent-brief.md|src/adoption-verdict/references/subagent-brief.md|src/product-description/references/subagent-brief.md"
  "src/improve-design/references/finding-discipline.md|src/review-changes/references/finding-discipline.md"
  "src/to-bug/references/github-sub-issues.md|src/to-story/references/github-sub-issues.md|src/to-tasks/references/github-sub-issues.md|src/chart-course/references/github-sub-issues.md"
  "src/to-bug/references/work-item-tags.md|src/to-feature/references/work-item-tags.md|src/to-story/references/work-item-tags.md|src/to-tasks/references/work-item-tags.md|src/chart-course/references/work-item-tags.md"
  "src/implement/references/completion-audit.md|src/handoff/references/completion-audit.md|src/committing/references/completion-audit.md"
)

# The registry above names this repo's own paths, so byte-identity runs only
# against this repo. Under LINT_ROOT every group would report as missing and
# drown the fixture's real failures; lint-skills-selftest.sh states this gap rather
# than implying it covered the check.
if [ -z "${LINT_ROOT:-}" ]; then
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
fi

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
      echo "FAIL: $f requires '$dep', but '$dep' is user-invoked — prose invocation can only reach model-invoked Discipline skills"
      fail=1
    fi
  done
done

# Two-way requires (see header): used-but-undeclared and declared-but-unused.
for f in src/*/SKILL.md; do
  skill=$(basename "$(dirname "$f")")
  reqs=$(frontmatter_value "$f" requires | tr ',' ' ')
  body=$(awk '/^---$/ { c++; next } c >= 2' "$f")
  scan=$(printf '%s\n' "$body" | awk "$FENCE_AWK"'{ print }' | sed -e 's/"[^"]*"//g' -e 's/([^)]*→[^)]*)//g')
  # One clause can name more than one skill ("with `A` and `B`", "with `A`,
  # then again with `B`"), and the verb is written as imperative or gerund
  # ("by calling the Skill tool with"). Match the whole clause, then take
  # every backticked name out of it — a regex ending at the first name reads
  # a two-skill call as a one-skill call and leaves the second undeclared.
  for used in $(printf '%s\n' "$scan" | grep -oiE 'call(ing)? the Skill tool with `[a-z0-9-]+`(,? (and|then again with|then with|again with) `[a-z0-9-]+`)*' | grep -o '`[a-z0-9-]*`' | tr -d '`' | sort -u); do
    [ -f "src/$used/SKILL.md" ] || continue
    if [ "$(is_user_invoked "src/$used/SKILL.md")" = "true" ]; then
      echo "FAIL: $f calls the Skill tool with \`$used\`, but '$used' is user-invoked — a user-invoked skill's description is hidden from the model, so the call does nothing; suggest \`/$used\` for the human to type"
      fail=1
      continue
    fi
    [ "$used" = "$skill" ] && continue
    if ! printf ' %s ' "$reqs" | grep -q " $used "; then
      echo "FAIL: $f calls the Skill tool with \`$used\` but its requires: line does not declare '$used' — the installer will not link it"
      fail=1
    fi
  done
  for dep in $reqs; do
    if ! grep -q "\`/\{0,1\}$dep\`" <<<"$body"; then
      echo "FAIL: $f declares requires: '$dep' but the body never names it — drop the declaration, or name the skill in the body where it is used"
      fail=1
    fi
  done
done

# slash-on-model-invoked check (see header). The slash form names a command a
# human types, so it can only name a user-invoked skill or a built-in. A
# `/name` naming a model-invoked skill asks the model to type what it cannot
# type, and hides the call from the used-but-undeclared scan above. This one
# is file-local — it needs no `requires:` line — so it sweeps wider than the
# scan above: every markdown file the repo ships as instructions, not just
# `src/*/SKILL.md`. A `references/` template is where the convention regresses
# unseen, because that is what a publisher writes from.
while IFS= read -r f; do
  # Strip frontmatter where there is any; a reference file has none.
  scan=$(awk 'NR == 1 && $0 == "---" { fm = 1; next }
              fm && $0 == "---" { fm = 0; next }
              fm { next } { print }' "$f" \
    | awk "$FENCE_AWK"'{ print }' | sed -e 's/"[^"]*"//g' -e 's/([^)]*→[^)]*)//g')
  for slashed in $(printf '%s\n' "$scan" | grep -o '`/[a-z0-9-]*`' | tr -d '`/' | sort -u); do
    [ -f "src/$slashed/SKILL.md" ] || continue
    [ "$(is_user_invoked "src/$slashed/SKILL.md")" = "true" ] && continue
    echo "FAIL: $f writes \`/$slashed\`, but '$slashed' is model-invoked — the slash form is for commands a human types; use \`\`Call the Skill tool with \`$slashed\` \`\`"
    fail=1
  done
done < <({ find src -type f -name '*.md'
           [ -d .claude/skills ] && find .claude/skills -type f -name '*.md'
           [ -f DOMAIN.md ] && echo DOMAIN.md
           [ -f README.md ] && echo README.md; } | sort -u)

# Global rules admission (see header): a `Depends:` line naming skills that
# exist under src/. Names are read as backticked or bare comma-separated slugs.
for f in global/rules/*.md; do
  dep_line=$(grep -m1 -E '^Depends:' "$f" || true)
  if [ -z "$dep_line" ]; then
    echo "FAIL: $f has no 'Depends:' line — a global rule must name the skill(s) that depend on it (global/README.md admission rule), or leave global/"
    fail=1
    continue
  fi
  deps=$(printf '%s' "${dep_line#Depends:}" | tr -d '`' | tr ',' ' ')
  resolved=0
  stem=$(basename "$f" .md)
  for dep in $deps; do
    if [ -f "src/$dep/SKILL.md" ]; then
      resolved=$((resolved + 1))
      # Citation (see header): the path form or the backticked stem. The
      # bodies are captured first rather than piped straight into `grep -q`.
      # `grep -q` exits at its first match and closes the pipe; awk, which
      # writes in chunks, then takes SIGPIPE on the writes it still had to
      # make, and under `set -o pipefail` that status is the pipeline's — so
      # the check reported the *earliest* citations as missing, failing
      # loudest on the skills that cite a rule in their opening lines. Size
      # alone is not the trigger: what decides it is whether the producer
      # still has writes pending when the reader walks away, which is why a
      # single-write producer survives lengths a chunked one dies at.
      # Dropping `2>/dev/null` also lets a real read failure say so instead
      # of being read as a violation; find's status is checked separately
      # from grep's.
      if ! bodies=$(find "src/$dep" -type f -name '*.md' -exec awk "$FENCE_AWK"'{ print }' {} +); then
        echo "FAIL: $f Depends: names '$dep' but src/$dep/ could not be read, so the '$stem' citation was never checked — this is not a verdict on the citation; fix the permissions or the path and re-run"
        fail=1
      elif ! grep -qE "~/\.claude/rules/${stem}\.md|\`${stem}\`" <<<"$bodies"; then
        echo "FAIL: $f Depends: names '$dep' but src/$dep/ never cites the rule — write '~/.claude/rules/$stem.md' or the backticked stem '\`$stem\`' where the skill leans on it, or drop the name"
        fail=1
      fi
    else
      echo "FAIL: $f Depends: names '$dep' but src/$dep/SKILL.md does not exist — names are bare or backticked slugs, comma-separated; fix the name or drop it"
      fail=1
    fi
  done
  if [ "$resolved" -eq 0 ]; then
    echo "FAIL: $f Depends: resolves to no existing skill — a global rule with no dependant leaves global/ (global/README.md admission rule)"
    fail=1
  fi
done

# Every hook has a selftest (CLAUDE.md § Linting: "one selftest per hook, which
# `lint-skills.sh` enforces"): a hook is a global/hooks/*.sh whose header
# carries `# Install note:` — the marker install.sh and post-merge derive the
# roster from — and each has an executable global/hooks/<name>-selftest.sh.
# A fourth hook landing without one is the drift this replaces the
# counted-by-hand "three hooks, three selftests" line with.
if [ -d global/hooks ]; then
  for h in global/hooks/*.sh; do
    [ -f "$h" ] || continue
    grep -q '^# Install note: ' "$h" 2>/dev/null || continue
    st="${h%.sh}-selftest.sh"
    if [ ! -f "$st" ]; then
      echo "FAIL: $h carries an '# Install note:' header, so it is a hook, and has no selftest — write $st (source global/hooks/selftest-lib.sh; every hook's rules are proven by a selftest that mutates them)"
      fail=1
    elif [ ! -x "$st" ]; then
      echo "FAIL: $st is not executable — chmod +x it, so 'bash' is not the only way it runs and the roster can be run as a set"
      fail=1
    fi
  done
fi

# Every script has a selftest (see header): scripts/<name>.sh that is not a
# selftest, a library, or an installer has an executable
# scripts/<name>-selftest.sh. post-merge and sweep-corpus derive their gate
# rosters from that pairing, so a script landing without one is named here
# rather than left outside every automated run.
if [ -d scripts ]; then
  for sc in scripts/*.sh; do
    [ -f "$sc" ] || continue
    case "$sc" in *-selftest.sh | *-lib.sh | scripts/install.sh | scripts/setup-hooks.sh) continue ;; esac
    st="${sc%.sh}-selftest.sh"
    if [ ! -f "$st" ]; then
      echo "FAIL: $sc has no selftest — write $st (source scripts/selftest-lib.sh; every script in scripts/ is graded by a selftest that runs it against a fixture), or name the file *-lib.sh if it is a library"
      fail=1
    elif [ ! -x "$st" ]; then
      echo "FAIL: $st is not executable — chmod +x it, so 'bash' is not the only way it runs and the roster can be run as a set"
      fail=1
    fi
  done
fi

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
