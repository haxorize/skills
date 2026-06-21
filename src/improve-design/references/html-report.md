# The HTML candidate report

How `improve-design` Step 3 renders vetted deepening candidates as a self-contained HTML file.
This identity is **frozen** — designed once and reused every run (see ADR-0022). Don't redesign it
per scan; fill the scaffold with this run's candidates. The conversation still carries the terse
ordered list for the pick; this file is the rich, visual record the user reads.

## Identity — "structural section drawing"

The report's one job: let an engineer compare deepening candidates and pick one. The signature is the
**Ousterhout depth-rectangle** — a module drawn as a rectangle whose *top edge is its interface width*
and whose *body is its implementation*. Depth is encoded twice: by vertical extent **and** by color
saturation — a shallow module reads pale and flat, a deep module reads dark and dimensional. That dual
encoding is the one aesthetic risk; spend boldness there and keep everything else quiet.

This is deliberately *not* Matt Pocock's stone/emerald/Mermaid-neutral look, and it steers clear of the
three AI-default palettes (cream+serif+terracotta, near-black+acid, broadsheet hairline).

### Tokens

```
--paper:    #ECEFF1   /* cool drafting ground — not white, not cream */
--ink:      #1B2A32   /* deep petrol-slate — body + headings */
--depth:    #0E5A57   /* petrol-teal — the deep module, leverage, the one accent */
--depth-d:  #0A3D3B   /* darker base for the deep-module gradient */
--shallow:  #C8D2D4   /* pale desaturated teal-gray — shallow module fill */
--leak:     #C0392B   /* brick red — seam leakage only */
--warn:     #9A6B00   /* dark goldenrod — ADR-reopen callouts only */
```

Type (Google Fonts via CDN): **Archivo** for display/headings (structural, wide grotesque — reads as
mass), **IBM Plex Sans** for body, **IBM Plex Mono** for file paths, module labels, and all schematic
diagram text. Module labels inside diagrams are `Plex Mono, text-xs uppercase tracking-wider` so they
read as schematic, not as UI. Colour sparingly: `--depth` is the *only* accent; `--leak` and `--warn`
are signals, never decoration.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Design review — {{repo}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link href="https://fonts.googleapis.com/css2?family=Archivo:wght@600;800&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({
        startOnLoad: true, securityLevel: "loose", theme: "base",
        themeVariables: {                       /* match the identity, not default Mermaid */
          fontFamily: "IBM Plex Mono, monospace", primaryColor: "#ECEFF1",
          primaryBorderColor: "#1B2A32", primaryTextColor: "#1B2A32",
          lineColor: "#1B2A32", tertiaryColor: "#C8D2D4",
        },
      });
    </script>
    <style>
      :root{ --paper:#ECEFF1; --ink:#1B2A32; --depth:#0E5A57; --depth-d:#0A3D3B;
             --shallow:#C8D2D4; --leak:#C0392B; --warn:#9A6B00; }
      body{ background:var(--paper); color:var(--ink); }
      .display{ font-family:"Archivo",sans-serif; }
      .mono{ font-family:"IBM Plex Mono",monospace; }
      .seam{ stroke:var(--ink); stroke-dasharray:5 4; }     /* seam = dashed */
      .leak{ stroke:var(--leak); stroke-width:2; }           /* leakage = brick red */
      .mod-shallow{ background:var(--shallow); color:var(--ink); }
      .mod-deep{ background:linear-gradient(160deg,var(--depth),var(--depth-d)); color:var(--paper); }
      @media (prefers-reduced-motion:no-preference){ .reveal{ animation:rise .5s ease both; } }
      @keyframes rise{ from{ opacity:0; transform:translateY(8px);} to{ opacity:1; transform:none;} }
    </style>
  </head>
  <body class="font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Report title (`Design review — {{repo}}`), date, and a compact **legend** that teaches the visual
language in one glance — and *is itself* a depth-rectangle key: narrow-top dark box = deep module,
wide-top pale box = shallow module, dashed line = seam, red arrow = leakage, amber box = ADR warning.
No intro paragraph; straight into candidates.

## Candidate card

One `<article class="reveal">` per candidate, ordered by leverage. The diagram carries the weight;
prose is sparse and uses the glossary terms (`codebase-design`) without ceremony.

- **Title** — names the deepening (e.g. "Collapse the billing rollup pipeline").
- **Badge row** — a **leverage-tier** badge (High/Medium/Low, `--depth`-filled for High) and a
  **confidence** chip (HIGH/MED/LOW), plus a dependency-category tag (`in-process`,
  `local-substitutable`, `remote-but-owned`, `true-external`). Derived from the existing ranking
  axes — never a `Strong`/`Speculative` scale (ADR-0022).
- **Files** — `mono text-sm` list of involved modules with `file:line` evidence.
- **Before / After diagram** — the centerpiece (patterns below).
- **Problem** — one sentence. What hurts.
- **Solution** — one sentence. What changes.
- **Wins** — bullets, ≤6 words, in glossary terms ("locality: bugs concentrate here", "one interface,
  N call sites"). Not "easier to maintain".
- **ADR callout** (only if the candidate reopens one) — one line in a `--warn`-tinted box.

If a paragraph is needed to explain a diagram, redraw the diagram.

## Diagram patterns

Pick the one that fits; mix them so cards don't all look alike.

- **Depth-rectangle (the signature, default for shallow→deep).** Two `<div>`s side by side. Before:
  a `.mod-shallow` box, wide-but-thin, with leaked deps as `.leak` arrows crossing a `.seam` to
  outside boxes. After: a tall `.mod-deep` box with the now-internal deps drawn faded *inside* it and
  a narrow interface strip on top. Reads as "the interface shrank; the implementation absorbed the
  wrappers."
- **Mermaid graph (only when genuinely graph-shaped** — call/dependency mess). `flowchart` styled by
  the theme config above; `classDef leak stroke:#C0392B` for leakage edges, the deep node filled with
  `--depth`. Don't reach for Mermaid when a depth-rectangle would say it better.
- **Cross-section (layered shallowness).** Stacked horizontal bands; before: N thin layers each doing
  nothing; after: one thick `.mod-deep` band labelled with the consolidated responsibility.

Keep diagrams ~320px tall so before/after sits side by side without scrolling. Motion: at most the one
`reveal` fade, and only when `prefers-reduced-motion` allows.

## Top recommendation

One larger card after the candidates: the candidate you'd tackle first, one sentence on why, and an
anchor link to its card. That's it.

## Tone

Plain English, concise — but the architectural nouns come straight from `codebase-design`: **module,
interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality**. Never substitute
component/service (module), API (interface), or boundary (seam). The vet, finding format, and leverage
ranking are unchanged — see [finding-discipline.md](finding-discipline.md); this file only changes how
the vetted findings are *rendered*.
