# Register by artifact — the fat rows

The register table in the skill body routes every artifact; this file holds the rows whose rules outgrow a table cell, except the Meeting-notes row's transcript reading, which is [recap-from-transcript.md](recap-from-transcript.md). Open the section for the artifact at hand and no other.

## Session summary, incident report

Read this section only when writing a session summary or an incident report.

Outcome first; simple past with times ("Between 14:02 and 14:31 UTC, 12% of requests failed"); state the unknown as "unknown" — a hedge reads less honest, not more careful. The first line and the last line, read alone, must give what happened and what to do next.

## On-call shift note

Read this section only when writing the outgoing on-call's shift note.

Five sections, each present or an explicit "none": active incidents, ongoing investigations, recent changes, known issues with their workarounds, upcoming events. A section left blank is an incomplete note, and an incomplete note is a postmortem action item.

## Commit message, PR body, review reply, closing comment

Read this section only when writing one of these.

A maintainer recording a decision for another maintainer: impersonal, matter-of-fact ("Previously, …", "This caused …"); imperative only in the subject line; first person only for an actual decision or open question. The catalog's commit-and-PR family ([tell-catalog-shipping.md](tell-catalog-shipping.md)) fires here.

## Meeting notes

Read this section only when posting a meeting recap.

Decided separated from discussed; an action is an owner plus a date or is flagged unassigned or undated — the writer never fills either in; commitments and load-bearing statements verbatim, with a paraphrase marked as the writer's reading. A recap drawn from a transcript or recording reads it under [recap-from-transcript.md](recap-from-transcript.md) — the thread-state scale, the quote rule, and the refusal — open it before reading one.

## README, and a guide (a how-to, a tutorial)

Read this section only when the artifact is a README, how-to, or tutorial.

Same register as a ticket body, plus a first screen that answers four questions before anything else — what this is, who it is for, what state it is in, and the shortest path to running it. Every command is preceded by the question it answers, and a path the writer has not actually run is marked unverified rather than shown as working. A guide follows the same rules, plus three: the output a step produces (the rendered result, the terminal line, the file tree) is shown before the code that produces it; a prerequisite sits beside the step that needs it, never in a wall at the top; and callouts are rationed to two or three a page, because past that readers skip them as a block.

## Error messages and UX microcopy

Read this section only when writing or approving an error message or UX microcopy.

Before writing or approving one, answer five questions: what happened; why, at the most honest level of detail the product knows; what was *not* affected, if anything needs reassurance; what the user can do now; what they can do if that fails. Unanswerable questions are a product gap, not a copy problem — route them out. Shape: outcome first, then cause, reassurance, next step, escape route. No blame, no "Oops", no exclamation marks — and remember specific ≠ clear: a message can name scopes and tokens and still leave the reader with no move.

## Changelog entry, release note

Read this section only when writing a changelog entry or a release note.

Notable-to-users only: what a user of the product observes changed — never typo fixes or internal refactors ("Refactored internal code structure" is an entry about nothing). Order breaking changes → features → fixes; cite the PR (`#1234`), or the commit only where no PR exists; append to the unreleased section rather than rewriting released ones; match the file's declared format where one exists. The range is a command, not a memory: the baseline is `git describe --tags --abbrev=0` (lightweight tags count; in a monorepo with per-package tag prefixes, add `--match '<prefix>*'`), or `git rev-list --max-parents=0 HEAD` when the repo has no tag; the candidates are `git log <baseline>..HEAD --no-merges`, and every entry cites its PR, or its commit where no PR exists, inside that range — a change remembered from the session but absent from the log is not in the release.

## Weekly status note

Read this section only when writing the weekly status note to a manager.

One status line first — green, yellow, or red, with one sentence on where things stand — and the color matches reality: a note that is only ever green stops being read. Then four sections, each present: **wins** (what shipped, with its effect — never "made progress"), **next** (each step dated or marked undated), **risks** (each with its severity and the mitigation), **asks** (each with an owner and a by-when; "let me know if you have questions" is not an ask). The status and any ask land in the first three lines.

## Runbook, release or migration procedure

Read this section only when writing a procedure someone will execute, usually under time pressure.

Written from a real run: a step nobody has taken, or a branch nobody has exercised, is marked draft and names who reports back after its first run — a procedure imagined at the desk is a draft, never a runbook. The skeleton: what the document covers and what it does not; the happy path first, then the same steps numbered, one action each, every command paste-ready with concrete example values; where steps differ in risk, a legend up front applied to every command — safe to run anytime, writes to production, manual step outside the terminal; where order matters, the consequence of getting it wrong stated on the step; every state-changing step names its rollback or says plainly that none exists; a closing "verify it worked" with the observable end state and the command that shows it. A troubleshooting entry is symptom-first — the error text verbatim so it can be searched, then cause, then the exact fix — with the cheapest diagnostic first. A migration or deprecation guide adds a mapping table of old to new, one row per behavior or key, a date for what stops working (never "a future release"), and its own completion condition, after which it is marked superseded rather than deleted.
