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
#     The slash check is the mirror image, and file-local rather than
#     per-skill. It has two arms: `/<name>` naming a model-invoked skill fails,
#     because the slash form is what a human types and it hides the call from
#     the scan above; and `/<name>` naming no skill at all fails, because a
#     rename leaves the old name spelled correctly and pointing nowhere. The
#     second arm reads a roster of names that are not skills — typed prefixes,
#     built-in commands, filesystem paths — and a `<!-- slash-exempt: name -->`
#     marker for a one-file case. Needing no `requires:` line, it sweeps every markdown
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
#     check global/hooks/, the script-selftest check scripts/,
#     scripts/git-hooks/ and .claude/skills/*/scripts/ (all three trees on one
#     pairing contract: a skill-private script owes a selftest exactly as one
#     under scripts/ does, unless it is named *-lib.sh). The repo-local
#     skills under .claude/skills/, and DOMAIN.md and README.md, are in pass
#     2's walk for the slash sweep, the house-style set (spelling, reference
#     form, artifact names, labels, section pointers, heading case) and the
#     evaluation-ledger consumer sweep, and for nothing else: the hoisting,
#     frontmatter, ADR-citation, HTML-transport and reference-link checks do
#     not read them, and a repo-local body draws the loaded-file byte FAIL
#     because it is re-attached exactly as a hoisted one is. DOMAIN.md is the
#     one file check_labels skips — it is where the labels are registered. They never
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
#   - Re-attach byte FAIL (write-skill § Size constraints): a SKILL.md over
#     15,000 bytes is a FAIL — the platform figure it converts is dated in the
#     block below. A reference file and a repo-local body draw the same FAIL
#     under check_reference_bytes, with the remedy each has: a reference is
#     read whole when its pointer is followed, so an oversize one has a tail
#     the run does not reach, and the fix is to split it at a heading rather
#     than to move detail one tier down — there is no tier below a reference.
#     A WARN until Batch M-size of the 2026-08-30 tightening round brought the
#     last eight bodies under (ADR-0077 § Sizes); it flipped 2026-09-01 with
#     every body and reference under the bound.
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
#     setup-hooks.sh (by basename — one name, since install.sh left the list on
#     2026-09-01) has an executable scripts/<name>-selftest.sh beside it, so a gate landing
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
#   - The always-loaded budget (ADR-0077's C9 amendment): global/rules/ totals
#     no more than 12,000 bytes. A FAIL, not a WARN, because unlike the two
#     byte bounds above this figure is this repo's own ruling: every byte in
#     that directory is paid on every turn of every session. The directory
#     total is the unit, never a single file.
#   - British spellings (ADR-0077 § House style): a word list, over src/**,
#     .claude/skills/**, global/rules/, global/README.md, DOMAIN.md, README.md,
#     CLAUDE.md, docs/** and the prose READMEs under scripts/ — the one check
#     here whose scope runs past the skill tree, because a British form in an
#     ADR is the same drift. What it strips, what it excludes and why the list
#     is spelled out are stated ONCE, at check_spelling; a rationale written
#     here as well made widening the check three prose edits, and the copy
#     furthest from the code is the one a reader is least likely to open.
#   - Heading case (ADR-0077 § House style): a SKILL.md H1 is the skill's
#     display name in title case; every H2 is sentence case. Mid-heading
#     capitals that are legitimate and not chased: an acronym, a token
#     carrying or followed by a digit (`Tier 2`, `Phase 3`, `Step 11`), a term
#     registered in DOMAIN.md, and a short proper-noun list in the file. A
#     clause opened by an em dash or a colon starts a new sentence, which is
#     the shape every numbered step here takes. global/rules/ is not walked:
#     a rule file's H1 is a sentence-case proposition, not a display name.
#   - Invocation form (ADR-0077 § Amendments 2026-08-30, which narrowed
#     the flat rule): the bare backtick stays licensed for vocabulary, a
#     boundary statement, an already-loaded skill's rules, and a gated offer,
#     and no scan can tell those from a suggestion — so this grades the two
#     forms banned outright: "the X skill" for any name that resolves to a
#     skill, and an invocation verb followed by a bare backticked user-invoked
#     name, which is a suggestion site where `/name` is what the human types.
#     A suggestion written any other way is invisible here, and the licensed
#     classes are graded by nobody.
#   - Artifact filenames (ADR-0077 § Renames): a file a body tells a run to
#     write is lowercase with dashes. A backticked token ending in .md, .html,
#     .csv or .txt that carries an uppercase letter or an underscore fails,
#     except the repo-convention names (README.md, CLAUDE.md, AGENTS.md,
#     SKILL.md, DOMAIN.md, MEMORY.md). A source file in the user's own project
#     takes that ecosystem's convention and is deliberately out of the
#     extension set.
#   - Label family (DOMAIN.md's Status-marker row: "A marker outside those sets
#     is registered here before a body uses it"): an ALL-CAPS token in bold or
#     backticks is registered in DOMAIN.md or on the acronym-and-literal list
#     in this file. Not a marker by form: a single letter, a token carrying a
#     digit (`AC1`, `L-04`), a token carrying an underscore (`NO_COLOR`).
#     DOMAIN.md is not scanned against itself.
#   - Section pointers: a `§ Name` citation names a heading its target file
#     carries. check_reference_links reads the `.md` inside the parens and
#     stops, so the half that says WHERE to read has never been checked and a
#     renamed section shipped past a green lint. Graded only where the line
#     names a target — an inline link, a `~/.claude/` path, or a backticked
#     skill name (whose target is that skill's SKILL.md). A `§ 4` naming a
#     section of its own file has no target and is not read. The name is
#     matched as a PREFIX of a heading, because a citation runs on into its
#     sentence; that is also the limit — a heading that is a prefix of a
#     longer sibling can be cited by the shorter name and pass.
#   - Orphaned references: a file under src/*/references/ is linked from
#     somewhere. check_reference_links validates link -> file and never
#     file -> link, so a reference nothing points at passes every other check
#     while loading for nobody. Pointed at means an inline link from inside
#     its own skill (by path from the skill root or by basename from a sibling
#     reference) or the `~/.claude/skills/<owner>/<path>` form from anywhere in
#     the walk. A reference reached only by a link form the extractor above
#     does not read (reference-style, titled, angle-bracketed) reads as an
#     orphan here — the two checks share that boundary on purpose.
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
#     5,000 tokens of each", verified 2026-08-29. The FAIL below converts it to
#     bytes at 3 bytes/token, measured 2026-08-29 on this repo's four largest
#     bodies through `claude -p` usage deltas (2.97–3.10 bytes/token; the
#     earlier 4-bytes/token estimate undercounted by a quarter).
#   - The 200-line caps are this repo's own (write-skill § Size constraints), a
#     loaded-context proxy, not a platform limit.
#
# The checks, as the named functions below, grouped by the pass that reads
# for them. A check is one function, so a new check is a function and a call.
# Cost model, stated so it can be checked rather than assumed: pass 2 opens
# each walked file once for the body checks and once for the whole house-style
# set (house_style_checks strips fences once and hands the numbered stream to
# all six), and pass 3's reference checks then run per-reference greps over
# the owning skill's directory. Pass 4 is a second, separate walk over a
# different glob — docs/**, global/README.md and the prose READMEs, which no
# other pass reads. Measured 2026-08-31 over 225 files: ~25s, against ~12s
# before the six house-style checks landed. Measured again 2026-09-01 over
# 227 files, by pass, before Batch M-scripts: pass 0 0.2 s · pass 1 3.6 s ·
# pass 2 20.9 s · pass 3 5.4 s · pass 4 1.6 s, 31.7 s in all; 28.3 s after
# that batch's two cuts (the section-pointer forks, the ledger sweep's
# per-file greps). Dropping any one pass-2 check saves 0.5-3.5 s — the
# per-reference greps in check_reference_orphans, the cut the 2026-09-01
# Batch A residue named, measured at 0 — so pass 2's floor is process count:
# ten checks a file, each a few forks, over 227 files. A further cut is a
# rewrite that merges the six house-style scans into one awk pass, not a
# trim, and is not this file's next job unless the pre-commit gate is.
#   Pass 0 — read before any check runs, so no check's answer depends on how
#   far the pass that asks it has got: the user-invoked set (name_is_user_invoked,
#   the single predicate for that question) and both routers' text.
#   Pass 1 — every skill's frontmatter and its own body, src/*/SKILL.md:
#     check_reattach_bytes     the 15,000-byte FAIL
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
#   (the body checks), and for the slash sweep AND the whole house-style set
#   also .claude/skills/**, DOMAIN.md, README.md:
#     check_line_cap           <= 200 lines
#     check_adr_citation       no `ADR-<digit>` token
#     check_html_transport     no HTML through the shell
#     check_reference_links    every inline .md link resolves
#     check_load_gate          no "Launching skill" under a model-invoked skill
#     check_slash_form         no `/name` naming a model-invoked skill, and no
#                              `/name` naming nothing at all
#     check_spelling           no British form outside a code span
#     check_heading_case       SKILL.md H1 title case, every H2 sentence case
#                              (not global/rules/, whose H1 is a proposition)
#     check_invocation_form     no "the X skill"; `/name` at a suggestion site
#     check_artifact_names     a written filename is lowercase with dashes
#     check_labels             every ALL-CAPS label registered in DOMAIN.md
#     check_section_pointers   every `§ Name` names a heading its target has
#     check_reference_bytes    the 15,000-byte FAIL over a loaded file
#   Pass 3 — cross-file contracts, read from pass 2's captured walk:
#     check_sibling_identity   byte-identical copies (this repo, or the
#                              groups LINT_SIBLING_GROUPS names)
#     check_sibling_membership every PATH sharing a basename with another
#                              skill's is listed in a sibling group
#     check_reference_orphans  every reference is linked from somewhere
#     check_evaluation_ledger_authority       one legend, defining three statuses
#     check_evaluation_ledger_rule_agreement  the body's stored-status rule
#                              defines the same set as the legend
#     check_evaluation_ledger_consumers       a file that enumerates the
#                              vocabulary carries all of it
#   Pass 4 — the other trees, each read once:
#     check_rules_bytes        global/rules/ totals under 12,000 bytes
#     check_catalog_bytes      model-invoked description: lines total under
#                              13,200 bytes (ADR-0079; a WARN)
#     check_rule_pointers      every ~/.claude/skills/<owner>/<path> pointer in
#                              a rule resolves under src/
#     check_global_rule        Depends: resolves, and each dependant cites back
#     check_hook_selftest      every hook has an executable selftest
#     check_script_selftest    every script, and every git hook, has an
#                              executable selftest, and opens with the
#                              conventions pointer; a git hook is executable
#     check_claude_md_bytes    the 6,000-byte CLAUDE.md WARN
#     check_reference_links    every relative .md link in the root CLAUDE.md
#                              resolves (pass 2's parser, pointed at the
#                              root file)
#     check_spelling           over docs/**, global/README.md and
#                              scripts/README.md, which no other pass walks,
#                              and over CLAUDE.md with the rest of the
#                              house-style set
#     check_landing_key        every key in a CLAUDE.md `Landing:` block is one
#                              of the six, with a value `committing` reads, and
#                              a block that exists names `Review required:`
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
global/rules/, global/hooks/ (one selftest per hook), scripts/, scripts/git-hooks/ and
.claude/skills/*/scripts/ (one selftest per script or hook, and the conventions
pointer), CLAUDE.md's size and its relative links, and the two routers against the
rules each cites. Takes no argument but --help.

  LINT_ROOT=<dir>   point the whole sweep at another tree; unset in normal use
                    (scripts/lint-skills-selftest.sh sets it to the fixture roots)
  LINT_SIBLING_GROUPS='a|b c|d'
                    replace the sibling-group registry with these groups (paths
                    under the sweep root, `|` within a group, space between);
                    unset in normal use, where the registry in this file names
                    this repo's own paths. A value naming no group, or a group
                    of one path, is a usage error (exit 3), not a quiet run

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
checked) · 3 usage error (an unknown argument, an empty one, or more than one, or a
LINT_SIBLING_GROUPS naming no group or a group of one path) · 4 a check never ran, so
this run is not a verdict on anything — today the one cause is a failure flag under
TMPDIR that could not be written. WARN lines never change the exit code.
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

# The failure-flag mechanism, shared with scripts/lint-adrs.sh: the two carried
# the same nine lines under the same names until 2026-09-01. A source that
# fails is exit 4 — with no say_fail, no FAIL below could move the status.
lint_lib="$repo_root/scripts/lint-lib.sh"
# shellcheck source=scripts/lint-lib.sh
. "$lint_lib" || { echo "lint-skills.sh: could not source $lint_lib, where say_fail and the failure flag live — no check below could have moved the exit status, so no run from here is a verdict" >&2; exit 4; }

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
# The failure flag's directory is made after the `cd` below, so a RELATIVE
# TMPDIR must be absolutized here, while $PWD is still the caller's; the
# reasoning is in scripts/lint-lib.sh's header.
lint_absolutize_tmpdir
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

# say_fail, the failure flag, and why the status travels as a file rather than
# a variable: scripts/lint-lib.sh's header, which scripts/lint-adrs.sh reads
# too. Nothing below assigns a `fail` variable — there is none.
lint_fail_flag_init lint-skills.sh

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

# DOMAIN.md, read once for the two checks that grade a body against it. The
# registered ALL-CAPS labels are what check_labels admits; the capitalized
# words of every registered term name are the proper nouns check_heading_case
# admits mid-heading. Both are pipe- and space-delimited membership lists,
# since Darwin's bash 3.2 has no associative arrays, and both are empty when
# there is no DOMAIN.md — a tree without one registers nothing, so the checks
# that read them fall back to their own name lists rather than to silence.
# label_tokens reads a stream on stdin and prints the ALL-CAPS label tokens in
# it, one per line. It is called from BOTH sides of the one contract — pass 0
# building the registry out of DOMAIN.md, and check_labels extracting
# candidates from a body — because the two are halves of a single question,
# "what counts as a label", and the pipeline written twice had already drifted
# once (the registry copy ran without the fence strip, so a token inside a
# fenced example registered globally while the same token inside a fence in a
# body was invisible). Fences are stripped on both sides now.
label_tokens() {
  grep -oE '`[[:upper:]][[:upper:][:digit:] _:+-]{1,20}`|\*\*[[:upper:]][[:upper:][:digit:] _:+-]{1,20}\*\*' \
    | tr -d '`*' | sed -e 's/[[:space:]]*$//' -e 's/[.:!?]$//' | sort -u
}

registered_labels="|"
domain_terms=" "
if [ -f DOMAIN.md ]; then
  # Only the two rows that ARE the registry, not the whole file. Mined from
  # every span in the document, DOMAIN's own NEGATIVE examples registered the
  # tokens their sentences ban — `BLOCKED` among them, the one FAIL-family
  # synonym the Status-marker row names and forbids.
  registered_labels="|$(awk "$FENCE_AWK"'{ print }' DOMAIN.md \
    | grep -E '^\| \*\*(Status marker|Verdict scale)\*\* \|' \
    | label_tokens | tr '\n' '|')"
  domain_terms=" $(grep -oE '^\| \*\*[^*]+\*\*' DOMAIN.md | sed -e 's/^| \*\*//' -e 's/\*\*$//' \
    | tr ' ' '\n' | grep -E '^[[:upper:]]' | tr -d '`,()' | sort -u | tr '\n' ' ')"
fi
# The ordering constraint, made checkable instead of documented. check_labels
# and check_heading_case both read registries built HERE and take neither in
# their signature; called before this point — by a refactor, or by a selftest
# exercising one check alone — they return a plausible WRONG answer (an empty
# registry reads as "nothing is registered") rather than erroring. The
# sentinel turns that into the case the exit-code taxonomy already has a
# status for: a check that never ran.
domain_registries_loaded=1

# ---------------------------------------------------------------------------
# Pass 1 — every skill's frontmatter and its own body, read once each.
# ---------------------------------------------------------------------------

# (see header) Re-attach bound, as bytes. A FAIL: the cap is the platform's
# and moves with it, but a body over it loses its tail on the first re-attach,
# and a cap that only warns drifts (tell-catalog.md grew 1,191 bytes past it
# with nothing watching). What the author owes is a smaller body — relocate
# what some runs never reach, or cut. Measured before the description checks
# so a body with a broken description is still measured.
# bytes_bound <level> <file> <limit> <tail>: the one shape every byte bound
# shares — a count, a bound, a line at the given level (FAIL goes through
# say_fail and moves the exit status, WARN prints and never does). A file that
# cannot be counted is a FAIL, not a silent pass: an empty count would
# otherwise skip the comparison and read as under the bound. A level that is
# neither is exit 4, checked before the count so a misspelling is caught on
# every call and not only on the files that breach: a `*)` arm that printed
# WARN would turn a mis-cased FAIL into a status-neutral line, which is the
# defect this bound exists to catch.
bytes_bound() {
  local level=$1 f=$2 limit=$3 tail=$4 bytes
  case "$level" in
    FAIL|WARN) : ;;
    *) echo "lint-skills.sh: bytes_bound called with level '$level' on $f — the only levels are FAIL and WARN; fix the caller" >&2; exit 4 ;;
  esac
  bytes=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  if [ -z "$bytes" ]; then
    say_fail "$f could not be read for its byte count — the $limit-byte $level did not run on it"
    return
  fi
  if [ "$bytes" -gt "$limit" ]; then
    case "$level" in
      FAIL) say_fail "$f is $bytes bytes — $tail" ;;
      WARN) echo "WARN: $f is $bytes bytes — $tail" ;;
    esac
  fi
}
warn_bytes() { bytes_bound WARN "$@"; }
fail_bytes() { bytes_bound FAIL "$@"; }

check_reattach_bytes() {
  fail_bytes "$1" 15000 "past the 5,000-token re-attach bound (at 3 bytes/token) Claude Code keeps per skill after auto-compaction, so its tail is what a re-attach drops; put its hard stops and close-out steps above its long sections, or move detail into references/"
}

# The same bound over a file that is read rather than re-attached: a reference
# and a repo-local body are both loaded whole when their pointer is followed,
# so the tail of an oversize one is what the run never reaches. A FAIL on the
# same terms as the body's, with the remedy a reference has — split it, since
# there is no third tier to move detail into.
check_reference_bytes() {
  fail_bytes "$1" 15000 "past the 5,000-token bound (at 3 bytes/token) a loaded file is read within, so its tail is what the run does not reach; split it at a heading into two references the caller opens on different conditions"
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
  # nothing to measure. Every check that does not read it — the byte bound,
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
# The slash names this repo writes that resolve to no skill in the tree, each
# with the reason it is not a dangling pointer. This is a ROSTER, not a
# pattern: nothing derives it, and a name reaching it is a decision. It exists
# because the two failures look identical in the source — `/compact` and
# `/compakt` are both "a slash form naming no skill here" — and only a person
# knows which is a command Claude Code ships and which is a typo or a skill
# that was renamed out from under the sentence.
#   External commands, not skills in this collection:
#     clear compact init          Claude Code built-ins
#     code-review security-review simplify
#                                 commands shipped outside src/ and
#                                 .claude/skills/, named by the bodies that
#                                 route to them
#   Not a command at all, but written in the slash form:
#     name old-name               metasyntactic placeholders — `audit-skills`
#                                 and DOMAIN.md write `/name` for "whatever the
#                                 skill is called"
#     sweep                       a typed PREFIX, not a name: DOMAIN.md records
#                                 that typing it offers `/sweep-domain` and
#                                 `/sweep-corpus`
#     tmp                         a filesystem path written in the slash form —
#                                 never a command anywhere, and a whole-repo
#                                 fact, so a second site owes no second decision
# A line may also carry `<!-- slash-exempt: token -->`, which exempts exactly
# the tokens it names on exactly that line — the same scope its sibling
# `<!-- spelling-exempt: word -->` has, so one syntax means one thing. Use it
# for a name that is right here and wrong three paragraphs down; a name that is
# never a command anywhere in the repo belongs in the roster above instead.
slash_exempt=' clear compact init code-review security-review simplify name old-name sweep tmp '
check_slash_form() {
  local f=$1 scan slashed line line_exempt seen=' '
  # Strip frontmatter where there is any; a reference file has none.
  scan=$(awk 'NR == 1 && $0 == "---" { fm = 1; next }
              fm && $0 == "---" { fm = 0; next }
              fm { next } { print }' "$f" \
    | mask_examples)
  # Per line, because that is what the marker promises and what `spelling-exempt`
  # does: collected over the whole file instead, one marked site blesses every
  # later use of that name in the body, and the rename this check exists to
  # catch goes unreported. `seen` keeps it to one FAIL per name per file, so a
  # name written at three sites does not print three identical lines.
  # Only the lines carrying a slash form reach the loop: this check runs over
  # every markdown file the repo ships, and a per-line walk that forked for the
  # marker on every line put seconds on every pre-commit.
  while IFS= read -r line; do
    line_exempt=' '
    case "$line" in
      *'slash-exempt:'*)
        line_exempt=" $(printf '%s\n' "$line" \
          | grep -o '<!-- *slash-exempt:[^>]*-->' \
          | sed -E 's/<!-- *slash-exempt: *//; s/ *-->//' \
          | tr ',' ' ' | tr -s '[:space:]' ' ') " ;;
    esac
    for slashed in $(printf '%s\n' "$line" | grep -o '`/[a-z0-9-]*`' | tr -d '`/' | sort -u); do
      case "$seen" in *" $slashed "*) continue ;; esac
      if [ ! -f "src/$slashed/SKILL.md" ] && [ ! -f ".claude/skills/$slashed/SKILL.md" ]; then
        case "$slash_exempt" in *" $slashed "*) continue ;; esac
        case "$line_exempt" in *" $slashed "*) continue ;; esac
        seen="$seen$slashed "
        say_fail "$f writes \`/$slashed\`, and no skill of that name is in src/ or .claude/skills/ — a renamed or retired skill leaves this form behind pointing at nothing, and a reader types it and gets no command; fix the name, or add it to slash_exempt in scripts/lint-skills.sh with its reason, or mark the line \`<!-- slash-exempt: $slashed -->\` where the slash form is a route or a path rather than a command"
        continue
      fi
      [ -f "src/$slashed/SKILL.md" ] || continue
      name_is_user_invoked "$slashed" && continue
      seen="$seen$slashed "
      say_fail "$f writes \`/$slashed\`, but '$slashed' is model-invoked — the slash form is for commands a human types; use \`\`Call the Skill tool with \`$slashed\` \`\`"
    done
    # A here-string, not a pipe: `seen` accumulates across lines, and a pipe
    # would run the loop in a subshell and discard it.
  done <<< "$(printf '%s\n' "$scan" | grep -F '`/' || true)"
}


# (see header) British spellings. The word list IS the check: a form absent
# from it is not caught, which is why it is spelled out rather than derived
# from a suffix rule (`-ise` alone fires on `wise`, `precise`, `concise`).
# Code spans and URLs are stripped first, because a state value, an
# identifier, or a vendor path is not this repo's prose to spell —
# `order.cancelled` in a contract example stays. global/hooks/ and scripts/
# shell are outside every caller on purpose, and the exclusion is the WHOLE
# tree rather than one word: those files carry machine-matched literals in
# every position a code span cannot mark — a `hook_allow "tokeniser error"`
# breadcrumb three selftests grep for, a fixture path (`neighbours.sh`), a
# probe label, an expectation needle — so telling this repo's prose from a
# string some other file must match, line by line in shell, is what the
# exclusion buys out of. The consequence is that ordinary prose in those
# trees keeps its British forms too; ADR-0077's flip is repo-wide with these
# two trees excluded, not with one word excluded. The prose READMEs under
# scripts/ are NOT excluded — they hold no literals — and are walked in
# pass 4.
# The deliberate British forms in this tree, named in one greppable place —
# `grep -n deliberate_british scripts/lint-skills.sh` reaches the roster, and
# each entry says which consumer requires the form. This is a ROSTER, not a
# pattern: nothing reads it at runtime. It exists because a code span is
# indistinguishable from an ordinary path, so a hand-flipped literal inside one
# has no gate — which is how `licences.tsv` and a recorded `honours` regex were
# corrupted by a sweep that lint could never have caught.
#   tokeniser        global/hooks/*.sh, hook-lib.py — `hook_allow "tokeniser
#                    error"`, matched by three selftests
#   neighbours.sh    scripts/lint-fixtures*/security/**, a fixture path four
#                    security-selftest mutation rows name by string
#   cancelled        an `order.cancelled` contract example — someone else's
#                    state value, not this repo's prose
#   pre-authorised   src/committing/SKILL.md, README.md, docs/adr/0077 — the
#                    PRE-RENAME `Landing:` key, named so a repo still carrying
#                    it has a documented reader
#   licences.tsv     docs/adr/00{34,64,65,69,70,75} — a real path under
#                    ~/code/lib/_rounds/, outside this repo's naming scope
# A line may also carry `<!-- spelling-exempt: word -->`, which exempts exactly
# the words it names on exactly that line. Use it where the deliberate form
# cannot sit in a code span; the roster above is where the reason goes.
british_words='behaviour|behaviours|colour|colours|coloured|favour|favours|favoured|favourite|labour|honour|humour|neighbour|neighbours|rumour|endeavour|flavour|centre|centres|fibre|litre|metre|metres|theatre|licence|licences|defence|offence|pretence|analyse|analysed|analysing|paralyse|organise|organised|organises|organising|organisation|recognise|recognised|recognises|recognising|prioritise|prioritised|prioritises|prioritising|summarise|summarised|summarises|summarising|synthesise|synthesised|synthesises|synthesising|minimise|minimised|minimises|minimising|maximise|maximised|maximises|maximising|normalise|normalised|normalises|normalising|serialise|serialised|serialises|serialising|initialise|initialised|initialises|initialising|utilise|utilised|utilises|utilising|categorise|categorised|categorises|categorising|emphasise|emphasised|emphasises|emphasising|apologise|apologised|apologises|apologising|optimise|optimised|optimises|optimising|optimisation|specialise|specialised|standardise|standardised|generalise|generalised|formalise|formalised|realise|realised|realises|realising|criticise|criticised|memorise|memorised|characterise|characterised|itemise|itemised|harmonise|harmonised|tokenise|tokenised|tokenises|tokenising|tokeniser|tokenisation|cancelled|cancelling|modelling|labelling|labelled|travelled|travelling|signalled|fulfil|fulfilment|enrolment|instalment|whilst|amongst|grey|artefact|artefacts|sceptic|sceptical|scepticism|programme|programmes|judgement|judgements|acknowledgement|acknowledgements|storey|draught|practise|practised|enquire|enquiry|authorise|authorised|authorises|authorising|authorisation|authorisations|neighbouring|neighbourhood|neighbourhoods|catalogue|catalogues|catalogued|cataloguing|generalises|generalising|generalisation|generalisations|standardises|standardising|standardisation|honours|honoured|honouring|honourable|flavours|flavoured|flavouring|favourable|favourably|favourites|labours|laboured|labouring|humours|rumours|endeavours|endeavoured|endeavouring|fibres|litres|defences|offences|pretences|organisations|optimisations|specialises|specialising|specialisation|formalises|formalising|criticises|criticising|memorises|memorising|characterises|characterising|itemises|itemising|harmonises|harmonising|realisation|realisations|prioritisation|categorisation|normalisation|serialisation|initialisation|utilisation|minimisation|maximisation|summarisation|paralysed|paralyses|paralysing|modelled|signalling|fulfils|enrolments|instalments|judgemental|draughts|sceptics|storeys|enquires|enquired|enquiries|practises|practising|tokenisers|behavioural|behaviourally|colourful|colouring|manoeuvre|manoeuvres|manoeuvring|mould|moulds|moulded|counselling|counsellor|counsellors|centred|centring|licenced'
check_spelling() {
  local f=$1 scan=${2-} hits badlines words
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  # One awk with the list in a HASH, not a 260-alternative `grep -iwE` plus a
  # `sed` per file. The alternation was the single most expensive thing in the
  # sweep — measured at ~8s of a 36s run over 225 files — because an ERE that
  # wide is matched alternative by alternative against every line, where a hash
  # lookup per word is constant. Word boundaries are grep's: a run of
  # [A-Za-z0-9_]. Emits `<line>:<word as written>`.
  hits=$(printf '%s\n' "$scan" | awk -v list="$british_words" '
    BEGIN { n = split(list, w, "|"); for (i = 1; i <= n; i++) bad[tolower(w[i])] = 1 }
    {
      line = $0
      # An inline exemption, read BEFORE the strips so it survives them:
      # `<!-- spelling-exempt: colour-blind -->` exempts exactly the words it
      # names, on exactly that line. A deliberate British form that cannot sit
      # in a code span is otherwise indistinguishable from a missed one.
      delete ok
      if (match(line, /spelling-exempt:[^>]*/)) {
        e = substr(line, RSTART + length("spelling-exempt:"), RLENGTH - length("spelling-exempt:"))
        gsub(/-->/, "", e)
        ne = split(e, ew, /[^A-Za-z0-9_]+/)
        for (i = 1; i <= ne; i++) if (ew[i] != "") ok[tolower(ew[i])] = 1
      }
      gsub(/`[^`]*`/, "", line)                     # a literal is not this repo prose to spell
      gsub(/https?:\/\/[^ )]*/, "", line)           # nor is a vendor URL
      lno = line; sub(/:.*/, "", lno)
      body = line; sub(/^[0-9]*:/, "", body)
      n2 = split(body, toks, /[^A-Za-z0-9_]+/)
      for (i = 1; i <= n2; i++) if (toks[i] != "" && tolower(toks[i]) in bad && !(tolower(toks[i]) in ok)) print lno ":" toks[i]
    }
  ') || true
  if [ -n "$hits" ]; then
    badlines=$(printf '%s\n' "$hits" | cut -d: -f1 | sort -un | tr '\n' ' ')
    words=$(printf '%s\n' "$hits" | cut -d: -f2- | sort -fu | tr '\n' ' ')
    say_fail "$f uses a British spelling (line(s) ${badlines}— ${words}) — this repo writes the American form, so take one of three exits: flip the word; put it in a code span if it is a machine-matched literal; or, where it is deliberate and cannot sit in a span, mark the line \`<!-- spelling-exempt: WORD -->\` and add it to the deliberate_british roster in scripts/lint-skills.sh with the consumer that requires it"
  fi
}

# (see header) Invocation form. The bare backtick stays licensed for the
# classes write-skill names — vocabulary, a boundary statement, an
# already-loaded skill's rules, a gated offer — and no scan can tell those
# from a suggestion, so this check grades the two forms banned outright
# rather than guessing at the licensed ones:
#   "the `X` skill" (and its unbackticked twin), banned for every skill; and
#   an invocation verb followed by a bare backticked USER-INVOKED name, which
#   is a suggestion site, where `/name` is what the human types.
# Scope, stated so a pass isn't read as more than it is: a suggestion written
# any other way — "then hand it to `ship`", a name alone in a list row — is
# invisible here, and the licensed classes are graded by nobody. The verb list
# is the check.
invocation_verbs='run|runs|running|suggest|suggests|suggesting|offer|offers|offering|type|types|typing|invoke|invokes|invoking'
check_invocation_form() {
  local f=$1 scan=${2-} hits badlines named
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  # -i on `the`, because a sentence-initial "The `adr` skill is loaded." is the
  # most likely place to write the banned form and a case-sensitive arm could
  # not see it. The second arm already had it.
  for named in $(printf '%s\n' "$scan" | grep -oiE 'the `?[a-z][a-z0-9-]+`? skill([^a-z]|$)' | sed -e 's/^[Tt]he //' -e 's/ skill.*$//' | tr -d '`' | sort -u); do
    [ -f "src/$named/SKILL.md" ] || continue
    hits=$(printf '%s\n' "$scan" | grep -iE "the \`?$named\`? skill([^a-z]|\$)") || true
    badlines=$(linenos "$hits")
    say_fail "$f breaks the invocation form: it writes \"the $named skill\" (line(s) ${badlines}) — a skill is named, never described as one; write the bare backticked name, or \`/$named\` where a human types it"
  done
  for named in $(printf '%s\n' "$scan" | grep -oiE "($invocation_verbs) \`[a-z0-9-]+\`" | grep -oE '`[a-z0-9-]+`$' | tr -d '`' | sort -u); do
    [ -f "src/$named/SKILL.md" ] || continue
    name_is_user_invoked "$named" || continue
    say_fail "$f breaks the invocation form: it suggests \`$named\` at an invocation site, but '$named' is user-invoked — write \`/$named\`, the form the human types (write-skill: \`/<name>\` only where a human types it)"
  done
}

# (see header) Artifact filenames. A body that tells a run to write a file
# names it lowercase with dashes; the repo-convention names below are the
# exception, and any other backticked filename carrying an uppercase letter or
# an underscore is a name the next session's `ls` or grep will not predict.
# Scope: a backticked token ending in a document extension this repo's skills
# write (.md, .html, .csv, .txt) — a source file in the user's project takes
# that ecosystem's convention (`PrototypeSwitcher.tsx`) and is not read here.
# A token carrying a directory component is graded on its BASENAME, so
# `docs/notes/Progress_Log.md` is read and `docs/ADR/notes.md` is not. A
# `<placeholder>` span is dropped before the case test for the same reason a
# runtime-built path is not read — `<NNNN>-<slug>.md` names no file.
# A filename in prose without
# backticks, and a path built at runtime from a variable, are not read.
artifact_name_exempt='README.md|CLAUDE.md|AGENTS.md|SKILL.md|DOMAIN.md|MEMORY.md'
check_artifact_names() {
  local f=$1 scan=${2-} hits badlines names
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  hits=$(printf '%s\n' "$scan" | awk '
    {
      n = $0; sub(/:.*/, "", n)
      line = $0; sub(/^[0-9]*:/, "", line)
      while (match(line, /`[~\/A-Za-z0-9_.<>-]+`/)) {
        tok = substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
        if (tok !~ /\.(md|html|csv|txt)$/) continue   # a document this repo writes, not a source file
        # The token class carries `/` and `~` because this repo names the
        # artifacts a run writes as PATHS far more often than as bare
        # basenames (`docs/solutions/<slug>.md`, `references/<name>.md`).
        # Only the basename is graded: the directories a path runs through are
        # not names this check governs.
        base = tok
        sub(/.*\//, "", base)
        gsub(/<[^>]*>/, "", base)                    # a `<placeholder>` is filled at runtime, not a name
        if (base !~ /[A-Z_]/) continue
        print n ":" base
      }
    }
  ' | grep -vE ":($artifact_name_exempt)$") || true
  if [ -n "$hits" ]; then
    badlines=$(linenos "$hits")
    names=$(printf '%s\n' "$hits" | cut -d: -f2- | sort -u | tr '\n' ' ')
    say_fail "$f names an artifact file with an uppercase letter or an underscore (line(s) ${badlines}— ${names}) — a file a run writes is lowercase with dashes, so a later session can predict it; the repo-convention names ($artifact_name_exempt) are the exception"
  fi
}

# (see header) Label family. An ALL-CAPS token in bold or backticks is read as
# a status marker, and DOMAIN.md's Status-marker row is where the family is
# registered — so a token neither registered there nor on the list below is a
# marker coined in a body, which is the drift that row bans.
# Two forms are read, because the suite writes markers both ways: a bold or
# backticked span anywhere in the prose, and a BARE token standing alone in a
# table cell — `| **AC1** | DONE | …`, which is how every canonical status
# table in the suite writes one, and which a typography-only scan cannot see.
# What is not a marker by FORM: a single letter (an option label, a column
# key), a token carrying a digit (an identifier —
# `AC1`, `P2`, `L-04`) or an underscore (a shell or environment name —
# `NO_COLOR`, `TEST_CASE_ID`). What is not a marker by NAME: the list below,
# which is acronyms, SQL and shell keywords, and literals this repo quotes
# from somewhere else (a GitHub visibility, a confirm token, a template
# marker). DOMAIN.md is not scanned: every token in it is registered by
# sitting there.
# Stated scope, so a green run is not read wider than it is: a marker carrying
# a digit or an underscore is skipped by the two FORM rules above, and one
# bare in ordinary prose (not in a table cell) is not read at all — an
# unrestricted bare-CAPS scan over prose would need an exemption list longer
# than the family it guards.
known_caps=' ADO ADR AC ID UI UD DU SQL CI PR HTML CSS CSV TSV API URL CLI OS PHI PII WCAG NPI EOB SMS FHIR MRN HIPAA BAA VPAT ACR AT KT MCP SDK TDD YAML JSON HEAD README CONTRIBUTING ORDER BY SELECT DROP DELETE UPDATE INSERT WHERE CONTAINS TRUNCATE AND OR NOT NULL TITLE TODO STAGES CUTOVER PUBLIC INTERNAL PRIVATE CLOSED YELLOW BREAKING CHANGE YYYY-MM-DD HHMMSS HTTP HTTPS JWT REST XML PDF PNG SVG ARIA DOM LLM RAG GDPR ICD CPT SSN ZIP TTY UTF URI UUID RFC WCAG2 AA AAA SC SCAMPER OCR CRLF DNS TLS SSH JS TS '
# A table cell whose WHOLE content is an ALL-CAPS token, bare. Anchored on the
# cell boundaries so an ALL-CAPS word inside a sentence in a cell is not read.
bare_cell_labels() {
  awk '
    { sub(/^[0-9]*:/, "") }
    /^[[:space:]]*\|/ {
      n = split($0, cells, "|")
      for (i = 2; i <= n; i++) {
        cell = cells[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
        sub(/[.:!?]$/, "", cell)
        if (cell ~ /^[[:upper:]][[:upper:][:digit:] _+-]*$/ && length(cell) > 1) print cell
      }
    }
  ' | sort -u
}

check_labels() {
  local f=$1 scan=${2-} tokens tok
  # DOMAIN.md registers by sitting there; grading it against itself would make
  # every negative example a violation. The exemption lives in the check that
  # owns it, not in the classifier arms that call it.
  case "$f" in DOMAIN.md | */DOMAIN.md) return 0 ;; esac
  if [ "${domain_registries_loaded:-0}" != 1 ]; then
    say_fail "check_labels ran on $f before pass 0 built the DOMAIN.md registries — with an empty registry every label reads as unregistered, so this is a check that did not run, not a verdict on the file"
    return
  fi
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  tokens=$( { printf '%s\n' "$scan" | label_tokens
              printf '%s\n' "$scan" | bare_cell_labels; } | sort -u ) || true
  [ -z "$tokens" ] && return 0
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    case "$tok" in *[0-9]* | *_*) continue ;; esac
    [ "${#tok}" -lt 2 ] && continue
    case "$registered_labels" in *"|$tok|"*) continue ;; esac
    case "$known_caps" in *" $tok "*) continue ;; esac
    say_fail "$f uses the ALL-CAPS label '$tok', which is in none of the three places a label may come from — take one of three exits: register it in DOMAIN.md's Status-marker or Verdict-scale row with the skill that owns it; add it to known_caps in scripts/lint-skills.sh if it is an acronym or a literal quoted from elsewhere; or write it in prose. A marker nobody registered is one no consumer can match"
  done <<< "$tokens"
}

# The two name lists check_heading_case admits mid-heading, beside the
# DOMAIN.md-derived one built in pass 0: proper nouns the glossary has no
# reason to register (a vendor, a language, a format, and the two tracker
# field names this repo quotes verbatim), and the function words title case
# leaves lowercase.
proper_nouns=' Markdown Claude Anthropic Python Git GitHub Azure DevOps Boards Slack Teams Windows Linux macOS English Spanish YAML JSON Acceptance Criteria '
title_case_small=' a an the and or nor but for of to in on at by as vs with from into over per '

# (see header) Heading case, the H2 half. The clause split and the
# already-capitalized tests run in awk, which emits one candidate word per
# line; the shell filters those against the two name lists and reports. The em dash
# is written as literal UTF-8 in the awk program rather than as a `\x` escape,
# which this platform's awk does not read. Every capital test is
# `[[:upper:]]`, never `[A-Z]`: the sweep runs under a UTF-8 ctype (the probe
# above establishes one), where `[A-Z]` is a COLLATION range that includes
# every lowercase letter from `b` on — the H1 test silently passed every
# lowercase word until this was written as a class.
heading_case_candidates() {
  awk '
    function emit(lineno, heading, clause,   n, parts, i, probe, next_word) {
      n = split(clause, parts, " ")
      i = 1
      if (parts[1] ~ /^[0-9]+\.?$/) i = 2       # a numbered step: "4." is the label
      i++                                       # the clause opener is capitalized by right
      for (; i <= n; i++) {
        probe = parts[i]
        gsub(/[(),.*"\047\342\200\231]/, "", probe)
        next_word = (i < n) ? parts[i + 1] : ""
        if (probe == "") continue
        if (probe !~ /^[[:upper:]]/) continue
        if (probe ~ /[0-9]/) continue           # a label form: Tier 2, Phase 3, Step 11
        if (next_word ~ /^[(]?[0-9]/) continue  # the same, with the number as its own word
        if (probe ~ /^[[:upper:][:digit:]-]+$/) continue    # an acronym
        print lineno "\t" heading "\t" probe
      }
    }
    {
      lno = $0; sub(/:.*/, "", lno)
      raw = $0; sub(/^[0-9]*:/, "", raw)
    }
    raw ~ /^## / {
      heading = substr(raw, 4)
      stripped = heading
      gsub(/`[^`]*`/, "", stripped)             # a backticked span is a literal, not prose
      gsub(/ — /, "\n", stripped)               # an em-dash clause opens a new sentence
      gsub(/: /, "\n", stripped)                # so does a colon
      n = split(stripped, clauses, "\n")
      for (c = 1; c <= n; c++) emit(lno, heading, clauses[c])
    }
  '
}

check_heading_case() {
  local f=$1 scan=${2-} h1 w first bad hits lineno heading probe
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  # The two exemptions live here rather than in the classifier arms that call
  # it: a rule file's H1 is a sentence-case proposition and not a display name
  # (write-skill's spine row), so the H1 half would fail every file under
  # global/rules/ and the H2 half has nothing to grade; CLAUDE.md's H1 is the
  # repo's name, not a display name on that axis. Held in the caller, these
  # were two facts a caller had to know, spelled out at six call sites.
  case "$f" in
    global/rules/* | */global/rules/*) return 0 ;;
    CLAUDE.md | */CLAUDE.md) return 0 ;;
  esac
  if [ "${domain_registries_loaded:-0}" != 1 ]; then
    say_fail "check_heading_case ran on $f before pass 0 built the DOMAIN.md registries — with an empty proper-noun set every registered term reads as a violation, so this is a check that did not run, not a verdict on its headings"
    return
  fi
  # No read guard here: house_style_checks is this check's only caller and
  # guards the whole set once. A second guard would be dead code, and a dead
  # guard that a selftest asserts on is worse than none.
  case "$f" in
    */SKILL.md)
      h1=$(printf '%s\n' "$scan" | awk '{ sub(/^[0-9]*:/, "") } /^# / { sub(/^# /, ""); print; exit }')
      if [ -n "$h1" ]; then
        first=1; bad=""
        # Quoted expansion: `for w in $h1` word-split AND glob-expanded the
        # title against the scan root, so a bracketed word vanished and a `*`
        # became every file in the directory.
        local -a h1_words=()
        read -ra h1_words <<< "$h1"
        for w in "${h1_words[@]}"; do
          # Wrapping punctuation is not part of the word: a display name
          # carrying a parenthetical ("Ask for Me (Fixture)") is still title
          # case, and testing the bracket instead of the letter failed every
          # one of them.
          w=$(printf '%s' "$w" | sed -e 's/^[("'"'"'`[]*//' -e 's/[)"'"'"'`.,:;\]]*$//')
          [ -z "$w" ] && continue
          case "$w" in *[0-9]*) first=0; continue ;; esac
          if [ "$first" -eq 1 ]; then first=0; continue; fi
          case "$title_case_small" in *" $w "*) continue ;; esac
          case "$w" in [[:upper:]]*) : ;; *) bad="$bad $w" ;; esac
        done
        [ -n "$bad" ] && say_fail "$f H1 '$h1' is not in title case (lowercase:${bad}) — a SKILL.md H1 is the display name of the skill, so every word but the short function words (${title_case_small# }) is capitalized"
      fi
      ;;
  esac
  hits=$(printf '%s\n' "$scan" | heading_case_candidates)
  [ -z "$hits" ] && return 0
  # One FAIL per heading, not per word: three capitals in one heading are one
  # edit, and three lines for it is three times the noise for the same fix.
  # The grouping runs on a sorted stream, so the accumulator only ever holds
  # the heading it is still reading.
  local at="" seen_heading="" seen_words=""
  # The flush is written once and called twice — from the loop body and after
  # it — because a remedy edited in one of two verbatim copies is the classic
  # way a fix half-lands.
  heading_case_flush() {
    [ -n "$seen_words" ] || return 0
    say_fail "$f H2 '$seen_heading' (line $at) capitalizes${seen_words} mid-heading — an H2 is sentence case, so take one of three exits: lowercase the word; add it to proper_nouns in scripts/lint-skills.sh if it is a proper noun or product name; or register it in DOMAIN.md if it is a term this repo defines"
  }
  while IFS=$'\t' read -r lineno heading probe; do
    [ -z "$probe" ] && continue
    case "$proper_nouns" in *" $probe "*) continue ;; esac
    case "$domain_terms" in *" $probe "*) continue ;; esac
    if [ "$lineno" != "$at" ]; then
      heading_case_flush
      at=$lineno; seen_heading=$heading; seen_words=""
    fi
    seen_words="$seen_words '$probe'"
  done <<< "$hits"
  heading_case_flush
  unset -f heading_case_flush
  return 0
}

# (see header) Section pointers. check_reference_links reads the `.md` inside
# the parens and stops there, so a trailing ` § Name` — the half that says
# WHERE in the file to read — has never been checked, and a section renamed
# out from under a pointer shipped past a green lint. A citation is graded
# only where the line names a target file: an inline link, a `~/.claude/`
# path, or a backticked skill name (whose target is that skill's SKILL.md,
# the form F9's fix introduced). A `§ 4` naming a section of the file it sits
# in has no target and is not read.
# The match is a prefix test in EITHER direction, because a citation is
# written both ways: it runs on into the sentence ("§ Where to write it owns
# the shape", longer than the heading) and it abbreviates a long heading
# ("§ Obligation rulings" for "## Obligation rulings: what goes in, what stays
# behind", shorter than it). Requiring one direction alone made a heading
# carrying a `,` `;` `.` or `)` impossible to cite correctly, because the
# run-on cut truncated the citation at the same character. That is also the
# check's limit — a heading that is a prefix of a longer sibling can be cited
# by the shorter name and pass.
# Not graded: a `§` whose target is named only as "that file" earlier in the
# sentence, and a `§` naming a section of the file it sits in.
section_pointer_candidates() {
  awk '
    {
      lno = $0; sub(/:.*/, "", lno)
      rest = $0; sub(/^[0-9]*:/, "", rest)
      while ((i = index(rest, "§")) > 0) {
        before = substr(rest, 1, i - 1)
        rest = substr(rest, i + length("§"))
        name = rest
        sub(/^ /, "", name)
        if (name !~ /^[[:upper:]]/) continue
        print lno "\t" before "\t" name
      }
    }
  '
}

# The four target forms, as variables rather than inline patterns: a `~` at the
# start of a regex written inline in `[[ =~ ]]` is TILDE-EXPANDED to the home
# directory before the match runs, so both path arms silently matched nothing
# and the check graded the link arm alone while reporting a clean sweep.
section_link_re='\]\(([^)]+\.md)\)$'
section_skills_re='~/\.claude/skills/([a-z0-9-]+)/([A-Za-z0-9/._-]+)`?$'
section_rules_re='~/\.claude/rules/([a-z0-9-]+\.md)`?$'
section_name_re='`([a-z][a-z0-9-]+)`$'
# The fourth form puts the target AFTER the citation — "§ Media and free text
# in [references/media-and-free-text.md](…)". Resolving only from the text
# before the `§` skipped it, and it is the dominant form in the tree.
section_after_re='^(.+) in \[[^]]*\]\(([^)]+\.md)\)'
# Right-trim, written once because check_section_pointers below trimmed the same
# shape at three sites. The result lands in the global $rtrimmed rather than
# coming back through a `$( )`: this runs per citation in one of the costlier
# checks, a shell function is not a fork and a command substitution is.
rtrim_space() {  # <string> -> $rtrimmed, trailing whitespace gone
  rtrimmed=$1
  while :; do case "$rtrimmed" in *[[:space:]]) rtrimmed=${rtrimmed%?} ;; *) break ;; esac; done
}
# The same, plus the dash a citation's lead-in ends on ("... — § The topic").
rtrim_lead_in() {  # <string> -> $rtrimmed, trailing whitespace and dashes gone
  rtrim_space "$1"
  while :; do
    case "$rtrimmed" in
      *— | *-) rtrimmed=${rtrimmed%?}; rtrim_space "$rtrimmed" ;;
      *) break ;;
    esac
  done
}

check_section_pointers() {
  local f=$1 scan=${2-} dir cands lineno before name tail target heading found
  [ -n "${2+set}" ] || scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$f")
  # Most files cite no section at all; a substring test costs no process.
  case "$scan" in *§*) : ;; *) return 0 ;; esac
  dir=${f%/*}; [ "$dir" = "$f" ] && dir=.
  cands=$(printf '%s\n' "$scan" | section_pointer_candidates)
  [ -z "$cands" ] && return 0
  # Every trim below is a parameter expansion, not a `sed`: three forks per
  # citation and one per heading of its target were most of this check's cost
  # (about 3.5 s of a 32 s run, measured 2026-09-01 by dropping the check).
  local short headings
  while IFS=$'\t' read -r lineno before name; do
    [ -z "$name" ] && continue
    rtrim_lead_in "$before"; tail=$rtrimmed
    target=""
    if [[ "$tail" =~ $section_link_re ]]; then
      target="$dir/${BASH_REMATCH[1]%%#*}"
    elif [[ "$tail" =~ $section_skills_re ]]; then
      target="src/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ "$tail" =~ $section_rules_re ]]; then
      target="global/rules/${BASH_REMATCH[1]}"
    elif [[ "$tail" =~ $section_name_re ]]; then
      [ -f "src/${BASH_REMATCH[1]}/SKILL.md" ] && target="src/${BASH_REMATCH[1]}/SKILL.md"
    elif [[ "$name" =~ $section_after_re ]]; then
      name="${BASH_REMATCH[1]}"
      target="$dir/${BASH_REMATCH[2]%%#*}"
    fi
    [ -z "$target" ] && continue
    # The citation runs on into its sentence, so it is cut at the first
    # sentence end; `short` cuts harder, at a comma or a closing paren, and is
    # tried only as a fallback — a heading may legitimately carry either.
    name=${name%%. *}
    rtrim_space "$name"; name=${rtrimmed%.}
    [ -z "$name" ] && continue
    short=${name%%[,;)]*}
    rtrim_space "$short"; short=$rtrimmed
    if [ ! -f "$target" ]; then
      say_fail "$f cites '§ ${name}' (line $lineno) in $target, which is not a file — fix the path or the pointer; check_reference_links reads only the parenthesised half, so a pointer like this one is graded nowhere else"
      continue
    fi
    found=no
    headings=""
    while IFS= read -r heading; do
      heading=${heading#\#}; while [ "${heading#\#}" != "$heading" ]; do heading=${heading#\#}; done
      heading=${heading# }
      [ -z "$heading" ] && continue
      # A step number is a POSITION, not a name: `### 5. The topic glossary` is
      # cited as `§ The topic glossary`, and must stay citable when the section
      # is renumbered — which is the drift that broke the one `<skill>:<line>`
      # citation in the tree. Both forms are accepted.
      headings="$headings'$heading', "
      case "$name" in "$heading"*) found=yes; break ;; esac
      case "$heading" in "$name"*) found=yes; break ;; esac
      [[ $heading =~ ^[0-9]{1,3}\.\ * ]] && heading=${heading:${#BASH_REMATCH[0]}}
      [ -z "$heading" ] && continue
      # Either direction: the citation may run past the heading or abbreviate it.
      case "$name" in "$heading"*) found=yes; break ;; esac
      case "$heading" in "$name"*) found=yes; break ;; esac
      case "$short" in "$heading"*) found=yes; break ;; esac
      case "$heading" in "$short"*) found=yes; break ;; esac
    done <<< "$(grep -E '^#{1,6} ' "$target")"
    # The headings were read to do the match, so the remedy names them rather
    # than telling the maintainer to rename the pointer to a heading it does
    # not print.
    [ "$found" = no ] && say_fail "$f cites '§ ${name}' (line $lineno), and $target carries no heading by that name — rename the pointer to one of ${headings%, }, or rename the heading back; the pointer resolves to a file that loads and a section that is not there"
  done <<< "$cands"
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

# The house-style checks, named once for the same reason — all SIX of them,
# heading case included. Each of the three exemptions now sits in the check
# that owns it (check_labels skips DOMAIN.md, check_heading_case skips
# global/rules/ and CLAUDE.md), so every caller is the same single call and
# no caller has to know which cell its class drops. Spelling them out per arm
# had already cost the DOMAIN.md arm its read guard, 200 lines after the
# comment forbidding exactly that.
house_style_checks() {
  # One read guard for the six, on the taxonomy's terms: a file that cannot be
  # read is a set of checks that never ran, which is a different claim from a
  # file that passed them. Without it an unreadable file drew six awk errors
  # on stderr and a clean line on stdout.
  if [ ! -r "$1" ]; then
    say_fail "$1 could not be read — the house-style checks (spelling, invocation form, artifact names, labels, section pointers, heading case) did not run on it; this is not a verdict on the file"
    return
  fi
  # The fence strip runs ONCE per file, here, and the numbered stream goes to
  # all six. Six checks each opening the file and stripping the same fences was
  # six awk processes per file across a 225-file walk, and `--help`'s "each
  # pass reads its files once" was false the moment the fifth landed. The
  # stream is `<line number>:<text>`, fenced lines dropped, so every check
  # still reports the ORIGINAL line number.
  local scan
  scan=$(awk "$FENCE_AWK"'{ print FNR ":" $0 }' "$1")
  check_spelling "$1" "$scan"
  check_invocation_form "$1" "$scan"
  check_artifact_names "$1" "$scan"
  check_labels "$1" "$scan"
  check_section_pointers "$1" "$scan"
  check_heading_case "$1" "$scan"
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
      # Hoisted prose. Body checks and the house-style checks, and
      # deliberately no slash sweep: a rule file addresses the model directly
      # and names no skill as a command. Heading case is in the house-style
      # set and exempts this class itself.
      body_checks "$f"
      house_style_checks "$f"
      ;;
    src/*/*)
      # A skill's own SKILL.md or a reference beneath it. Everything.
      body_checks "$f"
      house_style_checks "$f"
      case "$f" in */SKILL.md) : ;; *) check_reference_bytes "$f" ;; esac
      owner=${f#src/}; owner=${owner%%/*}
      if [ -f "src/$owner/SKILL.md" ] && ! name_is_user_invoked "$owner"; then
        check_load_gate "$f"
      fi
      check_slash_form "$f"
      ;;
    src/*)
      # Depth one under src/: no owning skill, so no load gate to apply.
      body_checks "$f"
      house_style_checks "$f"
      check_slash_form "$f"
      ;;
    .claude/skills/*)
      # A repo-local skill: swept for the slash form, the house style, and the
      # loaded-file byte FAIL (it is re-attached exactly as a hoisted body
      # is). Its frontmatter is still the author's (see header Scope).
      check_slash_form "$f"
      house_style_checks "$f"
      check_reference_bytes "$f"
      ;;
    DOMAIN.md)
      # The glossary. Swept for the slash form and the house style; the label
      # check exempts this file itself, because every ALL-CAPS token here is
      # registered by sitting here.
      check_slash_form "$f"
      house_style_checks "$f"
      ;;
    README.md)
      # The second router. The slash form and the house style; its size and
      # frontmatter are the author's (see header Scope).
      check_slash_form "$f"
      house_style_checks "$f"
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

# -> every file in the walk carrying the legend line, one per line. One grep
# over the whole list, not one per file: the three ledger checks between them
# asked this question five times per walk, and at a grep per file that was
# about 1,100 processes and 4 s of a 32 s run (measured 2026-09-01). An
# unreadable file is not listed AND is reported: the caller FAILs on return 2.
files_carrying() {  # <walked list> <ERE> -> the files matching it; 2 if one could not be read
  local errs
  # grep's stdout (the matching paths) goes out on fd 3, which is this
  # function's own stdout; its stderr is captured instead of discarded. A file
  # grep could not open is a check that did not run on it, not a file with
  # nothing to report — the swallowed status is what `2>/dev/null || true` used
  # to hide, and what every caller below now reports. xargs adds no diagnostic
  # of its own for grep's "no match" exit 1 (probed), so a non-empty capture is
  # a read error and nothing else.
  { errs=$(printf '%s\n' "$1" | tr '\n' '\0' | xargs -0 grep -lE -- "$2" 2>&1 1>&3); } 3>&1
  if [ -n "$errs" ]; then
    printf '%s\n' "$errs" >&2
    return 2
  fi
  return 0
}

# The shared FAIL for that return: the grep's own error lines are on stderr
# above, so this names what was being looked for and why the silence would lie.
ledger_walk_read_fail() {  # <what the grep was looking for>
  say_fail "a file in the walk could not be read while looking for $1 (the grep error is on stderr above) — that check did not run on it, which is not the same as it having nothing to report"
}
evaluation_ledger_legend_files() { files_carrying "$1" '^Status is exactly one of:'; }

# -> every file in the walk carrying the body's stored-status rule.
evaluation_ledger_rule_files() { files_carrying "$1" 'Exactly one stored status'; }

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
  [ $? -eq 2 ] && ledger_walk_read_fail "the evaluation ledger legend line"
  rule_files=$(evaluation_ledger_rule_files "$walked_files")
  [ $? -eq 2 ] && ledger_walk_read_fail "the evaluation ledger stored-status rule"
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
  local walked_files=$1 legend legend_file v_legend legend_owner f hits present n_present missing
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
  # The anchored set is one grep over the list; the loop then asks a string,
  # not a process, per file. Two read guards, not one: the grep's own stderr
  # (files_carrying's return 2) covers a file it could not open, and the `-r`
  # test below names the file, since the grep's error names it only on stderr.
  local anchored nl=$'\n'
  anchored=$(files_carrying "$walked_files" "$evaluation_ledger_anchor_re")
  [ $? -eq 2 ] && ledger_walk_read_fail "the evaluation ledger anchor"
  while IFS= read -r f; do
    case "$f" in
      "$legend_owner"/*) : ;;
      *)
        if [ ! -r "$f" ]; then
          say_fail "$f could not be read for the evaluation ledger anchor — the vocabulary check did not run on it, which is not the same as it having nothing to report"; continue
        fi
        case "$nl$anchored$nl" in *"$nl$f$nl"*) : ;; *) continue ;; esac
        ;;
    esac
    if ! hits=$(status_tokens_anywhere "$f"); then
      say_fail "$f could not be read for evaluation ledger statuses — the vocabulary check did not run on it, which is not the same as it having nothing to report"
      continue
    fi
    # Both halves read the SAME masked token set. `missing` used to re-grep the
    # RAW file, so on the very input this check exists to catch — two statuses
    # in prose and the third only inside a fenced example — `hits` counted 2
    # (a FAIL) while the raw grep found all three and the FAIL rendered an
    # empty backtick pair where the missing status belongs.
    present=$(printf '%s\n' "$hits" | grep -xF "$v_legend")
    n_present=$(printf '%s\n' "$present" | grep -c .)
    [ "$n_present" -ge 2 ] || continue
    [ "$n_present" -eq 3 ] && continue
    missing=$(printf '%s\n' "$v_legend" | grep -vxF "$present" | tr '\n' ' ')
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
  "src/to-bug/references/github-sub-issues.md|src/to-feature/references/github-sub-issues.md|src/to-story/references/github-sub-issues.md|src/to-tasks/references/github-sub-issues.md|src/chart-course/references/github-sub-issues.md"
  "src/to-bug/references/work-item-tags.md|src/to-feature/references/work-item-tags.md|src/to-story/references/work-item-tags.md|src/to-tasks/references/work-item-tags.md|src/chart-course/references/work-item-tags.md"
  "src/implement/references/completion-audit.md|src/handoff/references/completion-audit.md|src/committing/references/completion-audit.md"
  "src/to-feature/references/ado-html-transport.md|src/to-story/references/ado-html-transport.md|src/to-tasks/references/ado-html-transport.md|src/to-bug/references/ado-html-transport.md|src/chart-course/references/ado-html-transport.md"
  "src/to-feature/references/ac-ids.md|src/to-story/references/ac-ids.md"
)

# The registry above names this repo's own paths, so under LINT_ROOT every
# group would report as missing and drown a fixture's real failures — which
# left byte-identity ungraded and the membership check's "listed -> stay
# quiet" branch reachable only from the real tree, at a whole lint run per
# selftest. LINT_SIBLING_GROUPS replaces the registry for one run, so a
# fixture root can list its own pairs and both checks run there; unset, the
# registry stands and byte-identity runs against this repo alone.
# A seam an agent drives is a seam that gets typed wrong, so both malformed
# shapes are usage errors named before any check runs rather than silences: an
# all-whitespace value parses to an empty array (which under bash 3.2's `set -u`
# aborts the run with no FAIL and no OK line), and a group written with spaces
# where `|` belongs is a one-path group that compares against nothing and runs
# green.
if [ -n "${LINT_SIBLING_GROUPS:-}" ]; then
  read -r -a sibling_groups <<< "$LINT_SIBLING_GROUPS"
  if [ "${#sibling_groups[@]}" -eq 0 ]; then
    echo "lint-skills.sh: LINT_SIBLING_GROUPS is set but names no group — write each group as two or more paths joined by '|', groups separated by spaces, or unset it" >&2; exit 3
  fi
  for sibling_group in "${sibling_groups[@]}"; do
    IFS='|' read -ra sibling_group_paths <<< "$sibling_group"
    if [ "${#sibling_group_paths[@]}" -lt 2 ]; then
      echo "lint-skills.sh: LINT_SIBLING_GROUPS group '$sibling_group' names one path — a group compares copies against each other, so join the paths within a group with '|' and separate groups with spaces" >&2; exit 3
    fi
  done
fi
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
        say_fail "$other drifted from $ref (per ADR-0007 these must stay byte-identical) — copy $ref over it, or, if the divergence is deliberate, split the file under a distinct name and drop it from \`sibling_groups\` in scripts/lint-skills.sh"
      fi
    done
  done
}

# Sibling-group membership: any reference PATH whose basename exists under two
# or more skills must be listed in a group above — an unlisted copy sits
# outside the byte-identity check and drifts silently, the exact failure that
# check exists to prevent. A deliberate variant needs a distinct name (or its
# own group entry).
# Graded per PATH, not per basename. The basename test this replaces asked only
# whether a name was grouped SOMEWHERE, so once `ac-ids.md` was grouped for two
# skills a THIRD copy under a skill the group does not list passed — covered by
# name, ungraded by path, and invisible to check_sibling_identity, which walks
# the group's listed paths and never sees it. A group gaining a new sharer is
# the commoner edit in a suite that adds a fifth and sixth publisher to a group
# of four, so it is the case that has to fire.
check_sibling_membership() {
  local walked_files=$1 grouped_paths shared_bases refs path base
  grouped_paths=$(printf '%s|' "${sibling_groups[@]}" | tr '|' '\n' | grep -v '^$' | sort -u)
  refs=$(printf '%s\n' "$walked_files" | grep '^src/.*/references/.*\.md$')
  [ -z "$refs" ] && return 0
  shared_bases=$(printf '%s\n' "$refs" | awk -F/ '{ print $NF }' | sort | uniq -d)
  [ -z "$shared_bases" ] && return 0
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    base=${path##*/}
    printf '%s\n' "$shared_bases" | grep -qxF "$base" || continue
    printf '%s\n' "$grouped_paths" | grep -qxF "$path" && continue
    say_fail "$path shares the reference basename '$base' with another skill and no sibling group lists this path — add it to sibling_groups in scripts/lint-skills.sh, or rename the deliberate variant; a copy no group lists sits outside the byte-identity check and drifts silently"
  done <<< "$refs"
}

if [ -z "${LINT_ROOT:-}" ] || [ -n "${LINT_SIBLING_GROUPS:-}" ]; then check_sibling_identity; fi

# (see header) Orphaned references. check_reference_links validates a link's
# target and never the other direction, so a reference file nothing points at
# passes every check today while loading for nobody — the failure mode a
# relocation-heavy round produces by the dozen. A reference counts as pointed
# at by an inline link from anywhere inside its own skill (by its path from
# the skill root, or by its basename from a sibling reference), or by the
# `~/.claude/skills/<owner>/<path>` form from anywhere in the walk, which is
# how one skill cites another's reference.
# Scope: src/*/references/ only. A file elsewhere under a skill is not walked,
# and a reference reached by a link form check_reference_links does not
# extract either (reference-style, titled, angle-bracketed) reads as an orphan
# here — the two checks share that boundary on purpose.
check_reference_orphans() {
  local files=$1 r owner rel base orphan_scan_roots
  orphan_scan_roots="src"
  # global/ and the three root files are scan roots because a reference cited
  # ONLY from global/rules/ or from CLAUDE.md/DOMAIN.md/README.md would
  # otherwise read as an orphan. Each is graded: see the orphan rows in
  # scripts/lint-skills-selftest.sh.
  [ -d global ] && orphan_scan_roots="$orphan_scan_roots global"
  [ -d .claude/skills ] && orphan_scan_roots="$orphan_scan_roots .claude/skills"
  for r in DOMAIN.md README.md CLAUDE.md; do [ -f "$r" ] && orphan_scan_roots="$orphan_scan_roots $r"; done
  while IFS= read -r r; do
    case "$r" in src/*/references/*) : ;; *) continue ;; esac
    owner=${r#src/}; owner=${owner%%/*}
    rel=${r#src/$owner/}
    base=${r##*/}
    # An anchored pointer — `](references/foo.md#a-heading)` — is a link.
    # check_reference_links explicitly accepts `.md#`, so a fixed-string match
    # on the closing paren made the fix for one check a violation of the
    # other: a correct anchored link read as "linked from nowhere".
    grep -rqF -- "]($rel)" "src/$owner" && continue
    grep -rqF -- "]($rel#" "src/$owner" && continue
    grep -rqF -- "]($base)" "src/$owner" && continue
    grep -rqF -- "]($base#" "src/$owner" && continue
    grep -rqF -- "~/.claude/skills/$owner/$rel" $orphan_scan_roots 2>/dev/null && continue
    say_fail "$r is linked from nowhere — every reference is opened by a caller that names the condition; add the pointer in src/$owner/SKILL.md, or delete the file (write-skill: a reference nobody opens is content that left a body and arrived nowhere)"
  done <<< "$files"
}

check_sibling_membership "$walked_files"
check_reference_orphans "$walked_files"
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

# (see header) The always-loaded budget. Every file under global/rules/ is
# read on every turn, so the directory's TOTAL is the figure that matters, not
# any one file's — a FAIL, unlike the CLAUDE.md byte WARN above, because this
# bound is this repo's own ruling rather than a platform figure that moves
# under it.
check_rules_bytes() {
  local bytes r one
  [ -d global/rules ] || return 0
  set -- global/rules/*.md
  [ $# -gt 0 ] || return 0
  bytes=0
  for r in "$@"; do
    one=$(wc -c < "$r" | tr -d ' ')
    if [ -z "$one" ]; then
      say_fail "$r could not be read for its byte total — the 12,000-byte budget did not run, so global/rules/ is unmeasured rather than under budget; fix the file's permissions and rerun"
      return
    fi
    bytes=$((bytes + one))
  done
  if [ "$bytes" -gt 12000 ]; then
    say_fail "global/rules/ totals $bytes bytes, over the 12,000-byte budget for the always-loaded layer — cut a rule, or move its procedure behind a reference the depending skill opens and leave a one-line verdict global (ADR-0079: the cap is permanent and a rule that cannot fit is relocated, never refused); every byte here is paid on every turn of every session"
  fi
}
check_rules_bytes

# (see header) The other per-turn load: the `description:` line of every
# model-invoked skill is in the catalog Claude Code loads on every turn, so
# the SUM over src/*/SKILL.md is the figure, not any one file's (that is
# check_description_limits' 1,024-char bound). ADR-0079 fixes the ceiling at
# 13,200 bytes — the 2026-09-04 sum, 13,132, rounded up — and rules it a WARN
# where check_rules_bytes above is a FAIL: the ceiling was set as the day's
# sum rounded up, not a budget argued from load, so it tightens by amendment
# to ADR-0079 rather than blocking a description on its first overrun.
# The measured span is the whole `description:` line, key and value and
# newline, which is what the 13,132 figure counted; a value-only reading
# would report 308 bytes of headroom that do not exist.
check_catalog_bytes() {
  local f skill bytes one
  bytes=0
  for f in src/*/SKILL.md; do
    [ -f "$f" ] || continue
    skill=$(basename "$(dirname "$f")")
    name_is_user_invoked "$skill" && continue
    one=$(grep -m1 -E '^description:' "$f" | wc -c | tr -d ' ')
    bytes=$((bytes + one))
  done
  if [ "$bytes" -gt 13200 ]; then
    echo "WARN: the model-invoked description lines total $bytes bytes, over the 13,200-byte ceiling ADR-0079 fixed for the catalog loaded on every turn — trim the description that grew, or trim others to pay for it; the ceiling does not move"
  fi
}
check_catalog_bytes

# (see header) A global rule's relocated procedure is reached by an absolute
# `~/.claude/skills/<owner>/<path>` pointer — the form ADR-0079 makes the
# standing remedy for a rule that will not fit — and nothing else resolved it:
# check_section_pointers reads only lines carrying `§`, check_reference_links
# reads the `](…)` form. A rename under src/ left the always-loaded layer
# pointing at a file that does not exist with every check green.
check_rule_pointers() {
  local f=$1 ptrs ptr target
  ptrs=$(grep -oE '~/\.claude/skills/[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+' "$f" | sort -u || true)
  [ -n "$ptrs" ] || return 0
  while IFS= read -r ptr; do
    target="src/$(printf '%s' "$ptr" | sed 's|^~/\.claude/skills/||')"
    [ -f "$target" ] || say_fail "$f points at $ptr but $target does not exist — the always-loaded layer names a file no session can open; fix the path, or move the file back"
  done <<<"$ptrs"
}

for f in global/rules/*.md; do
  check_global_rule "$f"
  check_rule_pointers "$f"
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
    # Both messages open with a literal prefix, ahead of every interpolation:
    # discoverable-code's rule is that a message copied out of a log greps back
    # to the line that threw it. Interpolating $f at the front made the whole
    # string unfindable — only the bare fragment "has no selftest" reached the
    # call sites, and the paste hit the selftest's expectation row instead.
    say_fail "selftest-pairing: $f $what — write $st $tail"
  elif [ ! -x "$st" ]; then
    say_fail "selftest-pairing: $st is not executable — chmod +x it, so 'bash' is not the only way this $kind's selftest runs and the roster can be run as a set"
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
# selftest or a library has an executable
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
  # setup-hooks.sh alone: it writes into .git/hooks and has no readable
  # surface to grade without a throwaway clone. Every other script here is
  # gradeable against a fixture or a redirected HOME, so the list is one name.
  case "${sc##*/}" in setup-hooks.sh) return 0 ;; esac
  case "$sc" in
    scripts/git-hooks/*)
      [ -x "$sc" ] || say_fail "$sc is not executable — chmod +x it; git runs a hook under core.hooksPath only when it carries the exec bit, and skips it silently otherwise"
      require_selftest "$sc" "git hook" "has no selftest" "(source scripts/selftest-lib.sh; every git hook under scripts/git-hooks/ is graded by a selftest that runs it against a throwaway repo)"
      ;;
    .claude/skills/*/scripts/*)
      require_selftest "$sc" script "has no selftest" "(source scripts/selftest-lib.sh; every .claude/skills/*/scripts/*.sh is graded by a selftest that runs it against a fixture, the same pairing scripts/ answers to), or name the file *-lib.sh if it is a library"
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
# A repo-local skill's own scripts/ is walked too. ADR-0075:23 recorded that no
# gate walked .claude/skills/*/scripts/, so the enumerator's stderr count landed
# with no selftest "by that scope, not by omission" — a deliberate scope rather
# than an oversight. Its 2026-09-01 amendment closes that: enum.sh drives the
# first step of every mining round, so the script with the widest blast radius
# was the one script nothing graded. Same contract as scripts/ — a *.sh here is
# paired with its selftest or named *-lib.sh.
for sc in .claude/skills/*/scripts/*.sh; do
  [ -f "$sc" ] && check_script_selftest "$sc"
done
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

# The spelling-only trees. docs/, the prose READMEs and global/README.md are
# read by people rather than loaded as instructions, so no other check here
# walks them — but a British form in an ADR is the same drift as one in a
# body, and this is the one check whose scope ADR-0077 wrote wider than the
# skill tree. A separate walk because it is a separate glob: nothing else
# reads these files. `find docs` rather than two enumerated levels, because
# the header states the scope as `docs/**` and `capturing-learnings` writes to
# `docs/solutions/`, which a two-level glob would never reach. The prose
# READMEs under scripts/ are here and not in the scripts/ exclusion above:
# the exclusion buys out of separating prose from machine-matched literal
# inside shell, and a README carries no literals. The two FIXTURE READMEs are
# NOT in this glob: each is a fixture whose job is to carry a violation for a
# LINT_ROOT run, so walking them from the repo's own run would report the
# fixture's deliberate instance as this repo's defect.
while IFS= read -r f; do
  [ -f "$f" ] && check_spelling "$f"
done < <({ [ -d docs ] && find docs -type f -name '*.md'
           printf '%s\n' global/README.md scripts/README.md
         } | sort -u)

# (see header) The `Landing:` key. `committing` § Before any outward act reads
# six lines out of CLAUDE.md and lets four of them pre-authorize an outward
# act — a push, a ticket close — so a typo in a key name or a value does not
# read as a malformed contract, it reads as "no block, nothing pre-authorized"
# or, worse, as a yes. Before this the key was a four-copy prose contract
# (CLAUDE.md, README.md, `committing`, `onboard-repo`) with nothing parsing it,
# which is how a nonsense value survives every gate.
#
# What this grades: key spelling, value vocabulary, and one presence rule. It
# does NOT require a `Landing:` block to exist, and inside a block that does
# exist every key but one is optional — `committing` says a missing line means
# `no`, so absence is a defined state and only a WRONG line is a defect. The
# exception is `Review required:`, which a block that exists must name; the arm
# at the bottom of this function carries the reason. The pre-2026-08-30
# `pre-authorised` spelling is accepted here for the same reason `committing`
# reads it: the key was renamed, not retired.
#
# The three keys whose value may carry a trailing parenthetical. `Review
# required:` is not among them and has its own arm, because the hook that reads
# it anchors at end of line.
landing_yesno_keys=' pr-required push-pre-authorized ticket-close-pre-authorized '
check_landing_key() {
  local f=$1 in_block=0 saw_block=0 line raw key val norm saw_review=0 masked
  # ADR-0072: an unreadable file is not a block-free file. Without this the
  # grep below fails, the check returns 0, and a repo whose CLAUDE.md cannot
  # be read reports as one whose Landing: key is well-formed.
  if [ ! -r "$f" ]; then
    say_fail "$f could not be read — the Landing: key check did not run on it, so nothing here says whether the push and ticket-close pre-authorizations are well-formed; this is not a verdict on the file"
    return
  fi
  # Fenced lines are not read, the way every other markdown check in this file
  # reads a file and the way global/hooks/review-receipt.sh reads this same
  # contract: a `Landing:` block shown inside a fenced example is an
  # illustration. Reading one consumed the whole check — an illustration above
  # the real block satisfied every arm, including the deletion arm below.
  masked=$(awk "$FENCE_AWK"'{ print }' "$f")
  printf '%s\n' "$masked" | grep -qE '^[[:space:]>]*\**`?Landing:`?\**[[:space:]]*$' || return 0
  while IFS= read -r line; do
    if [ "$in_block" -eq 0 ]; then
      printf '%s' "$line" | grep -qE '^[[:space:]>]*\**`?Landing:`?\**[[:space:]]*$' && { in_block=1; saw_block=1; }
      continue
    fi
    # The block is the contiguous run of bullets under the header: a blank line
    # ends it, and so does anything that is not a bullet. Without the blank-line
    # end, an unrelated list further down the file reads as Landing keys. A
    # bullet is read the way global/hooks/review-receipt.sh's OPT_IN reads one
    # — `-` or `*`, any indent, a `>` quote prefix — so the two readers of one
    # contract cannot disagree about what a line in the block is. Ending a block
    # is not ending the file: a later header starts another one.
    printf '%s' "$line" | grep -qE '^[[:space:]>]*[-*][[:space:]]' || { in_block=0; continue; }
    # The line as the author wrote it, less the bullet. Every FAIL below quotes
    # this and nothing else, so the string in the message is one an author can
    # grep their own file for; the normalized forms are for comparison only.
    raw=$(printf '%s' "$line" | sed -E 's/^[[:space:]>]*[-*][[:space:]]+//; s/[[:space:]]+$//')
    case "$raw" in *:*) key=${raw%%:*}; val=${raw#*:} ;; *) continue ;; esac
    # Normalize away the bold, the backticks, the case and the spaces, so the
    # check reads the same key a human writing `- **Push pre-authorized:** yes`
    # meant. `pre-authorised` folds to the current spelling.
    norm=$(printf '%s' "$key" | tr -d '*`' | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g; s/pre-authorised/pre-authorized/')
    # An HTML comment on the line is a marker for another check, not part of
    # the value: without this strip the value reads 'maybe <!-- ... -->' and no
    # arm below recognizes it.
    val=$(printf '%s' "$val" | sed -E 's/<!--.*-->//' | tr -d '*`' \
      | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | tr '[:upper:]' '[:lower:]')
    case " $norm " in
      ' branch-policy ')
        case "$val" in
          trunk | trunk\ * | branch-per-ticket | branch-per-ticket\ *) ;;
          *) say_fail "$f Landing: '$raw' — the vocabulary is 'trunk' or 'branch-per-ticket' (a naming pattern may follow), and \`committing\` reads no third value, so this line pre-authorizes nothing it looks like it pre-authorizes" ;;
        esac
        ;;
      ' defect-policy ')
        [ -n "$val" ] || say_fail "$f Landing: '$raw' has no value — name the policy ('fix, don't file' is the default \`committing\` states) or drop the line"
        ;;
      ' review-required ')
        saw_review=1
        # The one key that takes no parenthetical. global/hooks/review-receipt.sh
        # anchors its OPT_IN pattern at end of line, so `yes (planned)` matches
        # nothing there, the walk finds no line, and the repo is ungated — the
        # same silent disarm the deletion arm below exists to prevent, reached
        # by a value rather than a deletion. The hook's own selftest stages it.
        case "$val" in
          yes | no) ;;
          *) say_fail "$f Landing: '$raw' — 'Review required:' reads a bare 'yes' or 'no' and nothing after it, because global/hooks/review-receipt.sh matches the value to end of line: a parenthetical arms no gate, so the push goes out with no Reviewed-tree: stamp and nothing reports it" ;;
        esac
        ;;
      *)
        case "$landing_yesno_keys" in
          *" $norm "*)
            case "$val" in
              yes | yes\ * | no | no\ *) ;;
              *) say_fail "$f Landing: '$raw' — the pre-authorization keys read 'yes' or 'no' (a parenthetical may follow), and \`committing\` treats anything else as no block at all; write yes or no, or drop the line" ;;
            esac
            ;;
          *)
            say_fail "$f Landing: '$raw' is not one of the six keys \`committing\` § Before any outward act reads (Branch policy, PR required, Push pre-authorized, Ticket close pre-authorized, Review required, Defect policy) — nothing parses this line, so it states a contract no tool honors; fix the spelling, or move the sentence out of the block"
            ;;
        esac
        ;;
    esac
  # A here-string, not a pipe: the loop assigns saw_review, and a pipe would run
  # the body in a subshell and discard it.
  done <<< "$masked"
  # The deletion half, and the reason this check exists at all. `committing`
  # reads a missing `Review required:` line as `no`, so dropping the line from
  # a repo that gates on it turns the push gate off and reads, from every
  # angle, like a repo that never had one: global/hooks/review-receipt.sh arms
  # on that line alone. A block that is written at all names the key, so the
  # gate cannot be disarmed by a deletion nothing reports. A repo that does
  # not gate says so in the line — `no` satisfies this. saw_block, not
  # in_block: a block that ended before the file did is still a block.
  if [ "$saw_block" -eq 1 ] && [ "$saw_review" -eq 0 ]; then
    say_fail "$f has a Landing: block with no 'Review required:' line — \`committing\` reads the absence as 'no', so a gate deleted and a gate never configured are the same text; write 'Review required: no' if that is the policy, and 'yes' where global/hooks/review-receipt.sh should refuse a push with no matching Reviewed-tree: stamp"
  fi
}

# Every CLAUDE.md in the tree, not the root one alone. global/hooks/review-receipt.sh
# walks upward from the directory a push runs in and the NEAREST file carrying
# `Review required:` decides, in either direction — so a block under a
# subdirectory opts that subtree out of the repo's push gate while `git push`
# stays repo-scoped, and a monorepo's package files are where that block goes
# unreported. The FIXTURE roots are excluded on the rule the docs/** walk below
# states for the fixture READMEs: each is a file whose job is to carry a
# deliberate violation for a LINT_ROOT run, and walking it from this repo's own
# run would report that instance as this repo's defect. Their own CLAUDE.md is
# checked under LINT_ROOT, where it is the root file. What that exclusion does
# NOT buy back is a legal-but-wrong value in a fixture — `Review required: no`
# is well-formed vocabulary and no arm here fires on it; the property pins in
# scripts/lint-skills-selftest.sh are what hold that line.
while IFS= read -r claude_md; do
  [ -n "$claude_md" ] || continue
  check_landing_key "${claude_md#./}"
done < <(find . -name CLAUDE.md -not -path './.git/*' -not -path './scripts/lint-fixtures*/*' | sort)

if [ -f CLAUDE.md ]; then
  check_claude_md_bytes CLAUDE.md
  # ADR-0076 left the root file as triggers and pointers; a pointer to a
  # missing file silently loads nothing, so the root file gets the same link
  # check every shipped markdown file gets — pass 2's parser, reused rather
  # than a second extractor, so the two cannot disagree about scope.
  check_reference_links CLAUDE.md
  # The root file is an instruction file like any other: it names skills, cites
  # sections, and is written in this repo's prose. Heading case is in the set
  # and exempts this file itself.
  house_style_checks CLAUDE.md
fi

# The one read of the flag, and the whole exit. There is no `fail` variable to
# pair with it, on purpose: see scripts/lint-lib.sh's header.
[ -e "$LINT_FAIL_FLAG" ] && exit 1
echo "OK: skill conventions clean."
exit 0
