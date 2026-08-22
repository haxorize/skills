# First Off-path skill admitted: `change-quiz`, user-invoked

Status: accepted (2026-08-22)

The suite admits its first **Off-path skill**, working name `change-quiz`: after a session the engineer did not watch, a report of the change grouped by intent, a section on the code paths the diff does not show, and a quiz of 5 to 8 questions on interaction effects that the engineer passes before merging. Two failed rounds are a verdict on the change, not the reader: split it or simplify it. The pass or fail lands as one line in the completion audit or the handoff, so the skill's window measures passes, not fires. The admissions read on 2026-08-22 found nothing in `review-changes`, `implement`, `ship`, `committing`, or `wait-what` that makes the human prove they understand a diff; the suite audits the agent's claims and never the reader's model.

The alternative was one closing clause in `review-changes`. A rational team would choose that; it lost because a quiz blocks on the human's answers, and `review-changes` is a read-only findings report whose character the clause would change. The skill is user-invoked because its trigger, "I was not here for this", is known only to the human, and because no skill in the flow can depend on it; `ship` may name it in its pre-merge list without requiring it. Nick decided; the counter-case recorded is that no transcript shows a merge the engineer did not understand, so the admission rests on the lens and not on observed friction.

Admitting the skill admits the class, and that is the part reversal cannot undo in one commit: retiring `change-quiz` removes a body, a router row, and a README row, but the glossary term and the admission story a second Off-path candidate argues from stay. An Off-path skill serves the person's judgment, learning, or communication off the build path; it is admitted only with a named typist, it carries the retire-on-zero window that `black-box-check` established, and the register table in `writing-for-humans` gains no row without a named typist either. Those guards exist because the same session admitted two register rows (meeting notes, weekly status) and the next round could add meeting preparation and status dashboards until the suite is a productivity pack; the guard is the window, not a cap.

## Deferred

- The final name: B4b's rename table judges `change-quiz` with every other name.
- Whether `ship` names it: decided when B4c lands the folds.

## Consequences

- `DOMAIN.md` gains the term **Off-path skill** beside Domain skill; the router and README each gain one row marked Off-path.
- The window is the evidence. A second Off-path admission argues from this skill's fire and pass counts, never from the lens alone.
