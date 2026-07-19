---
name: chart-course
description: Chart a foggy, multi-session effort as a shared map of decision tickets on the project's tracker, then work them one per session until the way to the destination is clear. For efforts too big for one grill — the map ends where `to-feature`/`to-story` picks up. ADO — a map Feature with User Story tickets. GitHub — a map issue with sub-issue tickets.
disable-model-invocation: true
requires: grilling, domain-modeling
---

# Chart Course

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Charting a course is about finding that way, not charging at the destination. This skill builds a **Chart** — a shared map on the project's tracker — whose children are **decision tickets**: questions whose resolution is a decision, not slices of a build to execute. Work them one at a time until the way is clear.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. It might be a spec to hand off, a decision to lock before planning starts, or a change made in place. The map is domain-agnostic — engineering work, course content, whatever fits the shape.

## Plan, don't do

Each ticket resolves a decision; the Chart is done when nothing is left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off — a spec-shaped destination exits to `/to-feature` or `/to-story`. An effort can override this in the map's Notes, carrying execution into the map itself; absent that, produce decisions, not deliverables.

## The Chart

One work item is the map — ADO: a Feature; GitHub: an issue labeled `chart:map`. The Chart is a **discovery** Feature — in SAFe terms, enabler exploration — and is never the implementation Feature it drives: the Chart records the route walked (decisions, dead ends, out-of-scope rulings); the implementation work its destination produces is a separate artifact (see Closing the chart). Both map forms carry `Chart-type: map` in the body. **The body line is the source of truth for typing everywhere**; GitHub `chart:*` labels are an additive projection — apply them, surface a failed application for manual repair, never block on it. ADO uses no tags at all.

The map is an **index**, not a store: a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links. Open tickets are not listed in the map body; they are open children, found by query. Body templates: [references/chart-format.md](references/chart-format.md).

## Decision tickets

Each ticket is a child of the map — ADO: a User Story under the map Feature; GitHub: a native sub-issue (see [references/github-sub-issues.md](references/github-sub-issues.md)). The body leads with `## Question`, carries its `Chart-type:` line, and is sized to one agent session.

- **Title marker (ADO):** bake `Chart: ` into the drafted title *before* applying the tracker block's `Title prefix:` — yielding `[App] Chart: <question>` — so nobody scanning a board mistakes a question for a build-ready Story. On GitHub the labels carry this; skip the marker.
- **Claim by assignment.** Before any work, assign the ticket to whoever is driving it. Assignment *is* the claim: an open, unassigned ticket is unclaimed, and concurrent sessions skip claimed ones.
- **Blocking** uses the tracker's native dependency relations, so the frontier renders in the tracker's own UI. The **frontier** is the open, unblocked, unclaimed tickets — the edge of the known.
- The answer is never in the body — it's recorded on resolution. Assets created along the way are linked from the ticket, never pasted in.

In everything the human reads, refer to the map and its tickets by **name**, never bare id — see [references/tracker-resolution.md](references/tracker-resolution.md).

## Ticket types

Every ticket is either **HITL** — worked *with* a human who speaks for themselves; it only resolves through that live exchange, and the agent never stands in for the human's side of it — or **AFK**, driven by the agent alone.

- **Grilling** (HITL, the default): conversation via the `grilling` and `domain-modeling` skills — facts looked up, every decision put to the human.
- **Prototype** (HITL): raise the discussion's fidelity with a cheap, rough, concrete artifact to react to, via `/prototype`; link it from the ticket as an asset.
- **Research** (AFK): surface a fact a decision waits on — a subagent sweep over local resources, or `deep-research` for external questions. Findings land as the ticket's resolution comment; anything long-form is linked as an asset. The one type that resolves in parallel with other work.
- **Errand** (HITL or AFK): manual work that must happen *before* a decision can be made — provisioning access, signing up for a service, moving data so its shape can be seen. It *does* rather than decides, and earns its place only by unblocking a decision — never by delivering the destination. The agent drives what it can (AFK); otherwise it hands the human a precise checklist (HITL). The resolution records what was done and the facts later tickets depend on.

If the team speaks agile, **research and prototype tickets are spikes** — use the word freely in team-facing conversation; it is not the canonical term (grilling and errand tickets aren't spikes).

## Fog of war

The map is *deliberately* incomplete: don't chart what you can't yet see. The **Not yet specified** section holds the fog — decisions and investigations you can tell are coming but can't yet pin down. The admission test: can you state the *question* precisely now? (Not: can you answer it.) A sharp-but-blocked question is a ticket; anything fuzzier stays fog — don't pre-slice it, since one patch may graduate into several tickets, or none, once the frontier reaches it. Resolving tickets clears fog: graduate whatever's now specifiable into fresh tickets, removing it from the section.

## Out of scope

The destination fixes the scope; work beyond it is out of scope — not fog — and goes to the map's **Out of scope** section: the gist plus why, as a conscious ruling. When an existing ticket turns out to sit past the destination, **close it** and leave that one line linking the closed ticket. It stays out of Decisions so far, which records only the route actually walked. Out-of-scope work never graduates; it returns only if the destination is redrawn, as a fresh effort.

## Invocation

Two modes. Either way, **never resolve more than one decision ticket per session** — research tickets excepted. Expect other sessions to be editing the tracker concurrently.

### Chart the course

User invokes with a loose idea. Resolve the tracker first ([references/tracker-resolution.md](references/tracker-resolution.md)).

1. **Name the destination.** Run the `/grilling` and `/domain-modeling` skills — if you did not just see both `Launching skill:` lines, stop and load the missing one. Grill one question at a time until the destination is pinned; it fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, breadth-first, in `grilling`'s **batch cadence** — fan out across the whole space, surfacing the open decisions and the first steps takeable now. If this surfaces no fog — the whole journey fits one session — you don't need a map: stop and ask the user how they'd like to proceed.
3. **Create the map** with Destination and Notes filled in, Decisions-so-far empty, the fog sketched into Not yet specified.
4. **Create the tickets you can specify now** as children of the map — then wire blocking edges in a second pass (items need ids before they can reference each other). Everything you can't yet specify stays fog.
5. **Fire the research subagents** — one per research ticket, in parallel, each posting its findings as the ticket's resolution.
6. Stop — charting is one session's work; it hand-resolves nothing.

### Work the chart

User invokes with the map (URL or id); a ticket is optional — without one, you pick the next decision, not the user.

1. **Load the map** — the low-res view, not every ticket body.
2. **Choose the ticket.** The named one, else the first frontier ticket in order. **Claim it** before any work.
3. **Resolve it** — zoom as needed: fetch related or closed tickets on demand; invoke the skills the map's Notes name. Default is a grilling ticket: run the `/grilling` and `/domain-modeling` skills (same load gate as charting step 1).
4. **Record the resolution:** post the answer as a resolution comment, close the ticket, and append a one-line gist to the map's Decisions so far.
5. **Update the map:** graduate newly-specifiable fog into tickets (create, then wire); rule mis-scoped tickets out of scope rather than resolving them; update or delete tickets the decision invalidated.

## Closing the chart

When a session's map update leaves nothing — no frontier, no fog, no open tickets — the way is clear, and the Chart closes by handing off:

1. **Hand off the destination.** A spec-shaped destination goes through `/to-feature` or `/to-story` (usually a fresh session with the map as context); a locked decision or in-place change is simply its final ticket's resolution.
2. **Link both ways.** The successor artifact carries a `Discovery: <chart link>` line; the map gets a final comment linking what the effort produced.
3. **Close the map** work item. The Chart stays behind as the route record — never rewrite its body into the spec it produced.

## Tracker operations

Create, claim, block, frontier query, and resolve — per tracker: [references/chart-tracker-ops.md](references/chart-tracker-ops.md).
