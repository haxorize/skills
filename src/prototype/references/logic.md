# Logic Prototype

A single, self-contained HTML file — a **shareable demo** — that lets anyone drive a state model by clicking buttons. Use this when the question is about **business logic, state transitions, or data shape** — the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases.

Because it's one file with nothing to install, you can hand it to a non-developer — a designer, a PM, a domain expert — and let them feel the model for themselves. So it speaks their language, not the code's.

## When this is the right shape

- "I'm not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API should look like before writing it."
- Anything where the user wants to **press buttons and watch state change**.

If the question is "what should this look like" or "does this survive real content" — wrong branch; the routing table is in [SKILL.md](../SKILL.md).

## Process

### 1. State the question

Before writing code, write down what state model and what question you're prototyping — one paragraph in a comment at the top of the file, so it can be checked later.

### 2. Isolate the logic in a portable module

Put the actual logic — the bit that's answering the question — in its own clearly-marked `<script>` section above the shell code, behind a small, pure interface. The right shape depends on the question:

- **A pure reducer** — `(state, action) => state`. Good when actions are discrete events and state is a single value.
- **A state machine** — explicit states and transitions. Good when "which actions are even legal right now" is part of the question.
- **A small set of pure functions** over a plain data type. Good when there's no implicit current state — just transformations.

Keep it pure: no DOM access, no rendering. The shell reads it and calls into it; nothing flows the other direction. When the host project is JS/TS, write the module so it lifts into the real codebase verbatim; in any other stack the module is a faithful sketch — the *answer* transfers even where the code doesn't.

### 3. Build the shell for a non-developer

Every label in **domain language**, not code — buttons and state read like the business, not the reducer. Two parts:

- **Free play** — every legal action as a button; illegal actions visible but disabled (that they're disabled is often the answer).
- **Guided walkthroughs** — a set of **scenarios, one per tab**. Each step is a real button: clicking it performs that action and advances the walkthrough. Starting a walkthrough resets to a known initial state so the scenario runs the same way every time. Choose scenarios that demonstrate the awkward cases — the happy path, a tricky edge case, an attempt at something that should be illegal.

### 4. Keep it one double-clickable file

**Don't reach for a framework, bundler, or server.** One file the recipient double-clicks; a React app or a dev server defeats "shareable." Inline all CSS and JS.

### 5. Hand it over

Give the user the file path (and offer to send it to whoever else should feel the model). The interesting moments are when someone says "wait, that shouldn't be possible" or "huh, I assumed X would be different" — those are the bugs in the _idea_. If they want new actions or scenarios, add them.

### 6. Capture the answer

Capture the answer as `prototype`'s "When done" section describes.

## Anti-patterns

- **Don't generalize.** No "what if we wanted to support X later." The prototype answers one question.
- **Don't blur the logic and the shell together.** If the reducer references the DOM, it's no longer portable — keep the shell a thin skin over a pure module.
- **Don't let the labels drift into code-speak.** `"Cancel subscription"`, not `"dispatch(CANCEL_SUB)"` — the moment a domain expert needs a translator, the demo stopped doing its job.
