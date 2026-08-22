# Behavior contract template

Use this shape when the user hasn't provided a contract. Keep it short enough that a source-blind checker can execute it without any implementation knowledge — every clause states something observable. The final section is not for the checker: it is handed to the user or a non-checking session when a contract must be derived from legacy code.

```md
# Behavior contract

## User-visible goal
<What must be true from the user's point of view.>

## Target
- Type: web app | CLI | API | generated artifact | other
- Launch or access: <URL, command, endpoint, artifact path, or setup step>
- Fixtures and credential source: <fixtures, plus secret-tool or environment-variable names — never values>

## User tasks
1. <Concrete task a real user or operator performs.>
2. <Concrete task a real user or operator performs.>

## Expected observable behavior
- <Screen, CLI output, API response, file content, state change, or persistence rule.>
- <Failure behavior for invalid input or unavailable data.>

## Anti-cheat probes
- <Change fixture/input data and verify the output changes accordingly.>
- <Refresh/retry/reopen and verify the promised persistence or reset.>
- <Try invalid/empty/boundary input and verify the promised handling.>

## Evidence required
- <Screenshots, terminal excerpts, response snippets, file summaries, accessibility observations, or logs.>

## Out of scope
- <Anything the check must not judge.>
```

## Deriving a contract for existing behavior (not the checker's job)

When the target is legacy or already-shipped behavior with no request text to write from, the user or a session that will not run the check derives the contract from the code. The move is a mechanical translation from code pattern to behavior statement:

- `if (user.role === 'admin')` → "the action is restricted to administrator users"
- `password.length >= 8` → "passwords must be at least 8 characters"

Mark genuinely ambiguous code `[NEEDS CLARIFICATION]` rather than guessing intent, and have someone who knows the feature validate the derived contract before it is used — derived clauses describe what the code does, and only a human can confirm that is also what it should do.
