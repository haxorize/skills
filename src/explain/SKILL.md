---
name: explain
description: Re-explain the last answer when it didn't land — a fresh pitch with the missing context, in plain register, using the project's vocabulary. With a topic argument, explain a thing cold, before any confusion.
disable-model-invocation: true
requires: writing-for-humans
argument-hint: "[<topic>] — bare re-pitches the last answer; a topic explains it cold"
---

# Explain

Call the Skill tool with `writing-for-humans` now — the register change *is* the intervention here and not the finish, in both branches: on a re-pitch it is what differs from the answer that just failed, and on a cold open it is what keeps the explanation from being the wall the re-pitch exists to take down. If you did not just see a `Launching skill: writing-for-humans` line, stop and call it again before writing either branch.

Wait — the human stopped following. Re-pitch what you were explaining: supply the piece of context they were missing, write in `writing-for-humans`' plain descriptive register, and use the ubiquitous language from `DOMAIN.md` — a term enters the pitch at the step where it acts, defined there in the sentence that uses it, never in a glossary up front. With no `DOMAIN.md`, the re-pitch still works — you drop only the vocabulary instruction.

Open on the premise. The first sentence of either branch says, in plain words, what the pitch assumes the reader already holds ("this assumes you have seen the pre-push hook refuse once — say if not"), and the pitch keeps going without waiting for a reply: a wrong guess about what they hold is then corrected in a sentence instead of talked past for a third pitch. On a re-pitch the premise is read from the pitch that failed; on a cold open it is stated from the argument and the repo.

Prose already failed once, so consider showing rather than re-saying: the smallest **view** that carries the idea — a call tree, a file tree, five lines of pseudocode, a small diagram, a diff between the shape now and the shape proposed, drawn over whichever of those shapes the topic already uses. Pick by what they're missing, not by what looks thorough: a whole-system diagram is another wall to get lost in when the confusion is one function. Keep it inline — a view they have to open elsewhere is a third pitch, not a clearer second one.

How far back to re-pitch is your judgment — what lost them is usually bigger than the last message. The target is clearer, and usually shorter — never blunter: add the missing premise instead of only deleting words. A second `/explain` in a row re-pitches at full depth from the newly missing premise, not by trimming the last pitch.

## `/explain <topic>` — cold

Nothing has failed yet; the human wants the shape of a thing before they meet it — a module, a concept, a decision in the ADR log. Same register, same vocabulary, same smallest-view rule, same opening premise, and one difference in where it starts: with no failed pitch to read the missing premise from, the premise sentence is followed by what the topic is *for* in this project (the caller, the reader, the decision it serves), then the one view that carries its shape, then the two or three facts a person must hold to work with it. Stop there — a cold explanation that tries to be complete is the wall the re-pitch exists to take down. When the topic is a whole system or a module graph, the one view arrives in steps — a few structures at a time, each step running one flow over only what is already shown — and the full diagram, if it comes at all, comes last. When the topic names nothing the repo holds, say so and explain the general thing. And when the ask outgrows one sitting — the human wants to *learn* the topic over sessions, not meet its shape once — suggest `/teach-me <topic>`, which keeps a workspace and a mission; this branch is a single pitch.
