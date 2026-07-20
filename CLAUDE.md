# CLAUDE.md — Skills Repo

A repo of repo-agnostic Claude Code skills, symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there's no application to build, run, or deploy.

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.

## The invocation axis

Every skill is exactly one of **user-invoked** (carries `disable-model-invocation: true`, human-facing description, *orchestrates* — invisible to the model) or **model-invoked** (the default, trigger-rich description, holds a reusable *behavior* the model reaches for or an orchestrator declares via `requires:`). See `DOMAIN.md` → *Skill invocation* for the vocabulary and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md) / [ADR-0016](docs/adr/0016-behavior-skills-declared-deps-relaxed-atomicity.md) for the rationale. `write-skill` is the authoring guide that applies it; `scripts/lint-skills.sh` enforces it.

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Ported-skill upstreams

Before materially editing any skill below, diff its upstream — main *and* unmerged branches — since the last-swept point recorded in [ADR-0034](docs/adr/0034-branch-mining-lineage-or-dormant-main.md), and fold in or consciously reject what changed there. The upstream skill is named in parentheses where it differs; the rest share names.

- **mattpocock/skills** — `grilling`, `grill-me`, `grill-and-record` (grill-with-docs), `handoff`, `write-skill` (writing-great-skills), `review-changes` (review), `which-skill` (ask-matt), `improve-design` (improve-codebase-architecture), `teach-me` (teach), `chart-course` (wayfinder), `ask-for-me` (to-questionnaire), `codebase-design`, `domain-modeling`, `diagnosing-bugs`, `implement`, `prototype`, `tdd`.
- **compound-engineering-plugin** — `adoption-verdict` (ce-pov), `capturing-learnings` (the learnings loop).
- **obra/superpowers** — `receiving-review` (receiving-code-review).
- **oaustegard/claude-skills** — `diverging` (generative-thinking), `verify-docs` (verifying-claims).

The `to-feature`/`to-story`/`to-tasks`/`to-bug` family is structurally independent of Matt's `to-prd`/`to-issues`/`to-spec`/`to-tickets` — scan those for portable ideas, never diff them as an upstream. Every skill not listed here is a local original.

## Keep the router honest

[`src/which-skill/SKILL.md`](src/which-skill/SKILL.md) is the router that maps every skill and how they relate. Whenever you add, rename, or remove a skill, or change how one fits the flows, update the router in the same change — a new skill it never mentions, or a stale one it still routes to, is a router that lies. `scripts/lint-skills.sh` catches missing mentions mechanically; routing accuracy stays editorial.

## Commit order

When changes touch both an ADR and the skill it shapes (lineage runs ADR → skill — the ADR names the skill, never the reverse), commit the ADR first so reviewers see the rationale before the implementation.

## Linting

`bash scripts/lint-skills.sh` checks SKILL.md and reference files against the conventions in [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md) — size caps, frontmatter (description length/colon, the invocation-axis flag, `requires:` resolution), sibling-file byte-identity, the ban on skill bodies citing repo ADRs by number, and router coverage (every skill mentioned in `which-skill`). Run before committing skill changes.
