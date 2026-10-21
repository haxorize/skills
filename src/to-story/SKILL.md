---
name: to-story
description: Publish a Story — a single-feature spec synthesized from the conversation — to the project's tracker (an ADO User Story under a Feature, or a GitHub issue). Use when asked to file, create, or open a story, an issue, or a ticket for one deliverable, or to update a published story. Not for scope needing several stories (to-feature), splitting a story into tasks (to-tasks), or a defect (to-bug). Not for drafting or critiquing a body without filing it (work-item-shape).
argument-hint: "[--parent <feature-id>] [--update <story-id>] [--priority <1-4>]"
requires: writing-for-humans, work-item-shape, diverging
---

# To Story

Synthesize the current conversation into a Story-level artifact (single-feature spec) and publish it to the project's tracker. No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

Use `to-feature` only when scope explicitly needs multiple stories beneath it.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape`. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here: `## Approach`, `## Layers touched`, `## Tests`, and all others describe behavior and design intent only.

## Workflow

### 1. Resolve tracker

Resolve the tracker per `~/.claude/skills/work-item-shape/references/tracker-resolution.md`; the tracker script is `work-item-shape`'s, run as `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py`.

### 2. Resolve parent

On ADO, in no-repo CLI-only mode, save the resolved Feature ID to the same memory entry `tracker-resolution.md` keys by tracker context, so the next invocation does not re-look it up.

- **`Hierarchy: required`** (default for ADO): if `--parent <feature-id>` is provided, use it; otherwise interactively prompt for the Feature ID. If no Feature exists, suggest `to-feature` first or (only if team config allows top-level Stories) accepting a parentless Story.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

### 2a. Snapshot lookup (where `Hierarchy: required`)

See [references/ado-hierarchy.md](references/ado-hierarchy.md) for the snapshot-lookup procedure; its outcome classifies the story as **Planned** (Snapshot match) or **Emergent**, which steps 10-11 key on.

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`. Where a prototype answered this story's question, read its `notes.md` — the answer, never the throwaway code. `prototype` leaves it next to the prototype code on a `prototype/<name>` branch, not in a `prototype/` directory, so find it with `git log --all --name-only --format= -- '*notes.md'` and read it at that branch. When the search is empty, the answer went straight into an ADR or `DOMAIN.md` because the user was around, or the work item carries the pointer `prototype` left to the branch; absent all three, no prototype answered this story.

### 4. Sketch major modules

Name the modules to build or modify, and look for opportunities to extract deep modules. Check with the user that the module shape matches expectations and which modules they want tests for.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. This is a pre-publication direction check, not interviewing: present it once; if the user pushes back, revise and re-present once — do not loop, exhaustive trade-off exploration belongs in `grill-me`. Skip only when there's genuinely one defensible shape, and say why no second one holds. Distinct means the sketches trade off different things, not wear different dress: when two of the set collapse into one on inspection, the set holds one approach fewer than it claims, and that collapse is the fixation `diverging` breaks — call the Skill tool with `diverging` before re-proposing, and only then.

### 6. Draft the story

The draft *file* lands per section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`); the tracker sees the body only at publish.

Classify the story as user-facing (has a real user role with a stated goal) or non-user-facing (refactor, infra, observability, dependency upgrade, security hardening). User-facing stories lead the body with a Connextra user-story line (`**User story:** As a [role], I want [goal] so that [benefit].`); non-user-facing stories omit it and describe the developer-facing or operational outcome in `## User-facing behavior` instead.

Use the appropriate template:
- GitHub: [references/story-template-github.md](references/story-template-github.md)
- ADO: [references/story-template-ado.md](references/story-template-ado.md)

**On ADO, draft the body and the acceptance criteria as two separate artifacts — the two-field split.** ADO stores them in two fields, so carve them apart here, while you're thinking about content, rather than at publish time. The acceptance bullets are never a section of the body.

### 7. Self-review

Before showing the user, check:

- Placeholders (no TBD/TODO)
- Contradictions between sections
- Scope (focused enough for one story, or needs decomposition into a Feature)
- Ambiguity (any requirement readable two ways)
- Domain language matches `DOMAIN.md`
- AC IDs: append-only — no reused IDs across active and `## Removed acceptance criteria`; gaps from removals preserved (no renumbering)
- On ADO: the **two-field split** holds (step 6) — acceptance bullets are their own artifact
- `## Layers touched` populated for each layer (`none` is a valid value; missing layers are not)
- **Naming drift** vs. the parent's story map (where `Hierarchy: required`) — `work-item-shape`'s rule, surfaced before publish
- User-story line matches step 6 classification (Connextra for user-facing, absent otherwise); its "so that" carries a motivation the "I want" does not restate
- Documentation obligations, for stories that alter architecture or domain terms: ADR to write or edit, architecture-doc sections that go stale, glossary entries — each pinned as its own AC so a reviewer can't merge without them

Then run the **Cold-reader pass** from the `work-item-shape` discipline: the cold reader gets only the drafted body and answers "what would you build?".

### 8. Present draft to user

Iterate until approved.

### 9. Publish via tracker dispatch

The **Publish gate** in `~/.claude/skills/work-item-shape/references/publishing.md` holds first.

- **GitHub:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type "User Story" --title '<drafted title>' --body <scratchpad>/<draft>.md --parent <feature-number> --workdir <scratchpad>`, dropping `--parent` when there is none and adding `--debt` per `~/.claude/skills/work-item-shape/references/publishing.md` § Flags the script cannot derive. The script applies the default labels and links the issue as a native sub-issue of the parent; the template's `Parent: #N` body line stays, since `/implement`'s ticket load reads it.
- **ADO:** publish with the create call in [references/story-template-ado.md](references/story-template-ado.md) — the **two-field split**, body into `System.Description` and acceptance bullets into `Microsoft.VSTS.Common.AcceptanceCriteria`, each its own file. `--priority <1-4>` (an integer 1–4; a caller such as `inventory-cvits` decides the value) goes onto the same create as `--field "Microsoft.VSTS.Common.Priority=<n>"`. GitHub has no priority field and ignores it.

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow `~/.claude/skills/work-item-shape/references/publishing.md` — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

**An `incomplete=readback` exit 5 means the Story is written but not finished (ADO)** — on any create or patch carrying acceptance criteria, update mode included. Never re-run the create; the patch is in `~/.claude/skills/work-item-shape/references/publishing.md` `## Transport safety`.

### 10. Update parent's story map (where `Hierarchy: required`)

Gated on the parent tracker enforcing hierarchy — ADO default; GitHub projects opt in via CLAUDE.md.

See [references/ado-hierarchy.md](references/ado-hierarchy.md) for full procedures for both Planned Stories (stamp the snapshot) and Emergent Stories (append below the separator). The Story always publishes regardless of map-update outcome.

### 11. Materialize dependency relations (ADO only)

Native dependency relations are an ADO feature, so this step runs only on ADO — not on a GitHub project that opted into `Hierarchy: required` for Step 10, where story dependencies stay map-only. See [references/ado-hierarchy.md](references/ado-hierarchy.md) Step 11 for the projection procedure. The Story always publishes regardless.

## Update mode

`--update <story-id>` patches an existing Story in place. See [references/story-update-mode.md](references/story-update-mode.md) for cold-start commands, AC ID handling rules, self-review checks, re-snapshot prompt, reconcile prompt, and patch commands.

## Naming drift

On publish or an `--update` patch, run `work-item-shape`'s **Naming drift** rule against siblings (Stories under the same parent Feature, Tasks under this Story).
