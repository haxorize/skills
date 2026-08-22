# Lint fixture tree

A miniature repo root that `scripts/lint-selftest.sh` points `scripts/lint-skills.sh` at
via `LINT_ROOT`. Nothing here is a real skill — every file exists to make a check fire, or
to prove a check stays quiet on a form it is supposed to exempt.

This file doubles as the fixture's README-coverage target, so the roster check has
something to read: `which-skill`, `broken-links`, `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline`.

`global/rules/` holds eight rule fixtures for the `Depends:` admission check: one with no line, one naming a skill that does not exist, one naming a skill (`quoted-dep`) that names it only inside a fenced block, three naming a skill (`unused-dep`) whose body has every non-citation form — the bare `~/.claude/rules/` directory (`dir-only-cited`), some other rule's full path (`other-path-cited`), and this rule's stem as an unmarked word (`bare-stem-cited`) — and two well-formed rules that must stay quiet — `broken-links` cites `well-formed` by backticked stem, `undeclared-dep` cites `path-cited` by path.

`src/undeclared-dep/` invokes `fixture-discipline` by slash form without declaring it; `src/quoted-dep/` mentions it only in a quoted string, an arrow-parenthesised aside, and a fenced block, and must stay quiet on the requires check (it is also the dependant `uncited-depends.md` names, and must fire there — the two messages differ in their suffix, `/SKILL.md` versus `/`); `src/unused-dep/` declares it and never names it.

`security/injected-skill/` is `scripts/security-selftest.sh`'s fixture: a SKILL.md carrying an instruction-override phrase and a concealment phrase, and a script that pipes the network into a shell. Nothing in it runs.

Edit these fixtures only to add coverage. Weakening one to make the self-test pass is the
failure the self-test exists to catch.
