# Lint fixture tree

A miniature repo root that `scripts/lint-selftest.sh` points `scripts/lint-skills.sh` at
via `LINT_ROOT`. Nothing here is a real skill — every file exists to make a check fire, or
to prove a check stays quiet on a form it is supposed to exempt.

This file doubles as the fixture's README-coverage target, so the roster check has
something to read: `which-skill`, `broken-links`.

`global/rules/` holds three rule fixtures for the `Depends:` admission check: one with no line, one naming a skill that does not exist, and one well-formed rule that must stay quiet.

Edit these fixtures only to add coverage. Weakening one to make the self-test pass is the
failure the self-test exists to catch.
