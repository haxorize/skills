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
# Conventional Commits prefix (one row per type) and every filename of the config opt-out, the
# imperative-opener warning), the body rules (blank separator, code fence,
# markdown heading, the wrap cap and its boundary), the fold (an over-long
# prose line re-broken with its words intact and a short line beside it never
# joined; a run of spaces and a tab kept byte for byte, and a line with no
# lone space left whole and rejected under that reason, a list item under its
# own; list items, indented lines, `>` quotes, `|` table rows, lines in a
# ~~~ fence or after a ``` inside one, and the trailer paragraph left alone
# and still rejected; no break before a word opening with the comment string,
# '#' or a configured one; the write through a temp file and a rename, so a
# failed write leaves the message whole and no temp file survives a fold; a
# generated subject never folded), a mutation table that edits a copy of the
# hook and requires each fold-guard row to go red, the exemptions (an
# in-progress merge/revert/cherry-pick, git's generated subject prefixes,
# trailers, an unbreakable long token, git's own comments under each of the two
# config names that set the comment string alone, under both names in each
# order, and under a repo-local file overriding a global one, a verbose diff,
# an empty message), and the advisory lines. NOT covered, so a clean run here is
# not a claim about them: everything the hook's own header says it cannot
# check — one-logical-change, whether the body was needed, register, and the
# tell catalog. Those need a reader, and no fixture can stand in for one.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

hook="$repo_root/scripts/git-hooks/commit-msg"
# Temp-file template and guard: scripts/README.md § Temp files. Spelled out
# because this script reports its own rows; it sources selftest-lib.sh below
# for the mutation table's selftest_mutate and selftest_expect_killed alone.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/commit-msg-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "commit-msg-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT
# shellcheck source=../selftest-lib.sh
. "$repo_root/scripts/selftest-lib.sh"
fail=0

# The hook reads git config, so every row is graded against config this script
# controls and nothing else: an /etc/gitconfig or a developer's ~/.gitconfig
# carrying core.commentChar would otherwise red or green the comment rows for a
# reason outside them. The comment-string rows below point GIT_CONFIG_GLOBAL at
# their own throwaway file, one row at a time.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

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

# allow_unfolded <label> <message> [cwd]: allowed, nothing folded, and the
# message file left byte-for-byte as written. A comment, trailer, or diff line
# the fold wrongly took for prose would be re-broken and pass a plain allow_msg.
allow_unfolded() {
  allow_msg "$@"
  if printf '%s\n' "$out" | grep -qF "folded"; then
    note_fail "the $1 shape was folded — the fold must leave it alone"
  elif [ "$(cat "$tmp/msg")" != "$2" ]; then
    note_fail "the $1 message file changed with no fold reported"
  fi
}

# fold_msg <label> <message> <lines expected folded>: allowed, the count
# reported, every breakable body line inside the cap afterwards, and the same
# words in the same order — the fold may move whitespace and nothing else.
fold_msg() {
  run "$2"
  if [ "$rc" -ne 0 ]; then
    note_fail "the $1 message was rejected — its over-long prose must fold, not block"
    echo "  got: $out"
  elif ! printf '%s\n' "$out" | grep -qF "commit-msg: folded $3 body lines"; then
    note_fail "the $1 message did not report 'folded $3 body lines'"
    echo "  got: $out"
  fi
  if [ "$(printf '%s' "$2" | tr -s ' \n' '  ')" != "$(tr -s ' \n' '  ' < "$tmp/msg" | sed 's/ $//')" ]; then
    note_fail "the $1 fold changed a word or its order, not only whitespace"
  fi
  while IFS= read -r line; do
    [ "${#line}" -le "$WRAP" ] && continue
    case "${line:0:$((WRAP + 1))}" in *' '*) ;; *) continue ;; esac
    case "$line" in Claude-Session:*|Co-Authored-By:*) continue ;; esac
    note_fail "the $1 fold left a breakable line over the cap: ${line:0:40}…"
  done < "$tmp/msg"
}

# --- the subject cap, and both sides of its boundary ------------------------

reject_msg "subject over the cap" "$(pad $((WRAP + 1)) 'Add a subject line')"  "over the $WRAP hard cap"
allow_msg  "subject exactly at the cap" "$(pad "$WRAP" 'Add a subject line')"

# --- the other subject rules ------------------------------------------------

reject_msg "trailing period"      "Add the commit-msg hook."          "ends with a period"
reject_msg "conventional prefix"  "feat: add the commit-msg hook"     "Conventional Commits type prefix"
reject_msg "scoped cc prefix"     "fix(hooks): stop the bypass"       "Conventional Commits type prefix"
reject_msg "breaking cc prefix"   "refactor!: drop the old parser"    "Conventional Commits type prefix"
# One row per type the three above do not name, so a type dropped from the
# alternation reds by name (the 2026-09-13 mutation sweep found `test` and
# `chore` droppable with every row green).
for cc_type in docs style perf test build ci chore revert; do
  reject_msg "$cc_type cc prefix" "$cc_type: tidy the parser" "Conventional Commits type prefix"
done

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
reject_msg "tilde code fence"     "Add the hook

~~~
git commit
~~~"                                                                   "code fence"

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

# --- the wrap cap: prose folds, the rest still rejects -----------------------

fold_msg  "body one over the wrap cap" "Add the hook

$(pad $((WRAP + 1)) 'This body line')" 1
allow_unfolded "body exactly at the wrap cap" "Add the hook

$(pad "$WRAP" 'This body line')"

# Every over-long line is counted, and a paragraph is re-broken as a whole.
fold_msg "two over-long lines in one paragraph" "Add the hook

$(pad $((WRAP + 1)) 'The first body line')
$(pad $((WRAP + 1)) 'The second body line')" 2
fold_msg "two paragraphs, one over-long line each" "Add the hook

$(pad 90 'The first paragraph')

$(pad 80 'The second paragraph')" 2

# What the fold must not touch is still rejected, and every offending line is
# named, so one commit attempt shows the whole list.
run "Add the hook

- $(pad $((WRAP + 1)) 'A list item')
  $(pad $((WRAP + 1)) 'An indented line')"
if [ "$rc" -eq 0 ] || [ "$(printf '%s\n' "$out" | grep -c "exceeds $WRAP columns")" -ne 2 ]; then
  note_fail "an over-long list item and indented line were not both rejected — the fold must skip them and the wrap rule name each"
fi
reject_msg "numbered list item over the cap" "Add the hook

1. $(pad $((WRAP + 1)) 'A numbered item')"                             "exceeds $WRAP columns"
printf '%s\n' "$out" | grep -qF "folded" && note_fail "a numbered list item was folded — list items are left to the author"

# A prose line under a list item is its own run and folds; the item does not.
run "Add the hook

- a short item
$(pad 80 'Prose after the list')"
[ "$rc" -eq 0 ] && grep -qxF -- "- a short item" "$tmp/msg" ||
  note_fail "prose after a list item did not fold cleanly, or the item itself was re-broken"

# reject_unfolded <label> <message>: rejected on the wrap rule, nothing folded,
# and the message file left byte-for-byte as written — the shapes the fold must
# never touch, because re-breaking them changes what they mean.
reject_unfolded() {
  run "$2"
  if [ "$rc" -eq 0 ] || ! printf '%s\n' "$out" | grep -qF "exceeds $WRAP columns"; then
    note_fail "the $1 was not rejected on the wrap rule — it must be left for the author"
  fi
  if printf '%s\n' "$out" | grep -qF "folded" || [ "$(cat "$tmp/msg")" != "$2" ]; then
    note_fail "the $1 was rewritten — the fold must leave it alone"
  fi
}
reject_unfolded "line inside a ~~~ fence" "Add the hook

~~~
$(pad 80 'a fenced line')
~~~"
# A ``` inside a ~~~ block is a line of that block: the fence closes only on
# the marker that opened it, so the long line after it is still fenced.
row_nested_fence() {
  run "Add the hook

~~~
\`\`\`
$(pad 80 'still fenced')
~~~"
  if printf '%s\n' "$out" | grep -qF "folded"; then
    note_fail "a long line after a \`\`\` inside a ~~~ block was folded — the inner marker closed the fence"
  fi
}
row_nested_fence
reject_unfolded "> quote line" "Add the hook

> $(pad 80 'a quoted line')"
reject_unfolded "| table row" "Add the hook

| $(pad 80 'a table cell') |"

# Only the over-long line is re-broken; a short line above it in the same
# paragraph keeps its own line, so a deliberate "Before:"/"After:" pair stays a
# pair rather than becoming "Before: 3 calls After: …". A closing paragraph
# follows, since git would parse a last paragraph of "Key: value" lines as
# trailers and the fold would never reach it.
row_short_lines() {
  fold_msg "a short line above an over-long one" "Add the hook

Before: 3 calls
$(pad 90 'After: 1 call and')

That is the whole change." 1
  grep -qxF "Before: 3 calls" "$tmp/msg" ||
    note_fail "the short line above an over-long one was joined into it — the fold may only break the over-long line"
}
row_short_lines

# A generated subject is never rewritten, a long body line included: the skip
# runs before the fold.
for pre in "fixup!" "squash!" "amend!"; do
  allow_unfolded "$pre subject over a long body line" "$pre Add the hook

$(pad 90 'A long body line')"
done
allow_unfolded "Reapply subject over a long body line" "Reapply \"Add the hook\"

$(pad 90 'A long body line')"

# A break never lands before a word opening with the comment string: git
# strips that line under cleanup mode strip. The pad fills the line to the cap
# exactly, so a greedy break would put the next word first on a line.
row_no_comment_start() {
  fold_msg "a break before a #-word" "Add the hook

$(pad "$WRAP" 'This body line') #4242 ticket here." 1
  if grep -q '^#' "$tmp/msg"; then
    note_fail "a fold put '#4242' at the start of a line, which git strips as a comment"
  fi
}
row_no_comment_start
# ...and the comment string is the configured one, not a literal '#'.
row_no_comment_start_custom() {
  printf '[core]\n\tcommentChar = ";"\n' > "$tmp/gitconfig-semi"
  GIT_CONFIG_GLOBAL="$tmp/gitconfig-semi" fold_msg "a break before a ;-word under commentChar ';'" "Add the hook

$(pad "$WRAP" 'This body line') ;4242 ticket here." 1
  if grep -q '^;' "$tmp/msg"; then
    note_fail "a fold put ';4242' at the start of a line under commentChar ';', which git strips as a comment"
  fi
}
row_no_comment_start_custom

# A break lands only at a lone space: a run of spaces and a tab survive the
# fold byte for byte, and rejoining the folded lines with one space gives the
# line back. The pad fills the line to the cap, so the run sits at the break.
row_fold_keeps_runs() {
  local long
  long="$(pad "$WRAP" 'This body line')  next and a"$'\t'"tab run on past the seventy two column cap here."
  fold_msg "a line with a run of spaces and a tab" "Add the hook

$long" 1
  if [ "$(tail -n +3 "$tmp/msg" | paste -sd ' ' -)" != "$long" ]; then
    note_fail "the fold changed a run of spaces or a tab, not only a lone space to a newline"
  fi
  if grep -q '^ ' "$tmp/msg"; then
    note_fail "the fold broke inside a run of spaces, leaving a line that opens with a space"
  fi
}
row_fold_keeps_runs
# A line whose only spaces sit in runs has no break point: not folded, not
# rewritten, and rejected by the wrap rule under that reason, never as a list
# item, quote, table row or fenced line it is not.
row_no_lone_space() {
  reject_unfolded "line with no lone space to break at" "Add the hook

$(printf 'abcdefgh  %.0s' 1 2 3 4 5 6 7 8 9 10)end"
  printf '%s\n' "$out" | grep -qF "is prose with no lone space to break at" ||
    note_fail "a prose line with no lone space was rejected without naming that cause"
  if printf '%s\n' "$out" | grep -qF "is not prose the hook folds"; then
    note_fail "a prose line with no lone space was rejected as a shape the fold never touches"
  fi
}
row_no_lone_space
# ...and a shape the fold never touches keeps its own reason.
row_list_item_reason() {
  reject_unfolded "over-long list item" "Add the hook

- $(pad 80 'a list item')"
  printf '%s\n' "$out" | grep -qF "is not prose the hook folds" ||
    note_fail "an over-long list item was rejected without naming it as a shape the fold never touches"
}
row_list_item_reason

# The folded text reaches the message through a temp file beside it and a
# rename: a write that cannot complete leaves the message whole and is
# rejected, and a fold that succeeds leaves no temp file behind.
row_fold_leaves_no_temp() {
  fold_msg "a fold's temp file" "Add the hook

$(pad 80 'A long body line')" 1
  if compgen -G "$tmp/msg.fold.*" >/dev/null; then
    note_fail "a fold left its temp file beside the message"
    rm -f "$tmp"/msg.fold.*
  fi
}
row_fold_leaves_no_temp
skipped=0
row_unwritable_dir() {
  local ro="$tmp/ro" m
  m="Add the hook

$(pad 80 'A long body line')"
  mkdir -p "$ro"; printf '%s' "$m" > "$ro/msg"; chmod 555 "$ro"
  if [ -w "$ro" ]; then
    chmod 755 "$ro"
    echo "SELFTEST SKIP: a read-only directory is writable here (root, or a filesystem ignoring modes) — the failed-write row did not run"
    skipped=1; return
  fi
  out="$(cd "$work" && bash "$hook" "$ro/msg" 2>&1)"; rc=$?
  chmod 755 "$ro"
  [ "$rc" -ne 0 ] || note_fail "a fold that could not be written was allowed — the long line must still be rejected"
  printf '%s\n' "$out" | grep -qF "could not write the folded message back" ||
    note_fail "a fold that could not be written was not named"
  [ "$(cat "$ro/msg")" = "$m" ] || note_fail "a fold that could not be written changed the message file"
  rm -rf "$ro"
}
row_unwritable_dir

# --- the exemptions ---------------------------------------------------------

# A trailer is what git says is a trailer, and the trailer paragraph is never
# re-broken: the long session URL has a space before the cap, so only the
# trailer test keeps it whole.
allow_unfolded "trailers exempt from wrap and fold" "Add the commit-msg hook

A short body.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QPc1XNoRhSh4kmSpxAfjaFxxxxxxxxxxxxxxxx"
# ...and with prose above it that does fold, the trailer block still survives
# byte for byte.
fold_msg "prose folds above an intact trailer block" "Add the commit-msg hook

$(pad 100 'A long body paragraph')

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QPc1XNoRhSh4kmSpxAfjaFxxxxxxxxxxxxxxxx" 1
grep -qxF "Claude-Session: https://claude.ai/code/session_01QPc1XNoRhSh4kmSpxAfjaFxxxxxxxxxxxxxxxx" "$tmp/msg" ||
  note_fail "the fold re-broke the Claude-Session trailer"
# An ordinary paragraph that happens to open "Note: " is prose and folds like
# prose: a "Word: " pattern standing in for git's parse would exempt it.
fold_msg "a prose line opening Key:" "Add the hook

Some prose above it.
$(pad $((WRAP + 1)) 'Note: this line')" 1

allow_unfolded "unbreakable long token" "Add the commit-msg hook

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
allow_unfolded "comments stripped" "Add the commit-msg hook

# Please enter the commit message for your changes. Lines starting with '#' will be ignored.
# An empty message aborts the commit, and this line is also well past seventy-two columns."

# ...but a markdown heading must survive the strip, or the heading rule is dead.
reject_msg "heading survives the comment strip" "Add the hook

## Summary

Text."                                                                "markdown heading"

# The comment string is read under BOTH its names. Git 2.45 made
# core.commentString an alias of core.commentChar, and `git config --get
# core.commentChar` cannot see a value set under the other name — so a repo
# that sets commentString had its comment lines stripped by the wrong
# character: the `//` lines git drops tripped the wrap rule, and the `#` lines
# git keeps were dropped here. $work is not a repository, so the config the
# hook reads is the global file, pointed at a throwaway one for these rows
# (GIT_CONFIG_GLOBAL, git >= 2.32); GIT_CONFIG_SYSTEM is /dev/null for the
# whole run. Each row is over the cap on purpose: a comment line that is NOT
# stripped trips the wrap rule. So the alone rows red a hook that reads one
# name only — in either direction, since each pairs the stripped line with the
# other character's line, which must survive — and the both-names rows red a
# hook that takes the FIRST value rather than the last.
#
# Every `#` and `;` value below is QUOTED. An unquoted `#` or `;` opens a
# comment in git's config syntax, so `commentChar = #` sets an empty value git
# itself then refuses (`git stripspace -s` → "core.commentchar must have at
# least one character"); a row written that way grades a state no commit can
# reach and passes any hook that defaults an empty read back to '#'.
cfg="$tmp/gitconfig"

# commentString alone.
printf '[core]\n\tcommentString = //\n' > "$cfg"
GIT_CONFIG_GLOBAL="$cfg" allow_unfolded "commentString alone, '//' is the comment" "Add the commit-msg hook

// Under commentString this line is a git comment, and it runs well past the seventy-two column cap."
GIT_CONFIG_GLOBAL="$cfg" reject_msg "commentString alone, '#' is not the comment" "Add the commit-msg hook

# Under commentString this line is NOT a comment, git keeps it, and it runs well past the cap." \
  "exceeds $WRAP columns"

# commentChar alone, with a value that is not the default. Left to the unset
# default ('' → '#'), a hook that read commentString ONLY would still be green
# on every commentChar claim, so the row has to set the name to something else.
printf '[core]\n\tcommentChar = ";"\n' > "$cfg"
GIT_CONFIG_GLOBAL="$cfg" allow_unfolded "commentChar alone, ';' is the comment" "Add the commit-msg hook

; Under commentChar this line is a git comment, and it runs well past the seventy-two column cap."
GIT_CONFIG_GLOBAL="$cfg" reject_msg "commentChar alone, '#' is not the comment" "Add the commit-msg hook

# Under a commentChar of ';' this line is NOT a comment, git keeps it, and it runs past the cap." \
  "exceeds $WRAP columns"

# Both names set: the one git read LAST wins (measured with git stripspace -s
# under a quoted config, 2026-09-01, git 2.50.1). The hook must agree with git,
# in both orders. Each row hands the hook the LATER name's line: a hook that
# took the first value, or one name always, leaves that line unstripped and
# reds one of the two.
printf '[core]\n\tcommentChar = "#"\n\tcommentString = //\n' > "$cfg"
GIT_CONFIG_GLOBAL="$cfg" allow_unfolded "commentChar then commentString, git takes the later '//'" "Add the commit-msg hook

// With commentString read after commentChar, this is the comment, and it runs well past the cap."
printf '[core]\n\tcommentString = //\n\tcommentChar = "#"\n' > "$cfg"
GIT_CONFIG_GLOBAL="$cfg" allow_unfolded "commentString then commentChar, git takes the later '#'" "Add the commit-msg hook

# With commentChar read after commentString, this is the comment, and it runs well past the cap."

# ...and the order git actually reads in is system, global, local: the local
# file is last, so it wins over a global carrying the other name. Every real
# commit takes that path; $work, not being a repository, cannot exercise it.
cfgrepo="$tmp/cfgrepo"
git init -q "$cfgrepo" 2>/dev/null
git -C "$cfgrepo" config core.commentString '//'
printf '[core]\n\tcommentChar = ";"\n' > "$cfg"
GIT_CONFIG_GLOBAL="$cfg" allow_unfolded "local commentString beats a global commentChar" "Add the commit-msg hook

// The local commentString is read after the global commentChar, so this is the comment, past the cap." \
  "$cfgrepo"

# The verbose diff a `git commit -v` message carries is below the scissors and
# is not the message either.
allow_unfolded "git commit -v diff ignored" "Add the commit-msg hook

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

# --- mutation table -----------------------------------------------------------
# Each mutant edits a copy of the hook in one place and reruns the row that
# grades that place; the row must be green on the hook and go red on the
# mutant, or it grades nothing. Narrowing (an alternative dropped) and
# widening (a guard loosened) both appear.
# mutant <label> <find> <replace> <row command...>
mutant() {
  local label="$1"
  selftest_mutate "$hook" "$tmp/mutant-commit-msg" "$2" "$3" || return
  shift 3
  selftest_expect_killed --mutant hook "$tmp/mutant-commit-msg" "$label" "$@"
}
mutant "skip runs without squash!" 'fixup!*|squash!*|amend!*' 'fixup!*|amend!*' \
  allow_unfolded "squash! subject over a long body line" "squash! Add the hook

$(pad 90 'A long body line')"
mutant "fence rule drops ~~~" "grep -qE '^[[:space:]]*(\`\`\`|~~~)'" "grep -qE '^[[:space:]]*\`\`\`'" \
  reject_msg "tilde code fence" "Add the hook

~~~
git commit
~~~" "code fence"
mutant "fence drops ~~~" '(```|~~~)' '(```)' \
  reject_unfolded "line inside a ~~~ fence" "Add the hook

~~~
$(pad 80 'a fenced line')
~~~"
mutant "fence closes on any marker" 'elif [ "$in_fence" = "${BASH_REMATCH[1]}" ]; then' 'elif :; then' row_nested_fence
mutant "quote drops >" "re_quote='^[>|]'" "re_quote='^[|]'" \
  reject_unfolded "> quote line" "Add the hook

> $(pad 80 'a quoted line')"
mutant "quote drops |" "re_quote='^[>|]'" "re_quote='^[>]'" \
  reject_unfolded "| table row" "Add the hook

| $(pad 80 'a table cell') |"
mutant "run-of-spaces glue off" '[ -z "$w" ] || [ -z "${fields[$((j - 1))]}" ] || ' '' row_fold_keeps_runs
mutant "a line with no break point still counted" 'if [ "${#pieces[@]}" -eq 1 ]; then' 'if false; then' row_no_lone_space
mutant "an unbreakable line not recorded" '    unbreakable="$unbreakable$nl$l$nl"' '    :' row_no_lone_space
mutant "every over-cap line read as unbreakable" '    case "$unbreakable" in' '    case "$nl$line$nl" in' row_list_item_reason
mutant "comment-word glue off" '[[ "$w" == "$comment_char"* ]]' 'false' row_no_comment_start
mutant "glue reads a literal #" '[[ "$w" == "$comment_char"* ]]' '[[ "$w" == "#"* ]]' row_no_comment_start_custom
mutant "write in place, no temp file" \
  "if fold_tmp=\"\$(mktemp \"\$msg_file.fold.XXXXXX\" 2>/dev/null)\" && [ -f \"\$fold_tmp\" ] &&
     printf '%s\\n' \"\${out[@]}\" > \"\$fold_tmp\" && mv -f \"\$fold_tmp\" \"\$msg_file\"; then" \
  "if printf '%s\\n' \"\${out[@]}\" > \"\$msg_file\"; then" \
  row_unwritable_dir
mutant "temp file copied, not moved" 'mv -f "$fold_tmp" "$msg_file"' 'cp "$fold_tmp" "$msg_file"' row_fold_leaves_no_temp

if [ "$fail" -ne 0 ]; then
  echo "SELFTEST FAIL: commit-msg self-test failed."
  exit 1
fi
if [ "$skipped" -ne 0 ]; then
  echo "SELFTEST PARTIAL: commit-msg self-test clean except the SKIP line above."
  exit 2
fi
echo "OK: commit-msg self-test clean — every bad message rejected, every exempt shape allowed."
