#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Lint the skill tree against the conventions in src/write-skill/SKILL.md, and
# the trees beside it — global/rules/, global/hooks/, scripts/ and
# scripts/git-hooks/, and the root CLAUDE.md — against the rules each cites:
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
#     check global/hooks/, the script-selftest check scripts/ and
#     scripts/git-hooks/ (only those two directories: a skill-private script
#     under .claude/skills/*/scripts/ is walked by no check here and owes no
#     selftest). The repo-local
#     skills under .claude/skills/, and DOMAIN.md and README.md, are in pass
#     2's walk for the slash sweep and the evaluation-ledger consumer sweep
#     and for nothing else: the hoisting, size, frontmatter, ADR-citation,
#     HTML-transport and reference-link checks do not read them. They never
#     hoist, so the router-coverage and requires checks would demand mentions
#     that do not belong, and they legitimately cite this repo's paths. Their
#     size and frontmatter are the author's to keep; a pass here says nothing
#     about those. CLAUDE.md is read by two checks — its byte WARN, and the
#     reference-link resolution pass 4 points at the root file — and by
#     nothing else.
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
#   - Single-line description (write-skill references/descriptions.md
#     "Frontmatter pitfalls": the `description:` value sits on its own
#     line): a plain scalar. A block
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
#   - CLAUDE.md byte WARN (ADR-0076): a CLAUDE.md at the root over 6,000
#     bytes draws a WARN, never a FAIL — a round bound roughly 2.4 times the
#     2,471 bytes the 2026-08-30 cut left it at and just over a third of the
#     16,672 it cut from, so a regrowth is named on every run before it is a
#     problem. Only the root file is measured; a nested CLAUDE.md is not
#     walked, and a root with none draws nothing. The same root file also goes
#     through check_reference_links — pass 2's parser reused, not a second
#     extractor — because ADR-0076 left CLAUDE.md as triggers and pointers,
#     and a pointer to a missing file silently loads nothing: a relative .md
#     link naming no file is a FAIL naming the link and the target, under
#     pass 2's stated scope and exemptions.
#   - Hook selftest (global/README.md § Hooks: "Each hook has a `*-selftest.sh`
#     beside it"): every global/hooks/*.sh whose header carries
#     an `# Install note:` line — the marker install.sh and post-merge derive
#     the hook roster from, so all three answer "what is a hook" the same way —
#     has an executable global/hooks/<name>-selftest.sh beside it. A file with
#     no marker is a library or a selftest and owes nothing.
#   - Script selftest (ADR-0068: every selftest is `<script>-selftest.sh`):
#     every scripts/<name>.sh that is not itself a selftest, a `*-lib.sh`, or
#     one of the two installers (install.sh, setup-hooks.sh, by basename) has
#     an executable scripts/<name>-selftest.sh beside it, so a gate landing
#     without one is named here rather than silently ungated. Under
#     scripts/git-hooks/ a file is a git hook when its first line is a shebang
#     (a README or a sample there is not walked); each git hook carries no
#     .sh, is held to the same pairing, and must itself be executable, since
#     git skips a hook without the exec bit silently (ADR-0076); post-merge
#     derives its roster from both directories.
#   - Conventions pointer (scripts/README.md is the tree's rule file): every
#     file those two walks visit — scripts/*.sh, and every git hook and
#     selftest under scripts/git-hooks/ — carries the line
#     `# Conventions for this tree: scripts/README.md` as line 2 when line 1
#     is a shebang, and as line 1 otherwise (a sourced library has no
#     shebang), so an agent that opens the script instead of CLAUDE.md is
#     pointed at the rules that bind it.
#   - Evaluation ledger statuses (ADR-0071; DOMAIN.md's Evaluation-ledger row):
#     one file defines the legend, the body's stored-status rule defines the
#     same three, and any other file naming two of the three names all three.
#     All three checks find their authority by CONTENT — the legend line and
#     the rule phrase, wherever they live — never by path, so a deliberate
#     rename is followed rather than today's spelling pinned, and the checks
#     are portable to a fixture root. Scope, stated so a pass isn't read as
#     more than it is. They do not police a fourth status invented in a
#     consumer: the anchored lines legitimately carry other backticked
#     lowercase words (`awaiting:`, `sources/`, an ID, a path), and no marker
#     separates a status token from those, so a closed-set assertion would
#     false-positive on prose that is fine. They read backticked spans only,
#     so the bare forms in the memo's counts stamp are outside them, and they
#     read past fenced examples, so a worked example of the ledger's own
#     format is prose about the vocabulary rather than an enumeration of it.
#     And they cannot see a definition reworded without a rename — but a
#     reword that leaves no legend or no rule site is a FAIL in this repo
#     rather than a silent stand-down, and each anchor sentence carries a note
#     in its own file saying it is load-bearing.
#   - Router coverage (CLAUDE.md § Adding, renaming, or removing a skill:
#     update both in the same change): every skill under
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
#   Pass 3 — cross-file contracts, read from pass 2's captured walk:
#     check_sibling_identity   byte-identical copies (this repo only)
#     check_sibling_membership every basename shared by two skills is grouped
#     check_evaluation_ledger_authority       one legend, defining three statuses
#     check_evaluation_ledger_rule_agreement  the body's stored-status rule
#                              defines the same set as the legend
#     check_evaluation_ledger_consumers       a file that enumerates the
#                              vocabulary carries all of it
#   Pass 4 — the other trees, each read once:
#     check_global_rule        Depends: resolves, and each dependant cites back
#     check_hook_selftest      every hook has an executable selftest
#     check_script_selftest    every script, and every git hook, has an
#                              executable selftest, and opens with the
#                              conventions pointer; a git hook is executable
#     check_claude_md_bytes    the 6,000-byte CLAUDE.md WARN
#     check_reference_links    every relative .md link in the root CLAUDE.md
#                              resolves (pass 2's parser, pointed at the
#                              root file)
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

Lints src/*/SKILL.md and their references against src/write-skill/SKILL.md, and
global/rules/, global/hooks/ (one selftest per hook), scripts/ and scripts/git-hooks/
(one selftest per script or hook, and the conventions pointer), CLAUDE.md's size and
its relative links, and the two routers against the rules each cites. Takes no
argument but --help.

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
# warn_bytes <file> <limit> <tail>: the one shape both byte WARNs share — a
# count, a bound, a WARN that never touches `fail`. A file that cannot be
# counted is a FAIL, not a silent pass: an empty count would otherwise skip
# the comparison and read as under the bound.
warn_bytes() {
  local f=$1 limit=$2 tail=$3 bytes
  bytes=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  if [ -z "$bytes" ]; then
    say_fail "$f could not be read for its byte count — the $limit-byte WARN did not run on it"
    return
  fi
  if [ "$bytes" -gt "$limit" ]; then
    echo "WARN: $f is $bytes bytes — $tail"
  fi
}

check_reattach_bytes() {
  warn_bytes "$1" 15000 "past the 5,000-token re-attach bound (at 3 bytes/token) Claude Code keeps per skill after auto-compaction, so its tail is what a re-attach drops; put its hard stops and close-out steps above its long sections, or move detail into references/"
}

# (see header) CLAUDE.md byte WARN. A WARN, not a FAIL, on the re-attach
# precedent: the number is a regrowth alarm, not a platform cap, and a commit
# whose growth is legitimate is not blocked by it — only named. Called once,
# at the end of pass 4, on the root file when there is one.
check_claude_md_bytes() {
  warn_bytes "$1" 6000 "past the 6,000-byte bound ADR-0076 set for the always-loaded file; keep only triggers and contracts here, and move the rest behind a pointer (docs/lineage.md, scripts/README.md, an ADR)"
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
    say_fail "$router has no backticked mention of skill '$name' — route it or list it as standalone (CLAUDE.md § Adding, renaming, or removing a skill: update it and README.md's skill map in the same change)"
  fi
  if ! grep -qE "\`/?${name}([^a-z0-9-]|$)" <<<"$readme_text"; then
    say_fail "$readme has no backticked mention of skill '$name' — list it in the README skill map (CLAUDE.md § Adding, renaming, or removing a skill: update it and src/which-skill/SKILL.md in the same change)"
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
  # The count is taken from a checked read: awk on an unreadable file prints
  # nothing and the comparison below would then error and leave the cap
  # unapplied, which reads exactly like a file that came in under it.
  if ! lines=$(awk 'END { print NR }' "$f") || [ -z "$lines" ]; then
    say_fail "$f could not be read for its line count — the 200-line cap was not applied to it"
    return 0
  fi
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

# One walk, produced once and passed to every consumer. Pass 2 classifies it
# file by file; pass 3's checks need the same list as a whole, and re-running
# the find there would be a second walk that could silently disagree with this
# one. A find sweep rather than a fixed-depth glob, so nested reference files
# (references/sub/*.md) are covered too.
#
# The set of classes this emits is closed, and the classifier below fails on a
# path no arm claims — so adding a tree here without giving it an arm is a
# loud error rather than a class that silently gets one check.
walk_shipped_md() {
  { find src -type f -name '*.md'
    [ -d global/rules ] && find global/rules -type f -name '*.md'
    [ -d .claude/skills ] && find .claude/skills -type f -name '*.md'
    [ -f DOMAIN.md ] && echo DOMAIN.md
    [ -f README.md ] && echo README.md; } | sort -u
}
walked_files=$(walk_shipped_md)

# The four body checks, named once. Spelling them out per arm put the same
# four calls in three places, and a cell dropped from one arm reads identically
# to one that never ran there.
body_checks() {
  check_line_cap "$1"
  check_adr_citation "$1"
  check_html_transport "$1"
  check_reference_links "$1"
}

# One classifier, and it is exhaustive because the last arm says so rather
# than because a catch-all absorbs the remainder: a file the walk emits and no
# arm claims is a FAIL naming itself. Each arm names that class's whole check
# set, so "what runs on a rule file?" is one arm and not three blocks.
# Arms run most-specific first.
#
# In `case`, `*` matches `/` — so `src/*` is any depth under src/ and `src/*/*`
# is depth two or more. That is what separates a skill's own files (which have
# an owning SKILL.md to gate the load check on) from a bare src/*.md.
#
# The walk is guarded rather than fed straight in: `printf '%s\n' ""` emits one
# empty line, so an empty walk would otherwise run one iteration with an empty
# filename and hand `""` to the checks.
if [ -n "$walked_files" ]; then
while IFS= read -r f; do
  case "$f" in
    global/rules/*)
      # Hoisted prose. Body checks, and deliberately no slash sweep: a rule
      # file addresses the model directly and names no skill as a command.
      body_checks "$f"
      ;;
    src/*/*)
      # A skill's own SKILL.md or a reference beneath it. Everything.
      body_checks "$f"
      owner=${f#src/}; owner=${owner%%/*}
      if [ -f "src/$owner/SKILL.md" ] && ! name_is_user_invoked "$owner"; then
        check_load_gate "$f"
      fi
      check_slash_form "$f"
      ;;
    src/*)
      # Depth one under src/: no owning skill, so no load gate to apply.
      body_checks "$f"
      check_slash_form "$f"
      ;;
    .claude/skills/* | DOMAIN.md | README.md)
      # Swept for the slash form only; their size and frontmatter are the
      # author's (see header Scope).
      check_slash_form "$f"
      ;;
    *)
      say_fail "walk_shipped_md emitted $f and no classifier arm claims it — add an arm naming that class's whole check set, or drop the tree from the walk; an unclaimed file would otherwise be graded by nothing"
      ;;
  esac
done < <(printf '%s\n' "$walked_files")
fi

# ---------------------------------------------------------------------------
# Pass 3 — cross-file contracts: the sibling-reference registry, and the
# evaluation ledger's stored-status vocabulary.
# ---------------------------------------------------------------------------

# The evaluation ledger's stored statuses are one vocabulary defined in two
# places and prescribed in six more, and nothing checked either direction:
# rename one in the legend and `adoption-verdict` goes on telling a grader to
# look for a status no ledger will ever carry again.
#
# The authority is found by CONTENT, never by path — the legend line, wherever
# it lives. That is what makes this follow a deliberate rename instead of
# pinning today's spelling, and what makes it portable to a fixture root.
#
# Three checks, not one, and each is reachable on its own: a tree with two
# legends still gets its consumers swept, which a single short-circuiting
# function could not do. `find_evaluation_ledger_legend` is the one discovery
# they share.
#
# The two English sentences these anchor on — the legend's "Status is exactly
# one of:" and the body rule's "Exactly one stored status" — are machine
# contracts, and each anchor site says so in its own file, because a reword
# here is exactly the edit that would otherwise turn the checks off in silence.
# Discovery finding nothing is a FAIL in this repo (LINT_ROOT unset), never a
# quiet pass.
evaluation_ledger_anchor_re='docs/evaluation/|evaluation-ledger|[Ee]valuation ledger|ledger\.md'

# file -> its whole text; rc 2 and no output if the file cannot be read, so a
# read failure never reads as "no violations".
readable_text() {
  local raw
  raw=$(cat -- "$1") || return 2
  printf '%s\n' "$raw"
}

# file, line-matching regex -> the lowercase backticked status tokens on the
# lines that match, sorted and deduplicated, so two results compare as sets
# (the legend-versus-rule test is a raw string compare and is only a SET
# comparison because of that sort). Matches `[a-z][a-z-]*` only, so a
# `Verified` or a `not_started` is invisible to it. rc 2 and no output if the
# file cannot be read; empty output and rc 0 if nothing matched.
#
# Read RAW, deliberately: both callers anchor on a specific sentence, and in
# this repo the legend sentence itself sits inside a fenced block because
# `ledger-format.md` shows the row format it is describing. Masking here would
# find no legend at all. The whole-file sweep below is the one that has to
# tell prose from example, and it is the one that masks.
status_tokens_on() {
  local text
  text=$(readable_text "$1") || return 2
  printf '%s\n' "$text" | grep -hE "$2" | grep -o '`[a-z][a-z-]*`' | tr -d '`' | sort -u || true
}

# file -> the same tokens from every line, with fenced examples, quoted spans
# and arrow asides masked first — the same masking the other whole-file scans
# use, so "what counts as an example" keeps its one home. A worked example of
# the ledger's own format, which is exactly what `evaluation-ledger`'s memo
# reference is for, is prose ABOUT the vocabulary rather than an enumeration
# of it; without the mask an author documenting the format correctly draws a
# hard FAIL. The all-lines case is its own entry point rather than
# `status_tokens_on "$f" '.'`, so a reader greps a name that says what it does
# and no caller pays for a second grep process.
status_tokens_anywhere() {
  local text
  text=$(readable_text "$1") || return 2
  printf '%s\n' "$text" | mask_examples | grep -o '`[a-z][a-z-]*`' | tr -d '`' | sort -u || true
}

# -> every file in the walk carrying the legend line, one per line.
evaluation_ledger_legend_files() {
  local f
  printf '%s\n' "$1" | while IFS= read -r f; do
    grep -qE '^Status is exactly one of:' "$f" && echo "$f"
  done
}

# -> every file in the walk carrying the body's stored-status rule.
evaluation_ledger_rule_files() {
  local f
  printf '%s\n' "$1" | while IFS= read -r f; do
    grep -qE 'Exactly one stored status' "$f" && echo "$f"
  done
}

# -> "<legend file><TAB><status> <status> …" for the one file carrying the
# legend line, or nothing. Every caller re-runs it rather than sharing state:
# it is one grep over a captured list.
find_evaluation_ledger_legend() {
  local legend_files legend_file statuses
  legend_files=$(evaluation_ledger_legend_files "$1")
  [ -z "$legend_files" ] && return 1
  [ "$(printf '%s\n' "$legend_files" | grep -c .)" -gt 1 ] && return 2
  legend_file=$legend_files
  statuses=$(status_tokens_on "$legend_file" '^Status is exactly one of:') || return 3
  printf '%s\t%s\n' "$legend_file" "$(printf '%s' "$statuses" | tr '\n' ' ')"
}

# Rule 1 — one legend, defining three statuses. The two anchors pin each
# other: a tree that states the stored-status rule but defines no legend has
# had the legend sentence reworded, which is the edit that would otherwise
# switch all three checks off in silence. A tree with neither is a tree with
# no ledger vocabulary to hold together, which a fixture root legitimately is.
check_evaluation_ledger_authority() {
  local walked_files=$1 legend_files rule_files legend_file statuses n
  legend_files=$(evaluation_ledger_legend_files "$walked_files")
  rule_files=$(evaluation_ledger_rule_files "$walked_files")
  if [ -z "$legend_files" ]; then
    if [ -n "$rule_files" ]; then
      say_fail "an evaluation ledger stored-status rule exists ($(printf '%s' "$rule_files" | tr '\n' ' ' | sed 's/ $//')) but no file defines the legend — the line 'Status is exactly one of:' is the anchor all three ledger checks find their authority by, so rewording it turns them off rather than failing them; restore the line, or move the anchor in scripts/lint-skills.sh with it"
      return 0
    fi
    # Neither anchor present: no ledger vocabulary in this tree at all. Honest
    # silence for a fixture root; in this repo it means both sentences were
    # reworded in one pass, which no fixture can stage.
    [ -n "${LINT_ROOT:-}" ] && return 0
    say_fail "no file defines the evaluation ledger status legend and none states its stored-status rule — both anchors the three ledger checks hang on are gone, so they are grading nothing; restore them, or move the anchors in scripts/lint-skills.sh with them"
    return 0
  fi
  n=$(printf '%s\n' "$legend_files" | grep -c .)
  if [ "$n" -gt 1 ]; then
    say_fail "two files define the evaluation ledger status legend ($(printf '%s' "$legend_files" | tr '\n' ' ' | sed 's/ $//')) — one authority, or a rename updates whichever the reader did not open"
    return 0
  fi
  legend_file=$legend_files
  if ! statuses=$(status_tokens_on "$legend_file" '^Status is exactly one of:'); then
    say_fail "the evaluation ledger legend in $legend_file could not be read — the vocabulary checks did not run on it, which is not the same as it having nothing to report"
    return 0
  fi
  n=$(printf '%s\n' "$statuses" | grep -c .)
  if [ "$n" -ne 3 ]; then
    say_fail "the evaluation ledger legend defines $n statuses, not 3, in $legend_file — the skill body says 'There is no fourth'; change both or neither"
  fi
}

# Rule 2 — the body's own stored-status rule defines the same set as the
# legend. Same set, or the file a reader opens decides which vocabulary they
# get. A legend with no rule site is the mirror of rule 1's case: the rule
# phrase was reworded, and half the contract stopped being graded.
check_evaluation_ledger_rule_agreement() {
  local walked_files=$1 legend legend_file v_legend rule_files rule_file v_rule n
  legend=$(find_evaluation_ledger_legend "$walked_files") || return 0
  legend_file=${legend%%	*}
  v_legend=$(printf '%s\n' "${legend#*	}" | tr ' ' '\n' | grep -v '^$' | sort -u)
  rule_files=$(evaluation_ledger_rule_files "$walked_files")
  if [ -z "$rule_files" ]; then
    say_fail "the evaluation ledger legend is defined in $legend_file but no file states the stored-status rule — the phrase 'Exactly one stored status' is the anchor this check finds the second authority by, so rewording it leaves the two definition sites ungraded against each other"
    return 0
  fi
  n=$(printf '%s\n' "$rule_files" | grep -c .)
  if [ "$n" -gt 1 ]; then
    say_fail "two files state the evaluation ledger's stored-status rule ($(printf '%s' "$rule_files" | tr '\n' ' ' | sed 's/ $//')) — only one would be compared against the legend and the other could drift unseen; one rule site, or one sibling group covering them"
    return 0
  fi
  rule_file=$rule_files
  if ! v_rule=$(status_tokens_on "$rule_file" 'Exactly one stored status'); then
    say_fail "the evaluation ledger stored-status rule in $rule_file could not be read — it was not compared against the legend, which is not the same as the two agreeing"
    return 0
  fi
  if [ "$v_legend" != "$v_rule" ]; then
    say_fail "the evaluation ledger's two definition sites define different vocabularies — $legend_file's legend has ($(printf '%s' "$v_legend" | tr '\n' ' ' | sed 's/ $//')) and $rule_file's stored-status rule has ($(printf '%s' "$v_rule" | tr '\n' ' ' | sed 's/ $//')) — they are read by different people and must agree"
  fi
}

# Rule 3 — consumers. A file carrying two of the three is ENUMERATING the
# vocabulary and must carry all of it; one is referencing a single status,
# which is a legitimate thing to do (`doc-claims` judges a verified row and no
# other).
#
# Anchored per FILE, not per line. A consumer's sentence wraps, and the ledger
# mention and the statuses it lists then sit on different lines — a per-line
# anchor reads that as "one status" and stays quiet, which is the miss this
# check exists to prevent. The anchor names the evaluation ledger specifically:
# a bare "the ledger" would reach `accessible-ui`'s per-change criterion
# ledger, `implement`'s parked ledger and `review-changes`' coverage ledger,
# none of which use this vocabulary.
check_evaluation_ledger_consumers() {
  local walked_files=$1 legend legend_file v_legend legend_owner f hits missing t
  if ! legend=$(find_evaluation_ledger_legend "$walked_files"); then
    # No single readable legend, so there is no vocabulary to check consumers
    # against. Say so where a legend exists at all: the author fixes the
    # authority problem reported above, re-runs, and meets a crop of consumer
    # FAILs that were there all along — which reads as a regression their fix
    # caused unless this line told them the sweep had not run.
    if [ -n "$(evaluation_ledger_legend_files "$walked_files")" ]; then
      say_fail "the evaluation ledger consumer sweep did not run — it needs one readable legend to check against, and the failure above says there is not one; expect further failures here once that is fixed"
    fi
    return 0
  fi
  legend_file=${legend%%	*}
  v_legend=$(printf '%s\n' "${legend#*	}" | tr ' ' '\n' | grep -v '^$' | sort -u)
  # The legend's own skill is read wholesale, anchor or no anchor. Keyed off
  # the owning src/<name>/ segment the pass-2 classifier computes the same way,
  # so moving the legend line into a SKILL.md does not silently empty the rule.
  case "$legend_file" in
    src/*) legend_owner=${legend_file#src/}; legend_owner="src/${legend_owner%%/*}" ;;
    *) legend_owner=$(dirname "$legend_file") ;;
  esac
  # Process substitution, never a pipe: say_fail sets `fail` and a piped
  # `while` runs in a subshell, so every failure here would be discarded and
  # the gate would go green on a broken contract.
  while IFS= read -r f; do
    case "$f" in
      "$legend_owner"/*) : ;;
      *)
        grep -qE "$evaluation_ledger_anchor_re" "$f"
        case $? in
          0) : ;;
          1) continue ;;
          *) say_fail "$f could not be read for the evaluation ledger anchor — the vocabulary check did not run on it, which is not the same as it having nothing to report"; continue ;;
        esac
        ;;
    esac
    if ! hits=$(status_tokens_anywhere "$f"); then
      say_fail "$f could not be read for evaluation ledger statuses — the vocabulary check did not run on it, which is not the same as it having nothing to report"
      continue
    fi
    hits=$(printf '%s\n' "$hits" | grep -xF "$v_legend" | grep -c .)
    [ "$hits" -ge 2 ] || continue
    [ "$hits" -eq 3 ] && continue
    missing=$(printf '%s\n' "$v_legend" | while IFS= read -r t; do
      grep -q "\`$t\`" "$f" || echo "$t"
    done | tr '\n' ' ')
    say_fail "an evaluation ledger status is missing from $f — it names 2 of the 3 and not \`${missing% }\`; a file that enumerates the vocabulary carries all of it, or a rename leaves this one pointing at a status that no longer exists"
  done < <(printf '%s\n' "$walked_files")
}


sibling_groups=(
  "src/onboard-me/references/evidence-tags.md|src/offboard-engineer/references/evidence-tags.md|src/rebuild-contract/references/evidence-tags.md"
  "src/grill-me/references/adr-format.md|src/backfill-adrs/references/adr-format.md|src/adr/references/adr-format.md"
  "src/to-bug/references/tracker-resolution.md|src/to-feature/references/tracker-resolution.md|src/to-story/references/tracker-resolution.md|src/to-tasks/references/tracker-resolution.md|src/review-architecture/references/tracker-resolution.md|src/chart-course/references/tracker-resolution.md|src/from-ticket/references/tracker-resolution.md|src/ship/references/tracker-resolution.md|src/backfill-adrs/references/tracker-resolution.md"
  "src/to-bug/references/publishing.md|src/to-feature/references/publishing.md|src/to-story/references/publishing.md|src/to-tasks/references/publishing.md|src/chart-course/references/publishing.md"
  "src/review-changes/references/subagent-brief.md|src/review-architecture/references/subagent-brief.md|src/chart-course/references/subagent-brief.md|src/handoff/references/subagent-brief.md|src/work-item-shape/references/subagent-brief.md|src/adoption-verdict/references/subagent-brief.md|src/product-description/references/subagent-brief.md"
  "src/review-architecture/references/finding-discipline.md|src/review-changes/references/finding-discipline.md"
  "src/review-changes/references/tree-stamp.md|src/address-findings/references/tree-stamp.md"
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
  local walked_files=$1 grouped_basenames base
  grouped_basenames=$(printf '%s|' "${sibling_groups[@]}" | tr '|' '\n' | awk -F/ 'NF { print $NF }' | sort -u)
  while IFS= read -r base; do
    if ! printf '%s\n' "$grouped_basenames" | grep -qxF "$base"; then
      say_fail "reference file '$base' exists in multiple skills but no sibling group covers it — add it to sibling_groups in scripts/lint-skills.sh, or rename the deliberate variant"
    fi
  done < <(printf '%s\n' "$walked_files" | grep '^src/.*/references/.*\.md$' | awk -F/ '{ print $NF }' | sort | uniq -d)
}

[ -z "${LINT_ROOT:-}" ] && check_sibling_identity
check_sibling_membership "$walked_files"
check_evaluation_ledger_authority "$walked_files"
check_evaluation_ledger_rule_agreement "$walked_files"
check_evaluation_ledger_consumers "$walked_files"

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

# Every hook has a selftest (global/README.md § Hooks: "Each hook has a
# `*-selftest.sh` beside it"): a hook is a global/hooks/*.sh whose header
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

# Conventions pointer (see header): the line every file under scripts/ and
# scripts/git-hooks/ opens with, at line 2 after a shebang and line 1 without
# one. Read with head so a file that cannot be read says so rather than
# reading as a file without the line.
conventions_line='# Conventions for this tree: scripts/README.md'
check_conventions_pointer() {
  local f=$1 opening l1 l2
  if ! opening=$(head -n 2 "$f" 2>/dev/null); then
    say_fail "$f could not be read for its conventions pointer — that check did not run on it"
    return
  fi
  l1=$(printf '%s\n' "$opening" | sed -n 1p)
  l2=$(printf '%s\n' "$opening" | sed -n 2p)
  case "$l1" in '#!'*) [ "$l2" = "$conventions_line" ] && return 0 ;; *) [ "$l1" = "$conventions_line" ] && return 0 ;; esac
  say_fail "$f does not open with '$conventions_line' (line 2 after a shebang, line 1 without one) — add it, so an agent that opens the file instead of CLAUDE.md is pointed at the rules that bind it"
}

# Every script has a selftest (see header): scripts/<name>.sh that is not a
# selftest, a library, or an installer has an executable
# scripts/<name>-selftest.sh. post-merge and sweep-corpus derive their gate
# rosters from that pairing, so a script landing without one is named here
# rather than left outside every automated run. The same function grades the
# git hooks — check_hook_selftest is global/hooks/ only — with the remedy a
# hook can follow: its filename is git's, so `*-lib.sh` is no escape, and it
# must carry the exec bit itself or git skips it silently.
check_script_selftest() {
  local sc=$1
  check_conventions_pointer "$sc"
  case "$sc" in *-selftest.sh | *-lib.sh) return 0 ;; esac
  case "${sc##*/}" in install.sh | setup-hooks.sh) return 0 ;; esac
  case "$sc" in
    scripts/git-hooks/*)
      [ -x "$sc" ] || say_fail "$sc is not executable — chmod +x it; git runs a hook under core.hooksPath only when it carries the exec bit, and skips it silently otherwise"
      require_selftest "$sc" "git hook" "has no selftest" "(source scripts/selftest-lib.sh; every git hook under scripts/git-hooks/ is graded by a selftest that runs it against a throwaway repo)"
      ;;
    *)
      require_selftest "$sc" script "has no selftest" "(source scripts/selftest-lib.sh; every scripts/*.sh is graded by a selftest that runs it against a fixture), or name the file *-lib.sh if it is a library"
      ;;
  esac
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
# The git hooks walk: check_script_selftest grades these too (check_hook_selftest
# is global/hooks/ only). What makes a file here a hook is derived, not listed:
# its first line is a shebang, the way `# Install note:` marks a PreToolUse
# hook — so a README, a .gitignore or a *.sample beside the hooks is not held
# to the pairing, and the next hook needs no roster edit.
if [ -d scripts/git-hooks ]; then
  for sc in scripts/git-hooks/*; do
    [ -f "$sc" ] || continue
    case "$(head -n 1 "$sc" 2>/dev/null)" in '#!'*) check_script_selftest "$sc" ;; esac
  done
fi

if [ -f CLAUDE.md ]; then
  check_claude_md_bytes CLAUDE.md
  # ADR-0076 left the root file as triggers and pointers; a pointer to a
  # missing file silently loads nothing, so the root file gets the same link
  # check every shipped markdown file gets — pass 2's parser, reused rather
  # than a second extractor, so the two cannot disagree about scope.
  check_reference_links CLAUDE.md
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: skill conventions clean."
fi

exit "$fail"
