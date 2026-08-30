---
name: writing-for-humans
description: Writing conventions for human-facing prose — ticket and work-item bodies, docs and READMEs, ADR rationale, session summaries, incident reports, release notes, error messages, and outbound messages drafted for the user. Use when writing or editing prose whose job is to be understood by a person, when auditing a draft for AI tells, or when picking the register for an artifact. Not for agent-consumed instruction files (`writing-for-agents` owns those) and not for code.
---

# Writing for Humans

Human-facing prose exists to be **understood** — that is the boundary with `writing-for-agents`, which owns documents that exist to be *obeyed* (skill bodies, CLAUDE.md, references). The test is the document's function, not its reader: agents read ADRs too, but they read them the way a human does, for comprehension. Rationale, tickets, definitions, and summaries live here.

Serve the reader, never the detector. Don't try to make text score as human-written, and don't guess whether a text was AI-written — detectors guess; a named pattern with a quoted line is evidence the reader can check. The AI tells this skill hunts are banned because they are *clarity* failures, not because of who tends to produce them.

Write for the reader who arrives with no history. Prose that only makes sense to someone who watched the conversation happen is **overfitted** — rewrite it against the project's own vocabulary until it stands alone. On a document long enough to be worth the round-trip, prove that rather than assume it with a **Cold-reader pass** — the draft alone to a fresh-context reader that saw none of this conversation, asked what they took from it; every miss is a defect in the draft, fixed by editing it, never by briefing the reader (`work-item-shape` runs the work-item form of the same pass, asking what the reader would build). Readers scan rather than read (Nielsen Norman Group's eye-tracking shows an F-pattern covering 20–28% of the text), and GOV.UK's user research finds plain wording preferred *more* by expert readers, not less, with the preference growing as the topic gets harder — so front-loading and plain words are a service to every audience, never dumbing down.

## Classify, then write

Every passage is **procedural** (instructions — the reader will *do* something) or **descriptive** (explanation — the reader will *know* something). Classify first; the mode selects the rules. Don't mix modes in one passage or one list: acceptance criteria and repro steps are procedural; context, approach, and rationale are descriptive.

**Procedural:** imperative voice. One instruction per sentence, unless two actions happen at once. At most 20 words per sentence. A required condition comes *before* its command, split by a comma: "If the build fails, read the log" — trailing conditions get dropped. A warning leads with the command, then the risk: "Do not run this against production. The flag deletes rows that do not match the source" — never the explanation first.

**Descriptive:** no imperative. At most two clauses per sentence; split anything over 25 words. One new fact per sentence. Timelines use simple past — "we identified" not "we have identified", which hides when — except where the compound form is carrying the uncertainty or the current relevance the simple form would drop ("the request may have failed", "the job has completed and still holds the lock"), which the preservation contract's modality rule settles in the compound form's favour. Passive voice only when the actor is genuinely unknown; otherwise ask "by whom?" and put the answer first.

**Word counting**, so the caps survive technical prose: a backticked span, an identifier, a number with its unit, a parenthesized aside, and a hyphenated word each count as one word. `az boards work-item update --id 42` is one word.

**Never shorten by deletion of grammar.** Keep articles, keep "that", no telegram style — "Make sure that the file exists before you run the command", never "Ensure file exists before running". Plain means *explained*, not terse: a cramped sentence gets expanded so each point stands alone. Cutting is for words that carry no fact, never for words that carry the grammar.

## Register by artifact

A row is admitted only with a named typist — the role that writes the artifact, and how often — never for an artifact nobody here produces; a register entry inside a row is admitted after two sightings in real drafts, never one.

| Artifact | Register |
| --- | --- |
| Ticket body, doc | Neutral and plain; contractions fine — but avoid negative ones ("cannot", not "can't": readers misread them as their opposite) |
| README, and a guide (a how-to, a tutorial) | Same register, plus a first screen that answers four questions before anything else — what this is, who it is for, what state it is in, and the shortest path to running it. Every command is preceded by the question it answers, and a path the writer has not actually run is marked unverified rather than shown as working. A guide follows the same rules, plus three: the output a step produces (the rendered result, the terminal line, the file tree) is shown before the code that produces it; a prerequisite sits beside the step that needs it, never in a wall at the top; and callouts are rationed to two or three a page, because past that readers skip them as a block |
| ADR rationale | Descriptive, and it takes a position — "strike a balance" and "it depends" prose is the decision dodging itself; name who decided and why |
| Session summary, incident report | Outcome first; simple past with times ("Between 14:02 and 14:31 UTC, 12% of requests failed"); state the unknown as "unknown" — a hedge reads less honest, not more careful. The first line and the last line, read alone, must give what happened and what to do next |
| Changelog entry, release note | Notable-to-users only: what a user of the product observes changed — never typo fixes or internal refactors ("Refactored internal code structure" is an entry about nothing). Order breaking changes → features → fixes; cite PRs (`#1234`), never commit SHAs; append to the unreleased section rather than rewriting released ones; match the file's declared format where one exists |
| Error message, UX microcopy | Calm, zero playfulness; the five-question shape below |
| Commit message, PR body, review reply, closing comment | A maintainer recording a decision for another maintainer: impersonal, matter-of-fact ("Previously, …", "This caused …"); imperative only in the subject line; first person only for an actual decision or open question. The catalog's commit-and-PR family fires here |
| Meeting notes (whoever posts the recap) | Decided separated from discussed; an action is an owner plus a date or is flagged unassigned or undated — the writer never fills either in; commitments and load-bearing statements verbatim, with a paraphrase marked as the writer's reading |
| Weekly status note to a manager (any engineer, weekly) | Progress, not activity; every next step dated or marked undated; opens with what last week's note said would happen and whether it did |
| Outbound as the user — email, Teams message, memo, proposal, questionnaire | The user's own voice and register: a writing sample the user supplies (a prior email, a Teams thread) sets the voice — read it first and match its sentence length, openers, punctuation, and recurring phrases. What the sample never does binds too: a greeting, a sign-off, a contraction, or a glyph absent from every sample is off-limits in the draft, and a pattern present in one sample and absent in another is named, never averaged. Where the user has already written or said the thing, keep their sentence and cut, rather than composing a better one — composing in their voice is imitation, and imitation is what reads as not theirs. The dash sweep below still runs last and wins over anything a sample or a sentence of theirs contains: a dash inside a kept sentence is replaced with the user's own wording from elsewhere in the sample, or the sentence goes back to them, never composed over. No Markdown syntax in an email or Teams body (asterisks and pound signs render as symbols, and read as pasted). **No em dashes, none.** Sweep the full tell catalog at maximum strictness — the stake is authorship perception, not just clarity |

**The dash sweep** is the mandatory last step on an outbound draft; the global rule `~/.claude/rules/outbound-dash-sweep.md` owns it and fires with no skill loaded.

This discipline deletes persuasion by design. Marketing, brand, and campaign copy are out of scope — say so and offer to apply it to the factual parts only.

## Core rules

- **Front-load.** The most important sentence comes first — in the document, in each paragraph, in each heading. Headings are descriptive and verb-first where they name an action; never questions, never clever labels ("Applicable legal constraints", not "Legal requirements as a floor").
- **One term per concept.** Pick the word and reuse it — "check" every time, never rotated with "verify" and "confirm"; synonyms imply the things differ. Domain terms never vary; common verbs may repeat freely; `DOMAIN.md` is the project's approved vocabulary.
- **The press-release test.** If a sentence could move unchanged into any company's press release, it carries no fact — cut it, or replace it with the fact, number, mechanism, or consequence specific to this subject.
- **Vague quantifiers become questions.** "Many", "significant", "improved", "countless", "a handful" (when the count is known) each demand their number: how many, by how much. Answer from evidence you have; **never invent the number — ask.**
- **A number carries its method.** A precise figure with no sample, window, or measurement behind it reads as precision it has not earned — "94% of runs" needs the run count and the period, or it becomes "most runs". State the method beside the number, or write the honest imprecise version. A figure offered as good or bad also names what it is measured against — the prior value, the target, or the baseline — because "94% of runs" with its count and window still says nothing until the reader knows the comparison; where the source holds no comparator, the good/bad framing goes and the bare figure stays — a comparison is a slot the preservation contract's first line says to cut, never fill. Figures measured by different methods are reported side by side, never summed into one total: a re-counted file and a before-and-after median are not the same kind of evidence, and a blended total hides which component is wrong.
- **Durable docs carry no clock.** "Currently", "recently", "soon", "for now", "the new endpoint", "at the time of writing" date a sentence to the day it was typed and read as wrong the day after. State what is true without the temporal frame; where a change is the point, tie it to the version or date that carries it.
- **A deliverable ships bare.** When the output *is* the artifact — a drafted message, a release note, a summary someone will paste onward — it arrives with nothing wrapped around it: no "Here's the draft", no note on the approach taken, no closing offer to revise. The wrapper makes the reader dig the artifact out, and it travels with the artifact into wherever it lands next. The one exception is the flag the preservation contract requires: where a longer phrasing or a qualifier was kept on purpose, one line after the text names the phrase and the precision that would have been lost — after the artifact, never wrapped around it.
- **Protect the specific fact.** Don't smooth "cut review time from 30 minutes to 8" into "significantly improves review efficiency" — the edit that generalizes a detail is a deletion wearing a rewrite's clothes.
- **Verbs, not nominalizations.** "Validates", not "performs a validation of"; the nominalized verb is where long sentences come from.
- **Everyday word over formal word.** "Use" not "utilize", "help" not "facilitate", "about" not "approximately". The test: would you say it to a colleague out loud?
- **Paragraphs hold one topic, at most 5 sentences**, and the topic sentences alone must read as an outline of the document — check by reading only them.
- **Numerals for every number from 2 up** — "3 retries", not "three retries" — except at a sentence start.

## Two modes

**Edit.** First read the whole text and note the voice worth preserving; a difference from generic plain style is a finding only when it creates ambiguity, inconsistency, or wrong-stakes tone — deliberate character survives the edit. Then two passes: fix rule violations; reread as if you had never seen it and cut every clause the reader doesn't need. Make the minimum effective edit — a rough draft with a real voice still sounds like the same person after. A form fix cannot rescue substance: where the draft has no claim, no fact, and nothing the reader can act on, editing it produces better-sounding emptiness. Say the content is missing and name what it needs.

**Detect.** Audit without rewriting: name each distinct pattern from the catalog once per phrase, quote the offending line, give the fix in a few words. Where several tells converge on one phrase (bold plus scare quotes plus a dash aside on one coined term), report it once under the strongest name. No rewrite, no score, no authorship verdict. Offer the edit afterward.

Either mode: if the text already complies, say so and stop — don't churn compliant prose. A pass that finds the draft contradicting itself (two sentences that cannot both hold) reports the pair and stops; picking one is the author's decision, not the editor's.

## The preservation contract

- Never fabricate a fact, citation, number, or example the original didn't contain. The invented number has a cause: a template slot the source cannot fill — a before/after line in a status note, a measured-improvement claim in a release note, a proof figure in a proposal — is what produces it. Cut the slot, never fill it.
- **Modality is content.** A hedge, a scope word, a modal verb ("may", "usually", "in most cases", "on the paths we tested") is part of the claim, not decoration on it. Tense carries content on the same terms: a perfect form ("has completed and still holds the lock") states that the result is live now, which the simple past drops. Cutting one promotes a qualified statement into a flat assertion — a rewrite of the fact, and usually a false one. So thinning a hedge stack to the catalog's one-qualifier maximum is a rewrite decision, not a tidy: keep the qualifier carrying the real uncertainty, never whichever one reads shortest.
- **Logical scope is content too.** A rewrite keeps a trigger a trigger, never the only trigger ("do X if Y" does not say Y is the only case for X); a prerequisite a prerequisite, never a cause; "required" short of "sufficient"; "not tested" short of "wrong"; "has not started" short of "in progress"; and a scoped condition ("only under load") scoped, never widened to "always". Each of these promotions reads cleaner than the source and claims more than it did.
- Never silently drop a qualifier, scope condition, number, or safety condition to make a sentence fit a cap — keep the longer sentence and flag the trade-off instead, in one line after the artifact rather than wrapped around it — **A deliverable ships bare** above is where that line goes.
- A qualifier bolted on after a flat claim ("X always holds. In most cases.") is the claim being walked back: fix the claim, not the hedge.
- Untouchables: code spans, identifiers, CLI commands, file paths, quoted error text, proper nouns, and text quoted from or attributed to another person stay exact, even where they break a rule — a tell inside someone else's words is reported, never edited. The user's own sentence in an outbound draft is theirs on the same terms, under the *Outbound as the user* row above.

## Long documents

A document longer than a few screens is written the way the global large-write rule (`~/.claude/rules/large-write-chunking.md`) prescribes.

## Error messages

Before writing or approving one, answer five questions: what happened; why, at the most honest level of detail the product knows; what was *not* affected, if anything needs reassurance; what the user can do now; what they can do if that fails. Unanswerable questions are a product gap, not a copy problem — route them out. Shape: outcome first, then cause, reassurance, next step, escape route. No blame, no "Oops", no exclamation marks — and remember specific ≠ clear: a message can name scopes and tokens and still leave the reader with no move.

## The tell catalog

The named AI tells — filler, puffery, contrastive formulas, mic-drops, metadiscourse, anthropomorphism, and the rest — live in [references/tell-catalog.md](references/tell-catalog.md), each with its fix and, where known, the **displacement partner**: the adjacent form the tell migrates into once suppressed. Cite rules by name, never by number.

Lineage: the core rules descend from Orwell's six rules for writing ("Politics and the English Language", 1946), carried here in checkable form rather than quotation; the register split and caps from ASD-STE100's public structure; the evidence rows from GOV.UK's user research.
