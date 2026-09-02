# Lineage

A row here is a skill or scanner rule with a lineage other than local original. Anything else about an upstream — why it was admitted, what was rejected — goes to its ADR. **Every skill not listed is a local original with nothing to diff against**; the rows in the second table are listed for attribution only. A skill may hold a row in both tables where it has more than one upstream — `receiving-review` does — and the first table's row is what the lineage notice fires on.

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
| `scripts/security.sh` — hex blob, drop site, download-then-exec, minified line, `.npmrc`, install-time manifest hook, compiled binary, remote instructions | openhonest/honest-skills | the sweep skill's pattern list; diff its patterns, not a skill body | Apache-2.0 | ADR-0073 |
| `scripts/security.sh` — `sh-imds`, `sh-agentcfg`, `sh-persist`, `sh-noverify`, `sh-envdump`, `uni-confusable`, `bin-bytecode` | nvidia/skillspector and DataDog/guarddog | their pattern classes; the homoglyph table is the scanner's own | Apache-2.0 | ADR-0075 |

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
