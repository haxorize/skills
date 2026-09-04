# Bug template — GitHub

Use this body when publishing a Bug-shaped issue to GitHub via `gh issue create`. The title is set on the command line. GitHub has no native Bug type — apply the `bug` label and a severity label.

Assemble the body from the skeleton in [bug-body.md](bug-body.md): lead with a `## Repro` section (the skeleton's repro-steps block, headed), then the skeleton sections, then the `## Parent` section below at the end.

```markdown
## Parent

Parent: #<issue-number>
```

Omit `## Parent` if parentless.

## Labels

Two label categories apply:

- **Type:** `bug` — applied unconditionally by `to-bug` on GitHub.
- **Severity:** one of the labels declared in CLAUDE.md's severity-labels block — a `## Bug severity labels` section (the canonical heading) or a `## Severity labels` section, either holding a `Scale:` line and a `Labels:` line.

If no such section exists under either name, bootstrap on ask:

- Ask the user for the team's severity scale (default offer: `critical, high, medium, low` mapping to labels `sev:critical`, `sev:high`, `sev:medium`, `sev:low`).
- Preview an appended `## Bug severity labels` section (`- Scale:` and `- Labels:` lines); write to CLAUDE.md on confirmation. **Always append, never overwrite** — and never append when a section under either name already exists.
- In no-repo CLI-only mode, save the resolved scale to memory keyed by tracker context (e.g., `Severity labels — work-backlog`).

## Severity definitions (default)

- **critical** — production outage, data loss, security incident; needs immediate response.
- **high** — broken core flow with no workaround; blocks a release or significant user segment.
- **medium** — broken non-core flow, or core flow with a workaround.
- **low** — cosmetic, edge-case, or minor inconvenience.

Teams override these by declaring `## Severity definitions` in CLAUDE.md alongside the severity-labels section.

## Notes

- Every label applied must already exist on the repo — SKILL step 9 reconciles missing ones before `gh issue create`.
- Bugs do not produce child Task issues. The fix is the slice; if more structure is needed, that's a Story.
- `from-ticket <issue-number>` recognizes a `bug`-labeled issue as a Bug and loads the Bug-shaped context.
