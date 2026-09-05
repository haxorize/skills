# Register by artifact — the fat rows

The register table in the skill body routes every artifact; this file holds the rows whose rules outgrow a table cell, except the Meeting-notes row's transcript reading, which is [recap-from-transcript.md](recap-from-transcript.md). Open the section for the artifact at hand and no other.

## README, and a guide (a how-to, a tutorial)

Read this section only when the artifact is a README, how-to, or tutorial.

Same register as a ticket body, plus a first screen that answers four questions before anything else — what this is, who it is for, what state it is in, and the shortest path to running it. Every command is preceded by the question it answers, and a path the writer has not actually run is marked unverified rather than shown as working. A guide follows the same rules, plus three: the output a step produces (the rendered result, the terminal line, the file tree) is shown before the code that produces it; a prerequisite sits beside the step that needs it, never in a wall at the top; and callouts are rationed to two or three a page, because past that readers skip them as a block.

## Error messages and UX microcopy

Read this section only when writing or approving an error message or UX microcopy.

Before writing or approving one, answer five questions: what happened; why, at the most honest level of detail the product knows; what was *not* affected, if anything needs reassurance; what the user can do now; what they can do if that fails. Unanswerable questions are a product gap, not a copy problem — route them out. Shape: outcome first, then cause, reassurance, next step, escape route. No blame, no "Oops", no exclamation marks — and remember specific ≠ clear: a message can name scopes and tokens and still leave the reader with no move.

## Changelog entry, release note

Read this section only when writing a changelog entry or a release note.

Notable-to-users only: what a user of the product observes changed — never typo fixes or internal refactors ("Refactored internal code structure" is an entry about nothing). Order breaking changes → features → fixes; cite the PR (`#1234`), or the commit only where no PR exists; append to the unreleased section rather than rewriting released ones; match the file's declared format where one exists. The range is a command, not a memory: the baseline is `git describe --tags --abbrev=0` (lightweight tags count; in a monorepo with per-package tag prefixes, add `--match '<prefix>*'`), or `git rev-list --max-parents=0 HEAD` when the repo has no tag; the candidates are `git log <baseline>..HEAD --no-merges`, and every entry cites its PR, or its commit where no PR exists, inside that range — a change remembered from the session but absent from the log is not in the release.
