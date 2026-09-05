# UI Prototype

Generate **several radically different UI variations** on a single route, switchable from a floating bottom bar. The user flips between variants in the browser, picks one (or steals bits from each), then throws the rest away.

If the question is about logic/state rather than what something looks like, or the direction is settled and the question is whether the component survives real content — wrong branch; the routing table is in [SKILL.md](../SKILL.md).

## When this is the right shape

- "What should this page look like?"
- "I want to see a few options for this dashboard before committing."
- "Try a different layout for the settings screen."
- Any time the user would otherwise spend a day picking between three vague mockups in their head.

## Two sub-shapes — strongly prefer sub-shape A

A UI prototype is much easier to judge when it's **butting up against the rest of the app** — real header, real sidebar, real data, real density. A throwaway route on its own is a vacuum: every variant looks fine in isolation. Default to sub-shape A whenever there's a plausible existing page to host the variants. Only reach for sub-shape B if the prototype genuinely has no nearby home.

### Sub-shape A — adjustment to an existing page (preferred)

The route already exists. Variants are rendered **on the same route**, gated by a `?variant=` URL search param. The existing data fetching, params, and auth all stay — only the rendering swaps.

If the prototype is for something that doesn't yet have a page but *would naturally live inside one* (a new section of the dashboard, a new card on the settings screen, a new step in an existing flow) — that's still sub-shape A. Mount the variants inside the host page.

### Sub-shape B — a new page (last resort)

Only use this when the thing being prototyped genuinely has no existing page to live inside — e.g. an entirely new top-level surface, or a flow that can't be embedded anywhere sensible.

Create a **throwaway route** following whatever routing convention the project already uses — don't invent a new top-level structure. Name it so it's obviously a prototype (e.g. include the word `prototype` in the path or filename). Same `?variant=` pattern.

Before committing to sub-shape B, sanity-check: is there really no existing page this could be embedded in? An empty route hides design problems that a populated one would expose.

In both sub-shapes the floating bottom bar is identical.

## Process

### 1. State the question and pick N

Default to **3 variants**. More than 5 stops being radically different and starts being noise — cap there.

Write down the plan in one line, in the prototype's location or a top-of-file comment:

> "Three variants of the settings page, switchable via `?variant=`, on the existing `/settings` route. Divergence axis: information density."

Name the **divergence axis** before building — the one dimension the variants disagree along (density, information hierarchy, primary affordance, tone). Variants drawn without a declared axis differ by accident, and the user can't say what they are choosing between. No two variants take the same position on the axis. A collision caught before the variant is drafted is redrawn against the axis; one caught after it is built is cut, and cut out loud — shipping three names over two ideas is a fake choice.

### 2. Generate radically different variants

Draft each variant. Hold each one to:

- The page's purpose and the data it has access to.
- The project's component library / styling system (TailwindCSS, shadcn, MUI, plain CSS, whatever).
- An exported component name that names the variant's **direction**, not its slot in the list — `BroadsheetSettings`, `WristbandSettings`, `LedgerSettings`, never `VariantA` — and the direction itself is a named referent, not a stack of adjectives: a broadsheet front page, a hospital wristband, a bank statement, a terminal, each carrying its own constraints, where "modern, clean, trustworthy" evokes nothing specific and every variant drifts to the center of what those words mean. The URL key stays a letter so the switcher and the shareable link stay simple, but the label the user reads pairs the two (`B — Wristband`): a person holds "the wristband one" in their head for a week and cannot hold "option B" for an hour.

Variants must be **structurally different** — different layout, different information hierarchy, different primary affordance, not just different colors. Three slightly-tweaked card grids isn't a UI prototype, it's wallpaper. Redrawing a too-similar draft takes explicit negative guidance — "do not use a card grid" — because the second attempt drifts back to the first shape without it. When the divergence axis is hierarchy or density, draft the variants first in grayscale, so hue cannot stand in for hierarchy, and redraw the finalists in the project's real styling before step 5 — the user picks among real renderings, never among sketches.

### 3. Wire them together

Create a single switcher component on the route:

```tsx
// pseudo-code — adapt to the project's framework
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <BroadsheetSettings {...data} />}
    {variant === 'B' && <WristbandSettings {...data} />}
    {variant === 'C' && <LedgerSettings {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

For sub-shape A (existing page): keep all the existing data fetching above the switcher; only the rendered subtree changes per variant.

For sub-shape B (new page): the throwaway route created above (per the project's routing convention) mounts the same switcher.

### 4. Build the floating switcher

A small fixed-position bar at the bottom-center of the screen with three pieces:

- **Left arrow** — cycles to the previous variant (wraps around).
- **Variant label** — shows the current variant key and its direction name: `B — Wristband`.
- **Right arrow** — cycles forward (wraps around).

Behavior:

- Clicking an arrow updates the URL search param (use the framework's router — `router.replace` on Next, `navigate` on React Router, etc) so the variant is shareable and reload-stable.
- Keyboard: `←` and `→` arrow keys also cycle. Don't intercept arrow keys when an `<input>`, `<textarea>`, or `[contenteditable]` is focused.
- Visually distinct from the page (e.g. high-contrast pill, subtle shadow) so it's obviously not part of the design being evaluated.
- Hidden in production builds — gate on `process.env.NODE_ENV !== 'production'` or an equivalent check, so a stray prototype merge can't ship the bar to users.

Build the switcher as its own clearly-named throwaway component (e.g. `PrototypeSwitcher.tsx`) next to the variants it switches — not in the project's shared-UI folder, where prototype code can outlive cleanup.

### 5. Hand it over

Surface the URL (and the `?variant=` keys) with a short trade-off table: one row per direction, what it is the right choice for, and what it costs. State no preference — the choice is the user's, and a recommendation shipped alongside the variants collapses them back into one. The interesting feedback is usually **"I want the header from B with the sidebar from C"** — that's the actual design they want.

A variant cut for converging is named in the table as cut, never quietly absent from it — the user is choosing among the directions that survived, and cannot tell a direction that was never drawn from one that collapsed.

When a direction wins but isn't finished, run a **riff round**: two or three fresh variants that all sit inside the winning direction and diverge on a narrower axis. The first round picks the direction; the riff round picks within it.

### 6. Capture the answer and clean up

Once a variant has won, write down which one and why — as `prototype`'s "When done" section describes. Then:

- **Sub-shape A** — delete the losing variants and the switcher; fold the winner into the existing page.
- **Sub-shape B** — promote the winning variant to a real route, delete the throwaway route and the switcher.

Don't leave variant components or the switcher lying around.

## Defaults to refuse

A generated page arrives wearing one of five default costumes; recognize the cluster, then choose deliberately. This is the one home of the list — `review-architecture`'s report and `teach-me`'s lessons point here. The clusters: **cream with serifs and a terracotta accent**; **near-black with an acid accent**; **the hairline-rule broadsheet**; **the SaaS-card kit** (tracked-out eyebrow labels, `A · B · C` meta strings, `WORD — fragment` labels, `#0B0B0B` near-black, `→` on links); and **template chrome** (a hero, a three-column feature grid, a testimonial band). The `#D97757` clay accent is Anthropic's own house tell: a default on a page a *user* briefed, never a finding against this repo's own outputs, which carry it on purpose.

## Anti-patterns

- **Sharing too much code between variants.** A shared `<Header>` is fine; a shared `<Layout>` defeats the point. Each variant should be free to throw out the layout.
- **Wiring variants to real mutations.** Read-only prototypes are fine. If a variant needs to mutate, point it at a stub — the question is "what should this look like", not "does the backend work".
- **Promoting the prototype directly to production.** The variant code was written under prototype constraints (no tests, minimal error handling). Rewrite it properly when you fold it in.
