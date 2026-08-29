# First Off-path skill admitted: `change-quiz`, user-invoked

> **Amended by [ADR-0063](0063-team-fit-test-replaces-retire-on-zero-window.md):** Off-path skills no longer carry the retire-on-zero window; the Team-fit test judges them like any other skill. This reverses three sites in the body below rather than only the regime: the first paragraph's "the skill's window measures passes, not fires", the third paragraph's "the guard is the window, not a cap", and the Consequences bullet "The window is the evidence". The guard against the class widening is now the Team-fit test's own bar — a concrete moment in a product engineering team's work and the role who hits it, named in the deciding record, with retirement when an existing skill or global rule already serves that moment. That is a stricter cap than the window was, not a looser one: a count could be satisfied by the author's own typing, where a named moment and role cannot. See the 2026-08-27 amendment below.

Status: accepted (2026-08-22)

The suite admits its first **Off-path skill**, working name `change-quiz`: after a session the engineer did not watch, a report of the change grouped by intent, a section on the code paths the diff does not show, and a quiz of 5 to 8 questions on interaction effects that the engineer passes before merging. Two failed rounds are a verdict on the change, not the reader: split it or simplify it. The pass or fail lands as one line in the completion audit or the handoff, so the skill's window measures passes, not fires. The admissions read on 2026-08-22 found nothing in `review-changes`, `implement`, `ship`, `committing`, or `wait-what` that makes the human prove they understand a diff; the suite audits the agent's claims and never the reader's model.

The alternative was one closing clause in `review-changes`. A rational team would choose that; it lost because a quiz blocks on the human's answers, and `review-changes` is a read-only findings report whose character the clause would change. The skill is user-invoked because its trigger, "I was not here for this", is known only to the human, and because no skill in the flow can depend on it; `ship` may name it in its pre-merge list without requiring it. Nick decided; the counter-case recorded is that no transcript shows a merge the engineer did not understand, so the admission rests on the lens and not on observed friction.

Admitting the skill admits the class, and that is the part reversal cannot undo in one commit: retiring `change-quiz` removes a body, a router row, and a README row, but the glossary term and the admission story a second Off-path candidate argues from stay. An Off-path skill serves the person's judgment, learning, or communication off the build path; it is admitted only with a named typist, it carries the retire-on-zero window that `black-box-check` established, and the register table in `writing-for-humans` gains no row without a named typist either. Those guards exist because the same session admitted two register rows (meeting notes, weekly status) and the next round could add meeting preparation and status dashboards until the suite is a productivity pack; the guard is the window, not a cap.

## Deferred

- The final name: B4b's rename table judges `change-quiz` with every other name. — settled: see Amendments 2026-08-22
- Whether `ship` names it: decided when B4c lands the folds. — settled: see Amendments 2026-08-29

## Consequences

- `DOMAIN.md` gains the term **Off-path skill** beside Domain skill; the router and README each gain one row marked Off-path.
- The window is the evidence. A second Off-path admission argues from this skill's fire and pass counts, never from the lens alone.

## Amendments

- **2026-08-22** — The final name is `merge-quiz`, judged in [ADR-0057](0057-rename-table-and-discipline-skill-term.md)'s table: the quiz is the gating half and "before merging" is the moment this record names. The B4c build creates `src/merge-quiz/`; the name `change-quiz` above is the working name as cited at the time.
- **2026-08-27** — [ADR-0063](0063-team-fit-test-replaces-retire-on-zero-window.md) removes the retire-on-zero window from every **Skill**, this one included, and the three body sites the head banner names are superseded rather than rewritten. A second Off-path admission now argues from the Team-fit test — its own named moment and role — and never from this skill's fire or pass counts, which are evidence for a case and never the verdict. The `merge-quiz` admission itself stands: its moment is an engineer merging a change they did not watch being built, and its role is that engineer.
- **2026-08-29** — `ship` does name it, and in the form the body's second paragraph allowed: `src/ship/SKILL.md:46` reads "for a change the human did not watch being built, suggest `/merge-quiz` before they approve it (user-invoked; suggest, never require)". The mention landed with the skill itself in the B4c build (`4bd098a`), not as a later fold, which is why no amendment recorded it at the time and the Deferred line sat open through seven batches. The slash form is correct here rather than a defect: the target is user-invoked, so the text names what the human types and carries no **Load gate** ([ADR-0066](0066-skill-tool-form-replaces-slash-for-model-fired-invocations.md)). Nothing in `ship`'s own flow depends on the quiz having run.
