---
name: which-skill
description: Fixture stand-in for the router — carries no triggers, so it stays clean under the invocation-axis check.
disable-model-invocation: true
---

# Which skill (fixture)

The router-coverage check reads this file for a backticked mention of every skill in the
fixture tree. Keep one line per fixture skill.

- `broken-links` — the deliberately-bad skill the self-test asserts against.
- `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline` — the two-way requires fixtures and the dep they share.
- `call-forms` — the call shapes a one-name imperative regex misses, plus a user-invoked target.
- `slash-on-model-invoked` — the retired slash form, which the slash-on-model-invoked check must flag.
