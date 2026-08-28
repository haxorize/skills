# Lint fixture tree

A miniature repo root that `scripts/lint-selftest.sh` points `scripts/lint-skills.sh` at
via `LINT_ROOT`. Nothing here is a real skill — every file exists to make a check fire, or
to prove a check stays quiet on a form it is supposed to exempt.

This file doubles as the fixture's README-coverage target, so the roster check has
something to read: `which-skill`, `broken-links`, `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline`, `call-forms`, `slash-on-model-invoked`, `bulk-cited-dep`.

`global/rules/` holds nine rule fixtures for the `Depends:` admission check: one with no line, one naming a skill that does not exist, one naming a skill (`quoted-dep`) that names it only inside a fenced block, three naming a skill (`unused-dep`) whose body has every non-citation form — the bare `~/.claude/rules/` directory (`dir-only-cited`), some other rule's full path (`other-path-cited`), and this rule's stem as an unmarked word (`bare-stem-cited`) — and two well-formed rules that must stay quiet — `broken-links` cites `well-formed` by backticked stem, `undeclared-dep` cites `path-cited` by path — and one that grades the check's plumbing rather than its pattern: `early-cited` names `bulk-cited-dep`, which cites it in its opening lines and then follows that citation with three long `references/` files. Reading that through `grep -q` under `pipefail` killed the producer with SIGPIPE the moment the early match landed and the reader closed the pipe, and the check reported a citation that was there as missing; the small fixtures could not show it, because their producers finished writing before the reader walked away. The tail is sized past a Linux pipe's fixed 64 KiB capacity and `scripts/lint-selftest.sh` asserts that length, so trimming it fails loudly instead of turning the row into a no-op.

`src/undeclared-dep/` invokes `fixture-discipline` by the Skill-tool form without declaring it; `src/quoted-dep/` mentions it only in a quoted string, an arrow-parenthesised aside, and a fenced block, and must stay quiet on the requires check (it is also the dependant `uncited-depends.md` names, and must fire there — the two messages differ in their suffix, `/SKILL.md` versus `/`); `src/unused-dep/` declares it and never names it, and its `references/shell-transport.md` passes HTML to a tracker CLI through `$(cat …)`, which the rich-text transport check must flag.

The two invocation-form fixtures come after that pair. `src/slash-on-model-invoked/` names `fixture-discipline` in the retired slash form, which the slash-on-model-invoked check must flag; `src/call-forms/` writes the Skill-tool call in the three shapes a one-name imperative regex misses — a gerund, two names in one clause, and a user-invoked target the model cannot reach. Both scans read the same masked text, so `quoted-dep` carries each exempt shape in both forms, and carries the two slash forms that are correct unmasked — a user-invoked skill and a built-in — which grade the slash check's own guards.

`security/injected-skill/` is `scripts/security-selftest.sh`'s fixture: a SKILL.md carrying an instruction-override phrase and a concealment phrase, and a script that pipes the network into a shell. Nothing in it runs.

Edit these fixtures only to add coverage. Weakening one to make the self-test pass is the
failure the self-test exists to catch.
