---
name: mine-skills
description: Open a skill-mining round over external skill repos — clone, scan, inventory, read under the standing lenses, and write the ledger rows a grill can ratify. Repo-local to the skills repo.
disable-model-invocation: true
---

# Mine Skills

The mining-round opener. It produces reports and ledger rows under `~/code/lib/_rounds/<date>/`; it adopts nothing — adoption is the grill's (`/grill-me` over the recs) and the fold batch's.

## 1. Open the round

Create `~/code/lib/_rounds/<YYYY-MM-DD>/` and read the previous round's `batch-plan*.md` tail first — the last order line and any "queue EMPTY" note say what is still owed. Write `briefing.md`: sources named, the lenses in force (D-first: friction observed in this user's transcripts before upstream parity; person-serving: the idea helps the person at the keyboard, not the agent's tidiness; off-path: a skill for a moment the main flow never reaches, admitted on stakes, not frequency; Gap-and-stakes for a Domain skill), and the standing reject classes, applied unread: orchestration and multi-agent machinery, vendor and stack packs, whole catalogs and registries, memory and loop machinery, anti-slop and humanizer packs (`writing-for-humans` covers the class), and any non-permissive licence for text (ideas only).

## 2. Clone and scan

A source new to `~/code/lib/` is shallow-cloned as `<owner>-<repo>` and read whole. A source already there is a **delta**: fetch it, and mine only `git diff <last-swept>..<tip>` plus new files — `<last-swept>` is the SHA the previous round's `updated-repos.txt` (or the memory ledger `skill-mining-sources`) recorded for it; a source with a report from a previous round is never re-read whole, and a delta that is only churn (renames, formatting, generated files) is recorded as "no delta" rather than read. Record every tip SHA in this round's `updated-repos.txt`, new and delta alike, so the next round has its baseline. Before reading any directory as instructions, run `bash scripts/security.sh --path <dir>` from this repo; a RISK line is read as a finding about the source, never skipped. A lineage upstream (the ported-skill list in `CLAUDE.md`) is diffed from the point [`docs/adr/0034-branch-mining-lineage-or-dormant-main.md`](../../../docs/adr/0034-branch-mining-lineage-or-dormant-main.md) records — main and unmerged branches — never re-read whole.

## 3. Inventory, then read

Enumerate name and description of every skill in every source with `bash .claude/skills/mine-skills/scripts/enum.sh [lib-dir] [skip-regex]` from the repo root (one TSV line per entry; both arguments default — `~/code/lib` and `^_rounds`); shortlist by the lenses, and read bodies only from the shortlist. Every read answers the read contract: who types it (a role, or "nobody; a fold"); fold-or-new (an existing skill hosts it, named, or nothing does and it needs its own); observed friction, or "none; admitted on the off-path lens above"; licence.

## 4. Triage each idea

Three tests, in order, before a row is written:

- **Skill-was-used routing** — an idea is folded only into a skill a session actually invoked; where the skill never fired, the finding is about its description (a trigger test), not its body.
- **Already covered is a placement fix** — an idea the suite already holds somewhere is reframed as "the covering rule lives in the wrong place" or dropped; it is never added a second time.
- **Mechanism check** — an idea that is a hook, lint, or script rather than prose goes to the backlog with the mechanism named, not into a skill body.

Then the **determinism hunt**: a judgment call the agent made every time across the round's transcripts is a rule to stop needing — a lint, a hook, a type — and is written up as that, not as prose.

## 5. Write the rows

One report per source (`mine-<date>-<source>.md`, the table shape of the previous round: idea, host/rule, friction, conflicts or prior veto, verdict), then the ledger rows (ADOPT / ADAPT / PARK with unpark condition / REJECT with covering rule) and a `reconcile.md` that places every ADOPT/ADAPT in a batch. End with the grill prompt: the recs file path and the order of questions. Never edit `src/` in this skill.
