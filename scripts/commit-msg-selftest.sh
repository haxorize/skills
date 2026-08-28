#!/usr/bin/env bash
# Prove scripts/git-hooks/commit-msg still catches what it claims to catch.
#
# A commit-msg hook degrades silently the same way a linter does: the commit
# goes through whether the rule holds or the check quietly stopped matching.
# This script feeds the hook messages that are wrong on purpose and messages
# that are right on purpose, and grades it in both directions — every rule must
# reject its violation, and every exempt shape must be allowed. A one-directional
# check would pass just as happily against a hook that rejected everything.
#
# Run it after changing the hook.
#
# Covered here: the subject rules (72-char cap, trailing period, Conventional
# Commits prefix and the config opt-out, the imperative-opener warning), the
# body rules (blank separator, code fence, Summary/Changes/Testing heading,
# 72-column wrap), and the exemptions (merge, revert, fixup!, trailers, an
# unbreakable long token, an empty message). NOT covered, so a clean run here
# is not a claim about them: everything the hook's own header says it cannot
# check — one-logical-change, whether the body was needed, register, and the
# tell catalog. Those need a reader, and no fixture can stand in for one.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

hook="$repo_root/scripts/git-hooks/commit-msg"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

# run <message> -> sets $rc and $out
run() {
  printf '%s' "$1" > "$tmp/msg"
  out="$(bash "$hook" "$tmp/msg" 2>&1)"
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

allow_msg() { # allow_msg <label> <message>
  run "$2"
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

L73="Add a subject line that is deliberately far too long to fit inside the cap"

# --- must reject ---
reject_msg "subject over 72"      "$L73"                              "over the 72 hard cap"
reject_msg "trailing period"      "Add the commit-msg hook."          "ends with a period"
reject_msg "conventional prefix"  "feat: add the commit-msg hook"     "Conventional Commits type prefix"
reject_msg "scoped cc prefix"     "fix(hooks): stop the bypass"       "Conventional Commits type prefix"
reject_msg "no blank separator"   "Add the hook
The body starts immediately with no blank line above it."             "no blank line between subject and body"
reject_msg "code fence"           "Add the hook

Previously nothing checked the message:

\`\`\`
git commit -m 'whatever'
\`\`\`"                                                                "code fence"
reject_msg "Summary heading"      "Add the hook

## Summary

It checks the message."                                               "Summary/Changes/Testing heading"
reject_msg "Testing heading"      "Add the hook

## Testing

Ran the selftest."                                                    "Summary/Changes/Testing heading"
reject_msg "body over 72 columns" "Add the hook

This body line is deliberately written well past the seventy-two column limit that the style doc sets."  "exceeds 72 columns"

# --- must warn, not block ---
warn_msg "imperative opener" "Added the commit-msg hook"              "an imperative verb leads"

# --- must allow ---
allow_msg "clean subject only" "Add the commit-msg hook"
allow_msg "clean subject and body" "Add the commit-msg hook

Nothing checked commit message shape, so a style miss surfaced only in
review. The hook rejects at the moment of the mistake and names the
reference, so the block is also the load instruction."
allow_msg "trailers exempt from wrap" "Add the commit-msg hook

A short body.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QPc1XNoRhSh4kmSpxAfjaFxxxxxxxxxxxxxxxx"
allow_msg "unbreakable long token" "Add the commit-msg hook

See
https://example.com/a/very/long/url/that/cannot/be/wrapped/at/seventy/two/columns/at/all"
allow_msg "merge commit"  "Merge branch 'main' into feature-branch-with-a-very-long-name-past-72-chars"
allow_msg "revert commit" "Revert \"Add the commit-msg hook and a subject long enough to trip the cap\""
allow_msg "fixup commit"  "fixup! Add the commit-msg hook."
# The comment lines here are over 72 columns on purpose: if the hook stops
# stripping git's own comments, they trip the wrap rule and this row fails.
allow_msg "comments stripped" "Add the commit-msg hook

# Please enter the commit message for your changes. Lines starting with '#' will be ignored.
# An empty message aborts the commit, and this line is also well past seventy-two columns."
allow_msg "empty message" ""
allow_msg "72 exactly" "Add a subject line that is exactly seventy-two characters long ok yes"

# --- the Conventional Commits opt-out ---
touch "$repo_root/.commitlintrc"
run "feat: add the commit-msg hook"
rm -f "$repo_root/.commitlintrc"
if [ "$rc" -ne 0 ]; then
  echo "SELFTEST FAIL: the Conventional Commits opt-out did not apply — a repo declaring commitlint must allow the prefix"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "SELFTEST FAIL: commit-msg self-test failed."
  exit 1
fi
echo "OK: commit-msg self-test clean — every bad message rejected, every exempt shape allowed."
