# CLAUDE.md — Skills Repo

A repo of repo-agnostic Claude Code skills, symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there's no application to build, run, or deploy.

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.

## The invocation axis

Every skill is exactly one of **user-invoked** (carries `disable-model-invocation: true`, human-facing description, *orchestrates* — invisible to the model) or **model-invoked** (the default, trigger-rich description, holds a reusable *behavior* the model reaches for or an orchestrator declares via `requires:`). See `DOMAIN.md` → *Skill invocation* for the vocabulary and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md) / [ADR-0016](docs/adr/0016-behavior-skills-declared-deps-relaxed-atomicity.md) for the rationale. `write-skill` is the authoring guide that applies it; `scripts/lint-skills.sh` enforces it.

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Commit order

When changes touch both an ADR and the skill it shapes (lineage runs ADR → skill — the ADR names the skill, never the reverse), commit the ADR first so reviewers see the rationale before the implementation.

## Linting

`bash scripts/lint-skills.sh` checks SKILL.md and reference files against the conventions in [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md) — size caps, frontmatter (description length/colon, the invocation-axis flag, `requires:` resolution), sibling-file byte-identity, and the ban on skill bodies citing repo ADRs by number. Run before committing skill changes.
