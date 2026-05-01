# CLAUDE.md — Skills Repo

A repo of repo-agnostic Claude Code skills, symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there's no application to build, run, or deploy.

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.
- [`plans/`](plans/) — multi-phase work trackers (current: [`plans/to-x-expansion.md`](plans/to-x-expansion.md)).

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Commit order

When changes touch both an ADR and the skill that references it, commit the ADR first so reviewers see the rationale before the implementation.
