# The PR body

Open this only when a PR is being opened, or its body rewritten on re-entry; with no approver there is no PR, and the commit messages and the closing comment carry the change's claims.

The body is written for a reviewer who was not there. Every sentence is a claim under `committing`'s claims rule; a sentence with no evidence beside it carries its marker. Its shape — the commit body plus links, headings only for a change too complex to review without them, the repo's PR template always winning — is `committing`'s `references/commit-style.md` § The PR body; this file says what the body answers.

## Four questions, in this order

1. **What changed** — the behavior, grouped by intent, never a file list the diff already shows.
2. **What was checked, and how** — the behavioral checks that ran, each with its command and result, and a check the reviewer would expect that did not run, named as not run; generic lint, type-check, and CI output stays out, since the checks page shows it.
3. **The risks** — what could break, and the observation that would show it.
4. **What had to be fixed along the way** — the defects met and repaired inside the change, so the approver reads a repair as intended rather than as **Unrequested** work.

## What did not change

Name the unchanged neighbors the change leans on — the caller left as it was, the schema read but not written, the default that still holds (a scores-endpoint change that reads the `brands` table and writes nothing names that read). Blast radius reads off them, and a body naming only the changed nodes says nothing about it.

## The published-interface delta

A change that touches a published interface — anything something outside the change consumes, in `codebase-design`'s sense — gives it a section of its own: before and after, its class per that skill's `references/published-interfaces.md` table (non-breaking or breaking, and for a breaking one the deprecation path), and the consumers it reaches. A change touching no published interface has no such section; an empty "no interface changes" line is a claim nobody checked.

## Before and after

A change to what renders carries a before and an after capture in the body, at the same viewport and crop. The before is the one `implement` § Before building took before the first edit; where none was taken, the body says so rather than carrying one rebuilt afterwards. Each caption names where it was captured, under the captured-never-composed rule (`~/.claude/rules/evidence.md`). How a capture is uploaded is the project's convention skill's.
