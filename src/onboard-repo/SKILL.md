---
name: onboard-repo
description: Wire a repo for this suite in one sitting — the `Issue tracker:` and `Landing:` blocks, the `## Commands` section, the convention-skill roles, and the seed files the skills read (`DOMAIN.md`, `docs/adr/`, `docs/solutions/`), each written only where nothing exists yet.
disable-model-invocation: true
requires: writing-for-agents
---

# Onboard Repo

Run the `/writing-for-agents` skill now — `CLAUDE.md` is prose an agent obeys; if you did not just see a `Launching skill: writing-for-agents` line, stop and load it before writing a block.

One sitting turns a repo the suite has never seen into one every skill can read without asking. The skills degrade when the blocks are missing (the publishers bootstrap-on-ask, `committing` treats an absent `Landing:` as nothing pre-authorised), so this is a convenience, never a prerequisite — run it once per repo, or again after a block goes stale.

## 1. Read before asking

Look first, then ask only what the repo cannot answer: the remote (`git remote -v`) names the host; `CLAUDE.md` may already carry some blocks; `package.json` scripts, `Makefile`, `pyproject.toml`, `*.csproj`, or CI config name the loop commands; `.claude/skills/` lists convention skills. Report what was found before the interview, so the user corrects a wrong read instead of re-answering a known fact.

## 2. Interview

One numbered round, only the gaps from step 1:

1. **Tracker** — name (GitHub, ADO, other), and for ADO the `Project:` (the minimum the publishers need); default labels or area paths if the team uses them.
2. **Landing** — the five lines `committing` reads: `Branch policy:` (`trunk` or `branch-per-ticket` with its naming pattern), `PR required:`, `Push pre-authorised:`, `Ticket close pre-authorised:`, `Defect policy:` (default `fix, don't file`). Recommend the conservative line wherever the answer is unsure: nothing pre-authorised costs one question per landing; a wrong `yes` costs a push nobody asked for.
3. **Commands** — the test, lint, typecheck, and format invocations `feedback-loops` reads from `## Commands`, asked only where step 1 found none or found an invocation that looks wrong and is right (`uv run pytest` beside a bare `pytest` on PATH).
4. **Convention-skill roles** — which project-local skills own which layer (`database` → migrations, `api` → endpoint shape), for the `## Convention skills` section `tdd` and `feedback-loops` read by role.
5. **Registry** — whether installs go through a proxy with a curation policy (an Artifactory or JFrog minimum release age, a blocked-licence list): the `## Registry` lines `upgrade-deps` reads, asked only where the manifest or `.npmrc` / `NuGet.config` / `pip.conf` does not already name the proxy.
6. **Hooks** — whether to wire `rename-safety` (opt-in per directory) and `commit-bypass` from the suite's `global/hooks/`.

## 3. Write, never overwrite

Preview every block, then write on confirmation. A block or file that already exists is left exactly as it is and reported as skipped, even where it disagrees with the interview — the user edits it; this skill does not. Append to `CLAUDE.md` (create a minimal one when absent); never reorder or rewrite what is there.

- `## Issue tracker` — the `Issue tracker:` block the publishers read: the tracker name; for ADO, `Project:`; optional default labels or area path.
- `## Landing` — the `Landing:` block, five lines.
- `## Commands` — only the commands step 2 admitted, each preceded by the question it answers.
- `## Convention skills` — role → skill name, one line each.
- `## Registry` — `Minimum release age:` and any other curation line step 2 admitted; the number is the org's and lives here, never in a skill.
- `DOMAIN.md` — a heading and an empty `| Term | Definition | Aliases to avoid |` table; the vocabulary arrives through `grill-me` and `harden-domain`, not here.
- `docs/adr/` — the directory plus a one-paragraph `README.md` naming the `adr` discipline as the writer; no ADR is authored.
- `docs/solutions/` — the directory plus the one-line `CLAUDE.md` pointer `capturing-learnings` would otherwise add at first capture.

Hook opt-in is a printed `settings.json` snippet and, for `rename-safety`, the `touch .claude/rename-safety` line — this skill never edits `settings.json`.

## 4. Close

List every block written, every one skipped and why, and the two things only the human can do (paste the hook snippet; tell teammates the blocks exist). Where the repo already has code or history, suggest the two sweeps that fill the seeds this skill left empty — `/harden-domain` for `DOMAIN.md` from the code's vocabulary, `/backfill-adrs` for `docs/adr/` from the decisions in the log — as next sessions, not as part of this sitting. Commit nothing — the `committing` discipline lands it on the user's ask.
