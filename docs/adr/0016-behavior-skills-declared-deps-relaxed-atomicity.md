# Behavior skills, declared dependencies, and relaxed install atomicity

## Context

ADR-0015 introduces user-invoked orchestrators and model-invoked behaviors. The hybrid approach requires *extracting* shared discipline (the grilling loop, domain-modeling, the deep-module vocabulary, the feedback-loop pass) out of orchestrators that bundle it, so a single source serves multiple consumers and the model can reach for the discipline autonomously.

This collided with ADR-0007, which made each skill a self-contained atomic unit (shared **format docs** duplicated as byte-identical sibling reference files) because skills are symlinked into `~/.claude/skills/` one at a time, and an outside user might install one without the rest. [ADR-0108](0108-shared-references-have-one-owner-and-one-copy.md) has since superseded ADR-0007.

Mechanics confirmed from the Claude Code docs: there is **no hard "invoke another skill" primitive**. An orchestrator reaching a Discipline skill ("Run the `/grilling` skill") is soft and Claude-mediated, and it works only if the target is a model-invoked skill **and** installed. The symlink-per-skill model carries only a skill's own directory, so a within-repo `shared/` folder does not travel. A full plugin model *would* let a within-root shared dir resolve, since plugins cache the whole tree. It was rejected: it abandons per-skill install, Matt himself duplicates rather than sharing, and prose invocation stays soft regardless.

This repo's own `scripts/install.sh` links **all** of `src/*` (an opt-in skill per repo since [ADR-0114](0114-opt-in-skills-install-per-repo-from-a-shared-skills-line.md), where its opt-in dependencies come with it), so for the maintainer every Discipline-skill dependency is always present. ADR-0007's strict atomicity was really a *portability promise to outside cherry-pickers*.

## Decision

- **Behaviors are model-invoked skills**: `grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`, and `doc-claims`. Orchestrators reach them through prose invocation. `doc-claims` is the clearest case of the **Extraction test**: both its consumers, `/verify-docs` and the repo-local `/sweep-corpus`, are user-invoked, so neither could reach the other's judgment until it became a skill.
- **Inert format and data docs stay reference files**, because there is nothing to invoke. Each has one owner and one copy, which every other skill reads by installed path, per ADR-0108. Reading another skill's reference is not a dependency and is never declared.
- **The atomic unit is "a skill plus its declared Discipline-skill dependencies"**, not a lone skill. An orchestrator names the Discipline skills it requires in a frontmatter `requires:` line, and `scripts/install.sh` resolves and links those dependencies when it links the orchestrator.
- **A skill may run a script at the root of the repo its installed entry links out of**, resolved by `readlink` at run time rather than by `install.sh`. `audit-skills` runs `scripts/skill-usage.sh` this way, `retro`'s `digest.py` runs the same script from the checkout it resolves with `realpath`, and `adoption-verdict`, `upgrade-deps` and `write-skill` run `scripts/security.sh --path <dir>`. Each such skill's text says the step cannot run when the skill is linked alone.
- **No plugin migration.** Per-skill symlink install stays.

## Considered Options

- **Sibling reference files for Discipline skills too** (extract the grilling loop and the rest as duplicated `references/*.md`): rejected, because a reference file is inert text that the model cannot reach autonomously, so we would lose autonomous grilling and passive glossary upkeep.
- **Full plugin model** (one `plugin.json`, install as a unit, a shared dir, prose dependencies everywhere): rejected, because it abandons cherry-pick portability for a sharing mechanism Matt declines to use anyway.
- **Behaviors as skills, declared dependencies, and relaxed atomicity**: chosen.

## Consequences

- The portable unit is "skill plus declared dependencies". `scripts/install.sh` resolves dependencies, and `scripts/lint-skills.sh` checks that each declared dependency exists and is model-invoked.
- Cross-skill invocation is **soft**: an orchestrator cannot *guarantee* a Discipline skill runs, only instruct Claude to reach for it. That is acceptable, since it is the only mechanism available.
- A skill linked by hand alone loses two things: a reference it reads from another skill's directory, which ADR-0108 accepts, and a repo-root script step. The portability promise to outside cherry-pickers narrows by exactly those skills.
