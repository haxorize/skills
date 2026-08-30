#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/git-hooks/commit-msg still catches what it claims to catch.
#
# A commit-msg hook degrades silently the same way a linter does: the commit
# goes through whether the rule holds or the check quietly stopped matching.
# This script feeds the hook messages that are wrong on purpose and messages
# that are right on purpose, and grades it in both directions — every rule must
# reject its violation, and every exempt shape must be allowed. A one-directional
# check would pass just as happily against a hook that rejected everything.
#
# Grade a rule against narrowing and widening, not only against deletion. A row
# that only proves the rule fires at all leaves "off by one column" and "the
# wordlist lost an entry" invisible, which is how the trailer exemption shipped
# matching every "Word: " opener. Hence the boundary rows either side of the
# cap, and a row per exempt filename and per generated-subject prefix.
#
# Every row runs with the hook's cwd inside $tmp. The hook resolves the
# commitlint filenames against its cwd, so probing the opt-out anywhere else
# would create and delete files in a real working tree — and post-merge runs
# this script on every merging pull.
#
# Run it after changing the hook.
#
# Covered here: the subject rules (the cap and its boundary, trailing period,
# Conventional Commits prefix and every filename of the config opt-out, the
# imperative-opener warning), the body rules (blank separator, code fence,
# markdown heading, the wrap cap and its boundary), the exemptions (an
# in-progress merge/revert/cherry-pick, git's generated subject prefixes,
# trailers, an unbreakable long token, git's own comments, a verbose diff, an
# empty message), and the advisory lines. NOT covered, so a clean run here is
# not a claim about them: everything the hook's own header says it cannot
# check — one-logical-change, whether the body was needed, register, and the
# tell catalog. Those need a reader, and no fixture can stand in for one.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

hook="$repo_root/scripts/git-hooks/commit-msg"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

# The cap the hook enforces. Fixtures are built from it, so a row cannot drift
# to the wrong length the way a hand-counted English sentence did.
WRAP=72

work="$tmp/work"          # not a git repo: no operation is ever in progress
mkdir -p "$work"

# pad <length> <seed> -> a line of exactly <length> characters, spaces included
# so the wrap rule's "could this have been wrapped" test sees a break point.
pad() {
  local s="$2"
  while [ "${#s}" -lt "$1" ]; do s="$s word"; done
  printf '%s' "${s:0:$1}"
}

# run <message> [cwd] -> sets $rc and $out
run() {
  printf '%s' "$1" > "$tmp/msg"
  out="$(cd "${2:-$work}" && bash "$hook" "$tmp/msg" 2>&1)"
  rc=$?
}

reject_msg() { # reject_msg <label> <message> <expected substring>
  run "$2"
  if [ "$rc" -eq 0 ]; then
    echo "SELFTEST FAIL: the $1 rule did not reject — the hook allowed a message it must block"
    fail=1
  elif ! printf '%s\n' "$out" | grep -qF "$3"; then
    echo "SELFTEST FAIL: the $1 rule rejected with the wrong message — expected a line containing: $3"
    echo "  got: $out"
    fail=1
  fi
}

allow_msg() { # allow_msg <label> <message> [cwd]
  run "$2" "${3:-}"
  if [ "$rc" -ne 0 ]; then
    echo "SELFTEST FAIL: the $1 shape was rejected — the hook must allow it"
    echo "  got: $out"
    fail=1
  fi
}

warn_msg() { # warn_msg <label> <message> <expected substring>
  run "$2"
  if [ "$rc" -ne 0 ]; then
    echo "SELFTEST FAIL: the $1 check blocked — it must warn and allow"
    fail=1
  elif ! printf '%s\n' "$out" | grep -qF "$3"; then
    echo "SELFTEST FAIL: the $1 warning did not fire — expected a line containing: $3"
    fail=1
  fi
}

note_fail() { echo "SELFTEST FAIL: $1"; fail=1; }

# --- the subject cap, and both sides of its boundary ------------------------

reject_msg "subject over the cap" "$(pad $((WRAP + 1)) 'Add a subject line')"  "over the $WRAP hard cap"
allow_msg  "subject exactly at the cap" "$(pad "$WRAP" 'Add a subject line')"

# --- the other subject rules ------------------------------------------------

reject_msg "trailing period"      "Add the commit-msg hook."          "ends with a period"
reject_msg "conventional prefix"  "feat: add the commit-msg hook"     "Conventional Commits type prefix"
reject_msg "scoped cc prefix"     "fix(hooks): stop the bypass"       "Conventional Commits type prefix"
reject_msg "breaking cc prefix"   "refactor!: drop the old parser"    "Conventional Commits type prefix"

# The rule names the Conventional Commits type set, so a lowercase word that is
# not one of those types is ordinary prose and must pass — the message asserts a
# fact about the subject, and it has to be true.
allow_msg "lowercase prose, not a cc type" "note: keep the parser lowercase"
allow_msg "todo prose, not a cc type"      "todo: revisit the parser once"

# The anchors matter as much as the alternation: a prefix has to be at the very
# start, and the colon-space has to follow the type.
allow_msg "cc type mid-subject"   "Add the feat: marker to the parser"
allow_msg "cc type with no space" "Add feat:parser handling to the hook"

# --- the body rules ---------------------------------------------------------

reject_msg "no blank separator"   "Add the hook
The body starts immediately with no blank line above it."             "no blank line between subject and body"
reject_msg "code fence"           "Add the hook

Previously nothing checked the message:

\`\`\`
git commit -m 'whatever'
\`\`\`"                                                                "code fence"
reject_msg "indented code fence"  "Add the hook

  \`\`\`
  git commit
  \`\`\`"                                                              "code fence"

# The style doc's rule is every heading, not a wordlist, so the row set has to
# cover a word no wordlist would have carried.
reject_msg "Summary heading"      "Add the hook

## Summary

It checks the message."                                               "markdown heading"
reject_msg "Testing heading"      "Add the hook

## Testing

Ran the selftest."                                                    "markdown heading"
reject_msg "unlisted heading word" "Add the hook

## Rationale

It checks the message."                                               "markdown heading"
reject_msg "deep heading"         "Add the hook

###### Notes

It checks the message."                                               "markdown heading"

# A hash that is not a heading must not trip it — otherwise the rule is a ban
# on the character.
# Inline backticks are not a fence. Without this row the fence rule could widen
# to any backtick and still grade green, while blocking most bodies in this repo.
allow_msg "inline code span, not a fence" "Add the hook

The old test called \`grep -qE\` on each line."

allow_msg "hash mid-line, not a heading" "Add the hook

This fixes the parser bug, not issue ## 12, which stays open."

# --- the wrap cap, and both sides of its boundary ---------------------------

reject_msg "body over the wrap cap" "Add the hook

$(pad $((WRAP + 1)) 'This body line')"                                "exceeds $WRAP columns"
allow_msg  "body exactly at the wrap cap" "Add the hook

$(pad "$WRAP" 'This body line')"

# Every offending line is named, not only the first: one commit attempt has to
# show the whole list.
run "Add the hook

$(pad $((WRAP + 1)) 'The first body line')
$(pad $((WRAP + 1)) 'The second body line')"
if [ "$(printf '%s\n' "$out" | grep -c "exceeds $WRAP columns")" -ne 2 ]; then
  note_fail "the wrap rule reported only some of the over-long lines — every one must be named"
fi

# --- the exemptions ---------------------------------------------------------

# A trailer is what git says is a trailer. An ordinary paragraph that happens to
# open "Note: " is prose and wraps like prose.
allow_msg "trailers exempt from wrap" "Add the commit-msg hook

A short body.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QPc1XNoRhSh4kmSpxAfjaFxxxxxxxxxxxxxxxx"
reject_msg "a prose line opening Key:" "Add the hook

Some prose above it.
$(pad $((WRAP + 1)) 'Note: this line')"                               "exceeds $WRAP columns"

allow_msg "unbreakable long token" "Add the commit-msg hook

See
https://example.com/a/very/long/url/that/cannot/be/wrapped/at/seventy/two/columns/at/all"

# Git's generated subject prefixes. Each is its own row: dropping one from the
# case arm must fail here, not pass because a sibling still matches.
allow_msg "fixup subject"   "fixup! Add the commit-msg hook."
allow_msg "squash subject"  "squash! Add the commit-msg hook."
allow_msg "amend subject"   "amend! Add the commit-msg hook."
allow_msg "reapply subject" "Reapply \"$(pad 63 'Add the commit-msg hook')\""

# A subject a person wrote that merely begins "Merge " or "Revert " is ordinary
# prose. The exemption is the git state, so these must be checked.
reject_msg "prose Merge subject"  "Merge the two helpers into one."    "ends with a period"
reject_msg "prose Revert subject" "Revert to the older parser."        "ends with a period"

# ...and the git state itself must exempt. A real repo, so rev-parse answers.
mergerepo="$tmp/mergerepo"
git init -q "$mergerepo" 2>/dev/null
for state in MERGE_HEAD REVERT_HEAD CHERRY_PICK_HEAD; do
  : > "$mergerepo/.git/$state"
  allow_msg "a $state commit git is concluding" "Merged the feature branch in." "$mergerepo"
  rm -f "$mergerepo/.git/$state"
done
# ...and with no operation in progress, the same message is checked again.
reject_msg "the same subject with no merge in progress" "Merged the feature branch in." "ends with a period"

# Git's own comments are not the message. These comment lines are over the cap
# on purpose: if the strip stops working, they trip the wrap rule and this fails.
allow_msg "comments stripped" "Add the commit-msg hook

# Please enter the commit message for your changes. Lines starting with '#' will be ignored.
# An empty message aborts the commit, and this line is also well past seventy-two columns."

# ...but a markdown heading must survive the strip, or the heading rule is dead.
reject_msg "heading survives the comment strip" "Add the hook

## Summary

Text."                                                                "markdown heading"

# The verbose diff a `git commit -v` message carries is below the scissors and
# is not the message either.
allow_msg "git commit -v diff ignored" "Add the commit-msg hook

A short body.

# ------------------------ >8 ------------------------
diff --git a/scripts/git-hooks/commit-msg b/scripts/git-hooks/commit-msg
index e1fc2d1..554ef29 100755
--- a/scripts/git-hooks/commit-msg
+++ b/scripts/git-hooks/commit-msg
@@ -37,7 +37,7 @@ fi
-a line that is very long indeed and comfortably past the seventy-two column cap"

allow_msg "empty message" ""
allow_msg "blank lines only" "

"

# A message file that is not there must not abort a commit.
out="$(cd "$work" && bash "$hook" "$tmp/does-not-exist" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || note_fail "the missing-file guard did not allow — an absent message file must never block a commit"
[ -z "$out" ] || note_fail "the missing-file guard let an error through to the author: $out"

# A leading blank line: the subject and the body must agree on which line is
# which, or a message with no body fails a body rule.
allow_msg "leading blank line, no body"   "
Add the commit-msg hook"
allow_msg "leading blank line, with body" "
Add the commit-msg hook

A short body."

# ...and a leading blank line must not swallow the subject either: the rules
# still have to fire on it, or dropping the normalisation grades green.
reject_msg "leading blank line, subject still checked" "
Add the commit-msg hook." "ends with a period"

# A CR must not survive into the subject, where it would hide a trailing period.
reject_msg "CRLF trailing period" "$(printf 'Add the commit-msg hook.\r')" "ends with a period"

# --- must warn, not block ---------------------------------------------------

# One row per wordlist entry: dropping a single word must fail here.
for w in Added Adds Adding Updated Updates Updating Fixed Fixes Fixing \
         Changed Changes Changing Removed Removes Removing Created Creates Creating \
         Deleted Deletes Deleting Refactored Refactors Refactoring \
         Implemented Implements Implementing Improved Improves Improving \
         Bumped Bumps Bumping Moved Moves Moving Renamed Renames Renaming \
         Tagged Tags Tagging; do
  warn_msg "imperative opener '$w'" "$w the commit-msg hook" "an imperative verb leads"
done

# --- the Conventional Commits opt-out, one row per filename -----------------

for f in .commitlintrc .commitlintrc.json .commitlintrc.yml .commitlintrc.yaml \
         .commitlintrc.js commitlint.config.js commitlint.config.cjs commitlint.config.mjs \
         commitlint.config.ts .czrc; do
  : > "$work/$f"
  allow_msg "the $f opt-out" "feat: add the commit-msg hook"
  rm -f "$work/$f"
done
# ...and with none of them present, the prefix is rejected again.
reject_msg "no opt-out present" "feat: add the commit-msg hook" "Conventional Commits type prefix"

# --- the advisory lines, and the pointer they name --------------------------

run "Add the commit-msg hook."
printf '%s\n' "$out" | grep -qF "commit rejected. Fix the message" ||
  note_fail "a rejection did not carry the 'commit rejected' advisory line"
printf '%s\n' "$out" | grep -qF "SHAPE only" ||
  note_fail "a rejection did not carry the SHAPE-only advisory line"

run "Added the commit-msg hook"
printf '%s\n' "$out" | grep -qF "warnings only; commit allowed" ||
  note_fail "a warning-only message did not carry the 'commit allowed' line"

# The rejection names a reference file, and the whole design rests on a reader
# being able to open it. A rename that leaves the pointer dangling fails here.
style="$(printf '%s\n' "$out" | grep -oE '[a-z/.-]+commit-style\.md' | head -1)"
[ -n "$style" ] || note_fail "no rejection line named the style reference at all"
[ -z "$style" ] || [ -f "$repo_root/$style" ] ||
  note_fail "the rejection points at $style, which does not exist — the block is meant to be the load instruction"

# ...and every anchor it quotes has to be a heading that is actually in it.
# The anchors are read out of the rejection rather than listed here: a list
# would go stale silently the moment an anchor was reworded in the hook.
if [ -n "$style" ] && [ -f "$repo_root/$style" ]; then
  anchors=0
  while IFS= read -r anchor; do
    [ -n "$anchor" ] || continue
    anchors=$((anchors + 1))
    # -x, not a substring match: a prefix like "## The body" would "find" the
    # real heading and hide exactly the dangling-anchor defect this grades.
    grep -qxF "$anchor" "$repo_root/$style" ||
      note_fail "a rejection quotes the anchor '$anchor', which is not a heading in $style"
  done <<< "$(for m in "Add the commit-msg hook." "Add the hook
No blank line."; do
    run "$m"
    printf '%s\n' "$out" | grep -oE "'##[^']*'" | tr -d \'
  done | sort -u)"
  [ "$anchors" -ge 2 ] ||
    note_fail "expected the rejections to quote a subject anchor and a body anchor; saw $anchors"
fi

# The prefix has to be whole in the source, or a user pasting a rejection line
# into a search finds nothing.
grep -qF 'echo "commit-msg: FAIL subject ends with a period' "$hook" ||
  note_fail "rejection lines no longer carry the 'commit-msg: ' prefix inline — a pasted line will not grep back to the hook"

# --- character counting, not byte counting ----------------------------------

# Under a C locale ${#var} counts bytes, and this repo's prose is full of
# three-byte em dashes. A line inside the cap must stay inside it.
emdash_line="A body line — with — several — em — dashes — inside it — ok — yes"
printf '%s' "Add the commit-msg hook

$emdash_line" > "$tmp/msg"
out="$(cd "$work" && LC_ALL=C bash "$hook" "$tmp/msg" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] ||
  note_fail "a line of ${#emdash_line} characters was rejected under LC_ALL=C — the hook is counting bytes, not characters"

# --- clean messages ---------------------------------------------------------

allow_msg "clean subject only" "Add the commit-msg hook"
allow_msg "clean subject and body" "Add the commit-msg hook

Nothing checked commit message shape, so a style miss surfaced only in
review. The hook rejects at the moment of the mistake and names the
reference, so the block is also the load instruction."

if [ "$fail" -ne 0 ]; then
  echo "SELFTEST FAIL: commit-msg self-test failed."
  exit 1
fi
echo "OK: commit-msg self-test clean — every bad message rejected, every exempt shape allowed."
