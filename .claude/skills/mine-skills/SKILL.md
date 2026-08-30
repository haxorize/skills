---
name: mine-skills
description: Open a skill-mining round over external skill repos — clone, scan, inventory, read under the standing lenses, re-check the prior round's parks, and write the ledger rows a grill can ratify. Repo-local to the skills repo.
disable-model-invocation: true
---

# Mine Skills

The mining-round opener. It produces reports and ledger rows under `~/code/lib/_rounds/<date>/`; it adopts nothing — adoption is the grill's (`/grill-me` over the recs) and the fold batch's.

## 1. Open the round

Create `~/code/lib/_rounds/<YYYY-MM-DD>/` and read the previous round's `batch-plan*.md` tail first — the last order line and any "queue EMPTY" note say what is still owed — and its `ledger.md` PARK rows, which step 5 re-checks. Write `briefing.md`: sources named, the lenses in force (**Team-fit**, which every candidate skill takes: a concrete moment in a product engineering team's work and the role who hits it, named in whatever record would admit it — fire counts are evidence for the case, never the verdict; D-first: friction observed in this user's transcripts before upstream parity; person-serving: the idea helps the person at the keyboard, not the agent's tidiness; off-path: a skill for a moment the main flow never reaches, on stakes rather than frequency, as two extra prongs on top of Team-fit; Gap-and-stakes as the extra bar for a Domain skill), and the standing reject classes, applied unread: orchestration and multi-agent machinery, vendor and stack packs, whole catalogs and registries, memory and loop machinery, anti-slop and humanizer packs (`writing-for-humans` covers the class), and any non-permissive licence for text (ideas only).

## 2. Clone and scan

A source new to `~/code/lib/` is shallow-cloned as `<owner>-<repo>` and read whole. A source already there is a **delta**: fetch it, and mine only `git diff <last-swept>..<tip>` plus new files — `<last-swept>` is the SHA the previous round's `updated-repos.txt` (or the memory ledger `skill-mining-sources`) recorded for it; a source with a report from a previous round is never re-read whole, and a delta that is only churn (renames, formatting, generated files) is recorded as "no delta" rather than read. Record every tip SHA in this round's `updated-repos.txt`, new and delta alike, so the next round has its baseline. Before reading any directory as instructions, run `bash scripts/security.sh --path <dir>` from this repo; a RISK line is read as a finding about the source, never skipped. A lineage upstream (the ported-skill list in `CLAUDE.md`) is diffed from the point [`docs/adr/0034-branch-mining-lineage-or-dormant-main.md`](../../../docs/adr/0034-branch-mining-lineage-or-dormant-main.md) records — main and unmerged branches — never re-read whole.

## 3. Inventory, then read

Enumerate name and description of every skill in every source with `bash .claude/skills/mine-skills/scripts/enum.sh [lib-dir] [skip-regex]` from the repo root (one TSV line per entry; both arguments default — `~/code/lib` and `^_rounds`); shortlist by the lenses, and read bodies only from the shortlist. Every read answers the read contract: **the moment and the role** Team-fit asks for — a concrete moment in a team's work and who hits it, or "none; this is a fold"; who types it (a role, or "nobody; a fold"); fold-or-new (an existing skill hosts it, named, or nothing does and it needs its own — and a candidate an existing skill or global rule already serves is a reject, which is Team-fit's retirement half applied before admission); observed friction, or "none; admitted on the off-path lens above"; licence.

## 4. Triage each idea

Three rules, before a row is written:

- **Usage read** — a host's fire count goes in the row's `usage` cell, taken fresh from `bash scripts/skill-usage.sh --since <the last round's date> --exclude-session <the mining session>` run from this repo's root, written `N+` when the run floors it, never recalled. The count refuses nothing: a zero-load host still takes the fold on the idea's merit, and a zero says nothing about the description — the count is this machine's alone.
- **Already covered is a placement fix** — an idea the suite already holds somewhere is reframed as "the covering rule lives in the wrong place" or dropped; it is never added a second time.
- **Mechanism check** — an idea that is a hook, lint, or script rather than prose goes to the backlog with the mechanism named, not into a skill body.

Then the **determinism hunt**: a judgment call the agent made every time across the round's transcripts is a rule to stop needing — a lint, a hook, a type — and is written up as that, not as prose.

Friction read from the transcripts is graded before it is cited, in the row's `friction` cell. The signals that count are the user's corrections ("no, don't", "I said not to"), a revert of an edit the agent just made (`git checkout --` or `restore` on the file, or the user re-editing it), a repeated "no", and the same mistake twice in one session. Friction from a single session is written `single-instance`; a row that claims a pattern names a second session or transcript; "none; admitted on the off-path lens above" is the zero case. Each friction row names its failure class — instruction misunderstood, output shape, context lost, tool misused, constraint violated, or an edge case — so the fold that answers it is aimed at the cause and not the symptom. This stays prose because the round dirs sit outside the repo, where no lint reads them.

## 5. Write the rows

One report per source (`mine-<date>-<source>.md`, one table per report: idea, host/rule, usage, friction, conflicts or prior veto, verdict), the park sweep (`park-sweep-<prior date>.md`, in this round's directory), then the ledger rows (ADOPT / ADAPT / PARK with unpark condition / REJECT with covering rule) and a `reconcile.md` that places every ADOPT/ADAPT in a batch. The park sweep marks every prior-round PARK met or unmet — its unpark condition checked against this round's evidence and the tree, the check stated per row — and a met park enters this round's reconcile as a row of its own, while an unmet one is re-recorded in this round's ledger with its unpark condition so the next round's sweep sees it; a park nobody re-checks is a decision deferred to nobody. End with the grill prompt: the recs file path and the order of questions. Never edit `src/` in this skill.
