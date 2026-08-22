---
name: onboard-repo
description: Wire a repo for this suite in one sitting — the `Issue tracker:`, `Landing:`, and `## Registry` blocks, the `## Commands` section, the convention-skill roles, the seed files (`DOMAIN.md`, `docs/solutions/`), and the printed hook snippet — each block written only where nothing exists yet.
disable-model-invocation: true
requires: writing-for-agents
---

# Onboard Repo

Run the `/writing-for-agents` skill now — `CLAUDE.md` is prose an agent obeys; if you did not just see a `Launching skill: writing-for-agents` line, stop and load it before writing a block.

One sitting turns a repo the suite has never seen into one every skill can read without asking. The skills degrade when the blocks are missing (the publishers bootstrap-on-ask, `committing` treats an absent `Landing:` as nothing pre-authorised), so this is a convenience, never a prerequisite — run it once per repo; a block that later goes stale is edited by hand, since this skill never rewrites one.

## 1. Read before asking

Look first, then ask only what the repo cannot answer: the remote (`git remote -v`) names the host; `CLAUDE.md` may already carry some blocks; `package.json` scripts, `Makefile`, `pyproject.toml`, `*.csproj`, or CI config name the loop commands; `.claude/skills/` lists convention skills. Report what was found before the interview, so the user corrects a wrong read instead of re-answering a known fact.

## 2. Ask the gaps, in one round

One numbered round, only the gaps from step 1:

1. **Tracker** — name (GitHub, ADO, other), and for ADO every field a reader of the block names: `Organization:` and `Project:` (`ship` and the publishers), `Area path:` and `Iteration:` (`glapi-test-pass`); default labels if the team uses them. Ask for all four now — step 3 never adds a line to a block that exists, so a field skipped here stays missing.
2. **Landing** — the six lines `committing` reads: `Branch policy:`, `PR required:`, `Push pre-authorised:`, `Ticket close pre-authorised:`, `Review required:`, `Defect policy:` (their values are `committing`'s to define; the README's Landing key convention lists them). Recommend the conservative line wherever the answer is unsure: nothing pre-authorised costs one question per landing; a wrong `yes` costs a push nobody asked for. `Review required:` is `yes` when the review happens in the session and `no` when it happens on a PR an approver signs — the `PR required:` answer decides it; `yes` gates rather than authorises, which is why it is the conservative line.
3. **Commands** — the test, lint, typecheck, and format invocations `feedback-loops` reads from `## Commands`, asked only where step 1 found none or found an invocation that looks wrong and is right.
4. **Convention-skill roles** — which project-local skills own which layer (`database` → migrations, `api` → endpoint shape), for the `## Convention skills` section `implement` points `tdd` and `feedback-loops` at, by role. In a repo holding member or patient data, ask for the `phi` role too: `phi-safe-code` reads it for the org's allowed-field list, retention figures, and which stricter categories apply, and without it that skill has the *how* and no *what*.
5. **Registry** — whether installs go through a proxy with a curation policy (an Artifactory or JFrog minimum release age, a blocked-licence list): the `## Registry` lines `upgrade-deps` reads, asked only where the manifest or `.npmrc` / `NuGet.config` / `pip.conf` does not already name the proxy.
6. **Hooks** — whether to wire `rename-safety` (opt-in per directory), `commit-bypass` (always on), and `review-receipt` (armed by the `Review required: yes` line from item 2 — a repo with that line and no hook wired believes its pushes are gated while nothing fires) from the suite's `global/hooks/`.

## 3. Write, never overwrite

Preview every block, then write on confirmation. A block or file that already exists is left exactly as it is and reported as skipped, even where it disagrees with the interview — the user edits it; this skill does not. Append to `CLAUDE.md` (create a minimal one when absent); never reorder or rewrite what is there.

- `## Issue tracker` — the `Issue tracker:` block the publishers read: the tracker name; for ADO, the four fields from step 2; optional default labels.
- `## Landing` — the `Landing:` block, six lines.
- `## Commands` — only the commands step 2 admitted, each preceded by the question it answers.
- `## Convention skills` — role → skill name, one line each.
- `## Registry` — `Minimum release age:` and any other curation line step 2 admitted; the number is the org's and lives here, never in a skill.
- `DOMAIN.md` — a heading and an empty `| Term | Definition | Aliases to avoid |` table; the vocabulary arrives through `grill-me` and `harden-domain`, not here.
- `docs/solutions/` — the directory plus the `CLAUDE.md` line `capturing-learnings` would otherwise add at first capture, verbatim from its step 4: `docs/solutions/ — solved problems keyed by symptom frontmatter`.

Hook opt-in is a printed `settings.json` snippet and, for `rename-safety`, the `touch .claude/rename-safety` line; `review-receipt`'s opt-in is the `Review required: yes` line the Landing block already carries — this skill never edits `settings.json`.

## 4. Close

List every block written, every one skipped and why, and the two things only the human can do (paste the hook snippet; tell teammates the blocks exist). Where the repo already has code or history, suggest the two sweeps that fill what this skill left empty or absent — `/harden-domain` for `DOMAIN.md` from the code's vocabulary, `/backfill-adrs` to create `docs/adr/` from the decisions in the log (`docs/adr/` is never seeded: an empty one flips `grill-me` into recording mode on a repo with no decisions) — as next sessions, not as part of this sitting.
