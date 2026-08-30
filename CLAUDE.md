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
- **openhonest/honest-skills** — not a skill but `scripts/security.sh`'s eight 2026-08-29 rule classes (its header names them), rewritten from that repo's sweep skill's pattern list; cloned at `~/code/lib/openhonest-honest-skills`, swept at `2397865` (Apache-2.0). Diff the sweep skill's patterns, not a skill body, before materially editing those rules.

The `to-feature`/`to-story`/`to-tasks`/`to-bug` family is structurally independent of Matt's `to-prd`/`to-issues`/`to-spec`/`to-tickets` — scan those for portable ideas, never diff them as an upstream. `writing-for-humans` is a multi-source synthesis, not a port — ten sources, no single upstream to diff; [ADR-0042](docs/adr/0042-writing-for-humans-synthesized-from-writing-sources.md) records them. `work-item-shape` is likewise a synthesis — agent-armory and openai-skills ideas folded over local publisher discipline; [ADR-0044](docs/adr/0044-work-item-shape-extracted-behavior.md) records sources and rejections. Domain skills (`phi-safe-code`, `health-literacy`, `accessible-ui`) are local originals mined from the sources their admission ADRs name. `audit-skills` and `delete-dead-code` are rewrites of ECC-derived artifacts mined once from an enterprise plugin repo — not a tracked upstream, so nothing to diff; [ADR-0062](docs/adr/0062-enterprise-repo-mine-two-skills-and-ecc-lineage.md) records the lineage. `onboard-me`, `rebuild-contract` and `offboard-me` are written in local prose from one real, diffable source and so take the revisit trigger: **nitfolio-nirvajna-skills**, cloned at `~/code/lib/nitfolio-nirvajna-skills`, swept at `c842141` (MIT). It supplied `onboard-me`'s fog-of-war map, evidence tags, stage ladder with a completion criterion per rung, and read-only boundary (ADR-0064); `rebuild-contract`'s observer-and-fidelity boundary, inclusion test, two tag axes, behavior index as denominator, stable IDs, scope-down rule, section spine, and self-audit (ADR-0069); and `offboard-me`'s inversion, SCAN → RANK → ASK loop, five evidence tags, seven-rung ladder, five-section register, and eleven signals (ADR-0070). The two later records each keep two formulations close to the source's wording, which is why the MIT attribution belongs here and not only in ADR prose. `product-description` has no diffable upstream — it is local prose from the method in the `steveruizok` gists, whose licence is NONE-STATED, so ideas only and never their wording or templates (ADR-0065); nothing to diff. Every other skill not listed here is a local original.

## Keep the router honest

[`src/which-skill/SKILL.md`](src/which-skill/SKILL.md) is the router that maps every skill and how they relate. Whenever you add, rename, or remove a skill, or change how one fits the flows, update the router in the same change — a new skill it never mentions, or a stale one it still routes to, is a router that lies. `README.md`'s skill map is a second router under the same rule. `scripts/lint-skills.sh` catches missing mentions mechanically in both; routing and blurb accuracy stay editorial.

## Review lenses

The instruction-file lens in this repo also runs a **pruning test** against the pruning grounds in [`src/writing-for-agents/SKILL.md`](src/writing-for-agents/SKILL.md): for every rule the diff adds or edits, report keep / condense / move / delete, with the covering rule named for anything but keep (the rule elsewhere that already says it, or the reason nothing does). A skill-change review that never reports this ran the lens on another repo's terms.

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

**Where the record quotes its own implementation, the pair is one commit.** A record that states a count, a command's output, or a behaviour the same change produces would be false at an ADR-first commit, and the evidence rule — a claim carries its evidence, and a count states the command it was run with — outranks the reading order here. So: ADR first where the record does not cross-quote; ADR and implementation together where it does, with the record's own claims true at the commit that carries them. The ordering serves the reviewer; a record that is wrong when they read it serves nobody.

## Linting

`bash scripts/lint-skills.sh` checks the skill tree against the conventions in [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md) — size caps, frontmatter and the invocation axis, the shared-trigger-phrase check, sibling-file byte-identity, reference-link resolution, router coverage in both routers, `requires:` both ways, the slash-on-model-invoked check, the `global/rules/` admission check, the evaluation ledger's stored-status vocabulary as three checks (one legend defining three statuses, a stored-status rule defining the same set, and any other file that enumerates the vocabulary carrying all of it — each reachable on its own, so a legend problem does not suppress the consumer sweep, and the two prose anchors pin each other so rewording either fails rather than standing the checks down), and the two selftest-pairing checks. `bash scripts/lint-skills.sh --help` prints the check roster and the exit codes, read out of the script's own header so the two cannot drift; each check's scope — what it deliberately does not reach, so a clean run is not read as more than it is — is written beside it in that header. Run the linter before committing skill changes.

`bash scripts/lint-adrs.sh` checks `docs/adr/` against [`adr-format.md`](src/adr/references/adr-format.md)'s two-way rules — unique numbers, supersession links that resolve and link back, the forward pointer on every record an amend mention names (in the link, bold, and unlinked prose forms — its header lists what a pass does not cover), `Revisit when:` lines with text, settled `## Deferred` lines pointing at a dated amendment, corrected `## Consequences` bullets pointing at one, and every `](NNNN-*.md)` cross-reference resolving to a record that exists; `--help` for its exit codes. ADR-0068 records the linter decision; [ADR-0074](docs/adr/0074-corrected-consequence-marker-and-check.md) the corrected-Consequences convention. Run `lint-adrs.sh` after touching a record; run `bash scripts/lint-adrs-selftest.sh` after touching a check — it grades every check both ways against `scripts/lint-fixtures/adr/` and `scripts/lint-fixtures-clean/adr/`, and never reads `docs/adr/`.

`bash scripts/skill-usage.sh` prints, per skill, how often a human typed `/name` (`~/.claude/history.jsonl`) and how often the model loaded it (the assistant `Skill` tool_use block in every transcript under `~/.claude/projects/`), over a window (`--help` for the flags). A `+` after a figure marks it a floor — a file on that side did not fully parse, and the run exits 2 — and the counts are the running machine's alone. This is the count `audit-skills`' Usage read and every window record take from a run, never from recall. `bash scripts/skill-usage-selftest.sh` grades the counted and the ignored shapes against `scripts/lint-fixtures/usage/`.

`bash scripts/lint-skills-selftest.sh` runs the linter against four kinds of root: `scripts/lint-fixtures/`, a miniature tree that is wrong on purpose; `scripts/lint-fixtures-clean/`, its mirror that is right on purpose and must exit 0; throwaway copies of the clean tree with exactly one edit each, for branches whose effect is on the exit status rather than the output; and throwaway copies of both trees with one file made unreadable. It fails if a *covered* check stops firing or starts firing on a form it should exempt — its own header carries the NOT-covered list, and that list is the authority: several checks can be disabled outright with the selftest still green. It has a third outcome besides pass and fail: where a throwaway root cannot be built, an induced edit matches nothing, or a broken mode does not take (root, or a filesystem that ignores modes), it prints `SELFTEST PARTIAL` and **exits 2** — a third status, distinct from 0 and from a failure's 1, so a caller reading the status alone can still tell a narrower clean from a whole one. Every `scripts/*-selftest.sh` sources `scripts/selftest-lib.sh` for its matcher and that three-state close, so the wording of a `SELFTEST FAIL` line has one home. Run it after changing a check — a lint gate that quietly stopped matching looks identical to a repo with no violations. `bash scripts/wizard-template-selftest.sh` grades the library half of `src/wizard/template.sh` the same way, since nothing else runs that file.

`scripts/git-hooks/post-merge` derives its gate roster from that `<script>-selftest.sh` pairing (plus the two linters, which it names), so a script under `scripts/` is gated the moment its selftest exists — and `lint-skills.sh` fails one that lacks it. Both walks stop at `scripts/`: a skill-private script under `.claude/skills/*/scripts/` (today `mine-skills`' `enum.sh`) is reached by no gate. `bash scripts/git-hooks/post-merge-selftest.sh` proves the loop runs every gate whatever the one before it returned, reads all three statuses, and reaches the re-hoist.

`Review required: yes` in the Landing block above arms the `review-receipt` hook under `global/hooks/` once it is wired in `~/.claude/settings.json` (`bash scripts/install.sh` prints the snippet): a push needs a `/review-changes` report whose `Reviewed-tree:` stamp equals the tree being pushed (`/address-findings` re-stamps after its fix pass), so the order is review, fix up, commit the whole tree, push — any edit after the last stamp needs a new one. `bash global/hooks/<hook>-selftest.sh` proves a hook's rules still fire — one selftest per hook, which `lint-skills.sh` enforces; run it after changing the hook, and run every one after changing `hook-lib.sh`, `hook-lib.py`, or `selftest-lib.sh`, which every hook and selftest shares.

`scripts/git-hooks/commit-msg` is a **git hook**, not one of the PreToolUse hooks above: it rejects a commit whose message breaks the exact rules in [`src/committing/references/commit-style.md`](src/committing/references/commit-style.md), and its own header states which those are and which it cannot see. A green run is a claim about message shape and never about register, so `commit-style.md` is not pruned against it. `bash scripts/git-hooks/commit-msg-selftest.sh` proves its rules still fire — run after changing it.

`bash scripts/security.sh --path <dir>` (or `--each <parent>`) is the heuristic injection-and-malware scan (its header lists the rule classes, their lineage, and what a PASS does not cover): run it over any external skill directory before reading it as instructions or installing it — it reports, never blocks, and an incomplete scan (a file past its size cap, one it could not open) is a finding rather than a PASS. `bash scripts/security-selftest.sh` reads the rule roster out of the scanner and proves every rule still fires on the injected fixture and stays quiet on the clean one, and that every shipped skill still passes.
