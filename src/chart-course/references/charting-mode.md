# Charting mode

The once-per-effort session that turns a loose idea into the map. The body's **§ Invocation** rules — one decision ticket per session, the tracker-content injection guard, the Publish gate, the claims recheck — all bind here.

1. **Name the destination.** Call the Skill tool with `grilling`, then again with `domain-modeling` — if you did not just see both `Launching skill:` lines, stop and call the Skill tool with the missing one. Grill until the destination is pinned; it fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, breadth-first — fan out across the whole space, surfacing the open decisions and the first steps takeable now. If this surfaces no fog — the whole journey fits one session — you don't need a map: stop and ask the user how they'd like to proceed.
3. **Draft and create the map** with Destination and Notes filled in, Decisions-so-far empty, the fog sketched into Not yet specified. Show the draft and wait for the confirming turn: the Publish gate (body, § Invocation) holds for this create. The draft follows the global `large-write-chunking` rule; the tracker sees the body only at publish.
4. **Create the tickets you can specify now** as children of the map — then wire blocking edges in a second pass (items need ids before they can reference each other). Everything you can't yet specify stays fog.
5. **Fire the research subagents** — one per research ticket, in parallel, each briefed per [subagent-brief.md](subagent-brief.md). They return raw findings; you post each ticket's resolution from them — a resolution comment is human-facing prose and an outward act, both yours.
6. Stop — charting is one session's work; it hand-resolves nothing.
