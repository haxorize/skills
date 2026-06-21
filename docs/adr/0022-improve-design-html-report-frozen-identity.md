# improve-design presents candidates as an HTML report with a frozen, authored identity

`improve-design` Step 3 presents its vetted deepening candidates as a self-contained HTML report (Tailwind + Mermaid via CDN) written to the OS temp directory and opened in the browser, rather than as an inline text list alone — the conversation keeps only a terse ordered list (number, title, leverage/confidence chips, one-line problem) for the pick and the transcript record, while the report carries the full per-candidate detail and the before/after deepening visuals. The report's visual identity is **designed once and frozen** into `references/html-report.md` (palette, type, the Ousterhout depth-rectangle signature, diagram primitives, Mermaid theme config) — authored by applying the `frontend-design` skill's method *at authoring time*, deliberately **not** by prose-invoking `frontend-design` at runtime on every scan.

## Considered Options

- **Status-quo text-only** (inline numbered list, no report) — rejected: the before/after depth visualization is the whole reason to present candidates graphically, and text can't carry it.
- **Runtime-bespoke via `frontend-design`** (regenerate the design each scan against "this codebase" as the brief) — rejected: it gives the report no recognizable identity, injects aesthetic-exploration latency and token cost into every scan, and makes tool output unpredictable. A recurring tool report wants the opposite of bespoke-per-brief; per `frontend-design`'s own "spend your boldness in one place," that boldness is spent once, at authoring time. It would also be a load-bearing runtime delegation, which ADR-0019 confines and we avoid here.
- **Zero-CDN, fully self-contained** (inlined CSS + hand-built SVG, no Tailwind/Mermaid) — considered for true offline-portability and maximal "our own" identity; not chosen — the CDN path keeps runtime authoring cheap (Tailwind utilities + Mermaid for graph-shaped diagrams) and the frozen custom `<style>` layer plus a Mermaid theme config supply the distinct identity without hand-rolling every primitive.
- **shadcn-style in-repo `plans/`** (durable artifacts committed to the repo) — rejected: `improve-design` is read-only and its durable record is the tracker work item; the report is an ephemeral presentation artifact, frozen at pick-time, that never enters the repo.

## Consequences

- The report is ephemeral: temp-dir, timestamped per run, frozen at the moment a candidate is picked (not regenerated as the design evolves through grilling). The durable record remains the conversation plus the filed work item.
- Only Step 3 changes; the shared `finding-discipline.md` (vet/format/rank, also used by `review-changes`) is untouched — the report is a new presentation *container* for already-vetted findings, not a new discipline.
- Badges are derived from the existing `leverage` and `confidence` axes, not from a new `Strong`/`Worth exploring`/`Speculative` scale, to avoid alias bloat against `DOMAIN.md`'s ranking vocabulary.
- Zero surviving candidates → no report is written; the result is reported inline. One or more → the report is written.
