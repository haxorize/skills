# Feature template — GitHub

Use this body when publishing a Feature-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

Assemble the body from the skeleton in [feature-body.md](feature-body.md), placing each section below at one anchor: `## Acceptance criteria` after `## Non-goals` (acceptance criteria live in the body on GitHub — there is no separate field), `## Stories underneath` after `## Constraints`, and `## Parent` at the end. AC IDs follow [ac-ids.md](ac-ids.md) — typed prefixes, append-only, removed-criteria record, and why the worked examples skip `AC3`.

```markdown
## Acceptance criteria

- [ ] **AC1:** Specific, testable Feature-level outcome
- [ ] **AC2:** Specific, testable Feature-level outcome
- [ ] **AC4:** Specific, testable Feature-level outcome

## Stories underneath

Sub-features that decompose this Feature. Each one becomes its own Story (file via `to-story --parent <this-issue-number>`).

- [ ] Story 1 — short title
- [ ] Story 2 — short title
- [ ] Story 3 — short title

## Parent

If filed under a parent (e.g., a tracking issue), link it here:

Parent: #<issue-number>
```

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
- Use checkboxes in `Stories underneath` so the parent issue auto-tracks completion as child stories close.
- For projects with `Hierarchy: required` set in CLAUDE.md, `to-feature` embeds a story-map block at the bottom of the body **in place of** `Stories underneath` — the two are alternatives, never nested: without hierarchy the `Stories underneath` checklist stands in for the map (`to-feature` SKILL.md step 2). The ADO template carries the block structure, in its own `## Story Decomposition` section; `to-feature` SKILL.md step 6 describes it only on its ADO path.
