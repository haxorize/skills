# Fragment mine of gsd-core, BMAD-METHOD, speckit-agent-skills, and agent-stuff

The 2026-08-09 round mined four newly cloned repos for portable fragments: open-gsd/gsd-core (`next` at dc9b299b), bmad-code-org/BMAD-METHOD (ae7aface), dceoy/speckit-agent-skills (c04cbb7), and mitsuhiko/agent-stuff (d265b8e). Three of the four sit in standing wholesale-reject classes — gsd-core is an SDD orchestration product, BMAD a persona framework, speckit the Spec Kit pipeline — and gsd-core's catalog listing was rejected unread in the 2026-07-19 discovery-index closure. We mined them anyway under the standing rule that reject classes ban wholesale ports, not idea mining, and the first real read of gsd-core reversed the unread call at the fragment level: its separately-authored test-and-verification research notes supplied the round's densest cluster. All adoptions land as fragments folded into existing skills; none of the four repos becomes a lineage upstream under ADR-0034, so future sweeps read their mains only.

## What was adopted, by cluster

- **Test quality** (`tdd`, `audit-tests`, `diagnosing-bugs`; all gsd-core): the temporal-quantifier tell routing trajectory-shaped acceptance criteria to closed-loop tests; the clean-control side of fail-first proof (a red must be content-caused); fixture provenance and assert-the-buggy-value characterization; the coincidental-reliance taxonomy; the fix-acceptance gate with revert-and-reconfirm; gates-that-measure-nothing exemplars with the anti-vacuity rule; oracle-strength and boundary-neighbor trims. gsd-core's self-measured statistics were stripped on adoption — the mechanisms are argued on their own logic, not on unpublished internal experiments.
- **Review** (`review-changes`, `receiving-review`): a verification-gap lens (the one roster addition); the fail-fast error-handling and error-identity smell families; the verdict-fenced human-callouts sweep; blast-radius proof and codebase-consistent-rigor vetting; implicit branches; the "unrequested" finding class; reviewer-side softening catalogs with the anti-capitulation rule; upstream-routed triage with the moot cascade; per-finding dual dispositions.
- **Interview** (`grilling` and kin): a merged pre-closure category sweep with specify / dismiss-with-reason / defer-visibly resolution — chosen over adopting either source taxonomy verbatim; question-writing guards; the must-NOT probe; the ban on "let Claude decide" options.
- **Work items** (`work-item-shape`, publishers): checklist-items-as-unit-tests-for-English; the clarification priority ladder with an industry-default release valve; the readiness question; the theater taxonomy; Ask-First decision-shaped HITL triggers; the empty-`## Covers` gate.
- **Verification epistemics and authoring** (`black-box-check`, `handoff`, `implement`, authoring skills): the completion audit; UNCHECKABLE-never-reads-clean; blocked-claim three-strikes; observed-evidence gates for instruction-file pitfalls; the size-cap Goodhart guard; the ADR ratification bar; a changelog register row.

## Rejections that generalize

- **Walkthrough-as-a-skill** (BMAD checkpoint-preview): trimmed to a `ship` PR-body fragment; a guided-walkthrough skill has no demonstrated demand.
- **Structure models** (BMAD): shape-level document review with no consumer moment — the register-by-artifact table already dispatches at the level our writing passes act on.
- **Convergence-move catalogs** (BMAD): `grilling` converges decisions, not idea piles; no consumer.
- **Assumptions-mode interviewing** (gsd-core): the decision map plus explicit-assumption defaults already cover the can't-evaluate user.
- **Crossing/summary format contracts and per-repo review-guidelines files** (mitsuhiko): existing pointer discipline and CLAUDE.md are our mechanisms.

## Consequences

The pre-mortem named dilution as this round's failure mode — 38 fragments is the largest single-round widening this repo has taken. The build therefore folds each fragment into existing rules rather than appending sections, and treats lint's size caps as a hard stop: a fragment that cannot land without pushing its host past the cap comes back as a named cut, not a squeeze (the newly adopted size-cap Goodhart guard makes raising a cap on approach itself a violation).
