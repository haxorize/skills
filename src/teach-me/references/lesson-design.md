# Lesson design

The visual and structural system for lessons and cheat sheets. A lesson should be beautiful — the learner returns to these — and every lesson in a workspace should read as one course, not a pile of one-offs.

## One identity per workspace

- When the workspace earns its stylesheet (first lesson), derive a compact token system: palette, display + body type pairing, spacing scale, and one signature element. Record the tokens as CSS custom properties in the shared stylesheet.
- Source the identity from the topic's own world — its materials, instruments, and vernacular. A health-insurance topic and a synthesizer topic should not look alike.
- Refuse the generic AI-design clusters — cream-with-serifs, near-black-with-acid-accents, hairline-rule broadsheet. Recognize them as defaults, then choose deliberately.
- Spend boldness in exactly one place — the signature element. Keep everything around it quiet and disciplined.

## Typography and layout

- Content-first, Tufte-leaning: generous measure (~65ch), clear hierarchy, minimal chrome.
- Set a deliberate type scale with intentional weights; body text at least 16px-equivalent with line-height ≥1.5.
- Support light and dark via `prefers-color-scheme`, and print cleanly (`@media print`: hide interactive chrome, expand gated and hidden content) — cheat sheets especially are print artifacts.

## Lesson anatomy

1. **Header** — lesson number, title, date, and a one-line tie back to the mission.
2. **Hook + cold attempt** — the generation prompt as the first interactive element.
3. **Segments** — one idea each, ending in a gate check; boxed-insight asides capped at 2–3 bullets, placed adjacent to the thing they explain; load-bearing claims link their `RESOURCES.md` source.
4. **Practice** — the scaffold-arc exercises and ungraded self-checks. The graded quiz is agent-conducted in conversation, not embedded here (see SKILL.md Lessons).
5. **Footer** — one primary-source recommendation (the highest-trust `RESOURCES.md` entry on the lesson's point), relative-anchor links to related cheat sheets and lessons, and a reminder that the agent is the teacher: ask follow-up questions.

## Components (`assets/`)

- Reuse is the default: read `assets/` before authoring; anything new and reusable becomes a component, not an inline block.
- The shared stylesheet is the first component every workspace earns; every lesson links it.
- Build ungraded interactive elements as small vanilla-JS components — segment gate (a restate/apply check that unlocks the next section), reveal blocks, click-to-check self-tests. These aid the learner reading alone.
- Lessons are self-contained offline artifacts: no network requests, no CDN fonts or scripts — everything ships from `assets/` or inline.
- Motion is purposeful and rare — at most a restrained flourish on the signature element. Extra animation reads as generated, not designed.
