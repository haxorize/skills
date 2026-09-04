# Lineage

A row here is a skill or scanner rule with a lineage other than local original. Anything else about an upstream — why it was admitted, what was rejected — goes to its ADR. **Every skill not listed is a local original with nothing to diff against**; the rows in the second table are listed for attribution only. A skill or a script may hold a row in both tables where it has more than one upstream — `receiving-review` and `scripts/security.sh` do, as do the skills [ADR-0082](adr/0082-batch-family-4a-4f-admissions-2026-09-04.md)'s rows name — and the first table's row is what the pre-commit lineage notice fires on, for a staged `src/<skill>/` path only; a staged `scripts/` path draws no notice, so for a scanner rule `CLAUDE.md`'s read-this-file-first line is the whole guard.

Before materially editing anything in the first table, diff its upstream — main *and* unmerged branches — from the swept point recorded against that upstream in [ADR-0034](adr/0034-branch-mining-lineage-or-dormant-main.md)'s amendment ledger (the newest entry for an upstream supersedes the rest), and fold in or consciously reject what changed there. Clones live under `~/code/lib/<owner>-<repo>` on the machine that mined them; the license column is read from each clone's license file.

**A renamed skill keeps its old name in the ADRs that recorded it.** An ADR is the record as it landed and amendments never rewrite it, so a decision record naming a retired skill or path is history, not a stale reference — the `(until <date> <old-name>)` annotation in the Local column below is how a reader joins the two. What a rename *does* owe the record is a `> **Amended by [ADR-NNNN](…)** ` pointer above the first heading of every ADR whose decision it reversed, which is what `scripts/lint-adrs.sh`'s `check_forward_pointer` looks for and cannot see when the amending entry sits inside the amending record's own `## Amendments` log.

## Ported — diff before editing

| Local | Upstream | Name there | License | Record |
| --- | --- | --- | --- | --- |
| `grilling`, `handoff`, `codebase-design`, `domain-modeling`, `diagnosing-bugs`, `implement`, `prototype`, `tdd`, `wizard`, `writing-for-agents` | mattpocock/skills | same name | MIT | ADR-0034 |
| `grill-me` | mattpocock/skills | `grill-me`, and `grill-with-docs` (merged locally; both directories diffed) | MIT | ADR-0058 |
| `write-skill` | mattpocock/skills | `writing-great-skills`, renamed upstream to `writing-for-agents` at `1fc6573`, so `write-skill` and the ported `writing-for-agents` diff the same directory | MIT | ADR-0040 |
| `review-changes` | mattpocock/skills | `review` | MIT | ADR-0034 |
| `which-skill` | mattpocock/skills | `ask-matt` | MIT | ADR-0034 |
| `review-architecture` (until 2026-08-30 `improve-design`) | mattpocock/skills | `improve-codebase-architecture` | MIT | ADR-0034 |
| `teach-me` | mattpocock/skills | `teach` | MIT | ADR-0034 |
| `chart-course` | mattpocock/skills | `wayfinder` | MIT | ADR-0028 |
| `ask-for-me` | mattpocock/skills | `to-questionnaire` | MIT | ADR-0034 |
| `explain` | mattpocock/skills | `wait-what` | MIT | ADR-0043 |
| `adoption-verdict` | compound-engineering-plugin (clone `everyinc-compound-engineering-plugin`) | `ce-pov` | MIT | ADR-0032 |
| `capturing-learnings` | compound-engineering-plugin | the learnings loop | MIT | ADR-0025 |
| `receiving-review` | obra/superpowers | `receiving-code-review` | MIT | ADR-0034 |
| `diverging` | oaustegard/claude-skills | `generative-thinking` | MIT | ADR-0031 |
| `verify-docs`, `doc-claims` | oaustegard/claude-skills | `verifying-claims` (the verdict table lives in `doc-claims`) | MIT | ADR-0034 |
| `audit-tests` | oaustegard/claude-skills | `gating` — the audit half only | MIT | ADR-0034 |
| `validate-behavior` | openclaw/agent-skills | `behavior-validator` | MIT | ADR-0041 |
| `discoverable-code` | dmmulroy/dotfiles | `write-discoverable-code`, under `home/.agents/skills/` (modem-dev/skills is a byte-identical mirror, never diffed) | none stated | ADR-0050 |
| `onboard-me` | nitfolio/nirvajna-skills (clone `nitfolio-nirvajna-skills`) | fog-of-war map, evidence tags, stage ladder, read-only boundary | MIT | ADR-0064 |
| `rebuild-contract` | nitfolio/nirvajna-skills (clone `nitfolio-nirvajna-skills`) | observer-and-fidelity boundary, inclusion test, two tag axes, behavior index, stable IDs, scope-down rule, section spine, self-audit | MIT | ADR-0069 |
| `offboard-engineer` (until 2026-08-30 `offboard-me`) | nitfolio/nirvajna-skills (clone `nitfolio-nirvajna-skills`) | inversion, SCAN → RANK → ASK loop, five evidence tags, seven-rung ladder, five-section register, eleven signals | MIT | ADR-0070 |
| `scripts/security.sh` — hex blob, drop site, download-then-exec, minified line, `.npmrc`, install-time manifest hook, compiled binary, remote instructions | zcaceres/skills (clone `zcaceres-skills`) | `skills/investigate-repo/SKILL.md`'s pattern list; diff its patterns, not a skill body (attributed to openhonest/honest-skills until 2026-09-04 — ADR-0034's entry of that date) | MIT | ADR-0073 |
| `scripts/security.sh` — `sh-imds`, `sh-agentcfg`, `sh-persist`, `sh-noverify`, `sh-envdump`, `uni-confusable`, `bin-bytecode` | nvidia/skillspector and DataDog/guarddog | their pattern classes; the homoglyph table is the scanner's own | Apache-2.0 | ADR-0075 |
| `scripts/security.sh` — `inj-obfuscated` | nvidia/skillspector | its concealed-instruction class (spaced letters, a declared marker, entity encoding); the normalization is the scanner's own | Apache-2.0 | ADR-0081 |

The three nitfolio rows are written in local prose from one diffable upstream — ADR-0034 spells it by its clone directory, which is the form to grep there — and each keeps two formulations close to the upstream's wording — which is why the MIT attribution lives here and not only in the records.

## Synthesized or ideas only — nothing to diff

| Local | Upstream | Rule | Record |
| --- | --- | --- | --- |
| `to-feature`, `to-story`, `to-tasks`, `to-bug` | mattpocock/skills' `to-prd`, `to-issues`, `to-spec`, `to-tickets` | structurally independent: scan for portable ideas, never diff as an upstream | ADR-0009 |
| `writing-for-humans` | ten origins, named in the record | a synthesis with no single upstream | ADR-0042 |
| `work-item-shape` | agent-armory, openai-skills | ideas folded over local publisher discipline | ADR-0044 |
| `phi-safe-code`, `health-literacy`, `accessible-ui` | the material each admission ADR names | Domain skills mined from named material with no upstream skill to diff, so the diff-before-editing trigger does not fire; listed for attribution only | ADR-0055 and the later admission records |
| `receiving-review` | addyosmani/agent-skills | `doubt-driven-development`'s doubt-theater alarm, direction-flipped into the zero-accepted tripwire; attribution only | ADR-0029 |
| `audit-skills`, `delete-dead-code` | an enterprise plugin repo, ECC-derived, mined once | not a tracked upstream | ADR-0062 |
| `product-description` | the `steveruizok` gists | license NONE-STATED: ideas only, never their wording or templates | ADR-0065 |
| `scripts/security.sh` — `md-shell-inline` | dbreunig/drskill (MIT) | the observation that an invocation-time command runs before the body is read; the rule is the scanner's own; attribution only | ADR-0081 |
| `ship/references/after-landing.md` § The post-deploy watch; `wizard` § 1's cutover order; `committing` § The claims rule's live-path row | addyosmani/agent-skills (`shipping-and-launch`), affaan-m/ecc (`canary-watch`), wshobson/agents (`prod-logs-health-check`), rampstackco/claude-skills (`launch-runbook`) — all MIT | four sources' ideas in local prose — success and the rollback trigger written before the deploy, baseline-relative grades in one pass, logs not dashboards, retry-dedupe on the id, the cutover order with its clock illustrative; attribution only | ADR-0082 |
| `codebase-design/references/published-interfaces.md` | addyosmani/agent-skills (`deprecation-and-migration`), LambdaTest/agent-skills (`api-versioning-helper`), swyxio/skills (`future-only`) — all MIT | the five deprecation questions, the breaking/non-breaking table re-derived stack-free, the zero-consumer license with its production-data guard; local prose, attribution only | ADR-0082 |
| `codebase-design` § "A model's write to user-owned data lands behind an accept", its agent-gate sentences | zw008/VMware-AIops | MIT; one idea — a confirmation prompt is not a gate against an agent, the credential's privilege is | ADR-0082 |
| `codebase-design/references/agent-driven-cli.md` § "A machine shape on request", the partial-result and clamp clauses | Rootly-AI-Labs/Rootly-MCP-server | **Apache-2.0**: two `CHANGELOG.md` entries paraphrased, no sentence reproduced; the upstream has no `NOTICE` file, so the attribution owed is this row and the record. One example key name, `unreadable_skipped`, is openaccountants' (AGPL-3.0, the ledger's corroborating source) — an identifier, named here so it does not read as Rootly's | ADR-0082 |
| `delete-dead-code` § Workflow — the second detector pass, the pinned-arm heuristic, the responsibility-not-carrier unit, the test-only Caution note | smith-horn/code-health-auditor and thellmwhisperer/slopslint (`C4`), alirezarezvani/claude-skills (`H07`), GanyuanRan/Aegis (`D2.2`) — all MIT | one clause each, local wording; attribution only | ADR-0082 |
| `validate-behavior` § Workflow steps 2 and 5; § Verdicts' stand-in sentence | michaelshimeles/skills (`evidence-driven-testing`), poteto/verification-skill-example | both NONE-STATED: ideas only, every clause written fresh — the port-ownership check, the trigger-plus-end-state capture, the stand-in boundary | ADR-0082 |
| `capturing-learnings/references/learning-format.md` § The incident learning; `capturing-learnings` § The capture gate's quote clause | wshobson/agents (`postmortem-writing`), rampstackco/claude-skills (`after-action-report`), github/awesome-copilot (`incident-postmortem`) — MIT; cursor/plugins' `pstack/skills/why` (MIT, taken as ideas only: the seven evidence categories); compound-engineering-plugin's `ce-compound` durable bar (MIT; the first table's upstream for this skill) | triggers, six sections, the action-item rule, "what blameless does not mean" — structure, never the template; local prose; attribution only | ADR-0082 |
| `ship` § 2 "Reviewer groups are split lines"; `ship/references/pr-path.md`'s `CODEOWNERS` read; `onboard-me`'s `CODEOWNERS` paragraph | NVIDIA/skills (`mcore-split-pr`) | **Apache-2.0** by the file's own frontmatter, CC-BY-4.0 by the repo README for skills; three constraints in local prose, Megatron-LM specifics stripped; no `NOTICE` file upstream, so attribution is this row and the record | ADR-0082 |
| `committing` § Before any outward act — the dirty-path question and the credential-rotation paragraph; `ship` § 2's exclusion paragraph | kunchenguid/no-mistakes (MIT, `K1`); prompt-security/clawsec (AGPL-3.0, `D3.6` — ideas only, the wording is local) | the refuse-and-surface stance; rotate before remove; the exclusion paragraph also carries an own-corpus transcript row (`T1`) | ADR-0082 |
| `ship/references/pr-path.md` § Re-entry | Joannis/claude-skills (`pull-request`) | no license stated: ideas only — the body is rewritten against the cumulative diff, never appended | ADR-0082 |
| `handoff` § 2 "State so far", the porcelain list | open-gsd/gsd-core (`pause-work.md`) | MIT; one idea — the uncommitted list is measured, cut at 50 with the count, never narrated | ADR-0082 |
