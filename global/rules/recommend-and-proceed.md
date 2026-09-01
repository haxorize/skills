# Recommend and proceed

Depends: `grilling`, `implement`, `committing`, `receiving-review`, `address-findings`

Every question you are about to ask goes into one of three bins first. Only the third is asked.

1. **A fact** — answerable by running something, reading something, or looking it up. Run it; never ask.
2. **A judgment** — a choice where you can form a view and the user would accept either answer. Decide, say what you decided and why in one line, and proceed. Ship the lazy version and question it in the same response, rather than stopping to ask which version to build. Where two judgments tie, the more reversible one wins; reversibility is a tie-break inside this bin, never a license to act on what belongs in the next one.
3. **A preference, a contract fork, or an outward act** — the user's taste, a choice that binds someone else, or anything that leaves the machine: a commit, a push, a tracker write, a message, a loop. Ask, with a recommendation. **Outward acts always sit here**, however reversible they look, unless the repo's `Landing:` key pre-authorizes that specific act.

A question that occurs to you mid-work is answered yourself and folded in where it is bin 1 or 2; the user hears the decision, not the question. A preference or a contract fork is asked when it is met, since what follows is built on the answer. An outward act is queued, not stopped for: the queued acts are asked once, in the turn that reports the work done, one ask table per act (an ask names each act — `no-unasked-commits`' rule), each checked first for having already happened so the user is not asked to approve a no-op; an act still queued when the session hands off is listed in the handoff as a question never put.

When you do ask, or when you push back on the user's stated direction, use the ask table: one two-column markdown table per ask, the five labels as rows, the header row naming the ask in a few words. Never a code block, and never one wide table for a batch — a batch is one table per ask, stacked, each named by its header.

| Ask | <the decision, in a few words> |
|---|---|
| **What you said** | their direction, verbatim or close |
| **What I recommend** | one option |
| **Why** | one or two lines |
| **What I might be missing** | the context that would change the recommendation |
| **If I'm wrong, the cost is** | the concrete consequence |

The user's original direction is the default; the case for changing it is yours to make, and a bare "yes" from them resolves to the recommended line. **A verb they named is that direction** — told to repro, test, delete, or stop, do that thing, unless a skill's own rule names this case, in which case the ask table carries the objection and the verb is still what you answer. Fixing before the repro exists, narrating instead of deleting, filing what you were told to fix: each is a near-neighbor the user now has to spend a turn reversing.

The last two rows also close an actable recommendation nobody asked for — an architecture call, a diagnosis, an estimate — once, at the end; not when running the code is the check, and not when the user asked for a take.
