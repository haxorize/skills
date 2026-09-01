---
name: call-forms
description: Fixture writing the Skill-tool call in the shapes a one-name imperative regex misses — a gerund, two names in one clause, and a user-invoked target.
disable-model-invocation: true
---

# Call Forms

Run the mechanical checks by calling the Skill tool with `fixture-discipline` and `broken-links` — a gerund, mid-sentence, naming two skills in one clause.

Neither is declared, so the used-but-undeclared scan must fire on both. A regex that stops
at the first backticked name sees only the first; a regex without `calling` sees neither.
The clause stays on one line because the scan is line-based.

Call the Skill tool with `quoted-dep` as well. That one is user-invoked, so its description
never reaches the model and the call does nothing at runtime — the mirror of the slash
form on a model-invoked skill, and a failure in its own right rather than an exemption.
