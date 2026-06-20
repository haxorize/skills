---
name: prototype
description: Build a throwaway prototype to answer a design question — a runnable terminal app for state/logic questions, or several radically different UI variations toggleable from one route.
disable-model-invocation: true
requires: adr, domain-modeling
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [references/logic.md](references/logic.md). Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → [references/ui.md](references/ui.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts — getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious — but name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **One command to run.** Whatever the project's existing task runner supports — `pnpm <name>`, `python <path>`, `bun <path>`, etc. The user must be able to start it without thinking.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE — wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast and then delete it.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Delete or absorb when done.** When the prototype has answered its question, either delete it or fold the validated decision into the real code — don't leave it rotting in the repo.

## When done

The _answer_ is the only thing worth keeping from a prototype — the code is throwaway. Capture the
answer along with the question it was answering, then delete or absorb the code.

This is a natural delegation boundary, so delegate rather than inline:

- If the answer settled a **load-bearing decision** — hard to reverse, surprising without context, the
  result of a real trade-off — offer to record it via `adr`. The prototype *is* the considered-options
  exploration; synthesize the ADR from what it proved.
- If the prototype surfaced or sharpened a **domain concept** — a new state, a clearer name for a
  thing — run `domain-modeling` to capture it in `DOMAIN.md` before the precision is lost.

If the user is around, that capture is a quick conversation. If not, leave the answer in a `NOTES.md`
next to the prototype (with the question it answered) so they — or you, on the next pass — can record
it and delete the prototype.

## Pairing with handoff

A prototype is often a **detour** out of a main thread: a question came up that needs a runnable
answer. `handoff` is the bridge in both directions — `handoff` out of the full thread, open a fresh
session, `/prototype` here to answer the question, then `handoff` the *answer* (not the code) back to
the original thread. See `handoff` for the fork-vs-`/compact` distinction.
