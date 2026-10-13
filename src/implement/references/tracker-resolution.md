# Tracker resolution

Open this when the step in hand needs the tracker resolved — filing, reading, updating, or closing an item — and this session has not resolved it already. For the publishing skills and `/ship`'s step 1 that is every run, which is why the pointer there is unconditional; the reader-side callers (`review-architecture`, `backfill-adrs`) reach it only on the branch that touches an item.

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.
