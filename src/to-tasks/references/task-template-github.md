# Task template — GitHub

Use this body when publishing a Task-shaped child of a Story parent to GitHub via `gh issue create`. The title is set on the command line; this is the body.

Assemble the body from the skeleton in [task-body.md](task-body.md), appending the two GitHub-only sections below at the end.

```markdown
## Blocked by

- Blocked by: #<issue-number> — what specifically must land first
- Blocked by: ../<sibling-repo> — contract change required (file there first)

## Parent

Parent: #<issue-number>
```

GitHub has no native blocker relation, so both in-project and sibling-repo blockers are body text. Use real issue numbers if blockers were filed first (`to-tasks` publishes in dependency order so real IDs are available). If unblocked, omit the `## Blocked by` section.

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
