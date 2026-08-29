#!/usr/bin/env bash
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
# slash-on-model-invoked check is covered the same way, in a SKILL.md and in a
# reference file (the wider sweep), with the two slash forms that are correct
# unmasked — a user-invoked skill and a built-in — staying quiet.
# Also covered: the single-line-description check in three shapes (a folded
# block scalar, a literal one with an indentation indicator, a continued plain
# scalar), the re-attach byte-size WARN (fires on the oversize fixture, draws
# no FAIL, stays silent on the clean root, and stays silent on the clean
# root's near-cap body under the bound — so the threshold is pinned
# from below as well as above), the hook-selftest check (a marked hook with no
# selftest, one whose selftest lacks the exec bit, an unmarked file that must
# stay quiet whatever its name, and a *-lib.sh), the script-selftest check
# (a script with no selftest, one whose selftest lacks the exec bit, and the
# quiet forms: a *-lib.sh and install.sh), the shared-trigger-phrase check (two
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
# paths), the sibling-group MEMBERSHIP check (it does run against the fixture
# tree, but the fixtures hold no two reference files sharing a basename, so its
# `uniq -d` input is always empty and the check is structurally incapable of
# firing — covering it needs a fixture pair with one shared basename and no
# group), description length, angle brackets, name/directory agreement, the
# requires: resolution check (existence and model-invoked), router coverage,
# and the classifier's unclaimed-file arm — walk_shipped_md emits only the
# classes the arms above it claim, so no fixture can produce a path that
# reaches its say_fail; it guards a tree added to the walk without an arm, and
# has no input to grade it with. Several checks can be disabled outright with
# this run still green; this list is the authority on which, and lint-skills.sh's
# own header states what its scans never reach at all.
#
# What the covered list buys, stated no larger than it is: those shapes cannot
# stop grading without this script saying so. It was measured, not assumed —
# 31 mutations of lint-skills.sh graded by this script, 30 red and 1 silent
# (the unclaimed-file arm above). The 30: each of the three ledger check calls
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
# process substitution into a here-string instead is behaviour-preserving — no
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
expect "two-way requires (unused)" "src/unused-dep/SKILL.md declares requires: 'fixture-discipline' but the body never names it"
expect "single-line description (block scalar)" "src/folded-description/SKILL.md description is a YAML block scalar ('>-')"
expect "single-line description (literal block scalar with indicators)" "src/literal-description/SKILL.md description is a YAML block scalar ('|2-')"
expect "single-line description (continued line)" "src/continued-description/SKILL.md description continues onto an indented next line"
expect "re-attach byte-size WARN" "WARN: src/oversize-body/SKILL.md is "
expect "hook selftest (missing)" "global/hooks/orphan-hook.sh carries an '# Install note:' header, so it is a hook, and has no selftest — write global/hooks/orphan-hook-selftest.sh"
expect "hook selftest (not executable)" "global/hooks/unexec-hook-selftest.sh is not executable"
expect "script selftest (missing)" "scripts/orphan-tool.sh has no selftest — write scripts/orphan-tool-selftest.sh"
expect "script selftest (not executable)" "scripts/unexec-tool-selftest.sh is not executable"
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
reject "hook selftest (library exempt)" "global/hooks/quiet-lib.sh"
reject "hook selftest (no Install note, so not a hook)" "global/hooks/unmarked-helper.sh"
reject "script selftest (library exempt)" "scripts/quiet-lib.sh"
reject "script selftest (installer exempt)" "scripts/install.sh"

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
nfail=$(printf '%s\n' "$output" | grep -c '^FAIL: ')
[ "$nfail" -eq 45 ] || selftest_fail "expected exactly 45 FAIL lines against the fixture tree, got $nfail"
# The shared-trigger-phrase fixtures are pinned by property, as near_bytes and
# bulk_bytes are below: every row above them asserts a FAIL that appears or a
# FAIL that does not, and each of those readings is silently satisfied by a
# fixture whose phrase someone deleted. What the check is graded on is the
# phrases themselves, so they are asserted to still be there — an edit that
# weakens one fails here, naming the fixture, instead of turning a row into a
# no-op nothing reads.
phrase_pin() {
  local f=$1 what=$2 pattern=$3
  if [ ! -f "$f" ]; then
    selftest_fail "$f is missing — it carries $what for the shared-trigger-phrase check; restore it rather than reading the rows above as still graded"
  elif ! grep -q "^description:.*$pattern" "$f"; then
    selftest_fail "$f no longer carries $what in its description — the shared-trigger-phrase rows above stopped grading it; put it back rather than deleting the assertion"
  fi
}
phrase_pin "$fixtures/src/shared-trigger-straight/SKILL.md" "the shared phrase in straight double quotes" '"walk the tree"'
phrase_pin "$fixtures/src/shared-trigger-curly/SKILL.md" "the shared phrase in curly quotes and another case (the only place the curly branch of the extractor and the case fold are exercised)" '“Walk The Tree”'
phrase_pin "$fixtures/src/shared-trigger-scalar/SKILL.md" "the shared phrase escaped inside a whole-value YAML double-quoted scalar (the only place the unwrap-and-unescape path is exercised)" ' ".*\\"walk the tree\\"'
phrase_pin "$fixtures/src/shared-trigger-not-for/SKILL.md" "the shared phrase inside a disambiguating \"Not for…\" tail, which must stay quiet" 'Not for.*"walk the tree"'
phrase_pin "$fixtures/src/quoted-dep/SKILL.md" "the shared phrase in a user-invoked description, which must never be read" '"walk the tree"'
phrase_pin "$clean_fixtures/src/clean-skill/SKILL.md" "one phrase quoted twice, which is not a duplicate" '"do the thing".*"do the thing"'
phrase_pin "$clean_fixtures/src/which-skill/SKILL.md" "clean-skill's phrase in a user-invoked description, which must never be read" '"do the thing"'
# The backticked span is the clean root's quiet form for "only double-quoted
# spans are compared": two model-invoked descriptions share it, so widening the
# extractor's alternation to backticks turns this root red — which is what makes
# the exemption an assertion rather than a sentence in a header.
for capped in clean-skill near-cap; do
  phrase_pin "$clean_fixtures/src/$capped/SKILL.md" "the backticked span two model-invoked descriptions share, which only-double-quoted-spans must leave quiet" '`pin the bound`'
done

# The near-cap body is measured: the clean root holds one 49 bytes under the
# bound (asserted below to draw no WARN), and this pins that it is really there.
near_bytes=$(wc -c < "$clean_fixtures/src/near-cap/SKILL.md" | tr -d ' ')
{ [ "$near_bytes" -gt 14800 ] && [ "$near_bytes" -le 15000 ]; } || selftest_fail "src/near-cap/SKILL.md in the clean root is $near_bytes bytes; it must sit inside (14800, 15000] to pin the WARN threshold from below"

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
  selftest_fail "the clean fixture drew a WARN line; the byte-size warning fired on a body under the bound (near-cap sits 49 bytes under it)"
fi

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
isolated_case() {  # a fifth argument, when given, is a second required substring
  local root="$isolated_parent/$1"
  mkdir -p "$root" && cp -R "$clean_fixtures/." "$root/" || {
    selftest_skip "could not copy the clean tree for the '$1' case — that row was not exercised."
    return 0
  }
  perl -0pi -e "$2 or die" "$root/$3" 2>/dev/null || {
    selftest_skip "the edit for the '$1' case matched nothing in $3 — the fixture was renamed or reworded, so that row was not exercised. Fix the pattern rather than reading the row as still graded."
    return 0
  }
  local out rc
  out=$(LINT_ROOT="$root" bash scripts/lint-skills.sh 2>&1); rc=$?
  expect_in "$out" "the ledger check did not fire in the isolated '$1' root" "$4"
  [ -n "${5:-}" ] && expect_in "$out" "the isolated '$1' root did not carry its second required line" "$5"
  expect_rc "the lint against the isolated '$1' root" 1 "$rc"
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
# CLAUDE.md's "its two definition sites agree" is asserting.
isolated_case "rule-reworded" 's/\*\*Exactly one stored status\.\*\*/**Exactly one status is stored.**/' \
  "src/ledger-legend/SKILL.md" \
  "but no file states the stored-status rule"
# Two rule sites: only one would be compared against the legend, so the other
# could drift unseen. The old form took `head -1` and never said so.
isolated_case "two-rules" 's/\z/\n- **Exactly one stored status.** `marketed`, `verified`, `refuted`.\n/' \
  "src/ledger-legend/references/complete-consumer.md" \
  "two files state the evaluation ledger's stored-status rule"
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
if ! chmod 000 "$unreadable" "$clean_unreadable" "$clean_unreadable_in_legend_dir" 2>/dev/null; then
  selftest_fail "chmod 000 failed on one of $unreadable, $clean_unreadable or $clean_unreadable_in_legend_dir — a fixture was renamed or removed; update the paths here rather than reading the rows below as a dead branch"
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
  "lint self-test clean — every fixture failure fired, every exempt form stayed quiet, the isolated roots moved the exit status, and both read-error branches fired on an unreadable file." \
  "clean on the fixture trees — every fixture failure fired and every exempt form stayed quiet — but at least one throwaway-root block could not be built, so the rows it carries went ungraded. The SKIP line or lines above name which; a run that ends here has not graded them."
