# Self-contained skill bundles with duplicated format references

## Context

Several skills reference shared format docs — `domain-format.md` is needed by both `grill-and-record` (writing DOMAIN.md inline during grilling) and `harden-domain` (writing DOMAIN.md from a sweep); `adr-format.md` is needed by `grill-and-record`, `backfill-adrs`, and the standalone `adr` skill. The same need recurred for the **naming-drift queue**: its definition (lifecycle, storage, entry format) is shared by the four `to-X` publishing skills (`to-bug`, `to-feature`, `to-story`, `to-tasks`). Skills are symlinked individually into `~/.claude/skills/` from this repo; users routinely install one or two skills without cloning the whole tree.

## Decision

Each skill's `references/` folder is self-contained. Format docs are duplicated across the skills that need them — `domain-format.md` exists in `grill-and-record/references/` and `harden-domain/references/`; `adr-format.md` exists in `grill-and-record/references/` and `backfill-adrs/references/` (the standalone `adr` skill carries the format inline in its SKILL.md); `naming-drift-queue.md` exists in `to-bug/`, `to-feature/`, `to-story/`, and `to-tasks/` `references/`. There is no shared source. Drift is caught by `scripts/lint-skills.sh`, which fails if any sibling group's copies are not byte-identical — turning the original "grep and update in lockstep" discipline into a mechanism.

## Considered Options

- **Shared `references/` at the repo root** — rejected. Breaks symlink-install portability; symlinking just `src/grill-and-record/` into `~/.claude/skills/` doesn't carry the format doc.
- **Symlinks within the repo** (e.g., `harden-domain/references/domain-format.md → ../grill-and-record/references/domain-format.md`) — rejected. Symlink chains across the install symlinks are fragile, editors handle them inconsistently, and the second hop breaks if a user installs the second skill but not the first.
- **Generated copies via a build step** — rejected. Adds tooling to a repo whose entire premise is "skills are markdown, no build."

## Consequences

- Each skill is a portable atomic unit — symlink one directory, get everything it needs.
- Drift is caught mechanically: `scripts/lint-skills.sh` asserts every sibling group is byte-identical, so a fix that misses a copy fails lint rather than silently diverging. (The original consequence — "editorial discipline, not a mechanism" — was superseded once the linter landed; see Amendments.)
- Format docs stay short and stable by design — high-churn templates wouldn't survive this trade-off, so the duplication tax stays bounded.
- Nine copies in total today (two of `domain-format.md`, two of `adr-format.md`, four of `naming-drift-queue.md`, plus the inline ADR format in `adr/SKILL.md`). Adding a new skill that writes to a shared format adds a copy and a `sibling_groups` entry in the linter.

## Amendments

- **2026-06-19** — Extended the pattern to `naming-drift-queue.md` (four copies across the `to-X` skills), consolidating a definition that had drifted into four divergent inline phrasings. Reconciled the Context/Decision/Consequences with `scripts/lint-skills.sh`, which now enforces byte-identity for all sibling groups; this enforcement is what makes a four-copy group safe to maintain.
