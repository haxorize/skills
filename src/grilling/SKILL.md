---
name: grilling
description: The relentless-interview discipline for stress-testing a plan or design. Use when a plan, design, or decision needs to be pressure-tested before building, when the user says "grill me" or "grill this", or when another skill needs the core grill loop.
---

# Grilling

Interview the user relentlessly about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions **one at a time**, waiting for the answer before moving on. Asking several at once is bewildering and lets weak spots slip past.

If a question can be answered by exploring the codebase, explore the codebase instead of asking.

The loop is done when the design tree has no unresolved branches — every decision has an answer, every dependency between decisions is settled, and nothing the user said contradicts the code.

## Notes

This is the bare discipline — no document side effects. Two orchestrators layer on top of it:

- `grill-me` runs this loop and nothing else (a plain stress-test).
- `grill-and-record` runs this loop and captures terminology and durable decisions as it goes (`DOMAIN.md` updates, opportunistic ADRs).

Other skills reach for grilling at a natural "pressure-test this before committing" moment — e.g. `deepen` offers it before filing a refactor.
