---
name: prototype
description: Build a throwaway prototype to answer a design question — a shareable single-file HTML demo for state/logic questions, or several radically different UI variations toggleable from one route.
disable-model-invocation: true
requires: adr, domain-modeling
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [references/logic.md](references/logic.md). Build a single-file HTML demo — clickable, shareable with non-developers — that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → [references/ui.md](references/ui.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code next to the module or page it's prototyping for, but name it so a casual reader can see it's a prototype, not production.
2. **One step to run.** The logic demo is a file you double-click. A UI prototype adds no run step of its own — it appears under the command the project already uses to run the app (`pnpm dev`, `python manage.py runserver`, whatever the project's convention is), with no extra server, install, or build step.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE — wipe me" name.
4. **Fidelity follows the dimension under test.** Throwaway doesn't mean thin — the prototype has to be finished enough along the one dimension being judged that the question can actually be answered. A *see-it* question (does this layout read at real density?) needs real copy and a realistic row count, never lorem and three rows. A *drive-it* question (does this flow feel right?) needs the interactions on the judged path to genuinely work. Everything off that dimension stays crude: no tests, no error handling beyond what makes the prototype _runnable_, no abstractions.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Capture when done.** When the prototype has answered its question, fold the validated decision into the real code and keep the prototype itself as evidence — see When done.

## When done

Two things come out of a finished prototype: the **answer** (the verdict plus the question it settled) and the **prototype itself** — the runnable evidence the answer came from. Capture both.

For the prototype: with no tests and no maintenance story it doesn't belong on the main branch, but that's not a reason to delete it. Commit it to a throwaway branch (`prototype/<name>`), push, and leave a context pointer to the branch wherever the question came from — the work item that prompted it, or the handoff answer. Absorbing a validated reducer or UI direction into the real module keeps the *decision*; the branch keeps the *evidence*, one click away for anyone who wants to re-run it.

For the answer, this is a natural delegation boundary — delegate rather than inline:

- If the answer settled a **load-bearing decision** that passes the **ADR gate** in `adr`, offer to record it via `adr`. The prototype *is* the considered-options exploration; synthesize the ADR from what it proved.
- If the prototype surfaced or sharpened a **domain concept** — a new state, a clearer name for a thing — run the `/domain-modeling` skill to capture it in `DOMAIN.md` before the precision is lost.

If the user is around, that capture is a quick conversation. If not, leave the answer in a `NOTES.md` next to the prototype (with the question it answered) so they — or you, on the next pass — can record it before the code moves to its branch.

## Pairing with handoff

A prototype is often a **detour** out of a main thread: a question came up that needs a runnable answer. `handoff` is the bridge in both directions — `/handoff` out of the full thread, open a fresh session, `/prototype` here to answer the question, then `/handoff` the *answer* (not the code) back to the original thread. See `handoff` for the fork-vs-`/compact` distinction.
