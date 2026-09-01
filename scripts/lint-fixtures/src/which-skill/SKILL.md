---
name: which-skill
description: Fixture stand-in for the router — carries no triggers, so it stays clean under the invocation-axis check.
disable-model-invocation: true
---

# Which Skill (Fixture)

The router-coverage check reads this file for a backticked mention of every skill in the
fixture tree. Every skill is named on the bullet list below, and nowhere else in this
file; skills that grade one check together share a bullet.

- `broken-links` — the deliberately-bad skill the self-test asserts against.
- `undeclared-dep`, `unused-dep`, `quoted-dep`, `fixture-discipline` — the two-way requires fixtures and the dep they share. `quoted-dep` grades a second rule as well: it is user-invoked and its description quotes the shared trigger phrase, which the shared-trigger-phrase check must not read. Shortening that description removes that assertion.
- `call-forms` — the call shapes a one-name imperative regex misses, plus a user-invoked target.
- `slash-on-model-invoked` — the retired slash form, which the slash-on-model-invoked check must flag.
- `bulk-cited-dep` — the long-bodied dependant that grades the citation check on a stream the reader abandons mid-write.
- `folded-description`, `literal-description`, `continued-description` — the three description shapes a one-line reader truncates, which the single-line-scalar check must flag.
- `oversize-body` — a body past the re-attach bound, which draws a WARN and no FAIL.
- `shared-trigger-straight`, `shared-trigger-curly`, `shared-trigger-scalar` — three model-invoked descriptions carrying one trigger phrase, in straight quotes, in curly quotes and another case, and inside a whole-value YAML double-quoted scalar; the shared-trigger-phrase check must flag all three in one line, so this trio grades the case fold, the curly branch of the alternation, the unwrapping of a quoted scalar, and the rendering of more than two carriers.
- `shared-trigger-not-for` — a model-invoked description that quotes the same phrase inside a disambiguating "Not for…" tail, which routes a reader away from the sibling and must stay quiet.
- `ledger-legend` — the legend, and a stored-status rule in the same body that disagrees with it on one member, so the two-authority row fires; a file beside it names no ledger word at all and is read anyway, which is where the rule that the legend's own skill is swept wholesale gets exercised.
- `house-style` — one instance of every house-style violation (the descriptive form, a bare suggestion site, an unpredictable artifact name, an unregistered label, a pointer to a heading that is not there, and a title-cased H2) with the quiet neighbor of each beside it.
- `ledger-consumer` — a consumer that drops a status on an anchored line, four reference files each anchored by exactly one of the four alternatives the anchor pattern accepts, and three the check must stay quiet on: one status referenced rather than enumerated, an enumeration inside a fence, and two status words of an unrelated vocabulary with nothing anchoring them.
