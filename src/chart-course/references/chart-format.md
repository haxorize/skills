# Chart formats

## Map body

ADO: the map Feature's description. GitHub: the map issue's body.

```markdown
Chart-type: map

## Destination

<what reaching the end of this map looks like — the spec, decision, or change this
effort is finding its way to. One or two lines; every session orients to it before
choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort —
including any deliberate override of plan-don't-do>

## Decisions so far

<!-- the index — one line per closed ticket: enough to judge relevance, then zoom
the link for the detail the ticket holds -->

- [<closed ticket title>](link) — <one-line gist of the answer>

## Not yet specified

<!-- in-scope fog you can't ticket yet; graduates into tickets as the frontier advances -->

## Out of scope

<!-- work consciously ruled beyond the destination — gist + why, linking any closed
ticket; never graduates -->
```

Open tickets are **not** listed in the map body — they are open children, found by query.

## Decision ticket body

```markdown
Chart-type: <grilling | prototype | research | errand>

## Question

<the decision or investigation this ticket resolves>
```

The answer never lives in the body — it arrives as a **resolution comment** when the ticket closes:

```markdown
## Resolution

<the decision made, or the facts found, in full — this is the one place the detail lives>

Assets: <links to any prototype, document, or branch produced — linked, never pasted>
```

## ADO body handling

ADO description and comment fields expect HTML. Write the converted HTML to a file and pass its path with the CLI's `@` prefix (`--description @<file>`) — the content never crosses the shell; the commands are in [chart-tracker-ops.md](chart-tracker-ops.md) and the read-back in [publishing.md](publishing.md) `## Transport safety`.

## Titles

- **ADO:** bake `Chart: ` into the drafted title, then apply the CLAUDE.md tracker block's prefix resolution on top — for the map Feature, `Feature title prefix:` falling back to `Title prefix:`; for tickets, `Title prefix:`. Result: `[App] Chart: <question>`.
- **GitHub:** no marker — the `chart:*` labels carry the typing.
