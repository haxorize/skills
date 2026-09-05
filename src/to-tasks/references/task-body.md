# Task body skeleton

The tracker-neutral body sections, shared verbatim by the GitHub and ADO templates. Each tracker template says how its own blocker and parent conventions slot in around these.

```markdown
## Slice

One sentence describing what this thin vertical slice delivers end-to-end. Use canonical terms from `DOMAIN.md`.

## Layers touched

Which integration layers the slice crosses. Describe the behavioral change at each layer in one phrase; mark absent layers `none`. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed work expected (or `none`)
- **Backend:** endpoints/handlers/services (or `none`)
- **Client:** generated client / hooks / state (or `none`)
- **UI:** components / routes / forms (or `none`)
- **Tests:** interface / integration coverage expected (or `none`)

## Covers

Parent Story AC IDs this Task verifies. Comma-separated, no quotes. Used by `to-tasks --reconcile` to detect stale references mechanically when parent ACs change.

Covers: AC1, AC3

## Mode

**HITL** or **AFK**. One word, then a short reason. The call follows the `work-item-shape` readiness gate: AFK only when all five predicates hold; a HITL reason names what remains for the human.

An AFK Task adds one more line — its stop condition: the result, obstacle, or spent effort that means stop unattended work and ask.
```
