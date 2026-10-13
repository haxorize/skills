---
status: superseded by [ADR-0108](0108-shared-references-have-one-owner-and-one-copy.md)
---

# Self-contained skill bundles with duplicated format references

## Context

Skills are symlinked individually from this repo into `~/.claude/skills/`, and users routinely install one or two skills without cloning the whole tree. Several skills need the same inert format or data document: the tracker-resolution flow, the publishing gate, the brief a fan-out prompt must quote, the ADO HTML transport, and so on.

## Decision

Each skill's `references/` folder is self-contained. An inert format or data doc is copied into every skill that needs it, with no shared source. `scripts/lint-skills.sh` lists each set of copies in its `sibling_groups` array and fails when any group's copies are not byte-identical, so a fix that misses a copy fails lint instead of silently diverging. That array is the authority on which groups exist and who carries them.

The portable unit is a skill plus the model-invoked dependencies its `requires:` line declares, which `scripts/install.sh` links alongside it ([ADR-0016](0016-behavior-skills-declared-deps-relaxed-atomicity.md)). That does not change the duplication: a format doc has nothing to invoke, so it stays a sibling copy, while a genuine procedure belongs in a behavior skill that callers declare. For the same reason `domain-format.md` has one copy, in `domain-modeling`, since every skill that writes `DOMAIN.md` delegates to that behavior and declares it.

How groups are drawn:

- The parts that genuinely vary stay inline in each `SKILL.md`, not in the shared file: a publisher's title-prefix line, or the one sentence saying a reader-side host resolves a tracker in Declared mode only and never bootstraps.
- A shared doc carries only what its hosts run. The create-side procedure was split out of `tracker-resolution.md` into `publishing.md`, carried only by the skills that create work items, so readers do not carry procedure they never run.
- An override one caller needs is stated in the calling skill, never in the shared file, so byte-identity holds.
- A skill that starts needing a shared doc adds its copy and its path in `sibling_groups` in the same commit.

**The one exception is `adr-format.md`.** It has a single copy, in `src/adr/references/adr-format.md`. `grill-me` and `backfill-adrs` read it by its installed path, `~/.claude/skills/adr/references/adr-format.md`, and both declare `requires: adr`; their copies and the `sibling_groups` entry for them are gone. The three copies were byte-identical at 12,054 B each, about 24 KB of duplicate text, and eight other skills already declare `adr`, so it is installed wherever these two are. The risk accepted is a partial install without `adr`, where a grill that should record a decision finds no format file to follow. Nick chose this in the 2026-10-12 grill (Q26).

**Linking into another skill's `references/`** is allowed when the owner is user-invoked and so cannot be declared. A user-invoked skill sits outside `requires:`, so its reference can be neither loaded through a declaration nor copied without forking a definition every caller must read alike. `roll-out` and `respond-to-incident` link `../ship/references/after-landing.md`, and `address-findings` and `review-architecture` link into `review-changes`' references. On 2026-09-27, `grep -rhoE '\]\(\.\./[a-z-]+/references/[^)#]+' src | sort | uniq -c` returned `after-landing.md` 4, `finding-discipline.md` 1, `smell-baseline.md` 1, `model-seam.md` 1. The last, from `phi-safe-code` into `codebase-design`, falls outside this allowance, because `codebase-design` is model-invoked and can be declared. Moving the shared text to a declarable home was not taken for `after-landing.md`: the data-safety class belongs to `ship`, whose step 4 reads it before every deploy.

## Considered Options

- **Shared `references/` at the repo root.** Rejected: it breaks symlink-install portability, since symlinking one skill directory into `~/.claude/skills/` doesn't carry the format doc.
- **Symlinks within the repo** (one skill's reference pointing at another's). Rejected: symlink chains across the install symlinks are fragile, editors handle them inconsistently, and the second hop breaks if a user installs the second skill but not the first.
- **Generated copies via a build step.** Rejected: it adds tooling to a repo whose premise is "skills are markdown, no build."
- **Auto-discovered sibling groups in the linter** (group every `references/*.md` by basename, with a denylist for coincidental name clashes) instead of the hand-kept `sibling_groups` allowlist. Rejected. It would make a forgotten registration loud, but it would not have caught the case that prompted it, a tracker-resolution drift in inline prose that basename grouping never sees, and the explicit array is a readable declaration of what is guarded and why. The array is not short or rarely changed (it was touched four times in the 2026-08-30 round alone), so the allowlist stands on the first ground only.

## Consequences

- Each skill plus its declared dependencies is a portable unit: symlink those directories and the skill has everything it needs. A partial install that skips a declared dependency is the failure mode, and for `adr-format.md` it is the accepted one.
- Drift is caught mechanically: the byte-identity check fails on a fix that misses a copy.
- Format docs have to stay short and stable for this to work; a high-churn template would not survive the duplication.
- A link into a user-invoked skill's `references/` is checked by nothing but a reviewer following it, so a rename inside the owner breaks callers it never lists.
