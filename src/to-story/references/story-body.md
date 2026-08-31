# Story body skeleton

The tracker-neutral body sections, shared verbatim by the GitHub and ADO templates. Each tracker template says where its own sections (acceptance criteria, parent link) slot in around these.

Lead with the Connextra user-story line for user-facing stories; omit it for non-user-facing stories (see `to-story` SKILL.md step 6 for the classification rule).

```markdown
**User story:** As a [role], I want [goal] so that [benefit].

## Problem

What user-facing pain or behavior gap motivates this story. One paragraph. Use canonical terms from `DOMAIN.md`.

## User-facing behavior

What the user sees / can do once this ships. Concrete, observable. If the change is invisible to users (refactor, infra), describe the developer-facing or operational behavior instead.

## Modules touched

- `<module name>` — what changes here, what the deepening direction is if any
- `<module name>` — what changes here

Use module names from `DOMAIN.md` where applicable, not file paths.

## Layers touched

Which integration layers the Story crosses. Drives `from-ticket` cold-start and Task slicing. Describe the behavioral change at each layer in one phrase; mark absent layers `none`. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed work expected (or `none`)
- **Backend:** endpoints/handlers/services (or `none`)
- **Client:** generated client / hooks / state (or `none`)
- **UI:** components / routes / forms (or `none`)
- **Tests:** interface / integration coverage expected (or `none`)

## Approach

The approach the team agreed on. State the design direction and key tradeoffs in plain language. Reference existing ADRs the approach respects. No code snippets, no file paths, no specific field or type names.

## Tests

What gets tested at which seam. Use module names from `DOMAIN.md`, not file paths.

- `<module>` — interface tests for X behavior
- `<module>` — integration test covering Y end-to-end

## Out of scope

What this story explicitly does not include (so reviewers don't expand scope).
```
