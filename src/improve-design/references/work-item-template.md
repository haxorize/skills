# Improve Design — Work item template

Use this when creating or updating a work item in step 7.

```markdown
## Problem

- Which modules are shallow and tightly coupled
- What integration risk exists in the seams between them
- Why this makes the codebase harder to navigate and maintain

## Proposed Interface

- Interface signature (types, methods, params)
- Usage example showing how callers use it
- What complexity it hides internally

## Testing Strategy

- New interface tests to write (behaviors to verify at the seam)
- Tests to update or remove (shallow module tests that become redundant, or tests that need renaming/restructuring)

## Implementation Decisions

Durable architectural guidance, NOT coupled to current file paths:

- What the module should own (responsibilities)
- What it should hide (implementation details)
- What it should expose (the interface contract)
- How callers should migrate to the new interface

## Out of Scope

What is explicitly not part of this refactor.
```
