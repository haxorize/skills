# Phase boundaries — picking the move between phases

A **phase** is a chunk of work inside a session — the grilling, the implementation, the QA. The definition is fuzzy on purpose: a phase ends when you think *"ok, we're done with that."*

The **phase boundary** is the gap between two phases, and it is the only place this decision belongs. Mid-phase there is no decision to make — continue, or split the work that's left into subagents. Compacting mid-phase makes the agent lose the thread.

Every move except **Continue** turns a **primary source** (the full conversation) into a **secondary source** (a summary or a doc):

| | Fidelity | Context cost | Loss |
|---|---|---|---|
| Primary (Continue) | Full | Lots | Little |
| Secondary (`/compact`, `/handoff`) | Lossy | Less | Lots |

Ask **in order**; first yes wins:

1. **Can you continue in this session?** Yes when the next phase needs this phase as a *primary source*, or when enough smart zone remains (~150k tokens). Continue costs nothing and loses nothing, so rule it out before anything else.
2. **Is the context irrelevant to what comes next?** `/clear` (built-in) and start clean. The cost of getting this wrong is one-way: clear a *relevant* context and you lose the **why** behind what you built.
3. **Does the context need to travel?** `/handoff` is narrow — what it buys is **portability**, a file that travels to a fresh session, another machine, another person. If nothing is travelling, you don't need it.
4. **Can the remaining work run unattended?** Scoped tightly enough to run with you away from the keyboard, no steering → `handoff`'s background-agent exit, or a subagent for a bounded sub-question.
5. **Otherwise, `/compact`.** The **default, not the first reach**. A summary flattens decisions; the failure mode when people start here is a fresh session that is confidently wrong about a decision the summary lost. Pass a focus instruction naming what must survive — the decision map, the parked list, the ticket ID, the handoff path — `/compact keep the decisions from the grill, the parked ledger, and #142`; a bare `/compact` keeps whatever the summariser found salient.

The questions are not objective — each has taste in it, and the same boundary can go two ways on two days. The value is in asking them **in order**, at the boundary rather than in the middle of the work.
