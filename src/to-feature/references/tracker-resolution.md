# Tracker resolution

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask. On ADO, a publishing tier captures the pre-existing parent ID it publishes under (Epic for `to-feature`, Feature for `to-story`, Story for `to-tasks`) in the same memory entry to avoid re-lookup; the reader-side hosts of this file publish no tier and skip the clause.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.
