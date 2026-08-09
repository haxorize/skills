# Behavior skills, declared dependencies, and relaxed install atomicity

## Context

ADR-0015 introduces user-invoked orchestrators and model-invoked behaviors. The hybrid approach requires *extracting* shared discipline (the grilling loop, domain-modeling, the deep-module vocabulary, the feedback-loop pass) out of orchestrators that bundle it, so a single source serves multiple consumers and the model can reach for the discipline autonomously.

This collides with ADR-0007, which made each skill a self-contained atomic unit (shared **format docs** duplicated as byte-identical sibling reference files) precisely because skills are symlinked into `~/.claude/skills/` one at a time, and an outside user might install one without the rest.

Mechanics confirmed from the Claude Code docs: there is **no hard "invoke another skill" primitive** — an orchestrator reaching a behavior ("Run the `/grilling` skill") is soft, Claude-mediated, and works only if the target is a model-invoked skill **and** installed. The symlink-per-skill model carries only a skill's own directory; a within-repo `shared/` folder does not travel. (A full plugin model *would* let a within-root shared dir resolve, since plugins cache the whole tree — but that abandons per-skill install, Matt himself duplicates rather than sharing, and prose invocation stays soft regardless. Rejected.)

This repo's own `scripts/install.sh` already links **all** of `src/*`, so for the maintainer every behavior dependency is always present. ADR-0007's strict atomicity is really a *portability promise to outside cherry-pickers*.

## Decision

- **Behaviors** become **model-invoked skills**: `grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`. Orchestrators reach them via prose invocation.
- **Inert format/data docs stay sibling reference files** under ADR-0007 (`domain-format.md`, `adr-format.md`, `tracker-resolution.md`, `naming-drift-queue.md`) — there is nothing to "invoke," and lint keeps the copies byte-identical.
- **Relax ADR-0007's atomic unit** from "a lone skill" to **"a skill plus its declared behavior dependencies."** An orchestrator names the model-invoked behaviors it requires (frontmatter or a `## Notes` line); `scripts/install.sh` resolves and links those deps when it links the orchestrator.
- **No plugin migration.** Per-skill symlink install stays.

## Considered Options

- **Sibling reference files for behaviors too** (extract the grilling loop etc. as duplicated `references/*.md`) — rejected: a reference file is inert text and cannot be reached autonomously by the model, so we'd lose autonomous grilling and passive glossary upkeep.
- **Full plugin model** (one `plugin.json`, install-as-unit, a shared dir, prose deps everywhere) — rejected: abandons cherry-pick portability for a sharing mechanism Matt declines to use anyway.
- **Behaviors→skills + declared deps + relaxed atomicity** (chosen).

## Consequences

- **Amends ADR-0007:** the portable unit is now "skill + declared deps"; format-doc duplication is unchanged. (ADR-0007 to carry an amendment note pointing here.)
- `scripts/install.sh` gains dependency resolution; `scripts/lint-skills.sh` may verify declared deps resolve, and adds `adr/references/adr-format.md` to the `adr-format.md` sibling group.
- Sibling-ref groups **re-pair** but do not fully collapse: e.g. `domain-format.md` moves from `{grill-and-record, harden-domain}` to `{grill-and-record, domain-modeling}` (harden-domain delegates to domain-modeling and drops its copy; grill-and-record keeps an inline copy to protect grill rhythm, exactly as it already refuses to delegate to `/adr`).
- Cross-skill invocation is **soft** — an orchestrator cannot *guarantee* a behavior runs, only instruct Claude to reach for it. Acceptable; it is the only mechanism available and matches Matt's.
- The four `to-*` publishers cannot collapse their `tracker-resolution.md` / `naming-drift-queue.md` groups this way (all four are user-invoked and cannot invoke each other); those stay sibling refs unless a separate model-invoked tracker subroutine is later extracted.

## Amendments

- **2026-06-21 (see ADR-0020)** — The consequence above that `grill-and-record` "keeps an inline copy to protect grill rhythm (the same reason it already declines to delegate to `adr`)" is partially reversed. That reasoning conflated a **background-lens behavior** (`domain-modeling`, which runs interleaved inside the grill loop with no control transfer) with a **gated action** (`/adr`'s offer→confirm→write, which does interrupt). `grill-and-record` now delegates the glossary discipline *and* the ADR offer-gate to `domain-modeling` (a second load-bearing declared dependency) and inlines only the ADR **write**. Its `references/domain-format.md` copy is dropped — the `{grill-and-record, domain-modeling}` `domain-format.md` group collapses to a single home and leaves `scripts/lint-skills.sh`. The `adr-format.md` group is unchanged.
- **2026-08-09 (see [ADR-0048](0048-naming-drift-queue-trimmed-to-check-only.md))** — The consequence above that the `tracker-resolution.md` / `naming-drift-queue.md` groups "stay sibling refs unless a separate model-invoked tracker subroutine is later extracted" is half overtaken: the `naming-drift-queue.md` group dissolves by removal, not extraction — a usage audit kept the publish-time drift check and deleted the durable queue outright. `tracker-resolution.md` stays a sibling group as stated.
