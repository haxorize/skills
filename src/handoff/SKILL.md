---
name: handoff
description: Fork the current conversation into a handoff document so a fresh session can pick the work up, or hand it straight to a background agent.
disable-model-invocation: true
argument-hint: "What will the next session be used for?"
---

# Handoff

This skill **forks** the conversation — you don't continue in place. It has two exits: write the doc for a fresh interactive session (the default), or hand straight off to a background agent (on request).

If the user passed an argument, treat it as a description of what the next session will focus on and tailor the doc to that.

## Where to write it

Default to the **OS temporary directory** (`$TMPDIR` on macOS, `/tmp` on Linux, `%TEMP%` on Windows) — a handoff is throwaway, and the durable content already lives in the artifacts the doc points at.

**Escape hatch:** if the user names a path or asks for a durable target, honor it. Only then does the doc land in the workspace.

## Handing off to a background agent

When the user wants the work **continued unattended** rather than picked up in a fresh interactive session, don't save a doc — launch a background agent seeded with the handoff as its prompt:

```sh
claude --bg --name "<descriptive name>" "<handoff content>"
```

`--name` labels the agent in the job list and session picker. The agent starts in the current working directory; the user manages it with `claude agents`. The redaction rule matters doubly here — the handoff becomes the agent's prompt verbatim.

## What goes in it

- **The goal** — what the next session is trying to achieve (sharpened by the argument, if given).
- **State so far** — what's done, what's in flight, what's blocked, and on what.
- **Next steps** — the concrete things to do next, in order.
- **Suggested skills** — name the skills the next session should reach for. Start it at `/which-skill` if the next move isn't obvious; otherwise name the specific skill (e.g. "load the task with `/from-work-item <id>`, then `/implement`").

### Reference, don't duplicate

Point at **durable artifacts** instead of restating them. Reference:

- `DOMAIN.md` terms by name,
- `docs/adr/` decisions by number,
- tracker **work items** and **PRs** by name, ID attached — never a bare ID,
- commits, diffs, and PRDs by path or URL.

Do **not** duplicate their content, and do **not** invent a scratch location to hold it — there is no standing design-doc directory; the tracked artifacts above are the durable record.

### Redact

Strip API keys, passwords, tokens, and any personally identifiable information before writing the doc.

## `handoff` vs `/compact`

- **`handoff`** *forks*: it preserves the conversation as a document and you continue in a **fresh session** that references it. Use it when the window is full, when you want a clean context, or when you're branching off (e.g. into a `/prototype` detour).
- **`/compact`** (built-in) *continues in place*: it summarises earlier turns but keeps you in the **same conversation**. Use it at intentional breaks between phases when you don't mind losing verbatim history. Don't compact mid-phase — the agent can lose its way.

## The prototype bridge

`handoff` is the in-and-out bridge for a `/prototype` detour: when a question needs a runnable answer, `handoff` out → open a fresh session → `/prototype` to answer it → `handoff` the answer back, and reference it from the original thread. The prototype's *answer* (captured per `prototype`'s "when done") is what the return handoff carries — not the throwaway code.
