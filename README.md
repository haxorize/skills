# skills

Personal collection of repo-agnostic agent skills, hoisted into `~/.claude/skills/` for use across projects.

## Skills

### Grilling

- **`grill-me`** — Vanilla stress-testing through relentless interview. Zero setup, runs anywhere.
- **`grill-and-record`** — Doc-aware grilling. Updates `DOMAIN.md` inline as terms resolve and offers ADRs when the gate triggers. Use in projects that have (or will have) a `DOMAIN.md` and an ADR log.

### Domain language

- **`harden-domain`** — Sweep the codebase to refresh `DOMAIN.md`. Deliberate sweep mode (inline domain capture during grilling lives in `grill-and-record`).

### Decisions

- **`adr`** — Capture a single fresh Architecture Decision Record after a deliberate decision.
- **`backfill-adrs`** — Sweep recent git history for un-recorded architectural decisions and write the ones that pass the gate.

### Publishing to a tracker

- **`to-feature`** — Synthesize a Feature-level (PRD-shaped) artifact and publish it. Use only when scope is broad enough to warrant multiple stories underneath. ADO: Feature work item. GitHub: feature/PRD issue.
- **`to-story`** — Synthesize a Story-level (single-feature spec) artifact and publish it. Default entry point for turning a grilled plan into a tracked work item. ADO: User Story. GitHub: story-shaped issue.
- **`to-tasks`** — Break a parent User Story into child Tasks. Tracer-bullet style; verifies the parent is a Story before slicing. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly instead.

### Architecture

- **`deepen`** — Module-deepening refactor proposals.

### Meta

- **`write-skill`** — Conventions for writing new skills.

## Conventions

- **`DOMAIN.md`** at the repo root holds the project's ubiquitous language. For multi-context monorepos, the root is an index linking to nested `DOMAIN.md` files. Cross-repo siblings cross-reference each other in prose.
- **ADRs** live in `docs/adr/<NNNN>-<slug>.md` per repo. Numbering: scan highest, increment by one.
- **Tracker dispatch** is declared per-repo in `CLAUDE.md` under an `Issue tracker:` block. Supports GitHub (`gh`) and Azure DevOps (`az boards`). Hierarchy (`Hierarchy: required|optional`) controls whether the publishing skills enforce a `--parent` argument. ADO defaults to `required` (Epic → Feature → User Story → Task); GitHub defaults to `optional`.
- **Sibling repos** declared in `CLAUDE.md` under `## Sibling repos` so `to-tasks` can flag cross-repo blockers.

## Install

Symlink each skill directory into `~/.claude/skills/`:

```bash
cd ~/code/src/humana/skills
for skill in */; do
  [ "$skill" = "plans/" ] && continue
  ln -s "$(pwd)/${skill%/}" ~/.claude/skills/
done
```

Or link a single skill:

```bash
ln -s ~/code/src/humana/skills/grill-me ~/.claude/skills/
```

## Notes

- Several skills reference `DOMAIN.md` (from `harden-domain` / `grill-and-record`) and `docs/adr/` (from `adr` / `backfill-adrs`). They degrade gracefully in projects that don't use those conventions.
- The `to-feature`, `to-story`, and `to-tasks` skills operate in three modes: declared (CLAUDE.md present with tracker block), bootstrap-on-ask (repo present, asks once and writes the block), and no-repo CLI-only (publish via tracker CLI without touching files; saves tracker config to memory).
- Bootstrap-on-ask is safe to use alongside Claude Code's built-in `/init` — `/init` preserves existing CLAUDE.md sections rather than overwriting them, so the order of operations doesn't matter.
- See [`plans/skills-restructure.md`](plans/skills-restructure.md) for the design history and rationale behind the current skill set.
