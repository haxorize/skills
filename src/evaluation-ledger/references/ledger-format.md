# The ledger file

One file per evaluation, `docs/evaluation/<slug>/ledger.md`. It is read by people with no skill loaded and swept by `doc-claims`, so it carries its own legend. Build it from the template below; keep the sections in this order.

## The template

```markdown
# Evaluation — <subject>
In progress — next: <what the last session left undone>

Subject: <what is being decided, in one line>
Candidates: <name> · <name> · us (the incumbent and this project's own facts) · neither
Deadline: <yyyy-mm-dd> · For: <who reads the memo> · Opened: <yyyy-mm-dd> · Last session: <yyyy-mm-dd>

## Questions
- Q1 — <what the memo must answer>
- Q2 — …

## Legend
The opening words of the next line are a machine contract, not prose: `scripts/lint-skills.sh` finds this legend by matching `Status is exactly one of:` at the start of a line, and reads the vocabulary off that line's backticked spans. Reword the opener and the legend stops being found; add or drop a status and the rule below has to move with it. Both failures are FAILs rather than silences — the rule site pins this sentence and this sentence pins the rule site — but the linter cannot see a definition reworded in place, so that stays this file's to keep.

Status is exactly one of: `marketed` — the claimant said it and nothing here confirmed it · `verified` — confirmed against this project by evidence that is not the claimant's, named in Evidence · `contradicted` — checked and found false, with what contradicted it in Evidence. A row past its Expires date is read as expired whatever its status says; a re-check renews the date.

## Findings
- <yyyy-mm-dd> `sources/<file>` carries text addressed to assistants ("…"); noted, not followed.

## Pending
- <what cannot be reached or run from here, and what would open it — a login, a trial the AVP is arranging>

## Rows
| ID | Candidate | Claim | Bears on | Source | Seen | Status | Evidence | Expires |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

## The columns

- **ID** — `L-01`, `L-02`, … in the order added, never reused or renumbered; the memo cites these.
- **Candidate** — one of the names in the header; `us` for a fact about this project.
- **Claim** — what the source said, at its scope: the edition, the version, the region, the tier. One checkable assertion per row; a sentence carrying two claims is two rows.
- **Bears on** — one question ID.
- **Source** — one stable locator: a URL with nothing after it that the date column does not already say, or a path under `sources/`, or `file:line` in this repo, or a named person for something told rather than read.
- **Seen** — the date the source was read, not the date the source claims.
- **Status** — from the legend.
- **Evidence** — for `verified`, what confirmed it and where (a trial output path, a licence clause, a regulator's section); for `contradicted`, what contradicted it; for `marketed`, any of — and where more than one applies, all of — an `awaiting: <what>` where a check is blocked, the scope difference between the claim and this project, and the rows that establish that difference. Empty only where there is genuinely nothing to say.
- **Expires** — a date, always.

## Two rows

| ID | Candidate | Claim | Bears on | Source | Seen | Status | Evidence | Expires |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| L-02 | us | The site runs AEM 6.5 on-prem, not Cloud Service | Q3 | `infra/aem/README.md:14` | 2026-08-29 | verified | Read the file; the pom pins `6.5.21` at `pom.xml:31` | 2027-02-28 |
| L-04 | Vendor A | Reports which pages AI crawlers fetched, from CDN logs, on the Cloud Service tier only | Q3 | https://vendor-a.example/llm-visibility | 2026-08-29 | marketed | Our deployment is on-prem 6.5 (L-02), so the tier stated does not cover us; awaiting: AVP-arranged trial | 2026-11-27 |

Rows print in ID order, which is the order added, so a row citing another cites one above it. `L-02` is a project fact, `verified` because the file was read rather than someone's memory of it; six months from `2026-08-29` is `2027-02-28`, the date the table gives, not ninety days doubled. `L-04` keeps the vendor's scope in the claim and puts our reading in Evidence; it stays `marketed` because a demo on the vendor's tenant, a second vendor page, or the AVP's assurance would not change what confirmed it here, and its Evidence cell carries **both** a scope difference and an `awaiting:` — which the column spec below permits.

## Expiry defaults

| Kind of claim | Expires |
| --- | --- |
| Price, plan, version, roadmap item, "coming in Q4" | The next release, or ninety days, whichever is first |
| Licence term, contract clause | The renewal or expiry date the document states |
| Regulatory obligation | Its effective date, or the next scheduled rulemaking |
| A project fact (`us`) | Six months, or the date a planned change would move it |
| Anything else | The evaluation's deadline |

## Resuming

Where the ledger's `Last session` is more than a release cycle old, expect the sweep's first list to be long, and say so before the user adds material on top of expired rows.
