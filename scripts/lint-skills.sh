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
# scripts/lint-skills-selftest.sh runs this file against a deliberately-bad
# fixture tree and against a clean mirror, and fails if a *covered* check stops
# firing (or starts firing on a form it must exempt). It does not cover every
# check here: its own header carries the NOT-covered list, and that list is the
# authority — several checks below can be disabled outright with the selftest
# still green. Read it before trusting a green run, and run this file's
# selftest after changing a check here.
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
#   - Shared trigger phrases (write-skill "Writing the description": a phrase
#     a sibling already carries splits the load between the two): a quoted
#     span — straight or curly double quotes — that two or more model-invoked
#     descriptions carry is reported once, naming every description that
#     quotes it. Compared case-insensitively on the text inside the quotes.
#     Scope, stated so a pass isn't read as more than it is: only DOUBLE-quoted
#     spans are compared. An unquoted or backticked trigger clause ("when a
#     build turns up a failure", `grilling`) is not read, so two descriptions
#     phrasing one trigger that way pass here — that is still the author's
#     grep. A user-invoked description is not read (the model never sees it),
#     and a phrase quoted twice inside one description is not a duplicate.
#     Only the description's TRIGGER HALF is read: the text is cut at the
#     first sentence opening "Not …", "Don't …" or "Do not …", because that
#     disambiguating tail is the form this repo prescribes for routing a
#     reader *away* to a sibling and it quotes the sibling's own phrase on
#     purpose (adoption-verdict carries a live instance). A whole-value YAML
#     quoted scalar — the form the colon check exempts — is unwrapped and its
#     `\"` unescaped first, so the spans inside it are compared like any
#     other; leaving the wrapper on made every phrase in such a description
#     miss its twin. The comparison is byte-based after a case fold, so it
#     needs the UTF-8 ctype the probe below establishes.
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
# The checks, as the named functions below, grouped by the pass that reads
# for them. Each pass reads its files once; a check is one function, so a new
# check is a function and a call, never a new walk over the same glob:
#   Pass 0 — read before any check runs, so no check's answer depends on how
#   far the pass that asks it has got: the user-invoked set (name_is_user_invoked,
#   the single predicate for that question) and both routers' text.
#   Pass 1 — every skill's frontmatter and its own body, src/*/SKILL.md:
#     check_reattach_bytes     the 15,000-byte WARN
#     check_name_field         present, <= 64 chars, mirrors the directory
#     check_description_scalar present, on one line, no block indicator
#     check_description_limits <= 1024 chars, no bare ': ' or ' #', no < >
#     check_invocation_axis    the flag and the "Use when" opener agree
#     check_requires_resolve   each declared dep exists and is model-invoked
#     check_requires_two_way   every Skill-tool call declared, every
#                              declaration named in the body
#     check_router_coverage    named in which-skill and README.md
#     collect_trigger_phrases  the quoted spans of each model-invoked
#                              description's trigger half, called in the loop
#     check_shared_trigger_phrase  the shared-trigger-phrase check: no quoted
#                              phrase carried by two model-invoked
#                              descriptions (reported once, after the loop
#                              has read every description)
#   Pass 2 — every shipped markdown file, read once: src/**, global/rules/
#   (the body checks), and for the slash sweep also .claude/skills/**,
#   DOMAIN.md, README.md:
#     check_line_cap           <= 200 lines
#     check_adr_citation       no `ADR-<digit>` token
#     check_html_transport     no HTML through the shell
#     check_reference_links    every inline .md link resolves
#     check_load_gate          no "Launching skill" under a model-invoked skill
#     check_slash_form         no `/name` naming a model-invoked skill
#   Pass 3 — the sibling-reference registry:
#     check_sibling_identity   byte-identical copies (this repo only)
#     check_sibling_membership every basename shared by two skills is grouped
#   Pass 4 — the other trees, each read once:
#     check_global_rule        Depends: resolves, and each dependant cites back
#     check_hook_selftest      every hook has an executable selftest
#     check_script_selftest    every script has an executable selftest
#   Every FAIL goes through say_fail, so the prefix and the exit status
#   cannot disagree; a WARN is printed directly and never touches the status.
#
# Usage, arguments and exit codes: `scripts/lint-skills.sh --help`, which is
# their one home — restating them here is how the two came to disagree.

set -uo pipefail

# The check roster is printed, not summarised: it is read out of this file's own
# header, between the two markers below, so --help and the header cannot come to
# disagree about what runs. Everything each check does *not* reach is in the
# header's per-check prose above that block, which --help points at rather than
# reprinting.
usage() {
  cat <<'USAGE'
Usage: scripts/lint-skills.sh [--help]

Lints src/*/SKILL.md, their references, global/rules/, global/hooks/ (one selftest per
hook), scripts/ (one selftest per script), and the two routers against the conventions in
src/write-skill/SKILL.md. Takes no argument but --help.

  LINT_ROOT=<dir>   point the whole sweep at another tree; unset in normal use
                    (scripts/lint-skills-selftest.sh sets it to the fixture roots)

USAGE
  sed -n '/^# The checks, as the named functions below/,/^#   Every FAIL goes through/p' "$0" \
    | sed '$d' | sed 's/^# \{0,1\}//'
  cat <<'USAGE'
  Every FAIL goes through say_fail, so the prefix and the exit status cannot
  disagree; a WARN is printed directly and never touches the status.

Each check's scope — what it deliberately does not reach — is written beside it in this
file's header. scripts/lint-skills-selftest.sh's header names which checks it grades and
which it does not; a green selftest is not a claim about the rest.

Exit codes: 0 clean · 1 at least one FAIL · 2 LINT_ROOT is not a directory (nothing
checked) · 3 usage error (an unknown argument, an empty one, or more than one). WARN
lines never change the exit code.
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

# The masking the header states as one rule for both scans: fenced blocks
# (FENCE_AWK), then double-quoted spans and parenthesised asides holding an
# arrow. Both scans call this, so "what counts as an example" has one home and
# the two checks cannot come to disagree about it.
mask_examples() {
  awk "$FENCE_AWK"'{ print }' | sed -e 's/"[^"]*"//g' -e 's/([^)]*→[^)]*)//g'
}

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
    # The probe has no fallback that works, so a miss is announced rather than
    # left to degrade silently. It is not only a character count any more: the
    # shared-trigger-phrase extractor matches curly quotes as literal UTF-8
    # bytes, and under a C locale the phrase inside them mangles to a byte
    # sequence that can never equal its straight-quoted twin — the check goes
    # quiet and the run still says OK.
    case "${LC_CTYPE:-}" in
      *UTF-8* | *utf8* | *UTF8*) : ;;
      *)
        echo "WARN: no UTF-8 ctype locale is available (tried C.UTF-8, en_US.UTF-8, UTF-8) — the description length check counts bytes rather than characters, and the shared-trigger-phrase check cannot match a curly-quoted span, so it may pass a phrase two descriptions share. Install a UTF-8 locale or set LC_CTYPE before trusting a clean run." >&2
        ;;
    esac
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

# Prints a FAIL line and sets the exit status to 1; every failure goes through
# here so the prefix the selftest counts and the status cannot disagree.
# scripts/lint-adrs.sh carries the same three lines under the same name; the
# two are kept in step by editorial discipline, not by a shared library —
# five shared lines across two callers do not earn one (see also
# scripts/selftest-lib.sh, which does).
say_fail() { echo "FAIL: $1"; fail=1; }

# The line numbers of a `grep -n` result, space-separated, as every FAIL that
# reports "line(s) …" renders them. Written once so the three callers cannot
# format the same field three ways.
linenos() { printf '%s\n' "$1" | cut -d: -f1 | tr '\n' ' '; }

# ---------------------------------------------------------------------------
# Pass 0 — the facts a later check needs about a file it is not currently
# reading. Everything here is read once, before any check runs, so no check's
# answer depends on where the pass that asks it has got to.
# ---------------------------------------------------------------------------

# The user-invoked set: the one predicate for "is this skill user-invoked",
# asked of the skill being read and of a *target* skill alike (a dep, a called
# name, a slash form, the owner of a reference file). A space-delimited list,
# since Darwin's bash 3.2 has no associative arrays; membership is by name,
# not path. It is an exit-status predicate, not a printing one — `if
# name_is_user_invoked x` is the correct call — and a name with no
# src/<name>/SKILL.md is not user-invoked, which every call site guards for
# separately before it asks.
user_invoked_skills=" "
name_is_user_invoked() { case "$user_invoked_skills" in *" $1 "*) return 0 ;; esac; return 1; }

# Both routers, read once. check_router_coverage runs per skill, so grepping
# the files there is two processes per skill over the same two files.
router_text=""; readme_text=""
[ -f src/which-skill/SKILL.md ] && router_text=$(cat src/which-skill/SKILL.md)
[ -f README.md ] && readme_text=$(cat README.md)

for f in src/*/SKILL.md; do
  skill=${f#src/}; skill=${skill%/SKILL.md}
  [ "$(frontmatter_value "$f" disable-model-invocation)" = "true" ] &&
    user_invoked_skills="$user_invoked_skills$skill "
done

# ---------------------------------------------------------------------------
# Pass 1 — every skill's frontmatter and its own body, read once each.
# ---------------------------------------------------------------------------

# (see header) Re-attach bound, as bytes. A WARN, not a FAIL: the cap is the
# platform's and moves with it; what the author owes is ordering — the rules
# a body cannot afford to lose sit early — or a smaller body. Measured before
# the description checks so a body with a broken description is still measured.
check_reattach_bytes() {
  local f=$1 bytes
  bytes=$(wc -c < "$f" | tr -d ' ')
  if [ "$bytes" -gt 15000 ]; then
    echo "WARN: $f is $bytes bytes (~$((bytes / 3)) tokens at 3 bytes/token) — past the 5,000-token re-attach bound Claude Code keeps per skill after auto-compaction, so its tail is what a re-attach drops; put its hard stops and close-out steps above its long sections, or move detail into references/"
  fi
}

# Single-line scalar (see header): frontmatter_value reads one line, and so
# does every consumer that truncates. A block indicator — `>` or `|` with
# any chomping, indentation, or comment suffix — is the whole value it would
# read; a plain scalar continued on an indented line loses its tail.
# Returns 1 where there is no description worth checking further — absent, or
# a block indicator — so the caller skips the checks that read the value; a
# continued scalar fails but returns 0, since its first line is still a value.
check_description_scalar() {
  local f=$1 desc=$2
  if [ -z "$desc" ]; then
    say_fail "$f has no description in frontmatter — add 'description:' to the YAML block"
    return 1
  fi
  case "$desc" in
    '>'* | '|'*)
      say_fail "$f description is a YAML block scalar ('$desc') — read one line at a time, the description is the indicator alone; write the value on the 'description:' line itself"
      return 1
      ;;
  esac
  if awk '/^---$/ { c++; next }
          c == 1 && found && /^[[:space:]]+[^[:space:]]/ { hit = 1; exit }
          c == 1 && found { exit }
          c == 1 && /^description:/ { found = 1 }
          END { exit !hit }' "$f"; then
    say_fail "$f description continues onto an indented next line — only its first line is read, so the rest is silently dropped; write the value on one line"
  fi
  return 0
}

# The description's caps (see header): <= 1024 chars; no bare ': ' or ' #',
# both of which end an unquoted YAML scalar early; no angle brackets, which
# the platform spec disallows in the field.
check_description_limits() {
  local f=$1 desc=$2 len stripped
  len=${#desc}
  if [ "$len" -gt 1024 ]; then
    say_fail "$f description exceeds 1024 chars ($len) — trim triggers; collapse synonym branches"
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
        say_fail "$f description has unquoted ': ' (use em-dash) — $desc"
      fi
      # A ' #' in an unquoted scalar starts a YAML comment: the loaded
      # description ends there, silently. Same exemptions as the colon check.
      if printf '%s' "$stripped" | grep -qE '(^|[[:space:]])#'; then
        say_fail "$f description has unquoted ' #' (YAML comment — the description is truncated there) — $desc"
      fi
      ;;
  esac
  case "$desc" in
    *[\<\>]*)
      say_fail "$f description contains angle brackets (< or >) — disallowed in the description field"
      ;;
  esac
}

# Required name (write-skill template): `name:` must exist and mirror the
# skill's directory. Platform-true spec limits (ADR-0030): Claude Code
# truncates/chokes on the same two caps the packaging spec enforces; the
# spec's other rules don't apply.
check_name_field() {
  local f=$1 name_val dir_slug
  name_val=$(frontmatter_value "$f" name)
  dir_slug=${f#src/}; dir_slug=${dir_slug%/SKILL.md}
  if [ -z "$name_val" ]; then
    say_fail "$f has no name in frontmatter (write-skill template requires name: $dir_slug)"
    return
  fi
  if [ "${#name_val}" -gt 64 ]; then
    say_fail "$f name exceeds 64 chars (${#name_val})"
  fi
  if [ "$name_val" != "$dir_slug" ]; then
    say_fail "$f name '$name_val' does not match its directory '$dir_slug' (write-skill template: name mirrors the skill-name/ directory)"
  fi
}

# Invocation axis (ADR-0015). A skill is user-invoked iff its frontmatter
# carries `disable-model-invocation: true`. The trigger marker is the
# normative "Use when/after/only" opener write-skill mandates (leading
# word-start avoids matching "reuse"); user-invoked must lack it,
# model-invoked must have it.
check_invocation_axis() {
  local f=$1 desc=$2 dmi=$3 has_trigger
  if printf '%s' "$desc" | grep -qE '(^| )[Uu]se (this skill |this |the )?(when|after|only)'; then
    has_trigger=1
  else
    has_trigger=0
  fi
  if [ "$dmi" = "true" ]; then
    if [ "$has_trigger" -eq 1 ]; then
      say_fail "$f is user-invoked (disable-model-invocation: true) but its description carries a 'Use when…' trigger list — make it human-facing (the model never sees it)"
    fi
  else
    if [ "$has_trigger" -eq 0 ]; then
      say_fail "$f is model-invoked but its description has no 'Use when…' trigger phrasing — auto-invocation needs it (or set disable-model-invocation: true)"
    fi
  fi
}

# Declared dependencies (ADR-0016): every name in a `requires:` line must
# resolve to a skill that exists and is model-invoked.
check_requires_resolve() {
  local f=$1 reqs=$2 dep depfile
  for dep in $reqs; do
    depfile="src/$dep/SKILL.md"
    if [ ! -f "$depfile" ]; then
      say_fail "$f requires '$dep' but src/$dep/SKILL.md does not exist"
      continue
    fi
    if name_is_user_invoked "$dep"; then
      say_fail "$f requires '$dep', but '$dep' is user-invoked — prose invocation can only reach model-invoked Discipline skills"
    fi
  done
}

# Two-way requires (see header): used-but-undeclared and declared-but-unused.
check_requires_two_way() {
  local f=$1 skill=$2 reqs=$3 body=$4 scan used dep
  scan=$(printf '%s\n' "$body" | mask_examples)
  # One clause can name more than one skill ("with `A` and `B`", "with `A`,
  # then again with `B`"), and the verb is written as imperative or gerund
  # ("by calling the Skill tool with"). Match the whole clause, then take
  # every backticked name out of it — a regex ending at the first name reads
  # a two-skill call as a one-skill call and leaves the second undeclared.
  for used in $(printf '%s\n' "$scan" | grep -oiE 'call(ing)? the Skill tool with `[a-z0-9-]+`(,? (and|then again with|then with|again with) `[a-z0-9-]+`)*' | grep -o '`[a-z0-9-]*`' | tr -d '`' | sort -u); do
    [ -f "src/$used/SKILL.md" ] || continue
    if name_is_user_invoked "$used"; then
      say_fail "$f calls the Skill tool with \`$used\`, but '$used' is user-invoked — a user-invoked skill's description is hidden from the model, so the call does nothing; suggest \`/$used\` for the human to type"
      continue
    fi
    [ "$used" = "$skill" ] && continue
    if ! printf ' %s ' "$reqs" | grep -q " $used "; then
      say_fail "$f calls the Skill tool with \`$used\` but its requires: line does not declare '$used' — the installer will not link it"
    fi
  done
  for dep in $reqs; do
    if ! grep -q "\`/\{0,1\}$dep\`" <<<"$body"; then
      say_fail "$f declares requires: '$dep' but the body never names it — drop the declaration, or name the skill in the body where it is used"
    fi
  done
}

# Router coverage (see header); the trailing class keeps a name from
# matching inside a longer slug (`adr` never matches `backfill-adrs`).
# README.md's skill map is a second router — every skill must appear there
# as a backticked code-span, same rule, so an added, renamed, or removed
# skill can't leave the README lying. Blurb accuracy stays editorial.
check_router_coverage() {
  local name=$1 router="src/which-skill/SKILL.md" readme="README.md"
  if [ "$name" != "which-skill" ] && ! grep -qE "\`/?${name}([^a-z0-9-]|$)" <<<"$router_text"; then
    say_fail "$router has no backticked mention of skill '$name' — route it or list it as standalone (CLAUDE.md: 'Keep the router honest')"
  fi
  if ! grep -qE "\`/?${name}([^a-z0-9-]|$)" <<<"$readme_text"; then
    say_fail "$readme has no backticked mention of skill '$name' — list it in the README skill map (CLAUDE.md: 'Keep the router honest')"
  fi
}

# Shared trigger phrases (see header). Pass 1 collects `phrase<tab>skill` rows
# from every model-invoked description — the quoted spans of its trigger half,
# lowercased — and the check runs once the loop has read them all, since a
# duplicate is a fact about the set and no single description can show it. A
# set-level check is the one shape that is not "one function, one call": a
# collector called inside the pass, and the check called after it, taking the
# collected rows as its argument so it is still driven without the loop.
trigger_phrases=""
collect_trigger_phrases() {
  local desc=$1 skill=$2 p
  # A whole-value YAML quote is not a trigger span: check_description_limits
  # exempts that form deliberately (a quoted scalar may hold a bare ': '), and
  # reading its wrapper as a span yields the whole description as one phrase
  # plus junk. Unwrap it first, and unescape the `\"` a double-quoted scalar
  # must use for the very spans this check compares — leaving the backslash on
  # makes every phrase in such a description miss its twin.
  case "$desc" in
    \"*\") desc=${desc#?}; desc=${desc%?}; desc=${desc//\\\"/\"} ;;
    \'*\') desc=${desc#?}; desc=${desc%?} ;;
  esac
  # Only the trigger half is compared. A disambiguating tail — the sentence
  # opening "Not …" or "Don't …" that write-skill prescribes for routing a
  # reader *away* to a sibling — legitimately quotes the sibling's own phrase
  # (Not for casual technology curiosity ("what is X?" — answer normally)),
  # and flagging that is telling the author to delete the routing. Cut from the
  # first such sentence; the convention puts them last.
  desc=$(printf '%s' "$desc" | sed -E "s/(^|\. |; )(Not |Don't |Don’t |Do not ).*//")
  while IFS= read -r p; do
    trigger_phrases="$trigger_phrases$p"$'\t'"$skill"$'\n'
  done < <(printf '%s\n' "$desc" | grep -oE '"[^"]+"|“[^”]+”' | sed -e 's/^[“"]//' -e 's/[”"]$//' | tr '[:upper:]' '[:lower:]')
}
# Takes the collected rows rather than reading the global, so the check can be
# driven with a row set of any shape without running the whole of pass 1.
check_shared_trigger_phrase() {
  local rows=$1 phrase files
  while IFS=$'\t' read -r phrase files; do
    say_fail "$files carry the same quoted trigger phrase \"$phrase\" in their descriptions — a phrase two or more model-invoked descriptions carry splits the load between them; one of them keeps it and the rest rephrase, and which is the author's call (write-skill § Writing the description)"
  done < <(printf '%s' "$rows" | sort -u | awk -F'\t' '
      { n[$1]++; who[$1] = (who[$1] == "" ? "" : who[$1] " ") "src/" $2 "/SKILL.md" }
      END { for (p in n) if (n[p] > 1) print p "\t" who[p] }' | sort)
}

for f in src/*/SKILL.md; do
  skill=${f#src/}; skill=${skill%/SKILL.md}
  desc=$(frontmatter_value "$f" description)
  dmi=""; name_is_user_invoked "$skill" && dmi=true
  [ "$dmi" = "true" ] || collect_trigger_phrases "$desc" "$skill"
  reqs=$(frontmatter_value "$f" requires | tr ',' ' ')
  body=$(awk '/^---$/ { c++; next } c >= 2' "$f")

  check_reattach_bytes "$f"
  check_name_field "$f"
  # Only the checks that read the description's *value* are gated: where there
  # is no single-line value, check_description_scalar has said so and there is
  # nothing to measure. Every check that does not read it — the byte WARN,
  # `name:`, requires: both ways, router coverage — runs regardless, so one
  # broken description cannot hide a second defect in the same file.
  if check_description_scalar "$f" "$desc"; then
    check_description_limits "$f" "$desc"
    check_invocation_axis "$f" "$desc" "$dmi"
  fi
  [ -n "$reqs" ] && check_requires_resolve "$f" "$reqs"
  check_requires_two_way "$f" "$skill" "$reqs" "$body"
  check_router_coverage "$skill"
done
check_shared_trigger_phrase "$trigger_phrases"

# ---------------------------------------------------------------------------
# Pass 2 — every shipped markdown file, read once. The body checks run over
# src/** and global/rules/; the slash sweep runs over src/**, .claude/skills/**,
# DOMAIN.md and README.md (see header for why its scope is the wider one).
# ---------------------------------------------------------------------------

check_line_cap() {
  local f=$1 lines
  lines=$(awk 'END { print NR }' "$f")
  if [ "$lines" -gt 200 ]; then
    say_fail "$f exceeds 200-line cap ($lines lines) — cut or move detail into references/; never raise the cap"
  fi
}

check_adr_citation() {
  local f=$1 adr_hits badlines
  adr_hits=$(grep -niE '\bADR-[0-9]' "$f")
  if [ -n "$adr_hits" ]; then
    badlines=$(linenos "$adr_hits")
    say_fail "$f cites a repo ADR by number (line(s) ${badlines}) — skill bodies must not (write-skill: 'Skill bodies don't cite repo ADRs'); lineage is ADR -> skill"
  fi
}

# Rich-text transport (see header): converted HTML reaches the tracker CLI
# as `@<file>`, never through the shell.
check_html_transport() {
  local f=$1 shell_hits badlines
  shell_hits=$(grep -nE '\$\(cat [^)]*\.html\)|--description "<html>"|=<html>"|temp file plus command substitution' "$f")
  if [ -n "$shell_hits" ]; then
    badlines=$(linenos "$shell_hits")
    say_fail "$f passes HTML through the shell (line(s) ${badlines}) — write the converted HTML to a file and pass its path as \`@<file>\` (publishing.md '## Transport safety'); a shell string mangles the body and hides a missing file"
  fi
}

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
check_reference_links() {
  local f=$1 dir link_targets lineno target
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
    say_fail "$f — the reference-link extractor errored, so no link in this file was checked; fix the awk block in scripts/lint-skills.sh"
    link_targets=""
  fi

  while IFS=$'\t' read -r lineno target; do
    [ -z "$target" ] && continue
    case "$target" in
      *://* | /* | \#*) continue ;;
    esac
    if [ ! -f "$dir/${target%%#*}" ]; then
      say_fail "$f links to '$target' (line $lineno), which resolves to no file — create $dir/${target%%#*}, fix the path, or drop the link; a pointer to a missing reference silently loads nothing at runtime"
    fi
  done <<< "$link_targets"
}

# Load-gate placement (see header): the "Launching skill" marker phrase must
# not appear anywhere in a model-invoked skill — body or references. The
# caller has already established that the file sits under a model-invoked
# skill's directory.
check_load_gate() {
  local f=$1 gate_hits badlines
  gate_hits=$(grep -n 'Launching skill' "$f")
  if [ -n "$gate_hits" ]; then
    badlines=$(linenos "$gate_hits")
    say_fail "$f carries a load gate ('Launching skill', line(s) ${badlines}) inside a model-invoked skill — no watcher, a miss must degrade gracefully (write-skill: 'Never gate inside a model-invoked skill')"
  fi
}

# slash-on-model-invoked check (see header). The slash form names a command a
# human types, so it can only name a user-invoked skill or a built-in. A
# `/name` naming a model-invoked skill asks the model to type what it cannot
# type, and hides the call from the used-but-undeclared scan in pass 1. This
# one is file-local — it needs no `requires:` line — so it sweeps wider than
# that scan: every markdown file the repo ships as instructions, not just
# `src/*/SKILL.md`. A `references/` template is where the convention regresses
# unseen, because that is what a publisher writes from.
check_slash_form() {
  local f=$1 scan slashed
  # Strip frontmatter where there is any; a reference file has none.
  scan=$(awk 'NR == 1 && $0 == "---" { fm = 1; next }
              fm && $0 == "---" { fm = 0; next }
              fm { next } { print }' "$f" \
    | mask_examples)
  for slashed in $(printf '%s\n' "$scan" | grep -o '`/[a-z0-9-]*`' | tr -d '`/' | sort -u); do
    [ -f "src/$slashed/SKILL.md" ] || continue
    name_is_user_invoked "$slashed" && continue
    say_fail "$f writes \`/$slashed\`, but '$slashed' is model-invoked — the slash form is for commands a human types; use \`\`Call the Skill tool with \`$slashed\` \`\`"
  done
}

# One walk. A find sweep (rather than a fixed-depth glob) covers nested
# reference files (references/sub/*.md) too. Which checks a file gets is
# decided by where it sits: the body checks for src/** and global/rules/,
# the load-gate check for a file under a model-invoked skill's directory,
# the slash sweep for everything but global/rules/.
while IFS= read -r f; do
  case "$f" in
    src/* | global/rules/*)
      check_line_cap "$f"
      check_adr_citation "$f"
      check_html_transport "$f"
      check_reference_links "$f"
      ;;
  esac
  case "$f" in
    src/*/*)
      owner=${f#src/}; owner=${owner%%/*}
      if [ -f "src/$owner/SKILL.md" ] && ! name_is_user_invoked "$owner"; then
        check_load_gate "$f"
      fi
      ;;
  esac
  case "$f" in
    global/rules/*) ;;
    *) check_slash_form "$f" ;;
  esac
done < <({ find src -type f -name '*.md'
           [ -d global/rules ] && find global/rules -type f -name '*.md'
           [ -d .claude/skills ] && find .claude/skills -type f -name '*.md'
           [ -f DOMAIN.md ] && echo DOMAIN.md
           [ -f README.md ] && echo README.md; } | sort -u)

# ---------------------------------------------------------------------------
# Pass 3 — the sibling-reference registry.
# ---------------------------------------------------------------------------

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
check_sibling_identity() {
  local group files ref other
  for group in "${sibling_groups[@]}"; do
    IFS='|' read -ra files <<< "$group"
    ref="${files[0]}"
    if [ ! -f "$ref" ]; then
      say_fail "sibling reference $ref is missing"
      continue
    fi
    for other in "${files[@]:1}"; do
      if [ ! -f "$other" ]; then
        say_fail "sibling reference $other is missing"
      elif ! cmp -s "$ref" "$other"; then
        say_fail "$other drifted from $ref (per ADR-0007 these must stay byte-identical)"
      fi
    done
  done
}

# Sibling-group membership: any reference basename that exists under two or
# more skills must be governed by a group above — an unlisted copy sits outside
# the byte-identity check and drifts silently, the exact failure that check
# exists to prevent. A deliberate variant needs a distinct name (or its own
# group entry).
check_sibling_membership() {
  local grouped_basenames base
  grouped_basenames=$(printf '%s|' "${sibling_groups[@]}" | tr '|' '\n' | awk -F/ 'NF { print $NF }' | sort -u)
  while IFS= read -r base; do
    if ! printf '%s\n' "$grouped_basenames" | grep -qxF "$base"; then
      say_fail "reference file '$base' exists in multiple skills but no sibling group covers it — add it to sibling_groups in scripts/lint-skills.sh, or rename the deliberate variant"
    fi
  done < <(find src -path '*/references/*' -type f -name '*.md' | awk -F/ '{ print $NF }' | sort | uniq -d)
}

[ -z "${LINT_ROOT:-}" ] && check_sibling_identity
check_sibling_membership

# ---------------------------------------------------------------------------
# Pass 4 — the other trees, each read once.
# ---------------------------------------------------------------------------

# Global rules admission (see header): a `Depends:` line naming skills that
# exist under src/. Names are read as backticked or bare comma-separated slugs.
check_global_rule() {
  local f=$1 dep_line deps resolved stem dep bodies
  dep_line=$(grep -m1 -E '^Depends:' "$f" || true)
  if [ -z "$dep_line" ]; then
    say_fail "$f has no 'Depends:' line — a global rule must name the skill(s) that depend on it (global/README.md admission rule), or leave global/"
    return
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
        say_fail "$f Depends: names '$dep' but src/$dep/ could not be read, so the '$stem' citation was never checked — this is not a verdict on the citation; fix the permissions or the path and re-run"
      elif ! grep -qE "~/\.claude/rules/${stem}\.md|\`${stem}\`" <<<"$bodies"; then
        say_fail "$f Depends: names '$dep' but src/$dep/ never cites the rule — write '~/.claude/rules/$stem.md' or the backticked stem '\`$stem\`' where the skill leans on it, or drop the name"
      fi
    else
      say_fail "$f Depends: names '$dep' but src/$dep/SKILL.md does not exist — names are bare or backticked slugs, comma-separated; fix the name or drop it"
    fi
  done
  if [ "$resolved" -eq 0 ]; then
    say_fail "$f Depends: resolves to no existing skill — a global rule with no dependant leaves global/ (global/README.md admission rule)"
  fi
}

for f in global/rules/*.md; do
  check_global_rule "$f"
done

# Every hook has a selftest (CLAUDE.md § Linting: "one selftest per hook, which
# `lint-skills.sh` enforces"): a hook is a global/hooks/*.sh whose header
# carries `# Install note:` — the marker install.sh and post-merge derive the
# roster from — and each has an executable global/hooks/<name>-selftest.sh.
# A fourth hook landing without one is the drift this replaces the
# counted-by-hand "three hooks, three selftests" line with.
# The pairing itself, for both callers: <file>.sh needs an executable
# <file>-selftest.sh beside it. The two checks differ only in who is eligible
# and in what the missing-selftest line should say, so that is all each passes
# in — the shared half is written once, and each FAIL line still greps back to
# exactly one call site because `$kind` is in it.
require_selftest() {
  local f=$1 kind=$2 what=$3 tail=$4 st
  # `st` is assigned on its own line: `local a=$1 b=${a%x}` expands every word
  # before the builtin assigns any of them, so `b` would read an outer `a`.
  st="${f%.sh}-selftest.sh"
  if [ ! -f "$st" ]; then
    say_fail "$f $what — write $st $tail"
  elif [ ! -x "$st" ]; then
    say_fail "$st is not executable — chmod +x it, so 'bash' is not the only way this $kind's selftest runs and the roster can be run as a set"
  fi
}

check_hook_selftest() {
  local h=$1
  grep -q '^# Install note: ' "$h" 2>/dev/null || return 0
  require_selftest "$h" hook "carries an '# Install note:' header, so it is a hook, and has no selftest" "(source global/hooks/selftest-lib.sh; every hook's rules are proven by a selftest that mutates them)"
}

# Every script has a selftest (see header): scripts/<name>.sh that is not a
# selftest, a library, or an installer has an executable
# scripts/<name>-selftest.sh. post-merge and sweep-corpus derive their gate
# rosters from that pairing, so a script landing without one is named here
# rather than left outside every automated run.
check_script_selftest() {
  local sc=$1
  case "$sc" in *-selftest.sh | *-lib.sh | scripts/install.sh | scripts/setup-hooks.sh) return 0 ;; esac
  require_selftest "$sc" script "has no selftest" "(source scripts/selftest-lib.sh; every script in scripts/ is graded by a selftest that runs it against a fixture), or name the file *-lib.sh if it is a library"
}

if [ -d global/hooks ]; then
  for h in global/hooks/*.sh; do
    [ -f "$h" ] && check_hook_selftest "$h"
  done
fi
if [ -d scripts ]; then
  for sc in scripts/*.sh; do
    [ -f "$sc" ] && check_script_selftest "$sc"
  done
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
