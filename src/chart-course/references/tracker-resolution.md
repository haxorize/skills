# Tracker resolution

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

## Label precheck (GitHub)

Before the first `gh issue create` of a publishing batch, ensure every label about to be applied exists on the repo — a create naming a missing label fails. Run `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing.

## Referring to work items

In anything the human reads — narration, publish confirmations, reports — refer to a work item by its **title**, with the ID and link riding inside (e.g. `[Rate-limit login](url) (#42)`), never by a bare ID. A wall of `#42, #43, #44` is illegible.

## Transport safety

A create call is not idempotent: on a timeout or transport error after the call went out, list the tracker for the item before retrying — the error may have arrived after the write committed, and a blind retry double-files. Never cite a query result or command output you didn't actually run this session, and never attach a link you haven't resolved.
