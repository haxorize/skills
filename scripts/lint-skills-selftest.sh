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
# wrong-on-purpose tree, roughly twenty deliberate violations force exit 1 no
# matter what the read error does.
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
# unmasked — a user-invoked skill and a built-in — staying quiet. What that
# buys, stated no larger than it is: those shapes cannot stop grading without
# this script saying so. It is not a claim about shapes no fixture holds, and
# lint-skills.sh's own header states what its scans never reach at all.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fixtures="scripts/lint-fixtures"
if [ ! -d "$fixtures" ]; then
  echo "SELFTEST FAIL: fixture tree $fixtures is missing"
  exit 1
fi

# The mirror tree: right on purpose, so an induced failure is attributable to
# the thing induced. See the read-error block near the bottom.
clean_fixtures="scripts/lint-fixtures-clean"
if [ ! -d "$clean_fixtures" ]; then
  echo "SELFTEST FAIL: clean fixture tree $clean_fixtures is missing"
  exit 1
fi

output=$(LINT_ROOT="$fixtures" bash scripts/lint-skills.sh 2>&1)
status=$?

fail=0

# Grading both directions. Each `expect` names a check and a substring only
# that check's message can produce; each `reject` names a form the linter must
# leave alone.
# One matcher for every root: $1 is the linter output to search, $2 says what
# went wrong and where, $3 is the substring only the graded check can produce.
# The wrappers below give each root its own wording without a second copy of
# the matcher, so a fix to the matching lands once.
expect_in() {
  if ! printf '%s\n' "$1" | grep -qF "$3"; then
    echo "SELFTEST FAIL: $2 — expected a line containing: $3"
    fail=1
  fi
}

expect() {
  expect_in "$output" "the $1 check did not fire on the fixture tree" "$2"
}

reject() {
  if printf '%s\n' "$output" | grep -qF "$2"; then
    echo "SELFTEST FAIL: the $1 check fired on a form it must exempt — found a line containing: $2"
    fail=1
  fi
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

# The reject above is the only row in this suite that grades the citation check's
# plumbing, and it discriminates only while bulk-cited-dep's tail is longer than a
# pipe will hold — otherwise the producer finishes writing before the reader walks
# away, the pre-fix pipeline passes too, and the row silently stops testing
# anything. Linux's pipe capacity is a fixed 65536 bytes and is the larger of the
# two this repo is run on, so that is the floor. Trimming the fixture must fail
# here, loudly, rather than turning the row into a no-op.
bulk_bytes=$(find "$fixtures/src/bulk-cited-dep" -type f -name '*.md' -exec cat {} + | wc -c | tr -d ' ')
if [ "$bulk_bytes" -le 65536 ]; then
  echo "SELFTEST FAIL: src/bulk-cited-dep/ is $bulk_bytes bytes, at or under a Linux pipe's 65536-byte capacity — the early-citation reject no longer discriminates, because the producer can hand over the whole stream before the reader exits. Add reference-file length back (each file caps at 200 lines)."
  fail=1
fi

if [ "$status" -ne 1 ]; then
  echo "SELFTEST FAIL: lint exited $status against the fixture tree; a tree this broken must exit 1"
  fail=1
fi

# The clean root's baseline. Every later assertion against it reads "the thing
# I broke caused this", and that reading is only sound while the untouched tree
# exits 0 — so a violation drifting into scripts/lint-fixtures-clean/ must fail
# here rather than quietly restoring the vacuous check this replaced.
if ! clean_baseline=$(LINT_ROOT="$clean_fixtures" bash scripts/lint-skills.sh 2>&1); then
  echo "SELFTEST FAIL: $clean_fixtures does not lint clean, so a failure induced in it proves nothing. Linter output was:"
  printf '%s\n' "$clean_baseline"
  fail=1
fi

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
skipped=0
# `set -e` is deliberately off in this script, so an empty inject_root would not
# stop anything: `cp -R "$fixtures/." "/"` is a valid command, and the trap's
# `rm -rf ""` cleans up nothing. Guard the variable before anything uses it as
# a path, and check the copy — a partial tree fails the two rows below and
# misattributes the failure to the read-error branches.
inject_parent="$(mktemp -d)"
if [ -z "$inject_parent" ] || [ ! -d "$inject_parent" ]; then
  echo "SELFTEST SKIP: mktemp -d produced no usable directory — the two read-error branches were not exercised by this run."
  skipped=1
else
trap 'chmod -R u+rwX "$inject_parent" 2>/dev/null; rm -rf "$inject_parent"' EXIT
inject_root="$inject_parent/broken"
clean_root="$inject_parent/clean"
if ! mkdir -p "$inject_root" "$clean_root" ||
   ! cp -R "$fixtures/." "$inject_root/" ||
   ! cp -R "$clean_fixtures/." "$clean_root/"; then
  echo "SELFTEST SKIP: could not copy the fixture trees into $inject_parent — the two read-error branches were not exercised by this run."
  skipped=1
else
unreadable="$inject_root/src/broken-links/references/real-reference.md"
clean_unreadable="$clean_root/src/clean-skill/references/note.md"
chmod 000 "$unreadable" "$clean_unreadable"
if cat "$unreadable" >/dev/null 2>&1 || cat "$clean_unreadable" >/dev/null 2>&1; then
  # Running as root, or on a filesystem that ignores the mode. Not a
  # regression, but the branches below went unexercised and the closing line
  # must not claim otherwise.
  echo "SELFTEST SKIP: $unreadable is still readable after chmod 000 (running as root, or a filesystem that ignores modes) — the two read-error branches were not exercised by this run."
  skipped=1
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
  clean_status=$?
  if [ "$clean_status" -ne 1 ]; then
    echo "SELFTEST FAIL: lint exited $clean_status against an otherwise-clean tree holding one unreadable file; a read error on its own must force exit 1"
    fail=1
  fi
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
elif [ "$skipped" -eq 0 ]; then
  echo "OK: lint self-test clean — every fixture failure fired, every exempt form stayed quiet, and both read-error branches fired on an unreadable file."
else
  echo "SELFTEST PARTIAL: clean on the fixture tree — every fixture failure fired and every exempt form stayed quiet — but the two read-error branches were not exercised; see the SKIP line above. A run that ends here has not graded them."
fi

# Three statuses, not two. 1 is a real failure; 2 is "nothing failed, and two
# branches went ungraded" — a distinct code because the only automated consumer,
# scripts/git-hooks/post-merge, discards stdout and reads the status alone, so a
# partial that exits 0 is indistinguishable from a whole clean to the one caller
# that most needs to tell them apart.
if [ "$fail" -ne 0 ]; then
  exit 1
elif [ "$skipped" -ne 0 ]; then
  exit 2
fi
exit 0
