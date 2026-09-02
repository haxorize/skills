# Text scaling and reflow

Open this only when the change alters layout, type size, spacing, the viewport meta, or anything that reflows — not on a change that only adds a control or a state. **Text scales** in [surface-and-content.md](surface-and-content.md) stands: text survives zoom, reflow, and user text spacing. The thresholds:

- At 200% zoom no text is clipped or lost (1.4.4), and at 320 CSS pixels wide nothing needs two-dimensional scrolling (1.4.10).
- The viewport meta never sets `user-scalable=no` or `maximum-scale=1`, which makes that zoom impossible rather than merely broken.
- User-applied text spacing — line height 1.5, paragraph 2×, letter 0.12em, word 0.16em — clips nothing (1.4.12).
- The root font size is not locked in pixels, so the browser's own text-size setting still reaches the page.

On a native platform, the scaling contract is [native.md](native.md)'s.
