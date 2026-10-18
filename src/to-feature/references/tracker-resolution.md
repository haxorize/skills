# Tracker resolution

Open this when the step in hand needs the tracker resolved — filing, reading, updating, or closing an item — and this session has not resolved it already. For the publishing skills and `/ship`'s step 1 that is every run, which is why the pointer there is unconditional; the reader-side callers (`review-architecture`, `backfill-adrs`, `implement`'s ticket load) reach it only on the branch that touches an item.

From inside the repo, run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py resolve` — `work-item-shape` owns the one copy, and every tracker skill runs it there. It reads the `## Issue tracker` block in `CLAUDE.md` and prints `mode=` first. Three modes:

- **Declared** (`mode=declared`, exit 0) — the block is present. The script then prints `tracker=github` or `tracker=ado` and one `key=value` per block line (`area_path=…`, `title_prefix=…`); dispatch on those. Every later `tracker.py` command reads the block itself, so no value is copied into a command by hand. A block naming two trackers exits 1: ask the user which tracker this run uses, never pick one.
- **Bootstrap-on-ask** (`mode=bootstrap`, exit 2) — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** (`mode=no-repo`, exit 2) — no git repo at all. Ask for tracker info and write the answers as an `## Issue tracker` block in `<scratchpad>/CLAUDE.md`, then pass `--root <scratchpad>` to every `tracker.py` command. No file lands outside the scratchpad. A GitHub block there carries `Repo: OWNER/NAME`, since no checkout names the repo. Save the answers to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum, and every command but `html`, which reads no block, exits 1 naming the line when it is missing.
