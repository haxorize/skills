# The review's fan-out is sized by the diff, and a conformance lens moves to a cheaper model only past a recall bar

`review-changes` decides how many lenses become subagents by counting the diff's changed lines (insertions plus deletions over the reviewed range, plus the lines of any untracked file in scope). A prose-only diff of 5 files or fewer runs every lens in-process, as before. Up to 300 changed lines, the review dispatches at most four subagents: `/code-review`, one combined conformance lens carrying the DOMAIN, ADR and (with a work item) AC briefs, the falsification lens when a handoff is the input, and the negative-space pass. Every other lens the triage picked runs in-process. The combined lens returns each lens it carries under its own heading with its own not-examined line, so the report still reads per lens and the coverage ledger still gets one line per lens. Over 300 lines, every lens is its own subagent. A rule or skill body takes the same count as any other diff; there is no path exception. The mechanics live in `src/review-changes/references/fan-out.md` § Fan-out budget.

A conformance lens may run on a cheaper model than the session's, named per machine by `REVIEW_CHECKLIST_MODEL` in that machine's `~/.claude/settings.json` `env`, but only after a re-run on that model over three past reviews recovers at least 80% of the lens's HIGH and MED findings and misses no Blocker. No lens has cleared the bar, so every lens runs on the session model and the key changes nothing until `fan-out.md` § Conformance-lens model names a lens. `CLAUDE_CODE_SUBAGENT_MODEL` is never used for this, because it moves every subagent in every repo.

**Why the budget.** Review size did not follow change size. A 13-line change got 9 reviewer subagents, and so did a 1,975-line change. Of the 28 reviews in the 16 days the 2026-10-12 round measured, 14 were 300 changed lines or fewer, and they dispatched 143 subagents between them; under this budget they would have dispatched about 56 (`~/code/lib/_rounds/2026-10-12/grill-recs.md` ask 11, `themes/tokens.md` TD-12). The diff sizes come from the first diffstat in each session, which may not be the reviewed range. Nick chose the 300-line cut with no path exception on 2026-10-12 (grill Q11), accepting that a one-sentence contract change in a rule now gets the lighter review.

**Why the bar, and why no lens has cleared it.** On 2026-10-14 the conformance lenses were re-run on Sonnet over the reports of three past reviews and one work-machine review, 18 runs in all, each graded by an Opus grader against the original review's HIGH and MED findings and the Blockers attributed to that lens (`~/code/lib/_rounds/2026-10-12/reconcile.md` § Batch 11). Counting partial matches as recovered, the lenses recovered 11% (DOMAIN, 2 of 17), 20% (amendment bookends), 40% (smell baseline), 46% (instruction-file), 50% (ADR) and 63% (discoverability, 7 of 11). Five of the six missed at least one Blocker; only discoverability missed none, and it recovered 63%. The AC lens was not tested, because none of the reports had a work item. The bar of 80% and no missed Blocker is the one set before the run, so a lens that loses most of its findings on a cheaper model does not move to it for the token saving alone.

**The gate.** Not hard to reverse: the budget is one section of one reference, and the model key is inert. It is recorded because it is surprising without context. A reader finds a review that dispatches four subagents on a 290-line change and about ten on a 310-line one, and an environment key that does nothing, and neither the threshold nor the inert key explains itself. The trade-off is real: a dedicated subagent per lens catches what a combined brief or an in-process pass misses, and the budget gives some of that up on small diffs.

## Considered Options

- **Full fan-out on every diff above the prose-only threshold.** Rejected: 143 subagents on the 14 smallest reviews, the same count a 1,975-line change got.
- **A 150-line cut.** Rejected: it covered 6 reviews and saved about 32 subagents, against the 300-line cut's 14 reviews and about 87.
- **Exempt `global/rules/` and skill bodies, always running the full set there.** Rejected (grill Q11): most small diffs in this repo are rule or skill text, so the exemption would remove most of the saving.
- **Move the conformance lenses to Sonnet without a re-run.** Rejected: the re-run showed it loses most findings and misses Blockers.
- **Set `CLAUDE_CODE_SUBAGENT_MODEL`.** Rejected: it moves every subagent in every repo, the reasoning lenses and the vet included.

## Consequences

- A diff of 300 changed lines or fewer gets one combined conformance subagent where it had three, and the lenses outside the four run in-process under §3's ordering rule.
- The combined lens must keep its per-lens headings and not-examined lines, or the per-lens report and the coverage ledger lose the separation they depend on.
- `REVIEW_CHECKLIST_MODEL` may be set on a machine and change nothing; the round's batch to set it on the work machine is moot until a lens passes.
- A lens that qualifies later is named in `fan-out.md` § Conformance-lens model, and the run that qualified it is added to this record.

Revisit when: a defect that a dedicated lens would have caught slips through a review of 300 lines or fewer, or a lens re-run on a cheaper model clears the bar.
