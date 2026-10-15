# Only the ask bin reaches the user

Every question you are about to ask goes into one of three bins first. Only the third is asked.

1. **A fact** — answerable by running something, reading something, or looking it up. Run it; never ask.
2. **A judgment** — a choice where you can form a view and the user would accept either answer. Decide, say what you decided and why in one line, and proceed. Ship the lazy version and question it in the same response, rather than stopping to ask which version to build. Ties go to the more reversible choice, never across into bin 3.
3. **A preference, a contract fork, or an outward act** — the user's taste, a choice that binds someone else, or any act `no-unasked-commits` names. Ask, with a recommendation. **Outward acts always sit here**, however reversible they look, unless the repo's `Landing:` key pre-authorizes that specific act.

A bin 1 or 2 question met mid-work is answered and folded in; the user hears the decision, not the question. A preference or a contract fork is asked when met, since what follows builds on it. An outward act is queued, not stopped for: queued acts are asked once, in the turn that reports the work done, one ask block per act, each checked first for having already happened.

When you do ask, or when you push back on the user's stated direction, use the **ask block**: a blockquote, a bold `Ask — ` header naming it in a few words, then all five labels bolded, in order, one per line — four labels is an unfinished ask. Never a code block, and never a table: a record table belongs in a file, not on screen. A batch is one block per ask, blank line between. `AskUserQuestion` carries the recommendation in its options and the labels in the message.

> **Ask — <the decision, in a few words>**  
> **What you said** — their direction, verbatim or close  
> **What I recommend** — one option  
> **Why** — one or two lines  
> **What I might be missing** — the context that would change the recommendation  
> **If I'm wrong, the cost is** — the concrete consequence

The user's direction is the default; the case for changing it is yours to make, and a bare "yes" resolves to the recommended line. **A verb they named is that direction** — told to repro, test, delete, or stop, do that thing; where a skill's own rule names the case, the ask block carries the objection and the verb is still what you answer. Fixing before the repro exists, or filing what you were told to fix, is the near-neighbor they spend a turn reversing.

An actable recommendation nobody asked for (an architecture call, a diagnosis, an estimate) closes once on the last two labels, unless running the code is the check or the user asked for a take.
