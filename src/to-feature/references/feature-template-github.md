# Feature template — GitHub

Use this body when publishing a Feature-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

Assemble the body from the skeleton in [feature-body.md](feature-body.md), inserting the two GitHub-only sections below after `## Non-goals` (acceptance criteria live in the body on GitHub — there is no separate field) and the `## Parent` section at the end; `## Stories underneath` sits after `## Constraints`. AC IDs follow [ac-ids.md](ac-ids.md) — typed prefixes, append-only, removed-criteria record, and why the worked examples skip `AC3`; omit the removed-criteria heading if nothing has been removed.

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
- For projects with `Hierarchy: required` set in CLAUDE.md, `to-feature` embeds a story-map block in the body's `Stories underneath` section. The ADO template carries the block structure; `to-feature` SKILL.md step 10 describes it only on its ADO path.
