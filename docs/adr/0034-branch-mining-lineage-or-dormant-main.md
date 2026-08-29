# Mine unmerged branches only for direct lineage or dormant main

The 2026-07-19 branch-coverage audit of the mined repos under `~/code/lib` found sweep coverage complete on every main tip but untested on unmerged branches — where real material was hiding (wayfinder's research-inline redesign, adopted in part into `chart-course`). Standing policy for future sweeps: read a repo's unmerged branches only when (a) the repo is the direct upstream of a ported skill (wayfinder → `chart-course`, ce-pov → `adoption-verdict`), or (b) main is dormant and branches carry the only delta (how superpowers' `tdd-writing-good-tests` material was found); otherwise sweeps are main-only. Exhaustive branch mining was rejected as disproportionate — unreleased WIP hasn't survived its own author's merge bar, and compound-engineering-plugin alone carries 499 unmerged branches — and pure main-only was rejected because it demonstrably missed the wayfinder material.

## Consequences

CLAUDE.md carries the revisit trigger: materially editing a ported skill starts with an upstream diff — main and branches — since the last-swept point. As of this ADR: wayfinder at main `9603c1c` (branches audited 2026-07-19), ce-pov at main `4927d7a1` (superseded; the newest dated entry under Amendments is the live ledger).

## Amendments

**2026-07-20** — `chart-course` edited under [ADR-0035](0035-ticket-names-the-assignable-tier.md) (terminology only: its tickets defined as the Charting sub-type of the new **Ticket** term). Upstream diff waived: wayfinder was swept the day before and the edit carries no behavioral delta.

**2026-07-20** — The CLAUDE.md revisit trigger now enumerates the full ported-skill lineage rather than the two examples this ADR named: seventeen skills from mattpocock/skills (main `9603c1c`, branches audited 2026-07-19 — wayfinder's repo), `adoption-verdict` and `capturing-learnings` from compound-engineering-plugin (main `4927d7a1`), `receiving-review` from obra/superpowers (main `d884ae0`, dormant since 2026-07-02; unmerged branches swept 2026-07-19), and `diverging` + `verify-docs` from oaustegard/claude-skills (main `7dea9c8`; 14 unmerged branches triaged into standing reject classes 2026-07-19). The policy itself is unchanged — those two were always examples, not the scope.

**2026-08-09** — Swept points refreshed; the 2026-07-20 ledger above is superseded by this one, which covers all five upstreams. The points are the tips of the mined checkouts under `~/code/lib` at the 2026-08-07/08 rounds:

- mattpocock/skills at `84fdeff` (2026-08-06; the 2026-08-07 spot-check found a flatten refactor only, no content changes)
- compound-engineering-plugin at `0a295785` (2026-08-06)
- obra/superpowers at `44c9b2d` (2026-07-27)
- oaustegard/claude-skills at `61a85b8` (2026-08-08) — now also the upstream of `audit-tests`, ported from `gating`'s audit half in the 2026-08-08 round
- openclaw/agent-skills at `2a409d3` (2026-08-02) — upstream of `black-box-check`, and absent from every earlier entry in this ledger

**2026-08-22** — Swept points refreshed at the 2026-08-21 round (ledger Part B; every SHA is the tip of the checkout under `~/code/lib` and resolves with `git cat-file -t`); this ledger supersedes the 2026-08-09 one:

- mattpocock/skills at `5b15a47` (2026-08-21; 34 commits since `84fdeff`, nine unmerged branches read, nothing portable) — `grill-and-record` is now a one-window stub of `grill-me`, so the grill-with-docs lineage ends there
- compound-engineering-plugin at `66ccf57` (2026-08-20; 118 commits, branches carried nothing beyond main)
- obra/superpowers at `b36e082` (2026-08-12; one commit, still dormant)
- oaustegard/claude-skills at `66ec85b` (2026-08-21; 37 commits, the three ported skills byte-unchanged)
- openclaw/agent-skills at `128a4ea` (2026-08-21; 25 commits) — upstream of `validate-behavior`, the skill this ledger's 2026-08-09 entry knew as `black-box-check`
- dmmulroy/dotfiles at `a7beb72` (2026-08-20; 12 commits) — upstream of `discoverable-code`, absent from every earlier entry; modem-dev/skills is an md5-identical mirror of its `write-discoverable-code` and is never diffed again
- jakubkrehel/skills at `6c43b20` (2026-08-20; range `d01493b..6c43b20`, 41 commits) — not a lineage upstream; recorded because the `after` SHA the round's plan wrote down did not resolve, and this is the `main` tip actually mined

**2026-08-22, correction** — Two lines above, read as written at `e913c39`: `grill-and-record` is a deprecation stub of `grill-me` ([ADR-0058](0058-grill-me-absorbs-grill-and-record.md)) whose revisit trigger is waived for the stub's window, so "the lineage ends there" means the port, not the upstream; and dmmulroy/dotfiles' twelve commits are counted since `aae3dd3`, the tip at the 2026-08-14 port.

**2026-08-26** — The stub's window closed and `src/grill-and-record/` is deleted ([ADR-0058](0058-grill-me-absorbs-grill-and-record.md)'s amendment of this date), so the correction above has outlived its subject and the waiver it granted is spent. The grill-with-docs lineage attaches to `grill-me` from here: `grill-me` diffs both upstream directories, and the mattpocock/skills line's "the lineage ends there" no longer names a live skill. The swept point is unchanged at `5b15a47` — this reassigns ownership of a directory, not the range.

**2026-08-27** — Swept points refreshed at the 2026-08-27 round (ledger Part B; copied verbatim from `~/code/lib/_rounds/2026-08-27/mine-2026-08-27-delta-lineage-a.md` § Swept points and `~/code/lib/_rounds/2026-08-27/mine-2026-08-27-delta-ce.md` § Swept point); this ledger supersedes the 2026-08-22 one:

- mattpocock/skills at `6654f6b` (2026-08-24; 3 commits since `5b15a47`, all the `retro` stub graduating from `stub/retro-skill` into `skills/in-progress/`; 101 remote branches, `git log --since=2026-08-21` empty on every unmerged branch except the bot `changeset-release/main`; `setup-skill-and-vague-prose` — 50 unmerged, tip `70653e1` of 2026-04-28, absent from the 2026-08-21 nine — predates every local port and was not read; no ported directory changed)
- obra/superpowers at `b36e082` (unchanged since 2026-08-12; 112 branches fetched at depth 20, none with a commit since 2026-08-21)
- oaustegard/claude-skills at `04bfd5b` (2026-08-25; 22 commits; `generative-thinking` and `verifying-claims` byte-unchanged, `gating` +26 lines — description and a "When NOT" table, nothing folded; the new `declaring-invariants` is the source of the two ADAPT rows into `tdd` and `audit-tests`)
- openclaw/agent-skills at `52b1a0a` (2026-08-26; one test-only commit in `autoreview`; `behavior-validator` unchanged)
- dmmulroy/dotfiles at `a6d5117` (2026-08-24; 2 commits; `write-discoverable-code` unchanged; the ten changed skills are Pocock forks re-punctuated, nothing folded)
- compound-engineering-plugin at `5985d82` (2026-08-26; 34 commits since `66ccf57`; **the ported `ce-pov` directory did change in range — its hunks were read and consciously REJECTED in the round's delta report, so the next editor of `adoption-verdict` diffs from `5985d82` knowing the intervening change was seen, not missed**; the `learnings` loop unchanged; branches: read — 10 post-08-20 branches touching ce-pov / compound / ce-skill-work checked, all pre-squash forms of commits inside the range; nothing beyond main)

Not re-swept, and carried forward from the superseded ledger rather than dropped: jakubkrehel/skills at `6c43b20` (2026-08-20) — not a lineage upstream, recorded because the `after` SHA the 2026-08-21 plan wrote down did not resolve and this is the `main` tip actually mined. It is not in the six above because it has no ported directory to diff; the SHA is kept so the next miner does not repeat the unresolved-SHA hunt.

Also for the lineage record: `modem-dev-skills` unchanged at `edcdedb`, byte-identical to dmmulroy's `write-discoverable-code` (A22.1 "record as mirror; never diff again" stands).

**2026-08-29** — A lineage entry for a script rather than a skill: `scripts/security.sh` gained eight rule classes in the 2026-08-27 round's batch 9 (hex blob, drop site, download-then-exec, minified line, `.npmrc`, install-time manifest hook, compiled binary, remote instructions), rewritten from the pattern list in the sweep skill of **openhonest/honest-skills** (`~/code/lib/openhonest-honest-skills`, tip `2397865`, 2026-08-25, Apache-2.0 — the scanner's header said MIT until the 2026-08-29 review's fix pass; the ledger of that round had it right). The swept point is recorded here and the source named in `CLAUDE.md` § *Ported-skill upstreams* so the diff-before-editing trigger can fire on the rules; nothing was ported as prose, so no skill body carries the lineage.

**2026-08-29** — `nitfolio-nirvajna-skills` enters this ledger, which it had never been in. It has fed three skills since 2026-08-27 — `onboard-me` ([ADR-0064](0064-onboard-me-read-only-kt-session.md)), `rebuild-contract` ([ADR-0069](0069-rebuild-contract-pre-rewrite-contract-in-repo.md)), and `offboard-me` ([ADR-0070](0070-offboard-me-handover-in-repo-human-as-evidence.md)) — with its swept point recorded only in `CLAUDE.md` prose and in those records' *Sources* sections, so a sweep enumerating this ledger omitted it silently. Swept at **`c842141`** (**MIT**, `~/code/lib/_rounds/2026-08-27/licences.tsv:52`; the 2026-08-27 batch plan's NONE-STATED attribution was wrong and binds the `steveruizok` gists instead, as [ADR-0065](0065-product-description-model-invoked-not-onboard-me-phase-0.md) records). Cloned at `~/code/lib/nitfolio-nirvajna-skills`. Branches were not audited at the sweep; the next editor of any of the three diffs from `c842141` on main and audits branches then. `evaluation-ledger` ([ADR-0071](0071-evaluation-ledger-multi-week-evaluation-in-repo.md)) is genuinely local and takes no trigger.

