# Lens briefs — code-gated lenses

Opened from §2 only when the diff touches code, and then only at the section for each lens triage selected. The trigger line per lens stays in §2; this file carries the brief each selected lens runs under.

## Smell baseline

Run against [smell-baseline.md](smell-baseline.md).

## `/security-review`

Where the repo records a trust model — a threat-model doc, a security section in `CLAUDE.md`, trust boundaries named in a decision record — brief the lens with it, so untrusted input is judged against the boundaries this project actually claims rather than a generic set. Where nothing records one, run the lens generically; inventing boundaries produces findings against a system nobody built.

## Design depth

Call the Skill tool with `codebase-design` and apply its **diff-relative bar** (if you don't see a `Launching skill: codebase-design` line, stop and call it again — that skill holds the regression shapes the two questions that follow are decided by, and names this skill as one of the two that apply its bar): two-sided — "did this change make the local architecture worse?" and "did it miss a visibly simpler shape?"

**Grading default.** A finding that trips the defensive bar (the diff actively regresses local architecture) defaults to **Blocker**; one that only trips the offensive bar (a missed simpler shape) defaults to **Follow-up**, with the simpler shape proposed. Taste never silently escalates to Blocker.

## Discoverability

Call the Skill tool with `discoverable-code` and apply its before-the-change-lands checklist to the `+` side (if you don't see a `Launching skill: discoverable-code` line, stop and call it again — that checklist has to reach the finder prompt verbatim, and the subagent that runs it cannot load the skill for itself), carrying the checklist into the finder prompt rather than paraphrasing it.

## Verification gap

One question: if this behavior broke where it is used, would any check fail? Three shapes: a **regression gap** (behavior changed, no test tightened with it), a **missing-adoption gap** (a new capability nothing exercises — flag only with a supersession signal, an old path the new one replaces, so the lens never degenerates into refactor nagging), a **broken-verification gap** (the diff itself weakens a check — a re-recorded snapshot or benchmark baseline, a lowered coverage floor, a widened tolerance, a new suppression comment that silences a linter, a type checker, a coverage or mutation tool, or a scanner (`eslint-disable`, `@ts-ignore`, `istanbul ignore`, `Stryker disable`, `nosemgrep`, `gitleaks:allow`); tightening a bar may be silent, loosening one is loud, so the finding quotes the reason the change gives for the trade, or says none was given). Findings name the smallest realistic break a consumer would observe — invert the branch, drop the default, omit the field. Two evidence rules ride in the prompt: read a test before claiming what it covers; search by the symbol under test and its import references before claiming no test exists.
