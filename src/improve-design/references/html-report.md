# The HTML candidate report

How `improve-design` Step 3 renders vetted deepening candidates as a self-contained HTML file. This identity is **frozen** — designed once and reused every run. Don't redesign it per scan; fill the scaffold with this run's candidates. The conversation still carries the terse ordered list for the pick; this file is the rich, visual record the user reads.

## Identity — "structural section drawing"

The report's one job: let an engineer compare deepening candidates and pick one. The signature is the **Ousterhout depth-rectangle** — a module drawn as a rectangle whose *top edge is its interface width* and whose *body is its implementation*. Depth is encoded twice: by vertical extent **and** by color saturation — a shallow module reads pale and flat, a deep module reads dark and dimensional. That dual encoding is the one aesthetic risk; spend boldness there and keep everything else quiet.

This is deliberately *not* Matt Pocock's stone/emerald/Mermaid-neutral look, and it steers clear of the three AI-default palettes (cream+serif+terracotta, near-black+acid, broadsheet hairline).

### Tokens

```
--paper:    #ECEFF1   /* cool drafting ground — not white, not cream */
--ink:      #1B2A32   /* deep petrol-slate — body + headings */
--depth:    #0E5A57   /* petrol-teal — the deep module, leverage, the one accent */
--depth-d:  #0A3D3B   /* darker base for the deep-module gradient */
--shallow:  #C8D2D4   /* pale desaturated teal-gray — shallow module fill */
--leak:     #C0392B   /* brick red — seam leakage only */
--warn:     #9A6B00   /* dark goldenrod — ADR-reopen callout border/text */
--warn-bg:  #F3E7C8   /* pale amber — ADR-reopen callout fill */
```

Type (Google Fonts via CDN): **Archivo** for display/headings (structural, wide grotesque — reads as mass), **IBM Plex Sans** for body, **IBM Plex Mono** for file paths, module labels, and all schematic diagram text. Module labels inside diagrams are `Plex Mono, text-xs uppercase tracking-wider` so they read as schematic, not as UI. Colour sparingly: `--depth` is the *only* accent; `--leak` and `--warn` are signals, never decoration.

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
             --shallow:#C8D2D4; --leak:#C0392B; --warn:#9A6B00; --warn-bg:#F3E7C8; }
      body{ background:var(--paper); color:var(--ink); }
      .display{ font-family:"Archivo",sans-serif; }
      .mono{ font-family:"IBM Plex Mono",monospace; }
      .seam{ stroke:var(--ink); stroke-dasharray:5 4; }      /* seam = dashed */
      .leak{ stroke:var(--leak); stroke-width:2; }           /* leakage = brick red */
      /* HTML legend swatches use background; SVG shapes must use fill (see below). */
      .mod-shallow{ background:var(--shallow); color:var(--ink); }
      .mod-deep{ background:linear-gradient(160deg,var(--depth),var(--depth-d)); color:var(--paper); }
      /* SVG-safe depth classes — background is a no-op inside SVG, fill is not. */
      .svg-shallow{ fill:var(--shallow); stroke:var(--ink); }
      .svg-deep{ fill:url(#deep); }                          /* refs the shared gradient below */
      .svg-lbl{ fill:var(--ink); font-family:"IBM Plex Mono",monospace; }
      .svg-lbl-on-deep{ fill:var(--paper); font-family:"IBM Plex Mono",monospace; }
      .card{ border:1px solid var(--ink); background:#fff; }
      /* deep-filled card (top recommendation) — self-contained: background AND light text
         in one rule. Never write `class="card card-deep"` — .card's later background wins
         the cascade and you get light text on white. Use .card-deep alone. */
      .card-deep{ border:1px solid var(--depth-d); color:var(--paper);
                  background:linear-gradient(160deg,var(--depth),var(--depth-d)); }
      @media (prefers-reduced-motion:no-preference){ .reveal{ animation:rise .5s ease both; } }
      @keyframes rise{ from{ opacity:0; transform:translateY(8px);} to{ opacity:1; transform:none;} }
    </style>
  </head>
  <body class="font-sans">
    <!-- one shared gradient for every deep-module body; .svg-deep / fill="url(#deep)" -->
    <svg width="0" height="0" aria-hidden="true"><defs>
      <linearGradient id="deep" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#0E5A57"/><stop offset="1" stop-color="#0A3D3B"/>
      </linearGradient>
    </defs></svg>
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Header

Report title (`Design review — {{repo}}`), date, and a compact **legend** that teaches the visual language in one glance — and *is itself* a depth-rectangle key: narrow-top dark box = deep module, wide-top pale box = shallow module, dashed line = seam, red arrow = leakage, amber box = ADR warning. No intro paragraph; straight into candidates.

## Candidate card

One `<article class="reveal">` per candidate, ordered by leverage. The diagram carries the weight; prose is sparse and uses the glossary terms (`codebase-design`) without ceremony.

- **Title** — names the deepening (e.g. "Collapse the billing rollup pipeline").
- **Badge row** — a **leverage-tier** badge (High/Medium/Low, `--depth`-filled for High) and a **confidence** chip (HIGH/MED/LOW), plus a dependency-category tag (`in-process`, `local-substitutable`, `remote-but-owned`, `true-external`). Derived from the existing ranking axes — never a `Strong`/`Speculative` scale.
- **Files** — `mono text-sm` list of involved modules with `file:line` evidence.
- **Before / After diagram** — the centerpiece (patterns below).
- **Problem** — one sentence. What hurts.
- **Solution** — one sentence. What changes.
- **Wins** — bullets, ≤6 words, in glossary terms ("locality: bugs concentrate here", "one interface, N call sites"). Not "easier to maintain".
- **ADR callout** (only if the candidate reopens one) — one line in a box filled `--warn-bg` with a `--warn` border and `--warn` label (use the tokens, don't hardcode the hex).

If a paragraph is needed to explain a diagram, redraw the diagram.

## Diagram patterns

Pick the one that fits; mix them so cards don't all look alike.

- **Depth-rectangle (the signature, default for shallow→deep).** Draw it in **inline SVG**, not HTML boxes. Before: a wide-but-thin shallow module `<rect class="svg-shallow">`, with leaked deps as `.leak` arrows crossing a `.seam` to outside boxes. After: a tall deep `<rect class="svg-deep">` (the shared `#deep` gradient) with the now-internal deps drawn faded *inside* it and a narrow interface strip on top. **SVG-safe rules — `background` is a no-op inside SVG; only `fill` paints it:** use `class="svg-shallow"` / `class="svg-deep"` (never `mod-shallow`/`mod-deep`, which are HTML-only and render *black* on a `<rect>`), and give **every `<text>` an explicit fill** — `class="svg-lbl"` on paper, `class="svg-lbl-on-deep"` inside the deep body — or it inherits black and vanishes. Keep the `.seam` line at the module's interface edge; don't run it through the deep body. Reads as "the interface shrank; the implementation absorbed the pass-throughs."
- **Mermaid graph (only when genuinely graph-shaped** — call/dependency mess). `flowchart` styled by the theme config above. **Colour the thing your label points at:** `classDef leak stroke:#C0392B` + `class a,b leak` reddens *nodes*; to redden *edges* (e.g. the function-local imports that can't be top-level) use `linkStyle <indices> stroke:#C0392B,stroke-width:2px` instead — a label that says "red edges" over reddened nodes misdirects the eye. Don't reach for Mermaid when a depth-rectangle would say it better.
- **Cross-section (layered shallowness).** Stacked horizontal bands; before: N thin layers each doing nothing; after: one thick `.mod-deep` band labelled with the consolidated responsibility.

Keep diagrams ~320px tall so before/after sits side by side without scrolling, and match the row height to the SVG — don't set a grid `min-height` taller than the SVG, or a dead band opens under the diagram. Motion: at most the one `reveal` fade, and only when `prefers-reduced-motion` allows.

## Top recommendation

One larger **`.card-deep`** after the candidates — the recommendation literally rendered *as* a deep module: the candidate you'd tackle first, one sentence on why, and an anchor link to its card. That's it. Use `.card-deep` alone (it carries its own light text); don't stack it with `.card`.

## Tone

Plain English, concise — but the architectural nouns come straight from `codebase-design`: **module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality**. Never substitute component/service (module), API (interface), or boundary (seam). The vet, finding format, and leverage ranking are unchanged — see [finding-discipline.md](finding-discipline.md); this file only changes how the vetted findings are *rendered*.
