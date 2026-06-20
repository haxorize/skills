# CLAUDE.md — Skills Repo

A repo of repo-agnostic Claude Code skills, symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there's no application to build, run, or deploy.

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.

## The invocation axis

Every skill is exactly one of **user-invoked** (carries `disable-model-invocation: true`, human-facing description, *orchestrates* — invisible to the model) or **model-invoked** (the default, trigger-rich description, holds a reusable *behavior* the model reaches for or an orchestrator declares via `requires:`). This split is the spine of the suite: it decides the description style, whether the skill can be prose-invoked, and which section of the README it lands in. See `DOMAIN.md` → *Skill invocation* for the vocabulary and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md) / [ADR-0016](docs/adr/0016-behavior-skills-declared-deps-relaxed-atomicity.md) for the rationale. `write-skill` is the authoring guide that applies it; `scripts/lint-skills.sh` enforces it.

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Commit order

When changes touch both an ADR and the skill that references it, commit the ADR first so reviewers see the rationale before the implementation.

## Linting

`bash scripts/lint-skills.sh` checks SKILL.md and reference files against the size caps and frontmatter conventions in [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md). Run before committing skill changes.
