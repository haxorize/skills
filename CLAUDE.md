# CLAUDE.md — Skills Repo

A repo of Claude Code skills — repo-agnostic in mechanism, with its Domain skills carrying subject matter — symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there's no application to build, run, or deploy.

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.

## The invocation axis

Every skill is exactly one of **user-invoked** (carries `disable-model-invocation: true`, human-facing description, *orchestrates* — invisible to the model) or **model-invoked** (the default, trigger-rich description, holds a reusable *behavior* the model reaches for or an orchestrator declares via `requires:`). See `DOMAIN.md` → *Skill invocation* for the vocabulary and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md) / [ADR-0016](docs/adr/0016-behavior-skills-declared-deps-relaxed-atomicity.md) for the rationale. `write-skill` is the authoring guide that applies it; `scripts/lint-skills.sh` enforces it.

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Ported-skill upstreams

Before materially editing any skill below, diff its upstream — main *and* unmerged branches — since the last-swept point recorded in [ADR-0034](docs/adr/0034-branch-mining-lineage-or-dormant-main.md), and fold in or consciously reject what changed there. The upstream skill is named in parentheses where it differs; the rest share names.

- **mattpocock/skills** — `grilling`, `grill-me` (also grill-with-docs — merged locally), `handoff`, `write-skill` (writing-great-skills — renamed upstream to `writing-for-agents` at `1fc6573`, so `write-skill` and the ported `writing-for-agents` now diff the same upstream directory), `review-changes` (review), `which-skill` (ask-matt), `improve-design` (improve-codebase-architecture), `teach-me` (teach), `chart-course` (wayfinder), `ask-for-me` (to-questionnaire), `codebase-design`, `domain-modeling`, `diagnosing-bugs`, `implement`, `prototype`, `tdd`, `explain` (wait-what), `wizard`, `writing-for-agents`.
- **compound-engineering-plugin** — `adoption-verdict` (ce-pov), `capturing-learnings` (the learnings loop).
- **obra/superpowers** — `receiving-review` (receiving-code-review).
- **oaustegard/claude-skills** — `diverging` (generative-thinking), `verify-docs` and `doc-claims` (both from verifying-claims — the verdict table lives in `doc-claims`), `audit-tests` (gating — the audit half only).
- **openclaw/agent-skills** — `validate-behavior` (behavior-validator).
- **dmmulroy/dotfiles** — `discoverable-code` (write-discoverable-code, under `home/.agents/skills/`).

The `to-feature`/`to-story`/`to-tasks`/`to-bug` family is structurally independent of Matt's `to-prd`/`to-issues`/`to-spec`/`to-tickets` — scan those for portable ideas, never diff them as an upstream. `writing-for-humans` is a multi-source synthesis, not a port — ten sources, no single upstream to diff; [ADR-0042](docs/adr/0042-writing-for-humans-synthesized-from-writing-sources.md) records them. `work-item-shape` is likewise a synthesis — agent-armory and openai-skills ideas folded over local publisher discipline; [ADR-0044](docs/adr/0044-work-item-shape-extracted-behavior.md) records sources and rejections. Domain skills (`phi-safe-code`, `health-literacy`, `accessible-ui`) are local originals mined from the sources their admission ADRs name. `audit-skills` and `delete-dead-code` are rewrites of ECC-derived artifacts mined once from an enterprise plugin repo — not a tracked upstream, so nothing to diff; [ADR-0062](docs/adr/0062-enterprise-repo-mine-two-skills-and-ecc-lineage.md) records the lineage. `onboard-me` is written in local prose from a real, diffable source and so takes the revisit trigger: **nitfolio-nirvajna-skills**, cloned at `~/code/lib/nitfolio-nirvajna-skills`, swept at `c842141` (MIT), which supplied the fog-of-war map, the evidence tags, the stage ladder with a completion criterion per rung, and the read-only boundary; ADR-0064 records the lineage. `product-description` has no diffable upstream — it is local prose from the method in the `steveruizok` gists, whose licence is NONE-STATED, so ideas only and never their wording or templates (ADR-0065); nothing to diff. Every other skill not listed here is a local original.

## Keep the router honest

[`src/which-skill/SKILL.md`](src/which-skill/SKILL.md) is the router that maps every skill and how they relate. Whenever you add, rename, or remove a skill, or change how one fits the flows, update the router in the same change — a new skill it never mentions, or a stale one it still routes to, is a router that lies. `README.md`'s skill map is a second router under the same rule. `scripts/lint-skills.sh` catches missing mentions mechanically in both; routing and blurb accuracy stay editorial.

## Review lenses

The instruction-file lens in this repo also runs `write-skill`'s **pruning test**: for every rule the diff adds or edits, report keep / condense / move / delete, with the covering rule named for anything but keep (the rule elsewhere that already says it, or the reason nothing does). A skill-change review that never reports this ran the lens on another repo's terms.

## Landing

Landing:
- Branch policy: trunk
- PR required: no
- Push pre-authorised: yes
- Ticket close pre-authorised: no (no tracker)
- Review required: yes
- Defect policy: fix, don't file

## Commit order

When changes touch both an ADR and the skill it shapes (lineage runs ADR → skill — the ADR names the skill, never the reverse), commit the ADR first so reviewers see the rationale before the implementation.

## Linting

`bash scripts/lint-skills.sh` checks SKILL.md and reference files against the conventions in [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md) — size caps, frontmatter (description length/colon, the invocation-axis flag, `requires:` resolution), sibling-file byte-identity, the ban on skill bodies citing repo ADRs by number, reference-link resolution (inline `[text](path.md)` links only — the script header names the link forms and resolution cases it does not reach, so a clean run isn't a claim about those), router coverage (every skill mentioned in `which-skill` and in `README.md`), the two-way `requires:` check (a skill the body calls with the Skill tool is declared, and calling the Skill tool with a user-invoked skill fails outright; a declared dep is named in the body), the slash-on-model-invoked check (a `/name` naming a model-invoked skill fails, swept over `src/`, `.claude/skills/`, `DOMAIN.md`, and `README.md` — not `global/rules/` or this file), and the `global/rules/` admission check both ways (every rule carries a `Depends:` line naming at least one existing skill, and every named skill cites the rule, in the forms the script header names; the size cap and ADR-number ban sweep `global/rules/` too). Run before committing skill changes.

`bash scripts/lint-selftest.sh` runs the linter against `scripts/lint-fixtures/`, a miniature tree that is wrong on purpose, and fails if a check stops firing or starts firing on a form it should exempt. Run it after changing a check — a lint gate that quietly stopped matching looks identical to a repo with no violations.

`Review required: yes` in the Landing block above arms the `review-receipt` hook under `global/hooks/` once it is wired in `~/.claude/settings.json` (`bash scripts/install.sh` prints the snippet): a push needs a `/review-changes` report whose `Reviewed-tree:` stamp equals the tree being pushed (`/address-findings` re-stamps after its fix pass), so the order is review, fix up, commit the whole tree, push — any edit after the last stamp needs a new one. `bash global/hooks/<hook>-selftest.sh` (three hooks, three selftests) proves a hook's rules still fire — run after changing one, and run all three after changing `hook-lib.sh`, `hook-lib.py`, or `selftest-lib.sh`, which every hook and selftest shares.

`scripts/git-hooks/commit-msg` is a **git hook**, not one of the PreToolUse hooks above: it rejects a commit whose message breaks the exact rules in [`src/committing/references/commit-style.md`](src/committing/references/commit-style.md), and its own header states which those are and which it cannot see. A green run is a claim about message shape and never about register, so `commit-style.md` is not pruned against it. `bash scripts/git-hooks/commit-msg-selftest.sh` proves its rules still fire — run after changing it.

`bash scripts/security.sh --path <dir>` (or `--each <parent>`) is the heuristic injection-and-malware scan, vendored from khendzel/skills-janitor (MIT): run it over any external skill directory before reading it as instructions or installing it — it reports, never blocks. `bash scripts/security-selftest.sh` proves its rules still fire.
