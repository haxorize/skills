# Story — ADO Hierarchy

Steps that only apply when `Hierarchy: required` is set (ADO default). Skip if using GitHub without opting in via CLAUDE.md.

## Step 2a — Snapshot lookup

After resolving the parent Feature ID:

```bash
az boards work-item show <feature-id> --output json
```

Parse `System.Description`. Extract content between `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->`; text above the `---` separator is the Snapshot.

If invoked with a story reference (e.g., `Story 2`, `S2`), search the Snapshot for a matching heading (e.g., `### Story 2`).

- **Match found (Planned Story):** Extract the entry's scope paragraph, `Covers:` line, and shared names as drafting source material (steps 3–6). Record the full matched heading line for the stamp in Step 10.
- **Multiple or partial matches:** surface the candidate headings to the user and ask which entry (or none) this Story is — never silently stamp the closest one.
- **No match or no story reference (Emergent Story):** Draft from conversation context. The Append-region append in Step 10 applies.

If the parent has no story-map markers but has a headed decomposition section (literally `<h2>Story Decomposition</h2>` in the HTML or `## Story Decomposition` as a Markdown heading — not an informal list or any other structure), treat as Emergent Story. If the parent has neither markers nor a headed decomposition section (or no parent), skip this step and treat as Emergent Story.

## Step 10 — Update parent's story map

**Planned Story** (Snapshot match in step 2a): Fetch the parent Feature's current description. **It is already HTML** — locate the matched Story heading in the raw HTML and append the new tracker ID as an HTML anchor, a targeted string replacement that modifies no other Snapshot content:

```html
<h3>Story 2 — short title — <a href="https://dev.azure.com/...">#<id></a></h3>
```

Write the modified HTML to a file and patch with its absolute path:

```bash
az boards work-item update --id <feature-id> --description @/absolute/path/feature_desc.html
```

**Emergent Story** (no Snapshot match): After publishing, fetch the parent Feature's description. Locate `<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`; append an entry below the separator with this Story's tracker ID, scope summary, parent Feature AC IDs it covers (`Covers: AC1, AC3`), and shared names. The Snapshot above the separator is immutable.

**HTML safety for both cases:** the fetched description is already HTML — convert **only the newly authored content** from Markdown to HTML (using the pandoc or Python one-liner from [ado-html-transport.md](ado-html-transport.md)), then append or splice the resulting fragment into the existing description HTML. Never pass fetched or combined content through pandoc or any Markdown → HTML converter: re-converting double-encodes the `<code>`, `<hr>`, and other HTML tags already present.

Three cases:

- **Has markers:** append using the standard marker-bounded region.
- **No markers, but has a headed `## Story Decomposition` section:** append to end of description; warn: "Parent feature has no story-map markers — appended to the end of the description. Consider adding `<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->` markers." An informal list or any other structure does not qualify.
- **No markers and no headed decomposition section (or no parent):** skip silently.

On failure: revision conflict → retry once with fresh fetch; permission denied → surface immediately (no retry); other error → surface with the published Story ID for manual update. The Story always publishes regardless.

## Step 11 — Materialize dependency relations

After Step 10 stamps this Story's ID into the map, project any Snapshot `### Dependencies` edge whose **both** endpoints are now published onto a built-in `Predecessor` relation. The relation graph is an additive, partial projection of the map — never delete a relation here. Reuse the description HTML already fetched and stamped in Step 10 to read the map; do not re-fetch the Feature.

Read the `### Dependencies` subsection. Each edge reads `Story B depends on Story A` — A is the **predecessor** (blocker), B the **successor** (dependent). Resolve each named Story to its Snapshot heading and read its stamped ID from that HTML. Step 10 appends the stamp as an HTML anchor (` — <a href="…">#<id></a>`), not a Markdown `[#<id>]` link — the ADO description is already HTML. An unstamped heading means that Story is not published yet — skip the edge.

Collect every edge that involves the Story just published, **in both directions** — the new Story as successor (its blockers) and as predecessor (the siblings that depend on it) — keeping only edges whose other endpoint is stamped. The relation always lands on the **successor**, so group the pending edges by successor ID.

For each distinct successor, fetch its existing relations once and build the set of `Predecessor` target IDs it already links:

```bash
az boards work-item show <successor-id> --output json --expand relations
```

Then add only the edges whose predecessor is not already in that set:

```bash
az boards work-item relation add --id <successor-id> --relation-type Predecessor --target-id <predecessor-id>
```

One fetch per successor, not one per edge, keeps republish idempotent without N redundant reads. `--update` never reaches this step — it skips the map-stamp and does not expand relations (see [update-mode.md](story-update-mode.md)) — so only create-mode republish is covered.

Both directions matter because Stories can publish out of map order — each edge then links the instant its second endpoint is stamped, with no separate reconcile pass. Emergent Stories (below the separator) carry no Dependencies edges and are skipped.

On failure: permission denied → surface immediately; other error → surface with both work-item IDs for manual linking. The Story always publishes regardless.
