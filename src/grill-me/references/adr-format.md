# ADR format

ADRs live in `docs/adr/<NNNN>-<slug>.md`. Create the directory lazily — only when the first ADR is written.

## Convention preflight

A repo that already records decisions keeps its own scheme. Before writing, look for an existing ADR convention — a populated `docs/adr/`, a `doc/architecture/decisions/` or similar directory, a `.adr-dir` file, an MADR/adr-tools layout — and if one exists, match its path, numbering, and format, continuing the existing sequence. If the evidence conflicts, surface the conflict and ask rather than silently introducing a second scheme. Everything below applies when no convention exists, or the existing one already matches.

One variant worth recognizing on sight: a **single-file decision log** — one document holding numbered entries — rather than a file per ADR. There, append at the tail with the next number, and expect a *textual* merge conflict when two branches both append. Resolve it by renumbering the later entry and fixing its inbound links; the loud conflict is the same collision the per-file scheme hides.

## Numbering and slug

Increment past the highest number claimed in **either** place, taking whichever is higher:

- **The working tree** — list the ADR directory. This catches a record written earlier this session and not yet committed.
- **Git history** — `git log --all --diff-filter=A --name-only -- <adr-dir>`, using the directory the preflight resolved. This catches numbers already claimed on branches you haven't merged.

Numbering time is the only moment a duplicate can be prevented: git merges two differently-named files without complaint, so the collision lands silently and leaves every `[ADR N](N-slug.md)` link ambiguous. Where there's no git repo, or the log comes back empty because the repo predates it, the working-tree scan stands alone. Numbers burned by abandoned branches leave gaps in the sequence — a gap is cosmetic, a duplicate is not.

Slug is a short kebab-case summary of the decision (e.g., `0007-transactional-test-isolation.md`).

## Amend or write new

Before drafting, search for a record that already owns this ground — one whose *premise this decision changes*, not merely one sharing keywords. If you find one, apply **the gate below to the new content alone**:

- **It doesn't clear the gate** — a refinement, a landed detail, a narrowed premise → **amend in place**. Append to the owning ADR's `## Amendments` section, dated (`- **<date>** — …`), adding a ticket reference where the repo has a tracker. No new number.
- **It clears the gate on its own** → **new record, linked both ways**. The new ADR states `This amends [ADR N](N-slug.md)` and says what moved; the amended one gets a forward pointer at its top (`> **Amended by [ADR N](N-slug.md):** …`).

**Amendment is not supersession.** An amended decision still stands on a changed premise; a superseded one is no longer in force and is marked in Status frontmatter. Reaching for supersession while the old decision survives loses that distinction. When superseding, the superseded record's Status names its successor as a file link (`superseded by [ADR N](N-slug.md)`) and the successor links back to what it replaces — a bare number breaks the moment numbering shifts or files move.

The search is a judgment call; when unsure, prefer a new record — the expensive error is amending one that should have been left alone. Amendments are additive and dated; never rewrite the original text.

## Default form

1-3 sentences. Use this template:

```md
# <Short title>

<1-3 sentences: what was the context, what did we decide, and why. Mention the rejected alternatives if their rejection wasn't obvious.>
```

## Optional sections

Only when they add real value, not for completeness:

- **Status** frontmatter (`proposed | accepted | superseded by [ADR N](N-slug.md)`) — useful when revisiting
- **Considered Options** — only when rejected alternatives are worth remembering in detail. The gate's third criterion guarantees an alternative was weighed, so when the section is omitted the rationale still names that alternative and why it lost, in a clause — a record with no alternative anywhere reads, years on, as a decision nobody compared. Where a record truly has none, it says which kind it is — *forced* (no alternative existed; name the constraint — such a record fails the gate's third criterion and is written only when the constraint itself is what the next reader needs, a mandated platform or a regulation) or *unexamined* (none was weighed, as in a backfill) — because a reader re-opening the decision treats the two differently
- **Deferred** — the open questions the decision leaves standing, one line each naming the question and the artifact that settles it (a ticket, a later ADR, a measurement); omitted when nothing is open, never padded. A line later settled stays as written and gains a trailing `— settled: see Amendments <date>`, so a reader who stops at Deferred is not left with a stale open question
- **Revisit when:** — one line naming the assumption or trigger that would falsify the decision (a load figure, a dependency's status, a team size); `backfill-adrs`' STALE sweep and the amendment step read it
- **Consequences** — only when downstream effects are non-obvious. A bullet a later amendment corrects stays as written — amendments are additive and never rewrite — and gains a trailing `— corrected: see Amendments <date>`, so a reader who stops at Consequences is not left taking a superseded figure for the current one
- **Amendments** — the dated log an in-place amendment appends to; created on the first amendment, never up front

## The gate

Before writing, confirm out loud which of the three criteria the decision meets, and which alternatives were considered:

1. **Hard to reverse** — undoing this later carries real cost (schema migration, dependency change, methodology shift); name that cost, or the decision is reversible and fails this criterion — rating everything hard-to-reverse produces records nobody reads.
2. **Surprising without context** — a future reader (or AFK agent) will look at the code and wonder "why did they do it this way?"
3. **Result of a real trade-off** — there were genuine alternatives and one was picked for specific reasons. Probe this one with the **opposite test**: state the rejected alternative as a decision of its own, and check that a rational team could have picked it. The opposite is the alternative someone argued for, never the claim negated — "validate at the handler" against "validate at the boundary and trust callers inward" is a trade-off two teams really do split on, while "we chose to write the feature" has no opposite anyone would defend, and describes the work rather than deciding anything.

If any one is missing, do not write the ADR — stop and tell the user why.

## Rejections are decisions

A considered rejection — a library not adopted, a capability deliberately not built, an approach turned down — is recordable on the same gate: the decision is "no", and the rejected thing is the alternative. Record the reason at the level that generalizes (why the *concept* was rejected, not just this instance) — the record's job is to stop a settled "no" from being re-litigated by someone who wasn't there.

## Example

```md
# Transactional rollback for test isolation

Each integration test runs inside a database transaction that is rolled back on teardown, rather than truncating tables between tests. Truncation was rejected because it was 5x slower in CI and required disabling foreign-key checks; transactional rollback keeps tests parallelizable as long as no test depends on observing committed state from another connection.
```
