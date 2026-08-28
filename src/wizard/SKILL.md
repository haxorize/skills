---
name: wizard
description: Generate an interactive bash wizard that walks a human through steps only they can perform — credentials, third-party dashboards, a cutover — or run the same step-by-step interview in chat when a script isn't wanted.
disable-model-invocation: true
requires: writing-for-humans
---

# Wizard

A **wizard** is a bash script that walks a human, step by step, through a manual procedure that's tedious to do by hand and tedious to re-explain to an agent every time. It opens each URL, says exactly what to click and copy, captures the values, writes them where they belong (`.env`, CI secrets), confirms at every stage, and shows how many stages are left. When a script is the wrong medium, the same discipline runs in chat — see the chat fallback at the end.

The UX is already solved by [template.sh](template.sh) — stage-by-stage progress, confirmation gates, cross-platform URL opening (including WSL), hidden secret entry, idempotent `.env` upserts, `gh secret`/`gh variable` writes, and a closing summary. **Your job is only to scope the procedure and author its stages.** The library above the `STAGES` marker is identical in every wizard; that consistency is the point — never hand-edit it.

A wizard is ephemeral by default — built for one run, saved to a scratch or `scripts/` path, deleted when the job's done. Commit it only when the user wants a repeatable setup path that should live in the repo.

## Process

### 1. Scope the procedure

Work out every manual step the human must take and every value captured along the way. Read the repo first — don't ask cold:

- For setup: `.env`, `.env.example`, `.env.*`, `README`, `docker-compose*`, framework config, and CI workflow files (every secret/variable reference is a value the wizard must produce).
- For a migration or transition: the current state, the target state, and the irreversible actions between them.

Design for the **fewest stages that still work**. Every stage is a place the human can lose the thread or stop, so merge stages that always happen together *and land on one task the human can hold at once*, and cut any stage capturing a value the wizard could read from the repo or derive itself. Two steps that merge into a stage the human has to re-read were two stages. A procedure written as eleven stages where six would do has five extra chances to be abandoned halfway.

Then show the user the ordered list of stages and the values each produces, and confirm — they may add, drop, or reorder.

**Done when:** every stage is named in order, and for each captured value you know (a) where the human gets it, (b) where it's written (`.env`, a CI secret, both, or nowhere — some stages are pure actions), and (c) whether it's secret (hidden entry) or public.

### 2. Map each stage's journey

For each stage, write the precise path a human follows: which URL to open, what to do there, where the value is shown, which variable it fills — "Dashboard → Developers → API keys → Reveal test key → copy". Where you don't actually know the current UI or the exact command, say so and ask the user or check the docs — never invent steps that may not exist.

**Done when:** every stage traces to concrete instructions a stranger could follow.

### 3. Author the wizard

Copy `template.sh` to the target path. Replace the example stage with one `stage` per step, in dependency order. Every string the human reads is procedural human prose — call the Skill tool with `writing-for-humans` at the first such string if it isn't already live. Use the library helpers — `stage`, `say`/`step`, `open_url`, `ask`/`ask_secret`, `write_env`, `set_secret`/`set_var`, `pause`/`confirm` — and set `TOTAL_STAGES` to the number of stages you wrote.

Hold the bar the template sets: open the URL before asking for its value, use `ask_secret` for anything secret, `write_env` every persisted value, `set_secret` only the values CI actually needs, and `confirm` before any irreversible action. When a stage starts anything long-lived — a provisioning job, a deploy, a background process — print the exact copy-paste command to watch it in the same stage, not after it finishes, and repeat it after `finish` prints the closing summary when the job outlives the wizard. Each `stage` clears the screen so only the current step is visible — keep a stage to one focused task so nothing the human needs scrolls away.

The secret/variable helpers speak `gh`, and when `gh` is missing or unauthenticated at run time they already degrade honestly — they warn, print the exact manual command, and list it in the closing summary — so on a GitHub repo, call them and let them handle it. On a non-GitHub tracker, don't fake the write: have the stage capture the value, then print the exact manual command (or portal path) the human runs to store it, and record it in the closing summary as waiting on them.

### 4. Verify and hand off

- `bash -n <script>`; run `shellcheck` if available.
- `chmod +x <script>`.
- Don't run it end-to-end yourself — it opens browsers and blocks on human input. Trace it statically instead: every value from step 1 is captured and lands where step 1 said, and every `set_secret` name exactly matches a secret reference in CI.
- If it's a repeatable setup path, commit it and link it from the README so the next person runs the script instead of asking an agent.

## The chat fallback

When a script is the wrong medium — no machine to run it where the human is, a procedure only a few steps long, or steps that will be discovered as you go — run the same discipline in chat instead. Keep the canonical checklist internally, complete and uncapped. Present **one atomic human step per message** with its full detail; after each completed step, show the remaining items as a headline-only list — a few glanceable words each, no commands, URLs, or values (detail appears only when an item becomes the current step). Before every reply, re-audit the visible list against the internal checklist, and cap the visible list at 8 items by merging far-off steps into phase-level headlines.
