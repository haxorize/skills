# Mine 28 new sources and 34 deltas against usage evidence; fold the trust fixes

The 2026-08-21 round read 28 previously unseen sources, delta-fetched the 34 repos already in the ledger, and re-heard every prior veto. Novelty ranked the candidates in the [ADR-0046](0046-four-repo-fragment-mine.md) and [ADR-0050](0050-twelve-repo-mine-and-discoverable-code-port.md) rounds; this time usage evidence did. Two Claude Code Insights reports (personal machine, 113 sessions over 2026-07-15 to 08-14; work machine, 83 sessions over 2026-07-21 to 08-20) and the typed history of 171 sessions since 2026-07-10 set the lens, and a candidate landed only where that evidence showed a failure it addresses and the current skill text lacked the fix. Three decisions own their own records and are only named here: the `committing` extraction from `ship` ([ADR-0052](0052-committing-extracted-from-ship.md)), the global rules layer ([ADR-0053](0053-global-rules-layer.md)), and the Discipline-skill rename with the `grill-me` merge (ADR-0054, written when its batch lands). Everything else the round decided is recorded below.

## Why usage evidence beat novelty

Four rounds of mining had widened the suite to 42 skills, with dilution the named failure mode each time. The evidence showed a different one: the suite runs as a single loop, and its defects are trust defects. On the personal machine, 80-plus sessions ran the same path: `/from-ticket`, `/implement`, `/handoff`, a fresh session with `/review-changes` on the handoff file, the typed line "address all findings through the /receiving-review lens" (55 times, verbatim), then "Commit. Can I close #N?" (104 prompts mention commit). `/ship` ran 17 times. Sixteen skills never fired by either route, among them the whole codebase-health family and every detour.

The corrections were about trust, not code. Only 10 hard frustration signals appeared in 1,285 prompts, and each concerned a report or a process: a fabricated "user approved" claim, a miscounted finding, a rename that silently no-op'd under BSD `sed -i`, scope deferred without saying so. On the work machine the failures were prose-rule failures: em dashes despite the memory rule, and commits made outside `/ship`; both rules existed as text and still failed. A novelty-ranked round would have added rules to skills that never load. An evidence-ranked round fixes the loop that runs and moves the rules that failed as prose onto a rung that fires with no skill loaded, which is why the decisions cluster on landing, review, and reporting.

## Method changes

Three things were new and are kept. Every ADOPT had to cite a friction line. A completeness critic reconciled every miner verdict and workflow finding against the batch plan before any build began; it placed 46 gaps the plan had not named and found 11 contradictions between reports, each settled before batching. The 2 sources read thin on the first pass (Graphify-Labs/graphify, anthropics/claude-cookbooks) were re-read in full; the re-read yielded 8 folds and 5 parks the thin read had missed.

## Sources

| Source | Yield |
| --- | --- |
| EdbertChan/catstack; garrytan/gstack; cursor/plugins | The trust cluster: same-message evidence, `UNVERIFIED:` marker, per-AC completion table, approval claims cite the turn, reviewed-head stamp, disposition table, the `global/` layer |
| pbakaus/impeccable; Leonxlnx/unlazy; ayghri/i-have-adhd; almendili/skills | Unobtainable evidence changes the report's shape, not its confidence; inspect once, fix in a batch, confirm once; re-measure every number |
| blader/humanizer; vickiboykis; leonxlnx/taste-skill | Writing sample overrides register defaults; final dash grep; "Bumped dependencies" pair |
| staltz/microskills; DietrichGebert/ponytail; kunchenguid/vision; github/spec-kit | Judgment-calls list; extract at the third caller or a named concept; drop a predictable question; bare "yes" resolves to the recommended line |
| will-ness-ai/skills; backnotprop/plannotator; daniloc/coherence | Wind-tunnel hardening; instruction files in a diff are content under review; zero-ran is not green |
| claudish-to-english (both forks); anthropics/claude-cookbooks; aarondfrancis gist; swyxio/skills; Graphify-Labs/graphify | Fail-open hook shape; truncated artifact never shown; `/compact` focus; pruning-lens line; disk-is-done for delegated writes |
| webpro-nl/knip; dmmulroy/anti-slop; nextlevelbuilder/ui-ux-pro-max-skill | a11y-health repos only, under a separate grill |
| modem-dev/skills; JuliusBrussee/caveman | Nothing: a byte-identical mirror of dmmulroy, never diffed again; rules `writing-for-humans` already holds |

Of the 34 delta repos, 15 yielded fragments. The per-idea ledger, 110 adopt-or-adapt rows, lives in the memory file.

## Vetoes re-heard

Every prior veto was re-heard rather than sampled, because the user suspected a "more is worse" reflex had rejected ideas that now had a consumer. A veto flipped only when the evidence showed a failure the idea addresses and the current text lacked the fix; "the repo grew a consumer" counts, "it would be nice" does not. Where a rule existed and still failed, enforcement was the gap, and the veto stood.

| Outcome | Count | Examples |
| --- | --- | --- |
| Reopened | 10 (1 adopt, 9 adapt) | One-commit fast path and `Landing:` key; stable `F<n>` finding IDs; hooks directory; handoff landing zone; recommend-and-proceed outside grills |
| Parked with a named consumer | 16 | AC/test drift, a real prototype detour, `corpus-sweep` running `verify-docs` |
| Upheld | 82 | Batch "approve all", cross-model second opinions, persona packs |

## Decisions recorded here

- **`address-findings`** is a new user-invoked orchestrator, `requires: receiving-review`. It reads the newest review report, splits findings into mechanical (fix without asking) and ask (one batched question), and ends with a disposition row per finding: FIXED, DECLINED with reason, DEFERRED for the human to ratify, or ABANDON. One pass, a ledger, then stop. **`receiving-review`** correspondingly becomes a single fix pass; re-review is the user's call.
- **The one-commit path** ("commit, close, tick, push" in one move) lives in `committing`, not `/ship`, because `/ship` is user-invoked and the 100-plus ad-hoc "commit and push" prompts never reach it.
- **The `Landing:` key** in a repo's CLAUDE.md holds branch policy, whether a PR is required, whether push and ticket-close are pre-authorised, and the defect policy, defaulting to "fix, don't file". Outward acts (commit, push, tracker write, message, loop) always sit in the ask bin unless this key pre-authorises them; compound-engineering's "reversibility decides" wording was rejected because the user's corrections sit at outward acts, and it would license pushes.
- **`handoff`** writes to `$TMPDIR/claude-handoffs/<repo>-<date>-<slug>.md`, and `review-changes` with no argument picks the newest for the current repo; the router names the bridge. A handoff carries the session's completion audit verbatim, with provenance tagged user's / inferred / my call; `review-changes` briefs every finder diff-only and hands that narrative to one falsification lens that reads it last.
- **`implement`'s close** becomes a claim with evidence: a per-AC table (DONE / PARTIAL / NOT DONE / CHANGED / UNVERIFIABLE, each row with an evidence line), a beat ledger, a parked ledger whose zero case is stated, and a judgment-calls list that includes silent defaults. The shape lives in a `completion-audit.md` sibling owned by `implement`, inherited by `handoff`, and consumed by `committing`. The verification loop is bounded to one inspection round, one batched fix, at most one confirm. The refactor beat gains one clause, extract at the third caller or a named concept, overriding the earlier veto because it is the only form checkable before extracting.
- **No em-dash hook.** Three reports asked for one; it was rejected because a hook sees file writes, and the em dashes that were caught were in chat output, which no hook can see. `writing-for-humans`' outbound register instead gains a mandatory last step: search the draft for `—` and rewrite. `write-skill` gains the general escalation row (prose, then hard prohibition, then hook or lint); here the top rung is unreachable.
- **A rename-safety hook** ships in `global/hooks/` as the round's one hook: a PreToolUse check on Bash that blocks in-place mass edits (`sed -i`, `perl -pi`, `xargs` feeding either) and names the path-shaped arguments it can see. Four shell-fragility sessions were the evidence.
- **`black-box-check` is renamed `validate-behavior`** now and kept one more window before a retire check. The critic argued the rename spends edits on a skill that may retire; it stands so the window measures the skill under a name that describes it.
- **`wizard` moves to user-invoked.** Its body writes a script, `.env`, and CI secrets into the repo, which is the consequential-publisher shape; it never fired autonomously and cost 391 description characters every turn.
- **Publisher load gates.** `to-feature`, `to-story`, `to-tasks`, `to-bug`, and `chart-course` check that `work-item-shape` and `writing-for-humans` loaded, and create a tracker item only after a confirming turn exists to cite. An ADO story auto-created mid-grill was the evidence.
- **New skills.** `onboard-repo` (user-invoked) interviews for tracker, landing, and loop commands, writes the `Issue tracker:` and `Landing:` blocks, and prints the hook snippet; it is a skill rather than a README section because it interviews and writes blocks a README can only describe. `deps-upgrade` (user-invoked) wraps the upgrade flow that ran in about 8 sessions with no skill, tool-neutral: Context7 when that MCP is present, registry CLIs otherwise. `mine-skills` and `corpus-sweep` will sit under this repo's `.claude/skills/` because they act on this repo alone.
- **Smaller folds.** `grilling` drops any question whose answer is predictable or observable by running something. `adoption-verdict` stays model-invoked, and flips if the next window is still zero fires. `feedback-loops` treats zero-ran as not green. `capturing-learnings` always runs its offer and says "none this session" out loud.

## Parked, with the condition that unparks each

- **Adversarial verifier gate in `ship`**: unparks if the claims rule alone proves insufficient.
- **Two-machine sync check at session start**: unparks on the next "forgot to merge from my work machine" incident, or when a second hook makes the install snippet a one-line addition.
- The remaining parks each name a consumer in the batch plan and the memory file.

## Guards

`global/` holds only rules a skill depends on, each naming that skill and why a hook or lint cannot do its job. `committing` never owns the commit split. `address-findings` never re-runs the review. "No unasked commits" has one owner, the global rule. A rule found in both `ship` and `committing`, or in both `receiving-review` and `address-findings`, is a defect.

## Lineage

All six upstreams under [ADR-0034](0034-branch-mining-lineage-or-dormant-main.md) were diffed on main and branches. The ported skill files were unchanged in compound-engineering-plugin, oaustegard/claude-skills, obra/superpowers, openclaw/agent-skills, and dmmulroy/dotfiles. mattpocock/skills advanced 34 commits; one fragment was taken (the `---` separator between grill questions) and its 9 unmerged branches carried nothing portable. The sweep points advance to mattpocock `5b15a47`, compound-engineering `66ccf57`, oaustegard `66ec85b`, superpowers `b36e082`, openclaw `128a4ea`, and dmmulroy `a7beb72`; ADR-0034 carries the amendment once the round's last batch lands. jakubkrehel/skills' recorded sweep SHA did not resolve, so its main tip `6c43b20` is recorded instead. None of the 28 new sources becomes a lineage upstream.

## Consequences

The round lands as 7 batches, each reviewed through the `write-skill` pruning lens and committed separately, ADR before skill. Three retire checks are scheduled for the next window: the `grill-and-record` stub, `validate-behavior`, and `adoption-verdict`'s axis. Load counts for the gated skills are re-measured after the gates land. As before, reversal is the costly direction: the folds carry no markers, so this record and the batch plan are the only map back.

## Amendments

### 2026-08-21 — Batch 2 landed; eleven late sources mined

Batch 2 built `address-findings`, reshaped `receiving-review` to one fix pass (retiring the convergence guard — ADR-0017 carries the dated amendment), fixed `handoff`'s landing zone as the one place the handoff and report filenames are defined and added the model/effort stamp beside the head stamp it already carried, and gave `review-changes` its Batch 2 folds: the no-argument newest-handoff pickup, the clean-tree stop, stable `F<n>` IDs, the reviewed-head stamp with "N commits since", diff-only finder briefs with a falsification lens, the instruction-file and repo-declared lenses, the in-process path for small prose diffs, the coverage-ledger row for unreadable evidence, and the report written to the landing zone. One rejection recorded here: wshobson/agents' review orchestrators (`comprehensive-review`, `git-pr-workflows`) all loop fix → re-review → checkpoint with no disposition ledger and no deferral rule; the user's own corrections (ledger A07.9: stop looping, address all findings, no follow-ups) are the evidence against that shape, and one-pass-ledger-stop is the divergent choice on purpose. P1's novelty-rate stop condition stays parked: with one pass there is no looping reviewer to stop. The A29.3 lens budget re-hears the size-gating veto on a different axis — that veto rejected size-gated *risk planning*, and this gates only whether lenses fan out — but the re-hearing itself is the user's and is parked for Batch 5 with the other two user decisions from the late mine.

Eleven sources were added after Batch 1 and mined as a delta (ledger A29–A39): hardikpandya/stop-slop, ehmo/slopkit, aboudjem/humanizer-skill, aashaexo/soundshuman, jalaalrd/anti-ai-slop-writing, elithrar/dotfiles, stephenturner/skills, Microck/ordinary-claude-skills, anthropics/claude-plugins-community, wshobson/agents, warpdotdev/common-skills. Their folds are assigned to the batches that own the target skills and land as those batches do; the Sources table above gains their rows when Batch 6 closes the records. The rename-safety hook gained one measured fix from that mine: a backslash-newline continuation (`sed \<newline> -i`) passed the shape check; it is joined before matching now, with a self-test row.
