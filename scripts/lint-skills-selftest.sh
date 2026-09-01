#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/lint-skills.sh still catches what it claims to catch.
#
# A lint gate degrades silently: the run stays green whether the rule holds or
# the check quietly stopped matching, and the two are indistinguishable from
# the outside. This script points the linter at scripts/lint-fixtures/ — a tiny
# repo root whose skills are wrong on purpose — and grades it in both
# directions: every expected failure must appear, and the forms the linter
# exempts must produce no failure at all. A one-directional check would pass
# just as happily against a linter that flagged everything.
#
# Four roots in all. The wrong-on-purpose tree; scripts/lint-fixtures-clean/,
# which is right on purpose and must exit 0; six throwaway copies of the clean
# tree with exactly one edit each, for branches whose effect is on the EXIT
# STATUS rather than on the output; and throwaway copies of both trees with one
# file's mode broken, because the read-error branches cannot be reached from a
# committed fixture — git stores only the exec bit, so an unreadable mode does
# not survive checkout. The clean root is what lets an exit-status assertion
# mean anything: in the wrong-on-purpose tree the deliberate violations force
# exit 1 no matter what the induced failure does — their count is pinned below,
# in one place, rather than restated here where it would drift every time a
# check is added.
#
# Run it after changing any check in lint-skills.sh.
#
# Covered here: reference-link resolution (both directions, including the
# backtick-span and fenced-block exemptions), the ADR-citation ban, the
# rich-text transport ban, the
# description's unquoted ': ' and ' #', load-gate placement (in a SKILL.md and
# in a reference file beneath it), and the global-rules
# Depends: admission check (missing line, dangling name, a dependant that never
# cites the rule outside a fence, a dependant that cites only another rule's
# path, and the three well-formed forms that must stay quiet — backticked stem,
# path, and a citation in the opening lines of a body whose tail the producer is
# still writing when the reader walks away, which grades the check's plumbing
# rather than its pattern).
#
# The pass-2 classifier's per-class routing is covered: every class the walk
# emits has a fixture that fires for it — a skill body and a reference beneath
# it, a global rule (`global/rules/body-checked.md`, the body checks only, since
# the slash sweep is meant to skip that class), a repo-local skill under
# `.claude/skills/`, the two routers `DOMAIN.md` and `README.md`, and a bare
# `src/*.md` at depth one — and each of the four body checks is named in a row
# of its own, so a cell dropped from one arm reds this run.
#
# The evaluation ledger's stored-status vocabulary is covered in both
# directions and at two levels: the substring rows below for its firing shapes
# and its three quiet ones (one status referenced, two statuses with nothing
# anchoring them, an enumeration inside a fenced example), one row per
# alternative in the anchor regex, and the isolated roots for the branches that
# return early — a fourth status in the legend, a second legend, a second rule
# site, the legend sentence reworded away, and the rule phrase reworded away.
# The last two are the edit an ordinary writing pass makes, and they are graded
# because the two anchors pin each other: a tree carrying one without the other
# fails, whatever root it is.
#
# The nine house-style checks (round plan §5) are covered in both directions,
# with one instance per ALTERNATIVE rather than one per check: British spelling
# (a form in prose fires; the same word in a code span and in a URL stays
# quiet), heading case (a SKILL.md H1 not in title case, and an H2 with three
# mid-heading capitals, fire; an acronym, a word whose number is the next
# token, a word carrying its own digit, and an em-dash clause opening after a
# numbered label all stay quiet), invocation form (the descriptive "the X
# skill" and a bare user-invoked name at a suggestion site fire; a model-invoked
# name at the same site stays quiet), artifact filenames (an uppercase name and
# an underscored one fire in one line whose rendered list is pinned; a
# repo-convention name stays quiet), the label family (an unregistered token in
# bold and one in backticks fire; a token registered in that tree's DOMAIN.md
# stays quiet, and an isolated root takes the registration away to prove the
# check reads the glossary rather than its own list), section pointers (all four
# target forms fire — an inline link, a backticked skill name, a
# `~/.claude/skills/` path and a `~/.claude/rules/` path — as does the branch
# where the target names no file; a pointer that resolves stays quiet), and
# orphaned references (one unlinked file fires; the three forms that count as a
# pointer — a path from the skill root, a basename from a sibling reference, and
# the installed path cited from another skill — each stay quiet). The
# always-loaded byte budget and the loaded-file byte WARN cannot be carried by a
# committed fixture without every root paying the bytes, so each takes an
# isolated one-edit copy of the clean root: the budget row asserts the FAIL and
# exit 1, the WARN row asserts the line, that it is NOT rendered as a FAIL, and
# that the root still exits 0. Every quiet form above is asserted PRESENT in its
# fixture by a `quiet_pin` row, so deleting one reds this run rather than
# turning a reject row into a no-op. Both read guards are covered below with the
# other read-error branches.
#
# All four read-error branches are covered, by a runtime `chmod 000` on
# throwaway copies rather than by a fixture: the link extractor's, the Depends:
# citation check's, the line cap's, and the ledger checks' two (the anchor grep,
# and the status-token read on a file inside the legend's own skill, which is
# the only place that branch is reachable — everywhere else the anchor grep
# fails first). Each reports that a check never ran rather than that it passed.
#
# The two-way requires check is covered in both directions across the
# forms the matcher must reach — an imperative call, a gerund one, two names in
# one clause, and a call on a user-invoked skill, each firing; a quoted, an
# arrow-parenthesised and a fenced mention staying quiet. The
# slash check is covered the same way, in a SKILL.md and in a reference file
# (the wider sweep), in both its arms: a slash form naming a model-invoked
# skill, and one naming no skill at all. Four quiet forms across two exemption
# mechanisms stay quiet — a user-invoked skill, a built-in and a roster name,
# and a name marked `<!-- slash-exempt: -->` ON ITS OWN LINE — with the same
# marker one line away from its name firing, which is what pins the marker's
# line scope.
# Also covered: the Landing: key check, in both directions and across the two
# roots — four malformed lines and two more under a bold and a backtick header
# in the wrong-on-purpose root (so a header form and a bullet form the
# review-receipt hook accepts cannot be narrowed out of this check silently),
# the quiet forms in the clean root (a bold key, a parenthetical after a yes/no
# value, an apostrophe in a free-text value, and an unrelated bullet list under
# the block that a blank line ends), the missing-`Review required:` arm and the
# negative value in two throwaway copies of that root, and the unreadable-file
# arm; the walk itself, through a CLAUDE.md below the root that no other check
# reaches; the single-line-description check in three shapes (a folded
# block scalar, a literal one with an indentation indicator, a continued plain
# scalar), the re-attach byte-size WARN (fires on the oversize fixture, draws
# no FAIL, stays silent on the clean root, and stays silent on the clean
# root's near-cap body under the bound — so the threshold is pinned
# from below as well as above), the hook-selftest check (a marked hook with no
# selftest, one whose selftest lacks the exec bit, an unmarked file that must
# stay quiet whatever its name, and a *-lib.sh), the script-selftest check
# (a script with no selftest, one whose selftest lacks the exec bit, and the
# quiet forms: a *-lib.sh and setup-hooks.sh — with install.sh beside them
# firing, so a one-name exemption is told from a two-name one), the same check
# over
# scripts/git-hooks/ (a hook with no selftest — with the hook-shaped remedy —
# one whose selftest lacks the exec bit, one that lacks the exec bit itself,
# a shebang-less README that is not a hook and must stay quiet, and a paired
# executable hook in the clean root that must stay quiet), the conventions
# pointer (one script lacking it fires; a shebang-less library carrying it on
# line 1, and every other fixture script carrying it on line 2, stay quiet),
# the clean run's stderr (no "command not found"), the
# CLAUDE.md byte WARN (fires on the oversize root fixture, draws no FAIL, and
# stays silent on the clean root's near-cap CLAUDE.md under the bound, so that
# threshold too is pinned from both sides), the root CLAUDE.md link check (the
# fixture root's CLAUDE.md links to a missing target and fires naming the link
# and its line; the clean root's CLAUDE.md carries a resolving link — pinned
# present below — and stays quiet), the shared-trigger-phrase check (two
# model-invoked descriptions carrying one phrase in different cases, in both
# quote styles, and inside a whole-value YAML double-quoted scalar fire once as
# one line naming all three; a user-invoked description carrying the same
# phrase is not read, a disambiguating "Not for…" tail quoting it stays quiet,
# and in the clean root one description quoting a phrase twice, with the
# user-invoked router quoting it too, draws nothing — and every one of those
# fixture properties is asserted present, so weakening a fixture reds this run
# rather than retiring a row), the
# pinned FAIL count against the broken tree (a check that begins false-positiving on a fixture reds here
# even when no substring row names it), and argument handling (--help runs
# nothing and exits 0, an unknown argument, two arguments, and an empty
# argument run nothing and exit 3, a LINT_ROOT that is not a directory runs
# nothing and exits 2).
#
# NOT covered, so a clean run here is not a claim about them: the 200-line caps
# (the read-error branch is graded, the cap itself is not), sibling
# byte-identity (skipped under LINT_ROOT — the registry names this repo's own
# paths; the MEMBERSHIP half beside it IS covered as of 2026-09-01, by the two
# `ac-ids.md` copies under src/bulk-cited-dep/ and src/quoted-dep/ — a basename
# the REAL registry groups, carried by two paths it does not list, so the
# pre-2026-09-01 basename reading stays quiet on them and the path reading fires
# twice; if `ac-ids.md` ever leaves sibling_groups those rows still fire but stop
# discriminating the two readings, and both copies must be renamed to another
# grouped basename then), description length, angle brackets, name/directory agreement, the
# requires: resolution check (existence and model-invoked), router coverage,
# and the classifier's unclaimed-file arm — walk_shipped_md emits only the
# classes the arms above it claim, so no fixture can produce a path that
# reaches its say_fail; it guards a tree added to the walk without an arm, and
# has no input to grade it with. The FIVE name lists inside the checks are
# graded by property rather than by member, because a member row grades one
# word and says nothing about the other 259: british_words, known_caps,
# proper_nouns, invocation_verbs and artifact_name_exempt each carry a
# member-count pin below, so a word silently dropped from any of them fails
# here naming the list. What a count pin does NOT buy: which member went, or
# that a member still has a fixture instance behind it.
#
# What the covered list buys, stated no larger than it is: those shapes cannot
# stop grading without this script saying so. It was measured, not assumed —
# 31 mutations of lint-skills.sh graded by this script, 30 red and 1 silent
# (the unclaimed-file arm above), and 24 more when the nine house-style checks
# landed: each of the nine dropped from its caller; the H1 title-case test
# disabled; each of the four section-pointer target arms dropped; the orphan
# check's basename and installed-path arms dropped; the artifact-name exempt
# list dropped; the spelling check's code-span strip and its URL strip dropped;
# the heading-case acronym, next-token-number and own-digit exemptions dropped;
# the label check's digit-and-underscore exemption dropped; and the DOMAIN.md
# lookups in check_labels and check_heading_case each made to miss. All 24 red
# — two of them only after the fixture that grades them was written, which is
# what a mutation run is for. Ten more when the Landing: key check and the
# per-line slash marker landed: the fence mask dropped from check_landing_key,
# its header regex narrowed to the bare form (twice — the gate grep and the
# in-loop one, only the second of which is graded), its bullet test narrowed to
# `- ` at column 0, its blank-line-ends-block rule dropped, its key bold strip
# dropped, `branch-per-ticket` dropped from the branch-policy arm, the
# `Review required:` arm widened to take a parenthetical, the slash marker
# collected file-wide instead of per line, and the sibling-membership check's
# `listed -> stay quiet` branch deleted. Nine red; the gate grep's narrowing is
# the one silent mutation, because the wrong-on-purpose root's first block
# carries the bare header either way, so the check still runs and the in-loop
# regex beside it is what decides which blocks it reads. The 30: each of the three ledger check calls
# removed; the consumer sweep's process substitution turned into a pipe, its
# `hits -ge 2` loosened to `-ge 1`, its `hits -eq 3` moved to `-eq 4`, its
# legend-owner wholesale arm removed, and its mask_examples dropped; the
# two-legends branch, the legend's arity-3 test, and the
# no-legend-but-a-rule-exists branch each disabled; the no-rule-site branch,
# the two-rule-sites branch and the legend-versus-rule comparison each
# disabled; each of the anchor regex's four alternatives dropped one at a time;
# body_checks dropped from the global/rules arm, the depth-one src/*.md arm
# deleted, the default arm narrowed to .claude/skills/, and the slash sweep
# dropped from the src/*/* arm; each of the four body checks removed from
# body_checks one at a time; the line-cap, anchor-grep and status-token
# read-error guards each removed; the empty-walk guard removed; and the
# consumer-sweep-did-not-run note removed from the authority-failure path.
# Turning the
# process substitution into a here-string instead is behavior-preserving — no
# subshell, so `fail=1` survives — and is correctly green.
#
# PARTIAL, and what it does and does not mean. Six sites can skip: three in the
# isolated-roots block (no usable temp directory, a copy that fails, an edit
# whose pattern matched nothing) and three in the read-error block (no usable
# temp directory, a copy that fails, or a run that can still read the file after
# chmod 000 — root, or a filesystem that ignores modes). Each prints a SELFTEST
# SKIP line naming what went ungraded, downgrades the closing line from OK: to
# SELFTEST PARTIAL:, and makes the script exit 2 rather than 0 — a third status,
# so a caller reading the status alone can still tell a narrower clean from a
# whole one. The closing PARTIAL line does not name which block skipped; the
# SKIP lines do, because more than one can fire in a run.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

fixtures="scripts/lint-fixtures"
if [ ! -d "$fixtures" ]; then
  selftest_fail "fixture tree $fixtures is missing"
  exit 1
fi

# The mirror tree: right on purpose, so an induced failure is attributable to
# the thing induced. See the read-error block near the bottom.
clean_fixtures="scripts/lint-fixtures-clean"
if [ ! -d "$clean_fixtures" ]; then
  selftest_fail "clean fixture tree $clean_fixtures is missing"
  exit 1
fi

output=$(LINT_ROOT="$fixtures" bash scripts/lint-skills.sh 2>&1)
status=$?

# Grading both directions. Each `expect` names a check and a substring only
# that check's message can produce; each `reject` names a form the linter must
# leave alone. The matcher is scripts/selftest-lib.sh's (expect_in/reject_in:
# haystack, what went wrong and where, the substring only the graded check can
# produce); the wrappers below give each root its own wording.
expect() {
  expect_in "$output" "the $1 check did not fire on the fixture tree" "$2"
}

reject() {
  reject_in "$output" "the $1 check fired on a form it must exempt" "$2"
}

# The line number is pinned, not just the path: reporting the wrong line is the
# defect this field was added to fix. Moving that link in the fixture is meant
# to fail here until the number is updated with it.
expect "reference-link resolution" "links to 'references/does-not-exist.md' (line 14)"
expect "ADR-citation ban" "cites a repo ADR by number"
expect "rich-text transport ban" "src/unused-dep/references/shell-transport.md passes HTML through the shell (line(s) 3 )"
expect "description colon" "description has unquoted ': '"
expect "description hash" "description has unquoted ' #'"
expect "load-gate placement" "carries a load gate ('Launching skill'"
expect "global-rule Depends (missing)" "global/rules/no-depends.md has no 'Depends:' line"
expect "global-rule Depends (dangling)" "global/rules/dangling-depends.md Depends: names 'no-such-skill'"
expect "global-rule Depends (uncited)" "global/rules/uncited-depends.md Depends: names 'quoted-dep' but src/quoted-dep/ never cites the rule"
expect "global-rule Depends (directory only)" "global/rules/dir-only-cited.md Depends: names 'unused-dep' but src/unused-dep/ never cites the rule"
expect "global-rule Depends (other rule's path)" "global/rules/other-path-cited.md Depends: names 'unused-dep' but src/unused-dep/ never cites the rule"
expect "global-rule Depends (unmarked stem)" "global/rules/bare-stem-cited.md Depends: names 'unused-dep' but src/unused-dep/ never cites the rule"
expect "two-way requires (undeclared)" "src/undeclared-dep/SKILL.md calls the Skill tool with \`fixture-discipline\` but its requires: line does not declare"
# The gerund and the two-name clause are separate matcher reaches: the first name
# grades 'calling', the second grades that the clause does not end at name one.
expect "two-way requires (gerund form)" "src/call-forms/SKILL.md calls the Skill tool with \`fixture-discipline\` but its requires: line does not declare"
expect "two-way requires (second name in one clause)" "src/call-forms/SKILL.md calls the Skill tool with \`broken-links\` but its requires: line does not declare"
expect "Skill-tool call on a user-invoked skill" "src/call-forms/SKILL.md calls the Skill tool with \`quoted-dep\`, but 'quoted-dep' is user-invoked"
expect "slash-on-model-invoked" "src/slash-on-model-invoked/SKILL.md writes \`/fixture-discipline\`, but 'fixture-discipline' is model-invoked"
# The check sweeps past src/*/SKILL.md: a references/ template is where the convention
# regresses unseen, because that is what a publisher writes from.
expect "slash-on-model-invoked (reference file)" "src/slash-on-model-invoked/references/retired-form.md writes \`/fixture-discipline\`"
# The dangling arm: a slash form naming no skill in either tree. Its two quiet
# neighbours are the roster and the line marker, rejected below — without both,
# the arm could be widened to fire on every unresolved name with this row still
# green, which is the shape that would red the whole repo.
# install.sh left the exempt list on 2026-09-01, and the fixture keeps both
# names so the row discriminates: a check that re-exempted install.sh, or that
# dropped the exemption entirely, moves exactly one of this row and the
# setup-hooks reject below.
expect "script selftest (install.sh is no longer exempt)" "scripts/install.sh has no selftest"
expect "slash names no skill (dangling)" "src/slash-on-model-invoked/SKILL.md writes \`/no-such-command\`, and no skill of that name is in src/ or .claude/skills/"
# The marker's SCOPE, from the other side: the same shape with its marker one
# line below fires. Collect the markers file-wide instead and this row goes
# quiet while `/checkout-page` stays quiet too, so the check would bless every
# later dangling name in a body that carries one marker anywhere.
expect "slash names no skill (marker on another line)" "src/slash-on-model-invoked/SKILL.md writes \`/order-status\`"
# The pass-2 classifier's per-class routing, graded here because nothing else
# reaches it: a rule file is the only class the body checks and the slash sweep
# disagree about, .claude/skills/ and the two routers are the only classes the
# slash sweep reaches alone, and src/*.md at depth one is the only class with no
# owning SKILL.md. A classifier that drops any one of them reads exactly like one
# that never carried it, so each has a row below.
# The load gate's reference-file half: narrowing the load-gate class to
# src/*/SKILL.md is a regression no SKILL.md fixture can see.
# The evaluation ledger's stored-status vocabulary, graded in both directions.
# The legend is found by content, so these fixtures carry their own — the checks
# are not pinned to this repo's paths and need no skipping under LINT_ROOT.
expect "ledger vocabulary (two authorities disagree)" "define different vocabularies — src/ledger-legend/references/legend-line.md's legend has (contradicted marketed verified) and src/ledger-legend/SKILL.md's stored-status rule has (marketed refuted verified)"
expect "ledger vocabulary (consumer drops one)" "missing from src/ledger-consumer/SKILL.md — it names 2 of the 3 and not \`contradicted\`"
expect "ledger vocabulary (legend dir is anchored wholesale)" "missing from src/ledger-legend/references/unanchored-in-legend-dir.md"
expect "ledger vocabulary (anchored consumer in the legend's own skill)" "missing from src/ledger-legend/SKILL.md"
# One row per alternative in the anchor regex, each fixture matching exactly one
# of them, so an alternative deleted from the regex reds exactly one row here.
# Without these the fixtures anchored redundantly and five of the six
# alternatives could be dropped one at a time in silence.
expect "ledger anchor (docs/evaluation/ path)" "missing from src/ledger-consumer/references/anchor-docs-path.md"
expect "ledger anchor (evaluation-ledger slug)" "missing from src/ledger-consumer/references/anchor-skill-slug.md"
expect "ledger anchor (Evaluation ledger in prose)" "missing from src/ledger-consumer/references/anchor-prose-form.md"
expect "ledger anchor (a bare ledger.md file name)" "missing from src/ledger-consumer/references/anchor-file-name.md"
expect "load-gate placement (reference file)" "src/broken-links/references/load-gated.md carries a load gate"
expect "body checks on a global rule (link)" "global/rules/body-checked.md links to 'references/no-such-rule-file.md' (line 12)"
expect "body checks on a global rule (ADR)" "global/rules/body-checked.md cites a repo ADR by number"
expect "slash-on-model-invoked (repo-local skill)" ".claude/skills/repo-local/SKILL.md writes \`/fixture-discipline\`"
# The classifier's other three cells, each the only input its arm has. Without
# them the depth-one src/*.md arm could be deleted, the DOMAIN.md and README.md
# names could be dropped from the default arm, and the transport ban could be
# lifted off the rule class, with every root here still green.
expect "body checks on a file at depth one under src/" "src/stray-note.md cites a repo ADR by number"
expect "slash-on-model-invoked (DOMAIN.md)" "DOMAIN.md writes \`/fixture-discipline\`"
expect "slash-on-model-invoked (README.md)" "README.md writes \`/fixture-discipline\`"
expect "body checks on a global rule (HTML transport)" "global/rules/body-checked.md passes HTML through the shell"
# The Landing: key, one row per alternative. Each needle carries the line as the
# fixture writes it, because the FAIL quotes the raw line: fold the case or strip
# the marker in the message and these rows red. The missing-`Review required:`
# arm is graded in an isolated copy of the clean root below, since this root's
# first block names the key.
expect "Landing key (branch policy vocabulary)" "Landing: 'Branch policy: squash-merge'"
expect "Landing key (a pre-authorization value that is neither yes nor no)" "Landing: 'Push pre-authorised: MAYBE <!-- spelling-exempt: authorised -->'"
expect "Landing key (empty value)" "Landing: 'Defect policy:' has no value"
expect "Landing key (a key committing does not read)" "Landing: 'Merge policy: squash' is not one of the six keys"
# The second and third blocks in the same file, under the bold and backtick
# header forms. Both die if the header regex narrows to the bare form, and the
# third dies as well if the block reader latches on the first header instead of
# resuming — which is how a fenced example consumed the whole check.
expect "Landing key (a parenthetical after Review required)" "Landing: 'Review required: yes (planned)'"
expect "Landing key (a second block, backtick header, indented bullet)" "Landing: 'PR required: sometimes'"
# A CLAUDE.md BELOW the root, which no other walk reaches. review-receipt.sh
# reads the nearest one from the push directory up, so a package file that
# loses the key opts its subtree out while `git push` stays repo-scoped. Point
# the check back at the root file alone and this row is the only thing that
# moves.
expect "Landing key (a CLAUDE.md below the root)" "packages/api/CLAUDE.md has a Landing: block with no 'Review required:' line"
expect "two-way requires (unused)" "src/unused-dep/SKILL.md declares requires: 'fixture-discipline' but the body never names it"
expect "single-line description (block scalar)" "src/folded-description/SKILL.md description is a YAML block scalar ('>-')"
expect "single-line description (literal block scalar with indicators)" "src/literal-description/SKILL.md description is a YAML block scalar ('|2-')"
expect "single-line description (continued line)" "src/continued-description/SKILL.md description continues onto an indented next line"
expect "re-attach byte-size WARN" "WARN: src/oversize-body/SKILL.md is "
expect "hook selftest (missing)" "global/hooks/orphan-hook.sh carries an '# Install note:' header, so it is a hook, and has no selftest — write global/hooks/orphan-hook-selftest.sh"
expect "hook selftest (not executable)" "global/hooks/unexec-hook-selftest.sh is not executable"
# The house-style checks (round plan §5, checks 2-9), each with its firing
# instance in src/house-style/SKILL.md and its quiet neighbour in that skill's
# references/quiet-forms.md — a file of its own, so a check that widens names
# that path and reds a reject row by name rather than by line number.
expect "British spelling" "src/house-style/SKILL.md uses a British spelling"
# Pass 4's own walk — a separate loop over a separate glob, which nothing
# reached before: emptying its `for` header left 65/0/0, green everywhere,
# because neither fixture root carried docs/ or global/README.md and the repo's
# own docs/ is already clean. One row per arm of the glob, and the nested one
# is what makes `find docs` rather than two enumerated levels an assertion.
expect "British spelling (pass 4: docs/adr)" "docs/adr/0001-fixture-record.md uses a British spelling"
expect "British spelling (pass 4: nested under docs/, which a two-level glob misses)" "docs/solutions/nested-note.md uses a British spelling"
expect "British spelling (pass 4: global/README.md)" "global/README.md uses a British spelling"
# One house-style instance per classifier CLASS. Every other house-style fixture
# sits in one class — a skill body — so `house_style_checks` could be deleted
# from five of the six arms with this file green, and check_reference_bytes from
# the .claude/skills/ arm as well. These are the inputs those arms never had.
expect "house style on a global rule" "global/rules/body-checked.md uses a British spelling"
expect "house style at depth one under src/" "src/stray-note.md uses a British spelling"
expect "house style on a repo-local skill" ".claude/skills/repo-local/SKILL.md uses a British spelling"
expect "house style on DOMAIN.md" "DOMAIN.md uses a British spelling"
expect "house style on README.md" "README.md uses a British spelling"
expect "loaded-file byte WARN on a repo-local reference" ".claude/skills/repo-local/references/oversize.md is 21327 bytes"
expect "heading case (SKILL.md H1 not in title case)" "src/broken-links/SKILL.md H1 'Broken links (fixture)' is not in title case"
expect "heading case (H2 not in sentence case)" "src/house-style/SKILL.md H2 'The Cold Reader Pass' (line 32) capitalizes 'Cold' 'Reader' 'Pass'"
expect "invocation form (the descriptive form)" "src/house-style/SKILL.md breaks the invocation form: it writes \"the fixture-discipline skill\""
expect "invocation form (a bare name at a suggestion site)" "src/house-style/SKILL.md breaks the invocation form: it suggests \`quoted-dep\` at an invocation site"
# Both alternatives of the artifact-name pattern in one line, so dropping
# either the uppercase or the underscore half changes the rendered list.
expect "artifact filenames (uppercase and underscore)" "— Notes.md Progress_Log.md run_log.md ) — a file a run writes is lowercase with dashes"
expect "label family (an unregistered token in bold)" "uses the ALL-CAPS label 'BLOCKEDX'"
expect "label family (an unregistered token in backticks)" "uses the ALL-CAPS label 'COINED'"
# The registry is mined from DOMAIN.md's Status-marker and Verdict-scale rows and
# nowhere else. Mined from the whole file, a banned synonym written in the
# admitted typography inside the row that bans it registers itself, and this row
# goes quiet — which is exactly what happened to `BLOCKED`.
expect "label family (a banned synonym named in the registry row)" "uses the ALL-CAPS label 'FIXTUREBANNED'"
# A marker bare in a table cell is the form every canonical status table in the
# suite actually uses; a typography-only scan cannot see it.
expect "label family (a bare marker alone in a table cell)" "uses the ALL-CAPS label 'BARECOINED'"
# One row per form the section-pointer check resolves a target from: dropping
# an arm otherwise leaves the other three firing and the selftest green.
expect "section pointers (inline link)" "src/house-style/SKILL.md cites '§ No Such Heading is where it lands' (line 25), and src/house-style/references/quiet-forms.md carries no heading by that name"
expect "section pointers (backticked skill name)" "cites '§ No Such Section' (line 26), and src/fixture-discipline/SKILL.md carries no heading"
expect "section pointers (a ~/.claude/skills/ path)" "cites '§ Missing Skill Section' (line 27), and src/fixture-discipline/SKILL.md carries no heading"
expect "section pointers (a ~/.claude/rules/ path)" "cites '§ Missing Rule Section' (line 28), and global/rules/body-checked.md carries no heading"
expect "section pointers (a target that is not a file)" "cites '§ Anything' (line 30) in src/fixture-discipline/references/gone.md, which is not a file"
expect "orphaned references" "src/broken-links/references/orphaned.md is linked from nowhere"
expect "script selftest (missing)" "scripts/orphan-tool.sh has no selftest — write scripts/orphan-tool-selftest.sh"
expect "script selftest (not executable)" "scripts/unexec-tool-selftest.sh is not executable"
expect "git-hook selftest (missing)" "scripts/git-hooks/orphan-hook has no selftest — write scripts/git-hooks/orphan-hook-selftest.sh"
# The remedy a git hook gets is one it can follow: no *-lib.sh rename (git
# fixes the filename), and the tree named is scripts/git-hooks/.
expect "git-hook selftest (missing, hook-shaped remedy)" "scripts/git-hooks/orphan-hook has no selftest — write scripts/git-hooks/orphan-hook-selftest.sh (source scripts/selftest-lib.sh; every git hook under scripts/git-hooks/"
expect "git-hook selftest (not executable)" "scripts/git-hooks/unexec-hook-selftest.sh is not executable"
expect "git hook itself not executable" "scripts/git-hooks/unexec-itself is not executable — chmod +x it"
expect "conventions pointer (missing)" "scripts/no-pointer.sh does not open with '# Conventions for this tree: scripts/README.md'"
expect "CLAUDE.md byte-size WARN" "WARN: CLAUDE.md is "
# The root file goes through pass 2's link parser too; the line number is
# pinned, as in the skill-tree link row above.
expect "CLAUDE.md reference-link resolution" "CLAUDE.md links to 'docs/no-such-file.md' (line 78)"
# One line for all the carriers, not one per skill: the phrase is the unit. The
# three fixtures carry it in straight quotes, in curly quotes and another case,
# and inside a whole-value YAML double-quoted scalar, so this row pins the
# comparison as case-insensitive, the curly-quote branch as read, the quoted
# scalar as unwrapped and unescaped, and the rendering of more than two carriers.
expect "shared trigger phrase" "src/shared-trigger-curly/SKILL.md src/shared-trigger-scalar/SKILL.md src/shared-trigger-straight/SKILL.md carry the same quoted trigger phrase \"walk the tree\""

# The three forms the vocabulary check must leave alone, one file each so a row
# proves one rule. Without them the check could start firing on every file that
# says "verified" and this root would still be green.
#   ledger-quiet-forms.md   — ledger-anchored, names ONE status: a reference,
#                             not an enumeration (`doc-claims`' shape)
#   unrelated-vocabulary.md — names TWO statuses with nothing anchoring it to
#                             the ledger: the same words, a different contract
#   fenced-example.md       — anchored AND naming two statuses, but only inside
#                             a fence: a worked example of the format, which is
#                             prose about the vocabulary rather than a claim in
#                             it. Unfence the block and it fires.
reject "ledger vocabulary (one status, referenced not enumerated)" "ledger-quiet-forms.md"
reject "ledger vocabulary (two statuses, nothing anchoring them)" "unrelated-vocabulary.md"
reject "ledger vocabulary (an enumeration inside a fenced example)" "fenced-example.md"
# The slash sweep's one exempted class. body-checked.md carries `/fixture-discipline`,
# which fires from every other file in the walk, so this row is the difference between
# an exemption that holds and a pattern nobody exercises.
reject "slash-on-model-invoked" "global/rules/body-checked.md writes"
reject "slash names no skill (slash_exempt roster)" "writes \`/compact\`"
reject "slash names no skill (line marker, same line)" "writes \`/checkout-page\`"
reject "reference-link resolution" "references/real-reference.md"
reject "reference-link resolution" "references/exempt-single.md"
reject "reference-link resolution" "references/exempt-double.md"
reject "reference-link resolution" "references/exempt-inner.md"
reject "reference-link resolution" "references/exempt-fenced.md"
reject "global-rule Depends" "global/rules/well-formed.md"
reject "global-rule Depends (path form)" "global/rules/path-cited.md"
# Grades the check's plumbing, not its pattern: bulk-cited-dep cites early and then
# carries a long tail, the shape that made a `grep -q` pipeline report a present
# citation as missing once the reader abandoned the producer mid-write.
reject "global-rule Depends (early citation, long tail behind it)" "global/rules/early-cited.md"
# The trailing /SKILL.md is load-bearing: the uncited-depends FAIL names src/quoted-dep/ without it.
# One reject covers both scans' exemptions: quoted-dep carries every exempt shape in the
# Skill-tool form and the slash form, plus the two slash forms that are correct unmasked
# (a user-invoked skill, a built-in). Drop a mask or invert either slash guard and it fires.
reject "two-way requires and slash-on-model-invoked (quoted, parenthesised and fenced forms)" "src/quoted-dep/SKILL.md"
# quoted-dep also quotes "walk the tree": it is user-invoked, so the shared-phrase check
# must not read it. The reject above already grades that — a widened check that reads
# user-invoked descriptions names src/quoted-dep/SKILL.md in the phrase line and reds it.
# The disambiguating tail is the other quiet form: shared-trigger-not-for quotes the same
# phrase inside a "Not for…" clause, which routes a reader *away* from the sibling that
# owns it — the style write-skill prescribes and this repo uses. A check that reads past
# the trigger half names it here and reds this row.
reject "shared trigger phrase (disambiguating \"Not for…\" tail)" "src/shared-trigger-not-for/SKILL.md carry"
# The WARN is a warning: the oversize body must draw no FAIL line of its own.
reject "re-attach byte-size WARN does not FAIL" "FAIL: src/oversize-body/SKILL.md"
# Pinned to the WARN's own shape ("… CLAUDE.md is <n> bytes"), because the
# root file legitimately draws a link-check FAIL in this tree and a bare
# "FAIL: CLAUDE.md" needle would read that correct line as the WARN failing.
reject "CLAUDE.md byte-size WARN does not FAIL" "FAIL: CLAUDE.md is "
# A selftest file under git-hooks is not itself held to the pairing.
reject "git-hook selftest (the selftest file is exempt)" "scripts/git-hooks/unexec-hook-selftest.sh has no selftest"
# A file under git-hooks with no shebang is not a hook: no pairing, no pointer.
reject "git-hook selftest (no shebang, so not a hook)" "scripts/git-hooks/README.md"
# A git hook's remedy never offers the *-lib.sh rename a hook cannot take.
reject "git-hook selftest (script-shaped remedy on a hook)" "scripts/git-hooks/orphan-hook has no selftest — write scripts/git-hooks/orphan-hook-selftest.sh (source scripts/selftest-lib.sh; every scripts/*.sh"
# The hook whose own mode is broken is otherwise paired, and the one whose
# selftest's mode is broken is itself executable: each fires exactly its own
# line, so the two checks cannot be merged with this run green.
reject "git hook itself not executable (its selftest is fine)" "scripts/git-hooks/unexec-itself-selftest.sh is not executable"
reject "git-hook selftest (the hook with an unexecutable selftest is itself executable)" "scripts/git-hooks/unexec-hook is not executable"
# The pointer check fires on the one script that lacks the line and on nothing
# else: every other fixture script carries it, so a matcher that widened past
# "line 2 after a shebang, line 1 without one" reds here.
# The masked/raw split in the consumer FAIL: `hits` counts masked tokens and
# `missing` used to re-grep the RAW file, so on this fixture — two statuses in
# prose, the third only inside a fence — the old reading rendered "and not ``".
# The row asserts the NAME, which is the only part the two readings disagree on.
expect "evaluation ledger consumers (the missing status is named, not an empty pair of backticks)" "fenced-third-status.md — it names 2 of the 3 and not \`contradicted\`"
expect "sibling-group membership (a copy no group lists, first skill)" "src/bulk-cited-dep/references/ac-ids.md shares the reference basename 'ac-ids.md'"
expect "sibling-group membership (a copy no group lists, second skill)" "src/quoted-dep/references/ac-ids.md shares the reference basename 'ac-ids.md'"
# The quiet half of the same check, which no fixture root can reach:
# sibling_groups names this repo's own src/ paths, so under LINT_ROOT nothing is
# ever listed and the "listed -> stay quiet" branch is unreachable. Delete it and
# every row above still fires, the FAIL count does not move, and the clean root
# still exits 0 — while the real tree's pre-commit reds on all 51 grouped paths.
# The only place the branch can be graded is the real tree, so this row runs the
# linter there. It costs one full lint run; the assertion is scoped to this
# check's own sentence, so an unrelated FAIL in the working tree does not red it.
real_out=$(bash scripts/lint-skills.sh 2>&1)
reject_in "$real_out" "a grouped sibling path FAILed the membership check in the real tree — the 'listed -> stay quiet' branch is what keeps sibling_groups from reporting its own members" "shares the reference basename"

# The quiet neighbour of each house-style check, one row per exemption. Each
# names a substring only a WIDENED check could produce — the neighbour itself,
# never the file, because one expect row above legitimately names
# quiet-forms.md as the TARGET of the broken pointer.
reject "invocation form (a model-invoked name at a suggestion site)" "suggests \`fixture-discipline\`"
reject "artifact filenames (a repo-convention name is exempt)" "— README.md ) — a file a run writes"
reject "label family (a label registered in DOMAIN.md)" "label 'FIXTUREPASS'"
reject "British spelling (a form inside a code span)" "— cancelled )"
# The pass-4 walk's third producer. docs/** and global/README.md were both
# reachable from a fixture root and scripts/README.md was not, so dropping it
# from the producer list moved nothing in the suite.
expect "British spelling (scripts/README.md, the walk's third producer)" "scripts/README.md uses a British spelling (line(s) 5 — catalogue )"
reject "heading case (an acronym and a numbered label mid-heading)" "src/house-style/references/quiet-forms.md H2"
reject "section pointers (a pointer that resolves)" "cites '§ The quiet half"
reject "orphaned references (a reference its body links)" "references/quiet-forms.md is linked from nowhere"
reject "orphaned references (a sibling reference linked by basename)" "references/sibling-note.md is linked from nowhere"
reject "orphaned references (a reference cited by its installed path from another skill)" "references/cited-by-path.md is linked from nowhere"
reject "British spelling (a form inside a URL)" "— behaviour )"
reject "conventions pointer (a shebang-less library carrying it on line 1)" "scripts/quiet-lib.sh does not open with"
reject "conventions pointer (no-pointer's own selftest carries it)" "scripts/no-pointer-selftest.sh does not open with"
reject "hook selftest (library exempt)" "global/hooks/quiet-lib.sh"
reject "hook selftest (no Install note, so not a hook)" "global/hooks/unmarked-helper.sh"
reject "script selftest (library exempt)" "scripts/quiet-lib.sh"
reject "script selftest (setup-hooks.sh exempt)" "scripts/setup-hooks.sh"

# The reject above is the only row in this suite that grades the citation check's
# plumbing, and it discriminates only while bulk-cited-dep's tail is longer than a
# pipe will hold — otherwise the producer finishes writing before the reader walks
# away, the pre-fix pipeline passes too, and the row silently stops testing
# anything. Linux's pipe capacity is a fixed 65536 bytes and is the larger of the
# two this repo is run on, so that is the floor. Trimming the fixture must fail
# here, loudly, rather than turning the row into a no-op.
bulk_bytes=$(find "$fixtures/src/bulk-cited-dep" -type f -name '*.md' -exec cat {} + | wc -c | tr -d ' ')
if [ "$bulk_bytes" -le 65536 ]; then
  selftest_fail "src/bulk-cited-dep/ is $bulk_bytes bytes, at or under a Linux pipe's 65536-byte capacity — the early-citation reject no longer discriminates, because the producer can hand over the whole stream before the reader exits. Add reference-file length back (each file caps at 200 lines)."
fi

expect_rc "the lint against the fixture tree" 1 "$status"
# The count of FAIL lines is pinned: a check that begins firing on a fixture
# it should leave alone reds here even when no substring row names the line.
# Last moved 2026-09-01 (Batch M-lint fix pass): 88. Seven of them are
# check_landing_key: six on the root CLAUDE.md's three deliberately malformed
# blocks, one on the packages/api file below it; one is the fixture install.sh, which owes a selftest; two are the dangling
# slash-name arm, on `/no-such-command` and on the `/order-status` whose marker
# sits on the wrong line; one is the British form in the fixture
# scripts/README.md, the pass-4 walk's third producer; three are the widened
# sibling-membership check naming the ungrouped `ac-ids.md` copies per PATH and
# the consumer fixture whose third status sits only inside a fence. A count that
# moves is read before it is re-pinned.
nfail=$(printf '%s\n' "$output" | grep -c '^FAIL: ')
[ "$nfail" -eq 88 ] || selftest_fail "expected exactly 88 FAIL lines against the fixture tree, got $nfail"
# The shared-trigger-phrase fixtures are pinned by property, as near_bytes and
# bulk_bytes are below: every row above them asserts a FAIL that appears or a
# FAIL that does not, and each of those readings is silently satisfied by a
# fixture whose phrase someone deleted. What the check is graded on is the
# phrases themselves, so they are asserted to still be there — an edit that
# weakens one fails here, naming the fixture, instead of turning a row into a
# no-op nothing reads.
# One pin, two matchers. phrase_pin and quiet_pin had the same signature and
# near-identical FAIL wording, differing only in whether the needle is anchored
# to a `description:` line (a regex) or matched literally anywhere in the file
# — which made the wording two things to fix, in a file whose library states
# its charter as "a failing line pasted into a search finds one definition".
# `mode` is `description` or `literal`; `owner` names the check set the pin
# serves, so the two FAIL lines still read differently to a human.
pin() {  # mode, owner, file, what, pattern
  local mode=$1 owner=$2 f=$3 what=$4 pattern=$5
  if [ ! -f "$f" ]; then
    selftest_fail "$f is missing — it carries $what for $owner; restore it rather than reading the rows above as still graded"
    return
  fi
  case $mode in
    description) grep -q "^description:.*$pattern" "$f" && return
                 selftest_fail "$f no longer carries $what in its description — the $owner rows above stopped grading it; put it back rather than deleting the assertion" ;;
    literal)     grep -qF -- "$pattern" "$f" && return
                 selftest_fail "$f no longer carries $what — the $owner row above stopped grading it; put it back rather than deleting the assertion" ;;
    *)           selftest_fail "pin called with mode '$mode', which is neither 'description' nor 'literal' — the row did not run" ;;
  esac
}
phrase_pin() { pin description "the shared-trigger-phrase check" "$1" "$2" "$3"; }
phrase_pin "$fixtures/src/shared-trigger-straight/SKILL.md" "the shared phrase in straight double quotes" '"walk the tree"'
phrase_pin "$fixtures/src/shared-trigger-curly/SKILL.md" "the shared phrase in curly quotes and another case (the only place the curly branch of the extractor and the case fold are exercised)" '“Walk The Tree”'
phrase_pin "$fixtures/src/shared-trigger-scalar/SKILL.md" "the shared phrase escaped inside a whole-value YAML double-quoted scalar (the only place the unwrap-and-unescape path is exercised)" ' ".*\\"walk the tree\\"'
phrase_pin "$fixtures/src/shared-trigger-not-for/SKILL.md" "the shared phrase inside a disambiguating \"Not for…\" tail, which must stay quiet" 'Not for.*"walk the tree"'
phrase_pin "$fixtures/src/quoted-dep/SKILL.md" "the shared phrase in a user-invoked description, which must never be read" '"walk the tree"'
phrase_pin "$clean_fixtures/src/clean-skill/SKILL.md" "one phrase quoted twice, which is not a duplicate" '"do the thing".*"do the thing"'
phrase_pin "$clean_fixtures/src/which-skill/SKILL.md" "clean-skill's phrase in a user-invoked description, which must never be read" '"do the thing"'

# The five name lists inside lint-skills.sh, pinned by MEMBER COUNT. A fixture
# row grades one member and says nothing about the rest: replacing
# british_words entirely with four words left this file green, emptying
# known_caps moved one line, and emptying proper_nouns moved nothing at all.
# The count is the property that changes when a word is dropped, whichever word
# it is. It is not a substitute for a fixture instance — it says a member left,
# never which — so a moved count is read before it is re-pinned.
list_pin() {  # variable name, expected member count, separator
  local var=$1 want=$2 sep=$3 got
  got=$(grep -cE "^${var}='" scripts/lint-skills.sh)
  if [ "$got" -ne 1 ]; then
    selftest_fail "expected exactly one \`${var}=\` assignment in scripts/lint-skills.sh, found $got — the count pin below cannot say which one it measured"
    return
  fi
  got=$(sed -n "s/^${var}='\\(.*\\)'$/\\1/p" scripts/lint-skills.sh | tr "$sep" '\n' | grep -c '[^[:space:]]')
  [ "$got" -eq "$want" ] || selftest_fail "${var} carries $got members, pinned at $want — a name added or dropped there changes what the whole tree is graded on, and no fixture row would have said so. Re-measure, land a fixture instance for anything added, then move this number."
}
list_pin british_words 260 '|'
list_pin known_caps 102 ' '
list_pin proper_nouns 20 ' '
list_pin invocation_verbs 15 '|'
list_pin artifact_name_exempt 6 '|' 
# The backticked span is the clean root's quiet form for "only double-quoted
# spans are compared": two model-invoked descriptions share it, so widening the
# extractor's alternation to backticks turns this root red — which is what makes
# the exemption an assertion rather than a sentence in a header.
# The house-style checks' quiet neighbours are pinned the same way and for the
# same reason: every reject row above is satisfied by a fixture whose quiet
# line someone deleted, so the lines themselves are asserted present. The
# firing instances need no pin — an expect row that stops matching says so.
quiet_pin() { pin literal "the house-style checks" "$1" "$2" "$3"; }
quiet="$fixtures/src/house-style/references/quiet-forms.md"
quiet_pin "$quiet" "a model-invoked name at a suggestion site" 'run `fixture-discipline` first'
quiet_pin "$quiet" "a repo-convention filename the artifact-name shape exempts" 'the artifact-name shape: `README.md`'
quiet_pin "$quiet" "a label this tree registers" '**FIXTUREPASS**'
quiet_pin "$quiet" "a British form inside a code span" 'an order in `cancelled`'
quiet_pin "$quiet" "a British form inside a URL" 'https://example.invalid/docs/behaviour'
# The inline exemption plan §5 specified and the batch did not build. A code
# span is indistinguishable from an ordinary path, so a deliberate British form
# that cannot sit in one had no way to say so — which is what let a sweep flip
# `licences.tsv` and a recorded `honours` regex with lint green.
quiet_pin "$quiet" "a deliberate British form marked with the inline spelling exemption" '<!-- spelling-exempt: normalises -->'
quiet_pin "$quiet" "a section pointer that resolves" '[the sibling note](sibling-note.md) § The sibling half'
quiet_pin "$quiet" "an acronym mid-heading" '## The HTML half'
# check_reference_orphans' `global` scan root. Deleting the line that adds it left
# this file green: the installed-path arm was graded only from src/, so a
# reference cited solely from a hoisted rule would have started reading as an
# orphan with nothing noticing. The pin holds the citation in place; the FAIL
# count above is what moves when the scan root goes.
quiet_pin "$fixtures/global/rules/body-checked.md" "the installed-path citation that is a src/ reference's ONLY pointer, and lives in the global/ scan root" '`~/.claude/skills/house-style/references/cited-from-global.md`' 
quiet_pin "$quiet" "an em-dash clause opening after a numbered label" '## Phase 2 — Reproduce the thing'
quiet_pin "$quiet" "a label whose number is the next token" '## The adversary pass (Tier 2/3)'
quiet_pin "$quiet" "an identifier carrying its own digit" '## The Sprint2 window'
quiet_pin "$fixtures/src/broken-links/SKILL.md" "the installed-path citation of another skill's reference, which is the orphan check's third arm" '`~/.claude/skills/house-style/references/cited-by-path.md`'
quiet_pin "$fixtures/src/house-style/references/quiet-forms.md" "the basename link that is the orphan check's second arm" '(sibling-note.md)'

for capped in clean-skill near-cap; do
  phrase_pin "$clean_fixtures/src/$capped/SKILL.md" "the backticked span two model-invoked descriptions share, which only-double-quoted-spans must leave quiet" '`pin the bound`'
done

# The near-cap body is measured: the clean root holds one 49 bytes under the
# bound (asserted below to draw no WARN), and this pins that it is really there.
near_bytes=$(wc -c < "$clean_fixtures/src/near-cap/SKILL.md" | tr -d ' ')
{ [ "$near_bytes" -gt 14800 ] && [ "$near_bytes" -le 15000 ]; } || selftest_fail "src/near-cap/SKILL.md in the clean root is $near_bytes bytes; it must sit inside (14800, 15000] to pin the WARN threshold from below"

# The clean root's CLAUDE.md sits just under its bound, so the WARN below is
# pinned from below as well as above; this pins that the file is really there.
claude_bytes=$(wc -c < "$clean_fixtures/CLAUDE.md" 2>/dev/null | tr -d ' ')
{ [ -n "$claude_bytes" ] && [ "$claude_bytes" -gt 5800 ] && [ "$claude_bytes" -le 6000 ]; } || selftest_fail "CLAUDE.md in the clean root is ${claude_bytes:-absent} bytes; it must sit inside (5800, 6000] to pin the CLAUDE.md WARN threshold from below"

# The clean root's CLAUDE.md also carries one resolving link, so the quiet
# direction of the root link check is a form actually exercised (the clean
# baseline's exit 0 below is what grades it); this pins that it is there.
grep -q '](README.md)' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md no longer carries its '](README.md)' link — the CLAUDE.md link check's quiet direction went ungraded; put the link back rather than reading the clean baseline as covering it"

# The clean root's Landing: block is the Landing-key check's whole quiet
# direction AND the base the two isolated rows below edit, so those readings die
# silently if someone trims it out of the fixture. Its keys carry the forms the
# check must exempt: a parenthetical after a yes/no value, an apostrophe in a
# free-text value, and a key written in bold. `Review required:` is `yes` here
# rather than `no` because this directory sits inside a gated repo and
# global/hooks/review-receipt.sh reads the nearest CLAUDE.md from the push
# directory up — a committed `no` opts the directory out of this repo's own push
# gate. The `no` value is exercised in the throwaway copy below instead.
grep -q '^Landing:$' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md no longer carries a 'Landing:' block — check_landing_key's quiet direction went ungraded, and the two isolated rows below have nothing to edit"
grep -q '^- Review required: yes$' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md Landing: block no longer carries '- Review required: yes' — that is the line the isolated 'landing-no-review' and 'landing-review-no' rows edit, so the missing-key arm and the negative value both went ungraded"
grep -q '^- Ticket close pre-authorized: no (no tracker)$' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md Landing: block no longer carries a yes/no value with a trailing parenthetical — that exemption went ungraded"
grep -q "^- Defect policy: fix, don't file$" "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md Landing: block no longer carries an apostrophe in a free-text value — that exemption went ungraded"
grep -q '^- \*\*Push pre-authorized:\*\* yes$' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md Landing: block no longer carries a key written in bold — check_landing_key strips the bold before matching the key name, and dropping that strip would FAIL every repo writing '- **Push pre-authorized:** yes' with nothing red here"
grep -q '^- Not a Landing key' "$clean_fixtures/CLAUDE.md" || selftest_fail "the clean root's CLAUDE.md no longer carries an unrelated bullet list under its Landing: block — that list is what grades the rule that a blank line ends the block; tolerate the blank instead and those bullets read as Landing keys"

# The clean root's baseline. Every later assertion against it reads "the thing
# I broke caused this", and that reading is only sound while the untouched tree
# exits 0 — so a violation drifting into scripts/lint-fixtures-clean/ must fail
# here rather than quietly restoring the vacuous check this replaced.
if ! clean_baseline=$(LINT_ROOT="$clean_fixtures" bash scripts/lint-skills.sh 2>&1); then
  selftest_fail "$clean_fixtures does not lint clean, so a failure induced in it proves nothing. Linter output was:"
  printf '%s\n' "$clean_baseline"
fi

# The clean root draws no WARN either: the byte-size warning fires on size alone,
# and nothing there is near the bound.
if printf '%s\n' "$clean_baseline" | grep -q '^WARN:'; then
  selftest_fail "the clean fixture drew a WARN line; a byte-size warning fired on a body under its bound (near-cap sits 49 bytes under the skill bound; the clean CLAUDE.md sits under the 6,000-byte one)"
fi
# And no shell noise: the baseline is captured with 2>&1, so a header line that
# lost its `#` and ran as a command lands here as "command not found" — with
# the linter still exiting 0, which is how one shipped on 2026-08-30.
reject_in "$clean_baseline" "the clean run printed a shell error (a header line running as a command, or a call to an undefined function)" "command not found"

# Argument handling, each direction: --help prints usage and runs no check;
# an unknown argument exits 3 and runs no check; a LINT_ROOT that is not a
# directory exits 2 rather than linting whatever directory the shell was in.
help_out=$(bash scripts/lint-skills.sh --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help_out" "--help printed no Usage: line" "Usage:"
printf '%s\n' "$help_out" | grep -qE '^(OK|FAIL|WARN):' && selftest_fail "--help ran the lint"
bogus_out=$(LINT_ROOT="$fixtures" bash scripts/lint-skills.sh --bogus 2>&1); expect_rc "an unknown argument" 3 $?
printf '%s\n' "$bogus_out" | grep -qE '^(OK|FAIL|WARN):' && selftest_fail "an unknown argument still ran the lint"
expect_in "$bogus_out" "the unknown-argument error did not name --help as the fix" "--help"
LINT_ROOT="$fixtures" bash scripts/lint-skills.sh --help --bogus >/dev/null 2>&1; expect_rc "two arguments (the second unknown)" 3 $?
LINT_ROOT="$fixtures" bash scripts/lint-skills.sh "" >/dev/null 2>&1; expect_rc "an empty argument" 3 $?
root_out=$(LINT_ROOT="$fixtures/does-not-exist" bash scripts/lint-skills.sh 2>&1); expect_rc "a LINT_ROOT that is not a directory" 2 $?
printf '%s\n' "$root_out" | grep -qE '^(OK|FAIL|WARN):' && selftest_fail "a LINT_ROOT that is not a directory still ran the lint"

# One cleanup for every throwaway tree this script builds, installed before the
# first one exists and never replaced. Both blocks below copy whole fixture
# trees and one of them breaks a file's mode, so an interrupt or an `exit` added
# inside either would otherwise leak them; the chmod runs first because a
# mode-broken directory resists rm.
selftest_cleanup() {
  local d
  for d in "${isolated_parent:-}" "${inject_parent:-}"; do
    [ -n "$d" ] || continue
    chmod -R u+rwX "$d" 2>/dev/null
    rm -rf "$d"
  done
  return 0
}
trap selftest_cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# The evaluation-ledger checks, graded for their effect on the EXIT STATUS
# rather than on the output, and for the branches that return early. In the
# wrong-on-purpose root a dozen other checks already force exit 1, so a
# vocabulary FAIL that printed its line but never reached `fail` would look
# identical to one that worked — the shape a piped `while` produces, since the
# loop body then runs in a subshell and its `fail=1` is discarded. Isolating
# that needs a root where one of these checks is the only thing wrong, so each
# case below is the CLEAN root with exactly one edit.
# ---------------------------------------------------------------------------
if ! isolated_parent="$(selftest_tmpdir)"; then
  selftest_skip "mktemp -d produced no usable directory — the evaluation-ledger exit-status and early-return rows were not exercised by this run."
else
# name, perl expression, file, expected substring.
#
# perl, not sed: the expressions below use \z and a \x escape, which BSD sed has
# neither of. The expression is interpolated into a double-quoted shell string
# AND runs in Perl's own double-quote context on the replacement side, so a `$`
# or `@` in a new case needs escaping for both. `or die` is what makes a stale
# pattern a loud SKIP: perl -0pi rewrites the file unchanged and exits 0 when
# nothing matched, so without it a renamed fixture would surface downstream as
# "the check did not fire" and blame the check for a fixture problem.
# The eleven lines both isolated helpers share, named once: copy the clean root,
# apply the one edit, run the lint against it. They were byte-identical, and a
# skip message or a copy flag fixed in one of two copies is the shape
# scripts/selftest-lib.sh exists to prevent.
# Sets isolated_out and isolated_rc; returns 1 when the row could not be run.
isolated_run() {  # name, perl expression, file
  local root="$isolated_parent/$1"
  mkdir -p "$root" && cp -R "$clean_fixtures/." "$root/" || {
    selftest_skip "could not copy the clean tree for the '$1' case — that row was not exercised."
    return 1
  }
  perl -0pi -e "$2 or die" "$root/$3" 2>/dev/null || {
    selftest_skip "the edit for the '$1' case matched nothing in $3 — the fixture was renamed or reworded, so that row was not exercised. Fix the pattern rather than reading the row as still graded."
    return 1
  }
  isolated_out=$(LINT_ROOT="$root" bash scripts/lint-skills.sh 2>&1); isolated_rc=$?
  return 0
}

isolated_case() {  # a fifth argument, when given, is a second required substring
  isolated_run "$1" "$2" "$3" || return 0
  local out=$isolated_out rc=$isolated_rc
  expect_in "$out" "the graded check did not fire in the isolated '$1' root" "$4"
  [ -n "${5:-}" ] && expect_in "$out" "the isolated '$1' root did not carry its second required line" "$5"
  expect_rc "the lint against the isolated '$1' root" 1 "$rc"
}
# The other polarity: an edit a check must stay QUIET about. Exit 0 alone would
# pass on a check that stopped running, so the fourth argument names a substring
# that must NOT appear in any FAIL line — the check's own vocabulary, so a FAIL
# from this edit is told apart from a FAIL the copy carried in.
isolated_quiet_case() {  # name, perl expression, file, substring that must not FAIL
  isolated_run "$1" "$2" "$3" || return 0
  local out=$isolated_out rc=$isolated_rc
  printf '%s\n' "$out" | grep '^FAIL: ' | grep -qF "$4" && \
    selftest_fail "the isolated '$1' root drew a FAIL naming '$4'; that edit is a form the check must accept"
  expect_rc "the lint against the isolated '$1' root" 0 "$rc"
}
# A consumer that drops one status is the whole difference between this root and
# the clean one, so exit 1 here is this check's doing and nothing else's.
isolated_case "dropped-status" 's/, and a `contradicted` row is disconfirming evidence the grade must account for//' \
  "src/ledger-legend/references/complete-consumer.md" \
  "missing from src/ledger-legend/references/complete-consumer.md — it names 2 of the 3 and not \`contradicted\`"
# A fourth status in the legend: the branch that returns early, so it can only be
# graded in a root where nothing else is wrong.
isolated_case "fourth-status" 's/`contradicted` — checked/`pending` — nobody looked · `contradicted` — checked/' \
  "src/ledger-legend/references/legend-line.md" \
  "legend defines 4 statuses, not 3"
# A second file defining a legend: two authorities, so a rename updates whichever
# one the editor happened to open. Appended rather than given its own fixture,
# because a committed second legend would make the clean root permanently red.
# The second substring is the other half of ADR-0072's never-ran-is-not-clean rule
# applied inside these checks: an authority failure leaves the consumer sweep
# unrun, and an author who fixes the authority and then meets a crop of consumer
# FAILs must not read them as a regression their fix caused.
isolated_case "two-legends" 's/\z/\nStatus is exactly one of: `marketed` \xc2\xb7 `verified` \xc2\xb7 `contradicted`.\n/' \
  "src/ledger-legend/references/complete-consumer.md" \
  "two files define the evaluation ledger status legend" \
  "the evaluation ledger consumer sweep did not run"
# The legend sentence reworded. This is the edit an ordinary writing pass makes,
# and before the two anchors were made to pin each other it turned all three
# checks off tree-wide while the linter printed OK and exited 0.
isolated_case "legend-reworded" 's/^Status is exactly one of:/A row stores exactly one of:/m' \
  "src/ledger-legend/references/legend-line.md" \
  "but no file defines the legend"
# The rule phrase reworded — the same failure from the other end, and the half
# check_evaluation_ledger_rule_agreement asserts: the legend and the rule
# define the same set, so losing either site is a FAIL, not a stand-down.
isolated_case "rule-reworded" 's/\*\*Exactly one stored status\.\*\*/**Exactly one status is stored.**/' \
  "src/ledger-legend/SKILL.md" \
  "but no file states the stored-status rule"
# Two rule sites: only one would be compared against the legend, so the other
# could drift unseen. The old form took `head -1` and never said so.
isolated_case "two-rules" 's/\z/\n- **Exactly one stored status.** `marketed`, `verified`, `refuted`.\n/' \
  "src/ledger-legend/references/complete-consumer.md" \
  "two files state the evaluation ledger's stored-status rule"

# The pass-4 spelling walk, graded for its EFFECT ON THE EXIT STATUS. In the
# wrong-on-purpose root a dozen other checks already force exit 1, and the FAIL
# count pins that the walk still PRINTS — so a walk whose FAILs never reached
# `fail` looked identical to one that worked, which is what shipped: the walk
# was a PIPE into `while`, its loop body ran in a subshell, and `fail=1` died
# with it, so `OK: skill conventions clean.` printed beside a FAIL and the run
# exited 0. Only a root where a docs/ spelling FAIL is the one thing wrong can
# tell the two apart, which is why this row is here and not beside the other
# spelling rows.
isolated_case "docs-spelling-status" 's/its behavior is/its behaviour is/' \
  "docs/adr/0001-clean-record.md" \
  "docs/adr/0001-clean-record.md uses a British spelling"

# The always-loaded budget. It is a per-DIRECTORY total, so no committed
# fixture can carry it without every other root paying the bytes: the clean
# tree's one rule file is padded past 12,000 in a copy instead.
isolated_case "rules-budget" 's/\z/"\n" . ("padding that carries the rules directory past the always-loaded budget. " x 200) . "\n"/e' \
  "global/rules/clean-rule.md" \
  "over the 12,000-byte budget for the always-loaded layer"
# The two checks that read DOMAIN.md as their registry, each graded by taking
# the registration away rather than by adding a violation: a check that stopped
# reading the glossary and fell back to its own list stays green in the clean
# root and reds here.
isolated_case "label-unregistered" 's/`FIXTUREPASS` and //' \
  "DOMAIN.md" \
  "uses the ALL-CAPS label 'FIXTUREPASS', which is in none of the three places a label may come from"
isolated_case "proper-noun-unregistered" 's/\*\*Cold-reader pass\*\*/**Fresh-eyes read**/' \
  "DOMAIN.md" \
  "capitalizes 'Cold-reader' mid-heading"

# The Landing: key's missing-`Review required:` arm. This is the arm that
# matters most, because it is the one a deletion trips: the review-receipt hook
# arms on that line alone, and a repo that loses it looks exactly like a repo
# that never gated.
isolated_case "landing-no-review" 's/^- Review required: yes\n//m' \
  "CLAUDE.md" \
  "has a Landing: block with no 'Review required:' line"
# The negative value, which must stay quiet. It cannot be exercised in a
# committed fixture: global/hooks/review-receipt.sh walks up from the push
# directory and the nearest CLAUDE.md carrying the line decides in either
# direction, so a `no` under scripts/ opts that directory out of this repo's own
# push gate. A throwaway copy carries it instead.
isolated_quiet_case "landing-review-no" 's/^- Review required: yes$/- Review required: no/m' \
  "CLAUDE.md" \
  "Landing:"

# The loaded-file byte WARN, which by construction cannot move the exit status
# — so it takes its own helper: the same one-edit copy of the clean root, with
# the assertion that the line appears AND that the root still exits 0. A WARN
# that started FAILing would pass the substring row and red here.
isolated_warn_case() {  # name, perl expression, file, expected substring
  isolated_run "$1" "$2" "$3" || return 0
  local out=$isolated_out rc=$isolated_rc
  expect_in "$out" "the WARN did not fire in the isolated '$1' root" "$4"
  reject_in "$out" "the '$1' WARN was rendered as a FAIL" "FAIL: $4"
  expect_rc "the lint against the isolated '$1' root" 0 "$rc"
}
isolated_warn_case "oversize-reference" 's/\z/"\n" . ("padding that carries this reference past the loaded-file bound. " x 260) . "\n"/e' \
  "src/clean-skill/references/note.md" \
  "src/clean-skill/references/note.md is "
fi

# ---------------------------------------------------------------------------
# The read-error branches, exercised by runtime injection. Each reports that a
# check never ran rather than that it passed, so a branch that stops firing
# turns an unread file into a silent clean — the exact failure the messages
# exist to prevent. None can be reached from a committed fixture: git stores
# only the exec bit, so an unreadable mode does not survive checkout. So copy
# the trees, break one file's mode in each copy, and grade the messages.
# ---------------------------------------------------------------------------
# One `chmod 000` reaches four of them because the file sits under `src/broken-links/`,
# which `global/rules/well-formed.md` names in its Depends: line — the link
# extractor reads the file directly, and the citation check reads it through
# the find/awk pipeline over that dep's directory.
# `set -e` is deliberately off in this script, so an empty inject_root would not
# stop anything: `cp -R "$fixtures/." "/"` is a valid command, and the trap's
# `rm -rf ""` cleans up nothing. Guard the variable before anything uses it as
# a path, and check the copy — a partial tree fails the two rows below and
# misattributes the failure to the read-error branches.
if ! inject_parent="$(selftest_tmpdir)"; then
  selftest_skip "mktemp -d produced no usable directory — the two read-error branches were not exercised by this run."
else
inject_root="$inject_parent/broken"
clean_root="$inject_parent/clean"
if ! mkdir -p "$inject_root" "$clean_root" ||
   ! cp -R "$fixtures/." "$inject_root/" ||
   ! cp -R "$clean_fixtures/." "$clean_root/"; then
  selftest_skip "could not copy the fixture trees into $inject_parent — the two read-error branches were not exercised by this run."
else
unreadable="$inject_root/src/broken-links/references/real-reference.md"
clean_unreadable="$clean_root/src/clean-skill/references/note.md"
# A third file, in the legend's own skill, where the anchor grep is bypassed by
# the whole-directory rule — the only place the status-token read-error branch
# is reachable, since everywhere else the anchor grep fails first and returns.
clean_unreadable_in_legend_dir="$clean_root/src/ledger-legend/references/complete-consumer.md"
# chmod's own status is read: a renamed fixture would otherwise fall through
# to the readability test below and be reported as a dead read-error branch.
# A fourth: the clean root's CLAUDE.md, so the byte WARN's read-error branch
# says the count never ran rather than reading an empty count as under the bound.
clean_unreadable_claude="$clean_root/CLAUDE.md"
if ! chmod 000 "$unreadable" "$clean_unreadable" "$clean_unreadable_in_legend_dir" "$clean_unreadable_claude" 2>/dev/null; then
  selftest_fail "chmod 000 failed on one of $unreadable, $clean_unreadable, $clean_unreadable_in_legend_dir or $clean_unreadable_claude — a fixture was renamed or removed; update the paths here rather than reading the rows below as a dead branch"
elif cat "$unreadable" >/dev/null 2>&1 || cat "$clean_unreadable" >/dev/null 2>&1; then
  # Running as root, or on a filesystem that ignores the mode. Not a
  # regression, but the branches below went unexercised and the closing line
  # must not claim otherwise.
  selftest_skip "$unreadable is still readable after chmod 000 (running as root, or a filesystem that ignores modes) — the two read-error branches were not exercised by this run."
else
  inject_output=$(LINT_ROOT="$inject_root" bash scripts/lint-skills.sh 2>&1)
  inject_expect() {
    expect_in "$inject_output" "the $1 branch did not fire on an unreadable file" "$2"
  }
  inject_expect "reference-link extractor read-error" "src/broken-links/references/real-reference.md — the reference-link extractor errored"
  inject_expect "Depends: citation read-error" "Depends: names 'broken-links' but src/broken-links/ could not be read"
  # Two more branches reach the same unreadable file, and each says the check did
  # not run rather than that it found nothing. Both are silent-pass shapes: a
  # count the cap was never applied to, and an anchor grep whose status 2 read as
  # status 1. Without these rows either could be deleted with this run green.
  inject_expect "line-cap read-error" "src/broken-links/references/real-reference.md could not be read for its line count"
  inject_expect "evaluation-ledger anchor read-error" "src/broken-links/references/real-reference.md could not be read for the evaluation ledger anchor"
  # ONE guard for the whole house-style set, heading case included, for the
  # same reason: six awk programs on an unreadable file printed errors on
  # stderr and nothing on stdout, which reads from outside exactly like a file
  # that passed all six. The message names all six, so a check dropped from
  # the set is visible here and not only in the classifier.
  inject_expect "house-style read-error" "src/broken-links/references/real-reference.md could not be read — the house-style checks (spelling, invocation form, artifact names, labels, section pointers, heading case)"

  # The same injection against the clean root, which is what makes an exit-status
  # assertion mean anything. Asserting exit 1 against the broken tree is vacuous:
  # ~20 deliberate violations force that already, and the assertion cannot fail
  # unless the linter stops exiting 1 at all, which the fixture-tree check above
  # catches first. The clean root exits 0 until this one mode is broken, so its
  # exit 1 is the read error's alone.
  clean_output=$(LINT_ROOT="$clean_root" bash scripts/lint-skills.sh 2>&1)
  expect_rc "the lint against an otherwise-clean tree holding one unreadable file (a read error on its own must force exit 1)" 1 $?
  expect_in "$clean_output" "the reference-link extractor read-error did not fire on an otherwise-clean tree" "src/clean-skill/references/note.md — the reference-link extractor errored"
  expect_in "$clean_output" "the Depends: citation read-error did not fire on an otherwise-clean tree" "Depends: names 'clean-skill' but src/clean-skill/ could not be read"
  expect_in "$clean_output" "the line-cap read-error did not fire on an otherwise-clean tree" "src/clean-skill/references/note.md could not be read for its line count"
  expect_in "$clean_output" "the evaluation-ledger anchor read-error did not fire on an otherwise-clean tree" "src/clean-skill/references/note.md could not be read for the evaluation ledger anchor"
  expect_in "$clean_output" "the evaluation-ledger status-token read-error did not fire on an unreadable file inside the legend's own skill" "src/ledger-legend/references/complete-consumer.md could not be read for evaluation ledger statuses"
  expect_in "$clean_output" "the CLAUDE.md byte-count read-error did not fire on an unreadable root file" "CLAUDE.md could not be read for its byte count"
  # The Landing: key check's own guard, on the same unreadable root file. Its
  # first act is a grep, which fails on an unreadable file and would otherwise
  # return 0 — reporting a CLAUDE.md nobody could read as one whose
  # pre-authorization keys are well-formed.
  expect_in "$clean_output" "the Landing: key read-error did not fire on an unreadable root file" "CLAUDE.md could not be read — the Landing: key check did not run on it"
fi
fi
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "Linter output against $fixtures was:"
  printf '%s\n' "$output"
  # The injected run is a second linter invocation against a second root; dumping
  # the fixture run for a failure of that one shows a tree that by construction
  # holds neither read-error message, and reads as "the branch does not exist".
  if [ -n "${inject_output:-}" ]; then
    echo
    echo "Linter output against the injected tree was:"
    printf '%s\n' "$inject_output"
  fi
  if [ -n "${clean_output:-}" ]; then
    echo
    echo "Linter output against the injected clean root was:"
    printf '%s\n' "$clean_output"
  fi
fi

# Three statuses, not two — selftest_close's contract: 1 is a real failure; 2 is
# "nothing failed, and some rows went ungraded", a distinct code because the only
# automated consumer, scripts/git-hooks/post-merge, discards stdout and reads the
# status alone. Which rows went ungraded is the SKIP lines' to say, not this
# one's: six sites can set it, across two blocks that skip for different reasons.
selftest_close \
  "lint self-test clean — every fixture failure fired, every exempt form stayed quiet, the isolated roots moved the exit status, and every read-error branch fired on an unreadable file." \
  "clean on the fixture trees — every fixture failure fired and every exempt form stayed quiet — but at least one throwaway-root block could not be built, so the rows it carries went ungraded. The SKIP line or lines above name which; a run that ends here has not graded them."
