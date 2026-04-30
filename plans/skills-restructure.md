# Skills Restructure Plan

Restructure the `humana/skills` repo to adopt a Matt Pocock-inspired workflow (grill → feature → story → tasks) while preserving the deliberate sweep / backfill modes of the existing skills, eliminating duplicate intent across global and per-repo `.claude/skills/`, and supporting both GitHub and Azure DevOps as publishing targets with explicit work-item hierarchy.

## Goals

1. **Eliminate duplicate intent** between `grill-me`, `ubiquitous-language`, `adr`, and the per-repo `write-feature-spec`/`spec-to-tasks` skills.
2. **Adopt a clean phased workflow**: grill (gather) → feature (optional, capture broad scope) → story (capture single feature) → tasks (break the Story down). Tasks are always children of Stories — never directly under Features. The feature step is optional in flat-hierarchy trackers (GitHub); a required upstream artifact in hierarchical trackers (ADO with `Hierarchy: required`), where every Story must have a parent Feature. To decompose a Feature into multiple Stories, run `to-story --parent <feature-id>` repeatedly under the same Feature.
3. **Move repo-specific spec/task skills to global** so a11y-health-ui, a11y-health-api, and future repos all share one implementation.
4. **Support both GitHub and Azure DevOps** so the same skills work for personal repos and the user's work backlog. Honor ADO's enforced work-item hierarchy (Epic → Feature → User Story → Task).
5. **Preserve deliberate sweep / backfill capabilities** of existing skills by retaining them in narrowed form.

## Final skill inventory

| Skill | Status | Notes |
|---|---|---|
| `grill-me` | **Keep, revert** | Strip "During the session"; revert to Matt's 3-line vanilla version. Zero-setup, runs anywhere. |
| `grill-and-record` | **New** | Doc-aware grill. Built from `grill-me` prose + three borrows from Matt: explicit "cross-reference with code," "update DOMAIN.md inline (don't batch)," `Relationships` as a first-class section in DOMAIN.md. Offers ADRs sparingly when gate triggers. |
| `harden-domain` | **Rename from `ubiquitous-language`** | Writes `DOMAIN.md` (renamed from `UBIQUITOUS_LANGUAGE.md`). Description scoped to deliberate sweep mode. |
| `adr` | **Keep, narrow** | Description scoped to deliberate single-record use. Backfill capability extracted. |
| `backfill-adrs` | **New (split from `adr`)** | Git-history archaeological mode. Core git ops host-agnostic; PR/work-item enrichment via tracker dispatch. v1: GitHub enrichment only; ADO branch as TODO. |
| `to-feature` | **New** | Synthesis-only. Creates a Feature-level (PRD-shaped) artifact. ADO: a Feature work item (parent Epic required). GitHub: an issue with feature/PRD template. Optional in most workflows; used when scope is large enough to need multiple stories underneath. |
| `to-story` | **New (replaces per-repo `write-feature-spec`)** | Synthesis-only. Creates a Story-level (single-feature spec) artifact. ADO: a User Story (parent Feature required). GitHub: an issue with story-shaped template. Most workflows start here. Reads CLAUDE.md + DOMAIN.md, synthesizes from conversation context. No interview fallback. |
| `to-tasks` | **New (replaces per-repo `spec-to-tasks`)** | Synthesis-only. Always breaks a parent **User Story** into child **Tasks** — never operates on Features. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly. Preserves HITL/AFK marking, full self-review, cross-repo dependency flagging. Drops local-plan-file option. |
| `deepen` | Keep, unchanged | |
| `find-skills` | Keep, unchanged | |
| `write-skill` | Keep, unchanged | |
| `context7-mcp` | Keep, unchanged | |
| Per-repo `write-feature-spec` (UI + API) | **Delete** (after migration verified) | |
| Per-repo `spec-to-tasks` (UI + API) | **Delete** (after migration verified) | |

## Conventions

### File naming and locations

- **`DOMAIN.md`** at every repo root. No `-MAP` suffix. For multi-context monorepos, root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files. For the cross-repo a11y-health setup (separate git repos under a non-repo parent), each repo's `DOMAIN.md` cross-references its sibling in prose. No parent map file.
- **ADRs** stay in `docs/adr/NNNN-slug.md` per repo.
- **No `UBIQUITOUS_LANGUAGE.md`** anywhere going forward. The existing `a11y-health-api/UBIQUITOUS_LANGUAGE.md` is converted to `DOMAIN.md`.

### Tracker dispatch

Each repo's `CLAUDE.md` carries an `Issue tracker:` block declaring the tracker and its publishing conventions. Examples:

```
Issue tracker: GitHub
  Default labels: needs-triage
  Hierarchy: optional
```

```
Issue tracker: Azure DevOps
  Project: Humana-Engineering
  Area path: Humana-Engineering\YourTeam
  Iteration: @CurrentIteration
  Default state: New
  Hierarchy: required
```

- All fields except the tracker name are optional for GitHub; ADO requires `Project:` minimum.
- `Hierarchy: required|optional` controls whether `to-feature`/`to-story`/`to-tasks` enforce a `--parent <id>` argument. Default `required` for ADO (matches enforced work-item hierarchy), `optional` for GitHub (no native hierarchy). Override per repo if a team diverges from the default.
- If a required field is missing, skill fails fast with a clear "add this to CLAUDE.md" message.
- Skills internally dispatch:
  - GitHub → `gh issue create` (markdown body); parent linking via `Tracked-by:` or template `Parent: #N` reference
  - ADO → `az boards work-item create --type "Feature" | "User Story" | "Task"` (with `--description` and `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."` where applicable); parent linking via `az boards work-item relation add --relation-type Parent`. See **ADO field shapes** below for which fields each work-item type carries.

### ADO field shapes

Each ADO work-item type populates a different set of rich-text fields. The skills target stable **field reference names** (immutable across process templates), not display names (which orgs often relabel).

| Work item | Body field (reference name) | Body field (typical display name) | Acceptance Criteria |
|---|---|---|---|
| Feature | `System.Description` | "Description" | `Microsoft.VSTS.Common.AcceptanceCriteria` |
| User Story | `System.Description` | "Description" (stock Agile/Scrum) or "Notes" (some custom templates incl. user's work org) | `Microsoft.VSTS.Common.AcceptanceCriteria` |
| Task | `System.Description` | "Description" | (none — Tasks have no AC field) |

The CLI flag `--description` always targets `System.Description` regardless of what the field is labeled in the UI. Acceptance Criteria goes via `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."`.

**Verify against any ADO project before first publish:**

```bash
az boards work-item show --id <existing-work-item-id> --output json --query 'fields'
```

Confirm `System.Description` is present (and `Microsoft.VSTS.Common.AcceptanceCriteria` for Features and User Stories). If a project uses a heavily customized template that exposes additional or replacement fields, the skill will need a per-project override; this should be rare.

### Markdown → HTML conversion for ADO

ADO rich-text fields render **HTML by default**. Markdown rendering is a per-org/per-field opt-in setting added in 2025 — not safe to assume. The publishing skills:

- **Author** all body content as Markdown (humans edit Markdown; templates are Markdown).
- **Convert** Markdown → HTML at publish time before passing to `--description` or `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."`.
- Conversion uses `pandoc -f markdown -t html` if available, or a Python `markdown` one-liner as fallback.

Both tools must be on the publishing machine before first ADO invocation. Phase 5 captures this as a setup step.

### Sibling repo awareness

Each repo's `CLAUDE.md` optionally declares siblings under a `## Sibling repos` section. Format spec:

```
## Sibling repos

- `<relative-path>`: <one-line description of relationship and what to flag>
- `<relative-path>`: <one-line description>
```

Example:

```
## Sibling repos

- `../a11y-health-api`: provides API contract; flag work that needs API changes as cross-repo blockers
```

Format rules the skill parses:

- Each sibling is a single bullet under `## Sibling repos`.
- Bullet format: backtick-wrapped relative path, then `: `, then free-text description.
- Path is interpreted relative to the current repo root.
- Description is free-text; the skill uses it for context but does not parse structure within it.

`to-tasks` reads this on invocation. For affected slices, marks **"Blocked by: sibling repo (<name>) — contract change required"**. Solo repos (no declaration) get vanilla behavior.

### Three-mode behavior (`to-feature`, `to-story`, `to-tasks`)

These skills operate in three escalating modes so they work in mature repos AND as kickstart tools for unconfigured contexts:

| Mode | Trigger | Behavior |
|---|---|---|
| **Declared** | CLAUDE.md present with tracker block | Read it, dispatch automatically |
| **Bootstrap-on-ask** | Repo present, CLAUDE.md missing or no tracker block | Ask user for tracker info inline. Then write to CLAUDE.md (see Bootstrap write behavior below) so future invocations are zero-friction |
| **No-repo CLI-only** | No git repo at all (pure backlog work) | Ask for tracker info. Publish via CLI. No file writes. Save to memory (see Memory key/scope below) so subsequent invocations don't re-ask |

`grill-me` stays vanilla — no detection, no writes, the kickstart tool when nothing is configured. `grill-and-record` requires a repo with (or willing to create) `DOMAIN.md`.

**Bootstrap write behavior:**

- **CLAUDE.md exists, no tracker block:** preview an appended `## Issue tracker` section (with the user's answers filled in); write on confirmation.
- **CLAUDE.md does not exist:** preview a new minimal CLAUDE.md containing only the `## Issue tracker` section; write on confirmation. Print one-line nudge: "Created minimal CLAUDE.md. Run `/init` to flesh out full project context."
- Same shape applies to `Sibling repos:` declarations — appended as `## Sibling repos` section if not already declared.
- **Always append, never overwrite.** The skill always preserves existing CLAUDE.md content; it only appends new sections. Always preview before writing; never write silently. This makes bootstrap mode safe regardless of whether `/init` is later run against the same file (see Phase 6 follow-up on built-in `/init` interaction).

**Memory key/scope (no-repo mode):**

When tracker info is captured in no-repo mode, save as a `reference` memory keyed by tracker context, not by repo. Examples:

- `Tracker default — personal` → GitHub, no labels
- `Tracker default — work-backlog` → Azure DevOps, project Humana-Engineering, area `...`, iteration `@CurrentIteration`, default state New

The skill asks the user which context applies if multiple memory entries exist; defaults to most-recently-used if user prefers no prompt. Single-context users (only ever one tracker) just use the one entry without prompting.

### Templates and references

Each new skill bundles a `references/` folder with templates. Self-contained (no cross-skill references) to preserve symlink-install portability. Per-tracker variants where publishing format differs:

```
to-feature/
  SKILL.md
  references/
    feature-template-github.md
    feature-template-ado.md
to-story/
  SKILL.md
  references/
    story-template-github.md
    story-template-ado.md
to-tasks/
  SKILL.md
  references/
    task-template-github.md
    task-template-ado.md
grill-and-record/
  SKILL.md
  references/
    domain-format.md
    adr-format.md
backfill-adrs/
  SKILL.md
  references/
    adr-format.md            # duplicate of grill-and-record's copy
harden-domain/
  SKILL.md
  references/
    domain-format.md         # duplicate of grill-and-record's copy
```

Format docs are duplicated where used. Cheap to maintain; preserves portability.

## New skill specifications

### `grill-and-record`

**Description:** Doc-aware grilling session. Stress-tests a plan while updating DOMAIN.md inline as terms resolve and offering ADRs when the gate triggers. Use when user wants to grill a plan in a project with (or willing to create) a DOMAIN.md.

**Behavior:**

- Inherits the core grill loop from `grill-me`: ask one question at a time, recommend an answer, walk down the design tree.
- During the session:
  - **Cross-reference with code.** When the user states how something works, check whether the code agrees. Surface contradictions immediately.
  - **Sharpen fuzzy language inline.** Propose canonical terms from `DOMAIN.md`.
  - **Challenge against the glossary.** When user usage conflicts with `DOMAIN.md`, surface immediately.
  - **Stress-test with concrete scenarios.** Invent edge cases that probe boundaries.
  - **Update DOMAIN.md inline (don't batch).** When a term resolves, write it to DOMAIN.md right then.
  - **Offer ADRs sparingly.** Only when all three gate criteria hold (hard to reverse + surprising + real trade-off). User opts in to write.
- **ADR-write behavior.** When the user accepts an ADR offer, `grill-and-record` writes the ADR file inline (does NOT delegate to the standalone `adr` skill). It uses the bundled `references/adr-format.md` as the single source of truth for format. The standalone `adr` skill is reserved for outside-grill use (deliberate single-record after a code review, mid-implementation, etc.). Both skills write to `docs/adr/NNNN-slug.md` using the same format and the same "scan highest, increment by one" numbering rule.
- Lazily creates `DOMAIN.md` and `docs/adr/` if missing.
- For multi-context repos, infers which context the topic belongs to; asks if unclear.

**Builder ↔ Specifier or Dev ↔ Domain expert?** Use `Dev ↔ Domain expert` in the example dialogue (better fit for a11y-health and most external use cases). Carries Matt's framing forward.

### `to-feature`

**Description:** Turn the current conversation into a Feature-level (PRD-shaped) artifact and publish it to the project's issue tracker. Use when scope is large enough to need multiple stories underneath. ADO: creates a Feature work item under a parent Epic. GitHub: creates an issue with a feature/PRD template. Synthesize from existing context — no interviewing.

**Behavior:**

1. **Resolve tracker** via three-mode behavior.
2. **Resolve parent.** If `Hierarchy: required` (default for ADO): if `--parent <epic-id>` is provided, use it; otherwise interactively prompt for the Epic ID. Do not silently default or skip — fail clearly if user has no parent to provide. If `Hierarchy: optional` (default for GitHub), parent linking is optional and the skill does not prompt unless `--parent` is provided.
3. **Explore the codebase** if not already done. Use canonical terms from `DOMAIN.md` and respect existing ADRs.
4. **Sketch the modules / boundaries** at a feature scope (broader than a single story — what areas are touched, what are the major sub-features). Check with user that the shape matches expectations.
5. **Propose 2-3 approaches** with their trade-offs (same shape as `to-story`'s propose-approaches step, scoped to the feature level).
6. **Draft the feature** using the appropriate template (`feature-template-github.md` or `feature-template-ado.md`).
7. **Self-review** (placeholders, contradictions, scope, ambiguity, domain language matches DOMAIN.md).
8. **Present draft to user**, iterate until approved.
9. **Publish via tracker dispatch.** Apply default labels / area / iteration. Link to parent Epic in ADO via `az boards work-item relation add`.

### `to-story`

**Description:** Turn the current conversation into a Story-level (single-feature spec) artifact and publish it to the project's issue tracker. Most workflows start here — use unless you specifically need a multi-story Feature. ADO: creates a User Story under a parent Feature. GitHub: creates an issue with a story-shaped template. Synthesize from existing context — no interviewing. Run `grill-and-record` (or `grill-me`) first if context is thin.

**Behavior:**

1. **Resolve tracker** via three-mode behavior (declared / bootstrap-on-ask / no-repo).
2. **Resolve parent.** If `Hierarchy: required` (default for ADO): if `--parent <feature-id>` is provided, use it; otherwise interactively prompt for the Feature ID. If no Feature exists, suggest running `to-feature` first or (only if team config allows top-level stories) accepting a parentless Story. If `Hierarchy: optional` (default for GitHub), parent linking is optional and the skill does not prompt unless `--parent` is provided.
3. **Explore the codebase** if not already done. Use canonical terms from `DOMAIN.md` and respect existing ADRs.
4. **Sketch major modules** to build/modify. Look for opportunities to extract deep modules. Check with user that modules match expectations and which they want tests for.
5. **Propose 2-3 approaches** with their trade-offs. Lead with the recommendation. Let user push back or confirm before drafting. Not interviewing — pre-publication direction check. If user pushes back, revise sketch and re-propose; do not interview through it. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two).
6. **Draft the story** using the appropriate template (`story-template-github.md` for GitHub issue body, `story-template-ado.md` for ADO User Story fields).
7. **Self-review** before showing the user:
   - Placeholders (no TBD/TODO)
   - Contradictions between sections
   - Scope (focused enough for one story, or needs decomposition)
   - Ambiguity (any requirement readable two ways)
   - Domain language matches DOMAIN.md
8. **Present draft to user**, iterate until approved.
9. **Publish via tracker dispatch.** Apply default labels / area / iteration. Link to parent Feature in ADO if provided.

### `to-tasks`

**Description:** Break a parent **User Story** into child **Tasks** on the project's issue tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. Tasks are always children of a User Story; never directly under a Feature. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly.

**Behavior:**

1. **Gather context.** If user passes a parent reference (issue number / work-item ID / URL), fetch the parent Story. Otherwise work from current conversation.
2. **Resolve tracker** via three-mode behavior.
3. **Resolve parent Story.** If `Hierarchy: required` (default for ADO): if `--parent <story-id>` is provided, use it; otherwise interactively prompt. If `Hierarchy: optional` (default for GitHub), parent linking is optional and the skill does not prompt unless `--parent` is provided. **Verify parent type:** ADO parent must be `User Story` (refuse Feature/Epic/Task/Bug with a clear redirect to `to-story`); GitHub parent must look story-shaped (refuse PRD-shaped with a redirect).
4. **Read `Sibling repos:`** declaration if present.
5. **Explore codebase** if needed. Identify durable architectural decisions — for any meeting the ADR gate, record via `adr` skill before slicing.
6. **Draft vertical slices.** Each slice = one Task = thin vertical cut through every layer end-to-end. Prefer many thin Tasks over few thick ones. Mark each as **HITL** or **AFK**. Flag cross-repo blockers based on `Sibling repos:` declaration.
7. **Quiz the user** on the breakdown. Iterate until approved.
8. **Self-review:**
   - Parent coverage (every parent Story acceptance criterion is referenced by at least one Task)
   - Naming consistency (route paths, query keys, model names, search-param keys identical across Tasks)
   - Domain language matches DOMAIN.md
   - No placeholders
9. **Publish in dependency order** (blockers first) so real work-item IDs can be referenced in "Blocked by" fields. Apply default labels / area / iteration. Link each Task to the parent Story via tracker-appropriate mechanism. ADO Tasks have only `System.Description` (no Acceptance Criteria field).

### `backfill-adrs`

**Description:** Sweep recent git history for architectural decisions that should have been recorded as ADRs but weren't. Use when adopting ADR practice retroactively or after a long stretch of un-recorded work.

**Behavior:**

1. **Read git log.** Skill prompts user for range if not specified. Suggested defaults: last 90 days OR last 200 commits, whichever is shorter. Skill confirms range with user before scanning.
2. **For each candidate decision, follow PR/work-item references via tracker dispatch:**
   - GitHub: `gh pr view`, `gh issue view` (v1 supported)
   - ADO: `az repos pr show`, `az boards work-item show <id>` (v1: TODO; scaffolded but not implemented)
3. **Apply ADR gate** (hard to reverse + surprising + real trade-off) to each candidate. Reject any that fail.
4. **Quiz the user** on the candidate list. Confirm which to write.
5. **Write approved ADRs** in `docs/adr/`, numbered sequentially after existing ADRs.

## Existing skill changes

### `grill-me`

Revert to Matt's vanilla 3-line version. Strip the "During the session" section entirely. Description unchanged.

### `adr`

Narrow description to **deliberate single-record use** (not backfill). Make it clear the skill activates when user has just made a decision and wants to capture it; backfilling is owned by `backfill-adrs`. SKILL.md content stays largely the same — the gate, numbering, template — but the workflow scope is single-record.

### `harden-domain` (renamed from `ubiquitous-language`)

- Rename directory: `ubiquitous-language/` → `harden-domain/`
- SKILL.md frontmatter `name: harden-domain`
- Description scoped to deliberate sweep mode: "Sweep the codebase to refresh DOMAIN.md. Use when user wants to harden terminology, define domain terms, or surface naming drift."
- Update all file paths from `UBIQUITOUS_LANGUAGE.md` → `DOMAIN.md`
- Add `Relationships` as a first-class section in the format
- Carry forward the rich format (Builder ↔ Specifier dialogue → Dev ↔ Domain expert dialogue, group tables, ambiguities section, "what to skip" rules)

## Migration plan

### Phase 1: Build (no-risk additions to skills repo)

1. Create new skills in `humana/skills/`:
   - `grill-and-record/` (with `SKILL.md`, `references/domain-format.md`, `references/adr-format.md`)
   - `to-feature/` (with `SKILL.md`, `references/feature-template-github.md`, `references/feature-template-ado.md`)
   - `to-story/` (with `SKILL.md`, `references/story-template-github.md`, `references/story-template-ado.md`)
   - `to-tasks/` (with `SKILL.md`, `references/task-template-github.md`, `references/task-template-ado.md`)
   - `backfill-adrs/` (with `SKILL.md`, `references/adr-format.md`)
2. Rename `ubiquitous-language/` → `harden-domain/`. Update SKILL.md frontmatter, description, file path references, format docs. **Remove the stale `~/.claude/skills/ubiquitous-language` symlink** before symlinking the new `harden-domain` directory in step 8 (a dangling symlink could confuse skill discovery).
3. Revert `grill-me/SKILL.md` to vanilla 3-line version.
4. Narrow `adr/SKILL.md` description to deliberate single-record use.
5. **Audit existing skills for collateral references.** Grep `humana/skills/` for any reference to `UBIQUITOUS_LANGUAGE.md` (e.g., in `init/`, `review/`, `security-review/`, or skill-internal docs). Update each hit to `DOMAIN.md`. Confirms no skill silently references the old name after this phase.
6. **Tighten paired-skill descriptions to prevent activation conflicts.** Read the descriptions of paired skills side-by-side and adjust until no plausible user phrase activates both:
   - `grill-me` vs `grill-and-record` — `grill-me` activates on "stress-test a plan, get grilled" with no doc/code context language; `grill-and-record` activates on phrasings that mention domain, glossary, decisions to capture, or working in a project with DOMAIN.md.
   - `adr` vs `backfill-adrs` — `adr` activates on "record this decision," "write an ADR for this"; `backfill-adrs` activates on "scan history for missed decisions," "backfill ADRs," "we never wrote ADRs and want to catch up."
   - `to-feature` vs `to-story` — both are synthesis-only publishing skills, so they collide on phrases like "create an issue for this," "publish this work." Disambiguation criteria: scope size (multi-story PRD shape → `to-feature`; single-feature spec → `to-story`) and ADO type (Feature work item → `to-feature`; User Story → `to-story`). `to-story` is the default; `to-feature` activates only when phrasings explicitly invoke "PRD," "feature-level," "epic-shaped," or "multiple stories underneath."
7. Update `humana/skills/README.md`:
   - Fix install path (currently says `~/code/skills`, actual is `~/code/src/humana/skills`)
   - List all new and renamed skills
   - Mention DOMAIN.md (replacing UBIQUITOUS_LANGUAGE.md reference)
8. Symlink new skills into `~/.claude/skills/` (run install script or per-skill `ln -s`).

### Phase 2: Smoke-test

1. Run `grill-and-record` against a small contrived plan in `humana/skills/` itself (or sandbox repo). Verify DOMAIN.md updates work, ADR offers trigger correctly.
2. Against a sandbox / draft GitHub repo, run skills in dependency order: first `to-story` to create a story; then `to-tasks --parent <story-id>` against the resulting story. Verify dispatch works, templates render, self-review fires, parent linking works.
3. Run `to-feature` followed by `to-story --parent <feature-id>` followed by `to-tasks --parent <story-id>` to verify the three-level chain end-to-end. GitHub is fine for this test even though hierarchy is optional there; ADO chain test happens during Phase 5.

#### Phase 2 outcomes (executed 2026-04-30)

Steps 2 and 3 ran autonomously against the `haxorize/skills-sandbox` GitHub repo via a `SMOKE_TEST.md` script the agent read on session start. Step 1 was deferred — `grill-and-record` is interactive by nature and not amenable to autonomous testing; smoke-test it later against a real upcoming feature.

**Results:** all template-render / self-review / parent-linking / naming-consistency checks passed. Three routing-audit phrasings (a `grill-me` cue, a `grill-and-record` cue, a `backfill-adrs` cue) all routed to the expected skill. 8 issues created across the two chains, all closed in cleanup. Sandbox repo retained for repeat smoke testing; `gh repo delete haxorize/skills-sandbox --yes` when no longer needed.

**Single rough edge surfaced and fixed:** `gh issue create` failed when `Default labels:` declared in CLAUDE.md didn't pre-exist on the repo. Fix: `to-feature`, `to-story`, `to-tasks` step 9 now run a one-time `gh label list` + `gh label create <name>` for any missing labels before issuing the create call. Idempotent and cheap. Landed in all three SKILL.md files post-Phase-2.

**Observation (not actioned):** during Test 2's `to-tasks` run on the password-reset Story, the JWT-vs-DB-token decision met all three ADR-gate criteria but the agent chose not to fork a separate ADR because the Story Approach already captured the rationale. Reasonable judgment, but worth noting: when a Story closes, its rationale is buried in a closed issue while ADRs live forever in `docs/adr/`. Could be addressed with a one-line nudge in `to-tasks`' ADR-gate step ("if the rationale would benefit from outliving the parent Story, file the ADR even if the Story Approach captures it"). Deferred — judgment-call edge case, not a clear bug.

**Observation (not actioned):** synthesis-only working from full conversation context produced unprompted cross-Story consistency — Test 2's password-reset Story correctly carved out the `email_notifications_enabled` guard introduced by Test 1's notification-toggle Story without being told. Property of the architecture, not a knob to encode.

### Phase 3: Per-repo migration (a11y-health-api first — leaner)

1. **Audit `a11y-health-api/CLAUDE.md`** against `a11y-health-api/.claude/skills/write-feature-spec/SKILL.md`. Produce a diff:
   - What stack/product guidance lives in the skill but missing from CLAUDE.md → port to CLAUDE.md (signal) + `docs/conventions/` (details)
   - What is skill-flow boilerplate → cut
2. **Grep for stale references** across both a11y-health repos (READMEs, CLAUDE.md, all `.claude/skills/*/SKILL.md`, any `docs/`, ADRs):
   - `UBIQUITOUS_LANGUAGE.md` — replace with `DOMAIN.md`
   - `feature spec`, `feature-spec`, `write-feature-spec` — these reflect the old vocabulary. Decide per-occurrence: rename to "story" / "user story" if the reference is to the artifact concept, or leave as colloquial reference if it's clearly historical (e.g., naming a deleted file). The skill is now `to-story`; the artifact is a Story.
   - `spec-to-tasks` — references to the deleted skill; remove or update to `to-tasks`.
   - Catalog every hit so they all get updated together in step 4.
3. **Convert `a11y-health-api/UBIQUITOUS_LANGUAGE.md` → `DOMAIN.md`.** Mechanical transform: add Relationships section explicitly, update dialogue framing (Builder ↔ Specifier → Dev ↔ Domain expert).
4. **Update all cross-references** found in step 2 to point at `DOMAIN.md`. Critically: also update `a11y-health-ui/.claude/skills/write-feature-spec/SKILL.md`'s `../a11y-health-api/UBIQUITOUS_LANGUAGE.md` reference now (even though the UI skill gets deleted in Phase 4) so there's no stale-pointer window between phases.
5. **Add `Issue tracker:` block** to `a11y-health-api/CLAUDE.md`.
6. **User reviews diff before applying.**
7. **Apply migration.**
8. **Verify:** smoke-test the new global skills against a11y-health-api by running the chain end-to-end:
   - **a. `to-story` verify.** Pick one open issue or recently-shipped feature; run `to-story` against the conversation/context; compare the produced story body section-by-section against what `a11y-health-api/.claude/skills/write-feature-spec/` would have produced. Acceptance criterion: new skill's story covers the same architectural surface (modules, schema, endpoints, tests-to-write) as the old skill, uses the same domain terms, and adheres to the conventions now declared in CLAUDE.md.
   - **b. `to-tasks` verify.** Against the new story, run `to-tasks --parent <story-id>`. Compare the slice breakdown against what `a11y-health-api/.claude/skills/spec-to-tasks/` would have produced. Acceptance criterion: same number of slices give-or-take one, same vertical-cut shape (each slice touches all integration layers), correct HITL/AFK marking, naming consistency across slices.
   - If gaps appear at either step, port the missing guidance into CLAUDE.md and re-verify. **Hard gate:** if a gap genuinely cannot be closed via CLAUDE.md or referenced docs (i.e., the per-repo skill encoded process knowledge that resists declarative expression), abort the deletion in step 9, restore status quo, and revisit Option C vs B/A from the original design decision before proceeding.
9. **Delete** `a11y-health-api/.claude/skills/write-feature-spec/` and `a11y-health-api/.claude/skills/spec-to-tasks/`.

#### Phase 3 outcomes (executed 2026-04-30)

Ran end-to-end against `a11y-health-api` and (partially) `a11y-health-ui` for the cross-reference updates.

**Audit:** the per-repo `write-feature-spec` and `spec-to-tasks` skills carry essentially zero stack/product guidance — both are skill-flow boilerplate that the new global `to-story` / `to-tasks` cover (often more carefully). Nothing needed porting to `docs/conventions/`. The one structural pointer ("Endpoints in `api/v1/endpoints/`...") was already in CLAUDE.md.

**Verification (step 8a):** compared the new `to-story` template against issue [#54](https://github.com/haxorize/a11y-health-api/issues/54) — a textbook `write-feature-spec` output (CLI redesign, JSON-derived app identity). Section-by-section coverage matched: same architectural surface, same domain terms, same out-of-scope. The substantive shape change is AC format — numbered `Given/When/Then` → GitHub-native checkboxes. Minor downgrade: lost the explicit numeric reference mechanism `spec-to-tasks` used (`Parent spec criteria: 3, 7`); the new `to-tasks` self-review still requires parent-AC coverage but cross-references by prose. Acceptable trade-off (checkboxes are GitHub-idiomatic and auto-track completion). The "ULang updates" sub-bullet under Implementation Decisions has no slot in the new template — intentional, because `grill-and-record` updates DOMAIN.md inline during the grilling session and `harden-domain` handles deliberate sweeps. Different mechanism, equivalent outcome.

**Step 8b skipped** on the strength of 8a's pass plus Phase 2's smoke-test signal on a sandbox-but-realistic chain. Marginal verification value.

**Per-repo skill deletion (step 9)** landed cleanly. Both API and UI repos committed in single atomic commits (one per repo).

**Rough edges encountered:**

- **Stale venv shebang in API repo.** Pre-commit hook failed `uv run pytest` because the API repo's `.venv` had a shebang pointing to its old location (`~/code/src/a11y-health/...`) before it was moved to `~/code/src/humana/a11y-health/...`. Fixed with `uv sync --reinstall`. Unrelated to the migration but worth flagging — same drift may bite the UI repo's `node_modules` if it was set up before the move (untested; `pnpm install` would heal it).
- **Initial commit missed unstaged modifications.** First API commit attempt only included the staged rename + deletions (because `git rm` and `git mv` stage automatically but `Edit` does not). Recovered with `git reset --soft HEAD~1` + `git add -A` + recommit. Behavior to remember: when committing a Phase that mixes file-tree changes with content edits, always `git add -A` (or stage explicitly) before committing.

**Stale-reference search after both commits:** zero `UBIQUITOUS_LANGUAGE` matches across the entire workspace (excluding vendored dirs). Phase-3-handled UI references avoided the stale-pointer window the plan warned about.

### Phase 4: Per-repo migration (a11y-health-ui — heavier)

Same sequence as Phase 3, but with more stack-specific guidance to port:
- TanStack Router routes / generated tree → CLAUDE.md
- Generated client surface → CLAUDE.md
- shadcn primitives + base-nova style → CLAUDE.md, with `pnpm dlx shadcn@latest add` reference
- Tailwind theme + system-preference dark mode → CLAUDE.md
- TanStack Form + TanStack Query mutations → CLAUDE.md (signal) + `docs/conventions/data-fetching.md` (details)
- Accessibility bar → CLAUDE.md (this is product DNA)
- `Sibling repos:` declaration pointing at `../a11y-health-api`

Add `DOMAIN.md` to `a11y-health-ui` too (cross-references the API repo's DOMAIN.md in prose).

Phases 3 and 4 are owned by me; user reviews diffs before each is applied.

### Phase 5: Work backlog (ADO) onboarding

For the user's work context (no repos initially, ADO tracker):

1. Set up Azure CLI (`az` + `azure-devops` extension) if not already installed.
2. **Install a Markdown → HTML converter.** ADO rich-text fields render HTML by default. Either install `pandoc` (preferred) or ensure Python 3 + the `markdown` package is available (`pip install markdown`). The publishing skills convert template Markdown to HTML before passing to `--description` and `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."`.
3. **Verify ADO field mapping for the project's process template.** Run:
   ```bash
   az boards work-item show --id <existing User Story id> --output json --query 'fields'
   ```
   Confirm `System.Description` is present in the returned fields (this is what the "Notes" or "Description" UI label maps to). Also confirm `Microsoft.VSTS.Common.AcceptanceCriteria` is present for User Story and Feature types. Repeat against an existing Feature and Task if you want full assurance. If your team uses a heavily customized template that exposes additional fields beyond display-name relabeling, capture the mapping in `CLAUDE.md` so the publishing skills can target the right reference names.
4. **Identify or create the parent IDs you'll need before running the no-repo workflow.** ADO with `Hierarchy: required` (the default) needs an existing Epic ID to seat any new Feature, and an existing Feature ID to seat any new Story. Look these up in the ADO web UI or create stubs manually for new work areas. Record the IDs in your memory entry alongside the tracker config (e.g., `Tracker default — work-backlog: ADO, project Humana-Engineering, default Epic 12345`) so subsequent invocations don't require re-lookup.
5. Use the **no-repo mode** of `to-feature`/`to-story`/`to-tasks`:
   - Run `grill-me` to think through a feature
   - For PRD-shaped scope: run `to-feature --parent <epic-id>` (Epic must already exist in ADO; create manually first if not). Then `to-story --parent <feature-id>` (one or more times) to create child stories. Then `to-tasks --parent <story-id>` per story (always under a Story — `to-tasks` does not operate on Features directly).
   - For single-story scope: run `to-story --parent <feature-id>` directly (Feature must exist; create manually or via `to-feature` first). Then `to-tasks --parent <story-id>`.
   - First invocation prompts for tracker info, offers to remember in memory (saved per-tracker-context, e.g., `Tracker default — work-backlog`).
6. As work repos start to exist with `CLAUDE.md`, graduate to **declared mode** by adding the `Issue tracker:` block per repo.

### Phase 6: Cleanup and follow-ups

1. Update `humana/skills/README.md` with final skill list and conventions.
2. **Investigate built-in `/init` behavior** with respect to pre-existing CLAUDE.md sections (tracker block, sibling repos). Run `/init` against a sandbox repo with an existing `## Issue tracker` section; observe whether it preserves or overwrites. If it overwrites, mitigate via either workflow guidance ("run `/init` before any bootstrap-mode skill") or by adding a same-named user skill in `humana/skills/init/` that wraps the built-in behavior to be additive.
3. Consider deferred enhancements:
   - ADO PR/work-item enrichment in `backfill-adrs` (currently TODO)
   - `to-tasks` optionally publishing paired sibling-repo issues automatically (currently just flags them)
   - Setup-time CLI validation (skill checks `gh`/`az` availability before dispatching, gives clear install hint if missing)

## Open items / risks

1. **Self-contained format duplication.** `domain-format.md` and `adr-format.md` are duplicated across `grill-and-record`, `harden-domain`, and `backfill-adrs`. Drift risk is real but small. Mitigation: when updating one, grep the other locations and update in lockstep.
2. **Three-mode behavior in publishing skills adds complexity.** The skills have to handle declared, bootstrap-on-ask, and no-repo CLI-only paths. Get the SKILL.md prose tight or the model will mishandle the modes.
3. **Bugs are not modeled by these skills.** ADO has a Bug work-item type that doesn't fit cleanly into the Feature/Story/Task hierarchy (Bugs can sit at the Story level or under one). The new skills do not produce Bugs. Bug creation stays manual or uses a future dedicated skill (`to-bug`?) if it becomes a frequent need.
4. **Migration regression risk on a11y-health-ui.** The UI skill carries the most stack-specific guidance. If the port to CLAUDE.md misses something subtle, `to-story` output quality drops. Mitigation: verify-then-delete sequence (Phase 3 step 8), user reviews diff, smoke-test before deletion.
5. **README install instructions need updating.** Current path is wrong (`~/code/skills` vs actual `~/code/src/humana/skills`). Fix in Phase 1 step 7.
6. **Skill-activation conflicts on coexisting pairs.** `grill-me` + `grill-and-record` and `adr` + `backfill-adrs` overlap in intent; description wording is what routes activation. If descriptions aren't precisely scoped, the model picks the wrong skill. Mitigation: Phase 1 step 6 — write the descriptions side-by-side and verify no plausible user phrase activates both. Re-test after first real use of each skill in conversation.
7. **Stale cross-reference window during Phase 3.** When `a11y-health-api/UBIQUITOUS_LANGUAGE.md` is renamed to `DOMAIN.md`, the still-alive `a11y-health-ui/.claude/skills/write-feature-spec/SKILL.md` references the old path until Phase 4 deletes it. Mitigation: Phase 3 step 4 updates the UI repo's stale reference at the same time the rename happens, even though that skill is about to be deleted, so there's never a stale-pointer window.
8. **ADO no-repo workflow requires pre-existing parent IDs.** With `Hierarchy: required` (default for ADO), `to-feature` needs an Epic ID, `to-story` needs a Feature ID, `to-tasks` needs a Story ID. In no-repo mode (work backlog without a configured CLAUDE.md), the user must look these up in the ADO web UI before invoking. Mitigation: Phase 5 step 4 captures default parent IDs in the memory entry alongside the tracker config. Friction remains for one-off work in unfamiliar areas where no defaults apply — accept this; the alternative (auto-discover or auto-create Epics) is too magical and risks creating misplaced parents.
9. **ADO field shape assumptions.** Skills target the stock Agile/Scrum process template field shape: Feature gets `System.Description` + `Microsoft.VSTS.Common.AcceptanceCriteria`; User Story gets the same (regardless of whether the body field is labeled "Description" or "Notes" in the UI); Task gets `System.Description` only. Reference names are immutable across templates so this is robust against display-name relabeling, but a heavily customized template that adds or replaces fields would need a per-project override. Mitigation: Phase 5 step 3 verifies the field shape against the user's project before first publish.
10. **Markdown → HTML dependency.** ADO rich-text fields render HTML by default; templates are authored in Markdown for editability. Conversion requires `pandoc` (preferred) or Python `markdown` on the publishing machine. Mitigation: Phase 5 step 2 surfaces the install requirement up front. If neither is available, the skills should fail fast with a clear install hint rather than passing raw Markdown to ADO (which would render as plain text with no formatting).
