---
name: explain
description: Re-explain the last answer when it didn't land — a fresh pitch with the missing context, in plain register, using the project's vocabulary.
disable-model-invocation: true
requires: writing-for-humans
---

# Explain

Run the `/writing-for-humans` skill now — if you did not just see a `Launching skill: writing-for-humans` line, stop and load it before re-pitching.

Wait — the human stopped following. Re-pitch what you were explaining: supply the piece of context they were missing, write in `writing-for-humans`' plain descriptive register, and use the ubiquitous language from `DOMAIN.md`. With no `DOMAIN.md`, the re-pitch still works — you drop only the vocabulary instruction.

Prose already failed once, so consider showing rather than re-saying: the smallest **view** that carries the idea — a call tree, a file tree, five lines of pseudocode, a small diagram, a diff between the shape now and the shape proposed, drawn over whichever of those shapes the topic already uses. Pick by what they're missing, not by what looks thorough: a whole-system diagram is another wall to get lost in when the confusion is one function. Keep it inline — a view they have to open elsewhere is a third pitch, not a clearer second one.

How far back to re-pitch is your judgment — what lost them is usually bigger than the last message. The target is clearer, and usually shorter — never blunter: add the missing premise instead of only deleting words. A second `/explain` in a row re-pitches at full depth from the newly missing premise, not by trimming the last pitch.
