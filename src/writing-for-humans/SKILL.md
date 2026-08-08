---
name: writing-for-humans
description: Writing conventions for human-facing prose — ticket and work-item bodies, docs and READMEs, ADR rationale, session summaries, incident reports, release notes, error messages, and outbound messages drafted for the user. Use when writing or editing prose whose job is to be understood by a person, when auditing a draft for AI tells, or when picking the register for an artifact. Not for agent-consumed instruction files (`writing-for-agents` owns those) and not for code.
---

# Writing for Humans

Human-facing prose exists to be **understood** — that is the boundary with `writing-for-agents`, which owns documents that exist to be *obeyed* (skill bodies, CLAUDE.md, references). The test is the document's function, not its reader: agents read ADRs too, but they read them the way a human does, for comprehension. Rationale, tickets, definitions, and summaries live here.

Serve the reader, never the detector. Don't try to make text score as human-written, and don't guess whether a text was AI-written — detectors guess; a named pattern with a quoted line is evidence the reader can check. The AI tells this skill hunts are banned because they are *clarity* failures, not because of who tends to produce them.

Write for the reader who arrives with no history. Prose that only makes sense to someone who watched the conversation happen is **overfitted** — rewrite it against the project's own vocabulary until it stands alone. Readers scan rather than read (Nielsen Norman Group's eye-tracking shows an F-pattern covering 20–28% of the text), and GOV.UK's user research finds plain wording preferred *more* by expert readers, not less, with the preference growing as the topic gets harder — so front-loading and plain words are a service to every audience, never dumbing down.

## Classify, then write

Every passage is **procedural** (instructions — the reader will *do* something) or **descriptive** (explanation — the reader will *know* something). Classify first; the mode selects the rules. Don't mix modes in one passage or one list: acceptance criteria and repro steps are procedural; context, approach, and rationale are descriptive.

**Procedural:** imperative voice. One instruction per sentence, unless two actions happen at once. At most 20 words per sentence. A required condition comes *before* its command, split by a comma: "If the build fails, read the log" — trailing conditions get dropped. A warning leads with the command, then the risk: "Do not run this against production. The flag deletes rows that do not match the source" — never the explanation first.

**Descriptive:** no imperative. At most two clauses per sentence; split anything over 25 words. One new fact per sentence. Timelines use simple past — "we identified" not "we have identified", which hides when. Passive voice only when the actor is genuinely unknown; otherwise ask "by whom?" and put the answer first.

**Word counting**, so the caps survive technical prose: a backticked span, an identifier, a number with its unit, a parenthesized aside, and a hyphenated word each count as one word. `az boards work-item update --id 42` is one word.

**Never shorten by deletion of grammar.** Keep articles, keep "that", no telegram style — "Make sure that the file exists before you run the command", never "Ensure file exists before running". Plain means *explained*, not terse: a cramped sentence gets expanded so each point stands alone. Cutting is for words that carry no fact, never for words that carry the grammar.

## Register by artifact

| Artifact | Register |
| --- | --- |
| Ticket body, doc, README | Neutral and plain; contractions fine — but avoid negative ones ("cannot", not "can't": readers misread them as their opposite) |
| ADR rationale | Descriptive, and it takes a position — "strike a balance" and "it depends" prose is the decision dodging itself; name who decided and why |
| Session summary, incident report | Outcome first; simple past with times ("Between 14:02 and 14:31 UTC, 12% of requests failed"); state the unknown as "unknown" — a hedge reads less honest, not more careful |
| Error message, UX microcopy | Calm, zero playfulness; the five-question shape below |
| Commit message, PR body, review reply, closing comment | A maintainer recording a decision for another maintainer: impersonal, matter-of-fact ("Previously, …", "This caused …"); imperative only in the subject line; first person only for an actual decision or open question. The catalog's commit-and-PR family fires here |
| Outbound as the user — email, Teams message, memo, proposal | The user's own voice and register. **No em dashes, none.** Sweep the full tell catalog at maximum strictness — the stake is authorship perception, not just clarity |

This discipline deletes persuasion by design. Marketing, brand, and campaign copy are out of scope — say so and offer to apply it to the factual parts only.

## Core rules

- **Front-load.** The most important sentence comes first — in the document, in each paragraph, in each heading. Headings are descriptive and verb-first where they name an action; never questions, never clever labels ("Applicable legal constraints", not "Legal requirements as a floor").
- **One term per concept.** Pick the word and reuse it — "check" every time, never rotated with "verify" and "confirm"; synonyms imply the things differ. Domain terms never vary; common verbs may repeat freely; `DOMAIN.md` is the project's approved vocabulary.
- **The press-release test.** If a sentence could move unchanged into any company's press release, it carries no fact — cut it, or replace it with the fact, number, mechanism, or consequence specific to this subject.
- **Vague quantifiers become questions.** "Many", "significant", "improved" each demand their number: how many, by how much. Answer from evidence you have; **never invent the number — ask.**
- **Protect the specific fact.** Don't smooth "cut review time from 30 minutes to 8" into "significantly improves review efficiency" — the edit that generalizes a detail is a deletion wearing a rewrite's clothes.
- **Verbs, not nominalizations.** "Validates", not "performs a validation of"; the nominalized verb is where long sentences come from.
- **Everyday word over formal word.** "Use" not "utilize", "help" not "facilitate", "about" not "approximately". The test: would you say it to a colleague out loud?
- **Paragraphs hold one topic, at most 5 sentences**, and the topic sentences alone must read as an outline of the document — check by reading only them.
- **Numerals for every number from 2 up** — "3 retries", not "three retries" — except at a sentence start.

## Two modes

**Edit.** First read the whole text and note the voice worth preserving; a difference from generic plain style is a finding only when it creates ambiguity, inconsistency, or wrong-stakes tone — deliberate character survives the edit. Then two passes: fix rule violations; reread as if you had never seen it and cut every clause the reader doesn't need. Make the minimum effective edit — a rough draft with a real voice still sounds like the same person after.

**Detect.** Audit without rewriting: name each pattern from the catalog, quote the offending line, give the fix in a few words. No rewrite, no score, no authorship verdict. Offer the edit afterward.

Either mode: if the text already complies, say so and stop — don't churn compliant prose.

## The preservation contract

- Never fabricate a fact, citation, number, or example the original didn't contain.
- Never silently drop a qualifier, scope condition, number, or safety condition to make a sentence fit a cap — keep the longer sentence and flag the trade-off instead.
- Untouchables: code spans, identifiers, CLI commands, file paths, quoted error text, and proper nouns stay exact, even where they break a rule.

## Error messages

Before writing or approving one, answer five questions: what happened; why, at the most honest level of detail the product knows; what was *not* affected, if anything needs reassurance; what the user can do now; what they can do if that fails. Unanswerable questions are a product gap, not a copy problem — route them out. Shape: outcome first, then cause, reassurance, next step, escape route. No blame, no "Oops", no exclamation marks — and remember specific ≠ clear: a message can name scopes and tokens and still leave the reader with no move.

## The tell catalog

The named AI tells — filler, puffery, contrastive formulas, mic-drops, metadiscourse, anthropomorphism, and the rest — live in [references/tell-catalog.md](references/tell-catalog.md), each with its fix and, where known, the **displacement partner**: the adjacent form the tell migrates into once suppressed. Cite rules by name, never by number.

Lineage: the core rules descend from Orwell's six rules for writing ("Politics and the English Language", 1946), carried here in checkable form rather than quotation; the register split and caps from ASD-STE100's public structure; the evidence rows from GOV.UK's user research.
