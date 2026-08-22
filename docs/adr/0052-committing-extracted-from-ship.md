# Extract `committing` from `ship`

`ship` held the rules for landing a change honestly: the claims rule, the closing-comment contract, closure verification, and the blocked-action protocol. It is user-invoked, so those rules ran only when someone typed `/ship`, which happened 17 times in the measured window. The ask that actually lands most work, "commit and push", "close #N", "commit what we have", appeared in 104 prompts and reached none of it. The same window holds the failures those rules exist to prevent: a closing comment that claimed user approval no turn had given, a partial slice that auto-closed its ticket, a rename that silently no-op'd and went unreported.

## Decision

The landing discipline moves into a new model-invoked skill, `committing`, and `ship` declares `requires: committing`. The extraction test passes on two real consumers: `ship`, and the plain commit-and-push prompt that arrives with no skill loaded. A model-invoked description is the only mechanism that reaches the second one.

What moves: the claims rule (with the rows the round added: an approval claim cites the turn, a "reviewed" claim cites a review report or handoff path and, when HEAD has moved past the reviewed stamp, says so as "reviewed at `<sha>`, N commits since" rather than claiming reviewed, an image cited as evidence was opened, unobtainable evidence gets its own `UNVERIFIABLE` line), the closing-comment contract, closure verification, the `Closes` versus `Refs` decision read off the completion audit, the blocked-action protocol with its auth pre-flight and single manual-commands block, and the one-commit fast path itself: stage, commit, tick, push, close, in one move, for the change that needs no split. The house commit style moves with them: `commit-style.md` leaves `ship/references/` for `committing/references/`, because both paths now draft commit prose under `committing`, and a reference cannot be shared across skills without a sibling copy. This amends [ADR-0045](0045-ship-commit-style-default-and-closing-contract.md), which placed it in `ship`.

What stays in `ship`: resolving the approver, proposing the commit split, the PR path with reviewers and work-item links, and re-entry after approval lands. `ship` delegates every claim and every outward act to `committing` rather than restating a rule.

## Considered Options

- **Leave the rules in `ship` and rely on the user typing it.** Rejected on the evidence: the ratio of ad-hoc commit prompts to `/ship` runs was six to one and had not moved over two months of the skill existing.
- **Move everything, including the split, and retire `ship`.** Rejected. The split is a proposal a human adjusts before staging, and a PR with reviewers is an orchestration; both are the user-invoked shape. Putting them in a model-invoked skill would let the model open PRs on its own judgment, the exact outward act the round's corrections sit at.
- **Keep the fast path in `ship` and extract only the claims rule.** Rejected because the bypass is the fast path: the prompts that skip `/ship` are the ones that want one commit. A behavior that owns the claims but not the commit would check prose the model never writes.

## Guard

`committing` never owns the split. A rule present in both `ship` and `committing` is a defect, and the round's review lens greps for it. "No unasked commits" is not in either skill; it is a global rule ([ADR-0053](0053-global-rules-layer.md)) that `committing` cites, because the commits made outside `/ship` were made with no skill loaded at all.

## Consequences

`committing` sits in the context window every turn, at the cost of its description. `ship` is the first user-invoked skill whose whole verification burden lives in a dependency; a `ship` run with `committing` missing stops at its load gate rather than running the split and PR ceremony with no claims check, and `install.sh` resolves `requires:` so that gate is rarely hit; lint refuses a `requires:` that names a user-invoked skill. This amends [ADR-0036](0036-ship-is-its-own-skill-not-implements-tail.md) without reversing it. That record rejected a general verify-before-asserting behavior because its trigger would be every turn; `committing` answers the objection rather than overriding it. Its trigger is commit-shaped, an ask to commit, push, or close, not every turn, and the every-turn part of the discipline, evidence stated in the same message as the claim, went to the global evidence rule instead of a skill. `ship` stays its own skill and now shares its discipline with the path that bypassed it.
