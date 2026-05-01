# Self-contained skill bundles with duplicated format references

## Context

Several skills reference shared format docs — `domain-format.md` is needed by both `grill-and-record` (writing DOMAIN.md inline during grilling) and `harden-domain` (writing DOMAIN.md from a sweep); `adr-format.md` is needed by `grill-and-record`, `backfill-adrs`, and the standalone `adr` skill. Skills are symlinked individually into `~/.claude/skills/` from this repo; users routinely install one or two skills without cloning the whole tree.

## Decision

Each skill's `references/` folder is self-contained. Format docs are duplicated across the skills that need them — `domain-format.md` exists in `grill-and-record/references/` and `harden-domain/references/`; `adr-format.md` exists in `grill-and-record/references/` and `backfill-adrs/references/` (the standalone `adr` skill carries the format inline in its SKILL.md). There is no shared source. Drift mitigation is "when updating one, grep the other locations and update in lockstep."

## Considered Options

- **Shared `references/` at the repo root** — rejected. Breaks symlink-install portability; symlinking just `src/grill-and-record/` into `~/.claude/skills/` doesn't carry the format doc.
- **Symlinks within the repo** (e.g., `harden-domain/references/domain-format.md → ../grill-and-record/references/domain-format.md`) — rejected. Symlink chains across the install symlinks are fragile, editors handle them inconsistently, and the second hop breaks if a user installs the second skill but not the first.
- **Generated copies via a build step** — rejected. Adds tooling to a repo whose entire premise is "skills are markdown, no build."

## Consequences

- Each skill is a portable atomic unit — symlink one directory, get everything it needs.
- Drift is real: a fix to `domain-format.md` in `grill-and-record` won't reach `harden-domain` until someone greps. The mitigation is editorial discipline, not a mechanism.
- Format docs stay short and stable by design — high-churn templates wouldn't survive this trade-off, so the duplication tax stays bounded.
- Five copies in total today (two of `domain-format.md`, two of `adr-format.md`, plus the inline ADR format in `adr/SKILL.md`). Adding a new skill that writes to either format adds a copy.
