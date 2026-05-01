# Tracker dispatch via CLAUDE.md `Issue tracker:` block with three-mode behavior

## Context

Multiple publishing and backfill skills (`to-feature`, `to-story`, `to-tasks`, `backfill-adrs`, later `to-bug` and `from-work-item`) need to know which issue tracker to publish to and how. Hardcoding picks one tracker at the cost of the rest. Per-invocation CLI flags multiply across every call and don't carry workflow shape cleanly. Real workflows span a personal GitHub context, a work ADO context with Jira Align two-way sync, and PI-planning sessions run from a coordinator directory with no repo at all.

## Decision

Per-repo `CLAUDE.md` carries an `Issue tracker:` block declaring tracker name, tracker-specific config (ADO project / area path / iteration / default state, or GitHub default labels), and a `Hierarchy: required|optional` setting. Skills resolve in three escalating modes:

- **Declared** — CLAUDE.md present with block; read and dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no block. Ask once inline, preview an appended `## Issue tracker` section, write on confirmation. Always append, never overwrite — safe to coexist with built-in `/init`.
- **No-repo CLI-only** — no git repo. Ask, save as a `reference` memory keyed by tracker context (e.g., `Tracker default — work-backlog`), publish via tracker CLI without touching files.

ADO defaults to `Hierarchy: required`; GitHub defaults to `Hierarchy: optional`. The setting controls whether publishing skills enforce a `--parent` argument.

## Considered Options

- **Per-skill CLI flags** — rejected. Repeating `--tracker ado --project ... --area ...` on every invocation is heavy and doesn't carry the workflow-shape config (`Hierarchy`, default labels) cleanly.
- **Single hardcoded tracker** — rejected. User operates in both personal GitHub and work ADO contexts; either choice strands the other.
- **Environment variables** — rejected. Per-shell setup is brittle, doesn't survive across IDE/Claude Code restarts cleanly, and doesn't carry structured workflow shape.
- **Declared-only (no bootstrap, no no-repo)** — rejected. PI planning from a coordinator directory without a repo is a real use case; bootstrap-on-ask makes the skill useful immediately in unconfigured repos rather than blocking on setup.

## Consequences

- Publishing skills work consistently across personal and work contexts without per-invocation config.
- Bootstrap-on-ask is safe alongside Claude Code's built-in `/init` — `/init` preserves existing CLAUDE.md sections rather than overwriting (verified Phase 6).
- No-repo memory entries keyed by tracker context (not by repo). Multi-context users get a disambiguation prompt; single-context users see no friction.
- Adds three-mode complexity to every publishing skill's first step. SKILL.md prose has to be tight or the model mishandles modes.
- ADO no-repo workflow requires pre-existing parent IDs (Epic for `to-feature`, Feature for `to-story`, Story for `to-tasks`); captured in the same memory entry to avoid re-lookup.
- Establishes the dispatch pattern that ADR-0005's `to-bug` and ADR-0004's `from-work-item` extend.
