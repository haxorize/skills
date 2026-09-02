# Motion and timing

Open this only when the change adds or alters animation, a transition, auto-advancing content, a flashing element, a timeout, or a self-dismissing toast. **Motion and timing respect the person** in [surface-and-content.md](surface-and-content.md) stands: non-essential motion gates on the person's setting, and nothing auto-advances or times out without a way to stop it.

- Gate all non-essential motion on the person's reduced-motion setting, read where the motion is driven — the CSS query for CSS, `matchMedia` re-read on change for script-, canvas-, and library-driven motion, the platform's environment value on native.
- Scope the gate to that non-essential motion: stopping it outright is a compliant answer, while a page-wide `animation: none` also freezes the progress indicator whose movement is essential. Where the motion was carrying meaning, keep it with a fade or a shorter transition.
- Nothing flashes more than three times a second (2.3.1).
- Auto-advancing content can be paused (2.2.2); a timeout can be extended (2.2.1); a toast that carries an action never dismisses itself.
