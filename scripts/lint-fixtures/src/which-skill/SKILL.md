---
name: which-skill
description: Fixture stand-in for the router — carries no triggers, so it stays clean under the invocation-axis check.
disable-model-invocation: true
---

# Which skill (fixture)

The router-coverage check reads this file for a backticked mention of every skill in the
fixture tree. Keep one line per fixture skill.

- `broken-links` — the deliberately-bad skill the self-test asserts against.
- `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline` — the two-way requires fixtures and the dep they share. `quoted-dep` grades a second rule as well: it is user-invoked and its description quotes the shared trigger phrase, which the shared-trigger-phrase check must not read. Shortening that description removes that assertion.
- `call-forms` — the call shapes a one-name imperative regex misses, plus a user-invoked target.
- `slash-on-model-invoked` — the retired slash form, which the slash-on-model-invoked check must flag.
- `bulk-cited-dep` — the long-bodied dependant that grades the citation check on a stream the reader abandons mid-write.
- `folded-description`, `literal-description`, `continued-description` — the three description shapes a one-line reader truncates, which the single-line-scalar check must flag.
- `oversize-body` — a body past the re-attach bound, which draws a WARN and no FAIL.
- `shared-trigger-straight`, `shared-trigger-curly`, `shared-trigger-scalar` — three model-invoked descriptions carrying one trigger phrase, in straight quotes, in curly quotes and another case, and inside a whole-value YAML double-quoted scalar; the shared-trigger-phrase check must flag all three in one line, so this trio grades the case fold, the curly branch of the alternation, the unwrapping of a quoted scalar, and the rendering of more than two carriers.
- `shared-trigger-not-for` — a model-invoked description that quotes the same phrase inside a disambiguating "Not for…" tail, which routes a reader away from the sibling and must stay quiet.
