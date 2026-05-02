# to-X Suite Expansion Plan (2026-05)

Expand the `to-X` skill suite with a maintenance loop, an implementation cold-start loader, a Bug-shaped publishing skill, and structural acceptance-criteria mapping — turning the existing creation-only family into a full creation + maintenance + implementation lifecycle. Triggered by the user's PI planning use case (loading a real ADO backlog with Jira Align two-way sync at the Feature level, multi-repo work, per-team Iteration assignment).

Design rationale captured in ADRs 0002–0005. **This plan is the implementation tracker.** No skill code has been written yet.

## Goals

1. Close the maintenance loop on Stories, Tasks, Bugs (ADR-0003).
2. Make AC coverage mechanical via stable AC IDs + Task `## Covers` (ADR-0002).
3. Preserve in-body history; never hard-delete (ADR-0002, ADR-0003).
4. Close the implementation cold-start loop with `from-work-item` (ADR-0004).
5. Cover all four work-item shapes by adding `to-bug` (ADR-0005).
6. Stay tracker-agnostic — every change ships per-tracker templates for ADO and GitHub.

## Skill inventory (after expansion)

| Skill | Change | ADR |
|---|---|---|
| `to-feature` | Update template — typed AC prefixes, `## Removed acceptance criteria` section. `--update <feature-id>` already exists; verify it preserves AC IDs on re-snapshot. | 0002 |
| `to-story` | Update template — typed AC prefixes, `## Layers touched`, `## Removed acceptance criteria`. **New `--update <story-id>` mode.** Cold-start parent-aware. | 0002, 0003, 0004 |
| `to-tasks` | Update template — `## Covers` section listing referenced AC IDs. **New `--update <task-id>` and `--reconcile <story-id>` modes.** State-aware reconcile. | 0002, 0003 |
| `to-bug` | **New skill.** ADO + GitHub dispatch. `--update <bug-id>` mode included from day one. | 0005 |
| `from-work-item` | **New skill.** Cold-start loader. Auto-detects Task/Story/Bug; refuses Feature/Epic. | 0004 |
| `grill-me` / `grill-and-record` | No change. Continue as upstream stress-testers for any publishing skill. | — |
| `tdd` | No change. Receives context from `from-work-item` and runs its standard RED/GREEN/REFACTOR loop. | — |

## Phases

### Phase 0 — Sync verification (BLOCKING, work-machine-only)

Before committing any markup-dependent design to ADO, verify Jira Align ↔ ADO sync round-trip fidelity.

**Test recipe:**

1. File one throwaway Feature in ADO with the full new markup: typed AC prefixes (`**AC1:**`, `**AC2:**`), a populated `## Removed acceptance criteria` section with strike-through, and the existing story-map snapshot/separator HTML comment markers.
2. Wait for sync to Jira Align.
3. Edit a trivial field in Jira Align (title or one description line). Trigger sync back.
4. Inspect the ADO Feature description: which markup survived, which was mangled or stripped?

**Decision tree:**

- All survives → proceed to Phase 1 unchanged.
- HTML comment markers stripped → redesign story-map fencing using visible headings (e.g., `### Story map (immutable above the separator)`). Update ADR-0001's mechanism.
- Strike-through mangled → fall back to plain markdown convention (e.g., `_removed_` annotation instead of `~~text~~`). Update ADR-0002.
- AC prefixes mangled → less aggressive convention (e.g., trailing tag `... <!-- ac:1 -->` survives some renderers). Update ADR-0002.

**Gate:** Phase 0 must complete before Phase 1 starts. The user runs this on their work machine when they have ADO + Jira Align access.

### Phase 1 — Template changes

- [x] `to-feature/references/feature-template-ado.md` and `feature-template-github.md` — typed AC prefixes, `## Removed acceptance criteria` section. ADO: AC field uses typed prefixes; Removed section lives in description body between `## Constraints` and `## Story Decomposition`. GH: new `## Acceptance criteria` section parallel to ADO's AC field; `## Removed acceptance criteria` immediately below it.
- [x] `to-story/references/story-template-ado.md` and `story-template-github.md` — typed AC prefixes, `## Layers touched` section, `## Removed acceptance criteria` section. ADO: AC field uses typed prefixes; `## Layers touched` and `## Removed acceptance criteria` in description body. GH: typed prefixes on existing `## Acceptance criteria` checkboxes; `## Removed acceptance criteria` immediately below; `## Layers touched` after `## Modules touched`.
- [x] `to-tasks/references/task-template-ado.md` and `task-template-github.md` — `## Covers` section listing referenced AC IDs. GH variant: dropped the per-Task `## Acceptance` checkboxes (parent ACs now own concrete outcomes via stable IDs); `## Covers` is the only AC-coupling on Tasks.
- [x] Update self-review checks in each SKILL.md to use AC-ID lookups instead of prose judgment. `to-feature` checks story-map AC ID coverage; `to-story` checks AC ID append-only invariant + `## Layers touched` populated; `to-tasks` checks parent coverage and `Covers:` reference resolution against active parent AC IDs.

**Risk noted at landing:** Phase 0 sync verification was not yet run. If Jira Align ↔ ADO sync mangles typed prefixes (`**AC1:**`), strike-through, or the new section headings, these templates will need rework. Phase 0 must run before any of these templates are exercised against production ADO.

### Phase 2 — Maintenance modes

- [x] `to-story --update <story-id>` — single Story patch. Cold-start fetches Story body, AC field, and parent Feature body so `Covers:` references are validated parent-aware. AC ID handling is append-only with edit-in-place vs. remove+add prompt on substantive changes. Self-review re-runs step 7 with append-only invariant as the load-bearing check. Re-snapshot prompt for parent Feature on material scope change (no auto-cascade).
- [x] `to-tasks --update <task-id>` — single Task body patch. Cold-start fetches Task body and parent Story (description + AC field). Self-review checks `## Covers` references resolve to active parent ACs, `## Layers touched` populated, naming consistency vs sibling Tasks.
- [x] `to-tasks --reconcile <story-id>` — multi-Task diff against current Story. Buckets Tasks into Stale Covers / Unknown Covers / Healthy + Covered / Uncovered ACs. State-aware per ADR-0003 (Done/Closed leave alone; In Progress surface for decision; New safe to revise/close). GitHub state default is **assignee-presence** (`In-progress signal:` override deferred to Phase 4). Mark-not-delete via state transition to Removed (ADO) or `gh issue close --reason not_planned` (GitHub). Reads removed ACs from description body, not the AC field on ADO.
- [x] Naming-drift queue: durable `.claude/queue.md` (repo mode) or memory entry keyed by tracker context (no-repo CLI-only). Entry format codified in each skill that has `--update` or `--reconcile`. Read on cold-start; written by any publish that surfaces drift; never blocks.
- [x] Pre-existing `to-feature --update` AC-ID-preservation verification — codified the patch-scope invariant (only text between BEGIN/END markers replaced; AC field and other description sections preserved verbatim). Cold-start now explicitly fetches the description in full, and the self-review section narrows to story-map checks only (skip placeholder/contradiction/scope/ambiguity/domain — the rest of the body is untouched).

**Open at landing:** Phase 0 sync verification still pending; if Jira Align ↔ ADO sync mangles typed AC prefixes, strike-through, story-map markers, or `## Removed acceptance criteria` headings, all of Phase 2's parsing assumptions need rework. Phase 0 must run before any of these maintenance modes are exercised against production ADO.

### Phase 3 — New skills

- [x] `to-bug` skill, full directory structure (`src/to-bug/SKILL.md` + `references/bug-template-ado.md` + `references/bug-template-github.md`). `--update <bug-id>` mode included from day one. ADO body splits content across two fields (`System.Description` for Expected/Actual/Scope/Regression/Layers; `Microsoft.VSTS.TCM.ReproSteps` for the numbered steps); GitHub puts every section in body. Severity resolves natively on ADO (`Microsoft.VSTS.Common.Severity`); on GitHub via labels per a `Severity labels:` CLAUDE.md block (bootstrap-on-ask if absent). Public-repo warn heuristic on GH publish: `gh repo view --json visibility`; on `PUBLIC`, case-insensitive scan for `customer`, `production`, `internal`, `corp`, `credential`, `password`, `secret`, `api[_-]?key`, the literal `Bearer ` token, the `-----BEGIN` PEM prefix, and `*.internal.*` / `*.corp.*` hostname shapes — warn-on-match, never block. Naming-drift queue read on `--update`; written on publish when names diverge from canonical use.
- [x] `from-work-item` skill (`src/from-work-item/SKILL.md`). Auto-detects work-item type: ADO reads `System.WorkItemType` directly; GitHub uses a detection ladder (`bug` label → Bug; `## Covers` → Task; `## Acceptance criteria` or `**User story:**` → Story; `## Story Decomposition` or story-map fenced region → Feature; else ask). Refuses Feature/Epic with a redirect to `to-story --parent <id>`. Branches load shape per type — Task: parent Story (filtered to `## Covers` ACs) + parent Feature title/Problem/Goals; Story: full AC list + parent Feature; Bug: body + repro + parent if linked. Loads DOMAIN.md (with nested-context selection if multi-context). ADR match: strict on Tasks (per layer), fuzzy on Stories, layer+actual-behavior on Bugs. Local-repo-only ADR traversal; warn on layer mismatch with the local repo. Surfaces naming-drift queue entries informationally. Hands off to `tdd` or freeform — no auto-invocation.

**Open at landing:** Phase 3 inherits the Phase 0 gate. `to-bug` and `from-work-item` are drafting-allowed but production exercise is gated on Phase 0 — particularly for `to-bug` since ADO Bug rich-text fields go through the same Jira Align sync path as Stories and Features.

### Phase 4 — GitHub-side adaptations

- [x] `Severity labels:` CLAUDE.md block convention codified. Consumer already exists in `src/to-bug/SKILL.md` step 4 and `src/to-bug/references/bug-template-github.md` (bootstrap-on-ask flow with default scale `critical / high / medium / low`). Phase 4 adds a README `## Conventions` bullet plus a **Severity label** entry in DOMAIN.md's Tracker integration table. No retroactive ADR — design is settled in the skill body.
- [x] `In-progress signal:` CLAUDE.md block — label-based override shipped (ADR-0011). `src/to-tasks/SKILL.md` reconcile cold-start now reads the signal from CLAUDE.md and applies it during state detection; assignee-presence remains the default when the line is absent. Single label only (no multi-label OR-match). Project-status form deferred per ADR-0011 to keep the GitHub API surface small. ADO ignores the signal — `System.State` is authoritative. README `## Conventions` and DOMAIN.md updated to match.

**Open at landing:** none — Phase 4 is GitHub-only, so the Phase 0 sync gate doesn't apply. ADO behavior is unchanged.

### Phase 5 — Documentation & rollout

- [ ] Add `from-work-item` row to README skill inventory.
- [ ] Update README `## Conventions` section with note on AC IDs and `## Removed acceptance criteria` patterns.
- [ ] Document the **PI workspace** pattern (directory with CLAUDE.md declaring tracker config + sibling repos, no code). Format: a doc in `plans/pi-workspace-pattern.md` rather than an ADR — it's a usage convention, not an architectural decision.
- [ ] DOMAIN.md already updated; verify post-Phase-0 if any markup conventions changed.

## Deferred / open

Surfaced during the design grilling but intentionally deferred. Revisit if usage friction materializes.

- **Story points** (`Microsoft.VSTS.Scheduling.StoryPoints`) — not in any current template. PI planning needs sizing. Could add `## Estimate` section to Story template, or surface as a `--estimate <points>` CLI flag. Defer until actual PI sizing work surfaces friction.
- **Per-item iteration / area-path overrides** — `--iteration "Sprint 3"` and `--area "Path/Team-Alpha"` flags on the publishing skills. CLAUDE.md currently provides single defaults; PI work spanning multiple Sprints or multiple teams needs overrides. Defer until multi-Sprint or multi-team publishing surfaces friction.
- **Risk / dependency fenced region in Feature description** — Jira Align authors risks/dependencies at the Feature level via two-way sync. `to-feature --update` could overwrite synced content. Mitigation: fence the section with markers; `--update` never touches inside the fence. **Wait on Phase 0 outcome before designing** — fencing depends on whether HTML comment markers survive sync.
- **Changelog section on Stories** — `## Changelog` appended on each `--update` for an audit trail of refinements. Largely redundant with `## Removed AC` and ADO revision history. Defer unless audit-trail friction shows up.
- **DoR / DoD checks** — process gate, not skill gate. Skip; teams enforce their own.
- **`from-work-item` cross-repo ADR traversal** — currently warns when a Task references layers not in the local repo. A future enhancement could traverse `## Sibling repos` declarations and pull ADRs from neighbors. Brittle (which sibling's ADR wins?). Defer.

## Operational rules captured (not ADR-worthy)

Decided during the grilling; honor as the suite is built and used. These are conventions, not architectural decisions.

- **Streaming over batching.** Stories within a Feature are grilled and published one at a time, not batched. Each Story-level grilling can reshape later Stories before they're drafted; the story map is append-only by design (ADR-0001) and supports this rhythm.
- **Conditional re-grilling.** After publishing a Feature, synthesize the first Story directly if you can draft the body without inventing facts; otherwise, grill (in the same Claude Code session if context is sufficient, fresh otherwise).
- **One Claude Code session per Feature** for PI-volume planning. Auto-compaction breaks coherence across multiple Features; the published Feature description and DOMAIN.md carry context across sessions.
- **Ordering warnings, not blocks.** When a user grills a Story whose dependencies aren't published yet, surface a warning, don't block. Same for naming drift at publish — warn, offer the queue, never block. Sometimes the deliberately-out-of-order grill is the right move.
- **Mark, never delete.** During reconcile, removed Tasks transition to `Removed` rather than being hard-deleted (rationale in ADR-0003).

## Cleanup tasks

Surfaced during compaction prep. Track separately from the main phases — these can land before, during, or after the to-X expansion. Independent of Phase 0.

### Move skills into a subfolder — done

Skill directories moved from the repo root into `src/`. Three in-repo ADR-0001 markdown links updated for the new depth (`src/to-feature/SKILL.md`, `src/to-feature/references/feature-template-ado.md`, `src/to-story/SKILL.md`). README install snippet rewritten to `cd src && for skill in */`. ADR deferred — reversible structural cosmetic, not gate-worthy.

User action: re-symlink `~/.claude/skills/*` against the new `src/` paths (per README).

### Align ADR-0001 to the 0002–0005 format — done

ADR-0001 expanded from single-paragraph to MADR-style four-section form. Original three rejected alternatives (pure-snapshot, authoritative, full-living) preserved as bulleted Considered Options. Consequences enumerate the load-bearing claims the rest of the suite depends on — snapshot/separator immutability, best-effort append semantics, and the in-body persistence principle ADR-0002 builds on. Same Phase-0 sync caveat as ADR-0002.

### Backfill ADRs across full commit history — done

Swept the full 10-commit history (default window override per the cleanup task). Five candidates passed the gate and were written as ADR-0006 through ADR-0010: tracker dispatch, self-contained skill bundles, ADO publishing conventions, synthesis-only publishing skills, and `tdd` global promotion. Rejections recorded inline in the conversation: `harden-domain` rename (reversible), `grill-me`/`adr` splits (folds into `tracker-dispatch` activation hygiene), YAML colon fix (bug fix), description tightening (writing quality, not architecture), and operational rules from this plan (already classified non-ADR-worthy).

## Decision log (ADRs)

| ADR | Title | Path |
|---|---|---|
| 0001 | Story map: append-only living, embedded in Feature description | `docs/adr/0001-story-map-append-only-living.md` (pre-existing) |
| 0002 | Structural AC mapping with stable IDs across Feature/Story/Task templates | `docs/adr/0002-structural-ac-mapping-stable-ids.md` |
| 0003 | Maintenance loop: separate `--update` and `--reconcile` verbs | `docs/adr/0003-maintenance-loop-update-reconcile-verbs.md` |
| 0004 | `from-work-item` as the implementation cold-start loader | `docs/adr/0004-from-work-item-cold-start-loader.md` |
| 0005 | `to-bug` as a parallel skill in the suite | `docs/adr/0005-to-bug-parallel-skill.md` |
| 0006 | Tracker dispatch via CLAUDE.md `Issue tracker:` block with three-mode behavior | `docs/adr/0006-tracker-dispatch-via-claude-md.md` (backfilled) |
| 0007 | Self-contained skill bundles with duplicated format references | `docs/adr/0007-self-contained-skill-bundles.md` (backfilled) |
| 0008 | ADO publishing: Markdown authoring with HTML conversion and reference-name field targeting | `docs/adr/0008-ado-publishing-markdown-and-reference-names.md` (backfilled) |
| 0009 | Synthesis-only stance for publishing skills (no-interview) | `docs/adr/0009-synthesis-only-publishing-skills.md` (backfilled) |
| 0010 | `tdd` promoted to global with active-skill finalization nudge | `docs/adr/0010-tdd-global-with-finalization-nudge.md` (backfilled) |
| 0011 | GitHub state detection via `In-progress signal:` CLAUDE.md block | `docs/adr/0011-in-progress-signal-claude-md.md` |

## Notes

- **Where to run skills from.** Backlog construction runs from a PI workspace directory (or a coordinator repo). Implementation runs from the codebase. `from-work-item` warns when a Task references layers not present in the local repo.
- **DOMAIN.md scope.** The skills repo's own `DOMAIN.md` (`./DOMAIN.md`) captures the suite's vocabulary and is referenced from `~/.claude/CLAUDE.md`. It doesn't replace project-specific `DOMAIN.md` files in user codebases.
- **Tracker support.** ADO is the primary target (Jira Align two-way sync use case). GitHub is supported as the secondary target via per-tracker templates. The same skills work for both.
- **Pre-expansion baseline.** The `skills-restructure.md` plan documented the prior generation of the suite (`grill-me` → `to-feature` → `to-story` → `to-tasks` plus `harden-domain`, `adr`, `backfill-adrs`, `tdd`, `deepen`, `write-skill`). This plan is its successor.
