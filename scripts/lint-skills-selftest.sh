#!/usr/bin/env bash
# Prove scripts/lint-skills.sh still catches what it claims to catch.
#
# A lint gate degrades silently: the run stays green whether the rule holds or
# the check quietly stopped matching, and the two are indistinguishable from
# the outside. This script points the linter at scripts/lint-fixtures/ — a tiny
# repo root whose skills are wrong on purpose — and grades it in both
# directions: every expected failure must appear, and the forms the linter
# exempts must produce no failure at all. A one-directional check would pass
# just as happily against a linter that flagged everything. It then grades a
# second root, scripts/lint-fixtures-clean/, which is right on purpose and must
# exit 0; and then throwaway copies of both with one file's mode broken, because
# the two read-error branches cannot be reached from a committed fixture. The
# clean root is what lets an exit-status assertion mean anything: in the
# wrong-on-purpose tree the deliberate violations force exit 1 no matter what
# the read error does — the count is pinned below, in one place, rather than
# restated here where it would drift every time a check is added.
#
# Run it after changing any check in lint-skills.sh.
#
# Covered here: reference-link resolution (both directions, including the
# backtick-span and fenced-block exemptions), the ADR-citation ban, the
# rich-text transport ban, the
# description's unquoted ': ' and ' #', load-gate placement, and the global-rules
# Depends: admission check (missing line, dangling name, a dependant that never
# cites the rule outside a fence, a dependant that cites only another rule's
# path, and the three well-formed forms that must stay quiet — backticked stem,
# path, and a citation in the opening lines of a body whose tail the producer is
# still writing when the reader walks away, which grades the check's plumbing
# rather than its pattern). Both read-error branches are covered too — the link
# extractor's and the Depends: citation check's — by a runtime `chmod 000` on a
# throwaway copy of the tree rather than by a fixture, since git stores only the
# exec bit and an unreadable mode does not survive checkout. Three conditions
# skip that second root — no usable temp directory, a copy that fails, or a run
# that can still read the file after chmod 000 (root, or a filesystem that
# ignores modes) — and each prints a SELFTEST SKIP line and downgrades the
# closing line from OK: to SELFTEST PARTIAL:, and the script exits 2 rather
# than 0 — a third status, so a caller reading the status alone can still tell a
# narrower clean from a whole one. NOT covered, so a clean
# run here is not a claim about them: the 200-line caps, sibling byte-identity
# (skipped under LINT_ROOT — the registry names this repo's own paths), the
# sibling-group MEMBERSHIP check (it does run against the fixture tree, but the
# fixtures hold no two reference files sharing a basename, so its `uniq -d`
# input is always empty and the check is structurally incapable of firing —
# covering it needs a fixture pair with one shared basename and no group),
# description length, angle brackets, name/directory agreement, the
# requires: resolution check (existence and model-invoked), and router
# coverage. The two-way requires check is covered in both directions across the
# forms the matcher must reach — an imperative call, a gerund one, two names in
# one clause, and a call on a user-invoked skill, each firing; a quoted, an
# arrow-parenthesised and a fenced mention staying quiet. The
# slash-on-model-invoked check is covered the same way, in a SKILL.md and in a
# reference file (the wider sweep), with the two slash forms that are correct
# unmasked — a user-invoked skill and a built-in — staying quiet. Covered since
# 2026-08-29: the single-line-description check in three shapes (a folded
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
# nothing and exits 2). What that
# buys, stated no larger than it is: those shapes cannot stop grading without
# this script saying so. It is not a claim about shapes no fixture holds, and
# lint-skills.sh's own header states what its scans never reach at all.

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
[ "$nfail" -eq 29 ] || selftest_fail "expected exactly 29 FAIL lines against the fixture tree, got $nfail"
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

# The two read-error branches, exercised by runtime injection. Both report that
# a check never ran rather than that it passed, so a branch that stops firing
# turns an unread file into a silent clean — the exact failure the messages
# exist to prevent. They cannot be reached from a committed fixture: git stores
# only the exec bit, so an unreadable mode does not survive checkout. So copy
# the tree, break one file's mode in the copy, and grade the two messages.
# One `chmod 000` reaches both because the file sits under `src/broken-links/`,
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
trap 'chmod -R u+rwX "$inject_parent" 2>/dev/null; rm -rf "$inject_parent"' EXIT
inject_root="$inject_parent/broken"
clean_root="$inject_parent/clean"
if ! mkdir -p "$inject_root" "$clean_root" ||
   ! cp -R "$fixtures/." "$inject_root/" ||
   ! cp -R "$clean_fixtures/." "$clean_root/"; then
  selftest_skip "could not copy the fixture trees into $inject_parent — the two read-error branches were not exercised by this run."
else
unreadable="$inject_root/src/broken-links/references/real-reference.md"
clean_unreadable="$clean_root/src/clean-skill/references/note.md"
# chmod's own status is read: a renamed fixture would otherwise fall through
# to the readability test below and be reported as a dead read-error branch.
if ! chmod 000 "$unreadable" "$clean_unreadable" 2>/dev/null; then
  selftest_fail "chmod 000 failed on $unreadable or $clean_unreadable — a fixture was renamed or removed; update the two paths here rather than reading the rows below as a dead branch"
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

# Three statuses, not two — selftest_close's contract: 1 is a real failure; 2
# is "nothing failed, and two branches went ungraded", a distinct code because
# the only automated consumer, scripts/git-hooks/post-merge, discards stdout
# and reads the status alone.
selftest_close \
  "lint self-test clean — every fixture failure fired, every exempt form stayed quiet, and both read-error branches fired on an unreadable file." \
  "clean on the fixture tree — every fixture failure fired and every exempt form stayed quiet — but the two read-error branches were not exercised; see the SKIP line above. A run that ends here has not graded them."
