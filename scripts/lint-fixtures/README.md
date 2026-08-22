# Lint fixture tree

A miniature repo root that `scripts/lint-selftest.sh` points `scripts/lint-skills.sh` at
via `LINT_ROOT`. Nothing here is a real skill — every file exists to make a check fire, or
to prove a check stays quiet on a form it is supposed to exempt.

This file doubles as the fixture's README-coverage target, so the roster check has
something to read: `which-skill`, `broken-links`, `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline`.

`global/rules/` holds four rule fixtures for the `Depends:` admission check: one with no line, one naming a skill that does not exist, one naming a skill (`quoted-dep`) that never cites it, and one well-formed rule that must stay quiet — `broken-links` cites it by stem.

`src/undeclared-dep/` invokes `fixture-discipline` by slash form without declaring it; `src/quoted-dep/` mentions it only in a quoted string, an arrow-parenthesised aside, and a fenced block, and must stay quiet; `src/unused-dep/` declares it and never names it.

`security/injected-skill/` is `scripts/security-selftest.sh`'s fixture: a SKILL.md carrying an instruction-override phrase and a concealment phrase, and a script that pipes the network into a shell. Nothing in it runs.

Edit these fixtures only to add coverage. Weakening one to make the self-test pass is the
failure the self-test exists to catch.
