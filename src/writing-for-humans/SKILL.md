---
name: writing-for-humans
description: Writing conventions for human-facing prose — ticket and work-item bodies, docs and READMEs, ADR rationale, session summaries, incident reports, release notes, error messages, outbound messages drafted for the user, and the narration, publish confirmations, and reports the user reads in the terminal. Use when writing or editing prose whose job is to be understood by a person, when narrating work or confirming a publish back to the user, when auditing a draft for AI tells, or when picking the register for an artifact. Not for agent-consumed instruction files (`writing-for-agents` owns those), not for copy a member, patient, or subscriber reads (`health-literacy` owns that), and not for code.
---

# Writing for Humans

Human-facing prose exists to be **understood**. The test is the prose's function, not its reader: agents read ADRs too, but they read them the way a human does, for comprehension. Rationale, tickets, definitions, summaries, and the prose a run addresses to the user live here.

**One hard stop, stated here because it fires last:** an outbound draft written as the user carries **no em dashes, none**, and the dash sweep is its mandatory final step — `~/.claude/rules/outbound-dash-sweep.md` owns the sweep and fires with no skill loaded, and § Register by artifact carries the row and the pipeline pointer.

Serve the reader, never the detector. Don't try to make text score as human-written, and don't guess whether a text was AI-written — detectors guess; a named pattern with a quoted line is evidence the reader can check. The tells this skill hunts are banned as *clarity* failures, not by who produces them. Authorship is the ground in exactly two places — the catalog's Formatting glyph entries and the Outbound row — and neither licenses mimicry or an authorship verdict. The named tells — filler, puffery, contrastive formulas, mic-drops, metadiscourse, anthropomorphism, and the rest — are the **tell catalog**, [references/tell-catalog.md](references/tell-catalog.md); open it when auditing a draft for tells or sweeping one before it ships.

Write for the reader who arrives with no history. Prose that only makes sense to someone who watched the conversation happen is **overfitted** — rewrite it against the project's own vocabulary until it stands alone. On any artifact that outlives this session — a work-item body, a doc, a release note, an outbound draft — and on any document over 500 words, prove that rather than assume it with a **Cold-reader pass** — the draft alone to a fresh-context reader that saw none of this conversation, asked what they took from it; every miss is a defect in the draft, fixed by editing it, never by briefing the reader. Readers scan rather than read, and expert readers prefer plain wording *more*, not less, as the topic gets harder — so front-loading and plain words are a service to every audience, never dumbing down.

## Classify, then write

Every passage is **procedural** (instructions — the reader will *do* something) or **descriptive** (explanation — the reader will *know* something). Classify first; the mode selects the rules. Don't mix modes in one passage or one list: acceptance criteria and repro steps are procedural; context, approach, and rationale are descriptive.

**Procedural:** imperative voice. One instruction per sentence, unless two actions happen at once. At most 20 words per sentence. A required condition comes *before* its command, split by a comma: "If the build fails, read the log" — trailing conditions get dropped. A warning leads with the command, then the risk: "Do not run this against production. The flag deletes rows that do not match the source" — never the explanation first.

**Descriptive:** no imperative. At most two clauses per sentence; split anything over 25 words. One new fact per sentence. Timelines use simple past — "we identified" not "we have identified", which hides when — except where the compound form carries an uncertainty or a current relevance the simple form would drop ("the job has completed and still holds the lock"), which the preservation contract's modality rule keeps when that prose is being rewritten ([references/modality-and-scope.md](references/modality-and-scope.md) holds it in full). Passive voice only when the actor is genuinely unknown; otherwise ask "by whom?" and put the answer first.

**Word counting**, so the caps survive technical prose: a backticked span, an identifier, a number with its unit, a parenthesized aside, and a hyphenated word each count as one word. `az boards work-item update --id 42` is one word.

**Never shorten by deletion of grammar.** Keep articles, keep "that", no telegram style — "Make sure that the file exists before you run the command", never "Ensure file exists before running". Plain means *explained*, not terse: a cramped sentence gets expanded so each point stands alone. Cutting is for words that carry no fact, never for words that carry the grammar.

## Register by artifact

Admit a row only with a named typist — the role that writes the artifact, and how often — never for an artifact nobody here produces; admit a register entry inside a row after two sightings in real drafts, never one.

| Artifact | Register |
| --- | --- |
| **Ticket body, doc** | Neutral and plain; contractions fine — but avoid negative ones ("cannot", not "can't": readers misread them as their opposite) |
| **README, and a guide (a how-to, a tutorial)** | Same register, plus the first-screen and guide structure rules in [references/register-by-artifact.md](references/register-by-artifact.md) — open it before writing one |
| **ADR rationale** | Descriptive, and it takes a position — "strike a balance" and "it depends" prose is the decision dodging itself; name who decided and why |
| **Session summary, incident report** | Outcome first; simple past with times ("Between 14:02 and 14:31 UTC, 12% of requests failed"); state the unknown as "unknown" — a hedge reads less honest, not more careful. The first line and the last line, read alone, must give what happened and what to do next |
| **Shift handover note (the outgoing on-call, per shift)** | Five sections, each present or an explicit "none": active incidents, ongoing investigations, recent changes, known issues with their workarounds, upcoming events; a section left blank is an incomplete handover, and an incomplete handover is a postmortem action item |
| **Changelog entry, release note** | Notable-to-users only; the ordering, citation, and file rules in [references/register-by-artifact.md](references/register-by-artifact.md) — open it before writing one |
| **Error message, UX microcopy** | Calm, zero playfulness; the five-question shape in [references/register-by-artifact.md](references/register-by-artifact.md) — open it before writing one |
| **Commit message, PR body, review reply, closing comment** | A maintainer recording a decision for another maintainer: impersonal, matter-of-fact ("Previously, …", "This caused …"); imperative only in the subject line; first person only for an actual decision or open question. The catalog's commit-and-PR family ([references/tell-catalog-shipping.md](references/tell-catalog-shipping.md)) fires here |
| **Meeting notes (whoever posts the recap)** | Decided separated from discussed; an action is an owner plus a date or is flagged unassigned or undated — the writer never fills either in; commitments and load-bearing statements verbatim, with a paraphrase marked as the writer's reading. A recap drawn from a transcript or recording reads it under [references/recap-from-transcript.md](references/recap-from-transcript.md) — the thread-state vocabulary, the receipt rule, and the refusal — open it before reading one |
| **Weekly status note to a manager (any engineer, weekly)** | Progress, not activity; every next step dated or marked undated; opens with what last week's note said would happen and whether it did |
| **Outbound as the user — email, Teams message, memo, proposal, questionnaire** | The user's own voice, matched from a writing sample they supply, with their own sentences kept over composed ones; **no em dashes, none**, and the full tell catalog swept at maximum strictness. The rules, and the sweep's pipeline (§ The dash sweep), are in [references/outbound-as-the-user.md](references/outbound-as-the-user.md) — open it before drafting |

## Referring to work items

In anything the human reads — narration, publish confirmations, reports — a work item goes by its **title**, the ID and link riding inside (`[Rate-limit login](url) (#42)`), never by a bare ID.

The report that closes a piece of work is one or two sentences: what changed, and the verification and review result, deferrals named. Never a list of changed files, a restatement of the spec, or a narration of the process — the diff and the transcript already hold those. A table a skill mandates at its close (`implement`'s completion audit) is exempt; the sentences sit above it.

## Core rules

- **Front-load.** The most important sentence comes first — in the document, in each paragraph, in each heading. Headings are descriptive and verb-first where they name an action; never questions, never clever labels ("Applicable legal constraints", not "Legal requirements as a floor").
- **One term per concept.** Pick the word and reuse it — "check" every time, never rotated with "verify" and "confirm"; synonyms imply the things differ. Domain terms never vary; common verbs may repeat freely; `DOMAIN.md` is the project's approved vocabulary.
- **The press-release test.** If a sentence could move unchanged into any company's press release, it carries no fact — cut it, or replace it with the fact, number, mechanism, or consequence specific to this subject.
- **Vague quantifiers become questions.** "Many", "significant", "improved", "countless", "a handful" (when the count is known) each demand their number: how many, by how much. Answer from evidence you have; **never invent the number — ask.**
- **Never fabricate a fact, citation, number, or example**, and on a fresh draft as much as a rewrite. The invented number has a cause: a template slot the source cannot fill — a before/after line in a status note, a measured-improvement claim in a release note, a proof figure in a proposal — is what produces it. **Cut the slot, never fill it.**
- **Untouchables stay exact**: code spans, identifiers, CLI commands, file paths, quoted error text, proper nouns, and text quoted from or attributed to another person, even where they break a rule — a tell inside someone else's words is reported, never edited.
- **A number carries its method.** A precise figure with no sample, window, or measurement behind it reads as precision it has not earned — "94% of runs" needs the run count and the period, or it becomes "most runs". State the method beside the number, or write the honest imprecise version. A figure offered as good or bad also names what it is measured against — the prior value, the target, or the baseline; where the source holds no comparator, the good/bad framing goes and the bare figure stays. Figures measured by different methods are reported side by side, never summed into one total: a re-counted file and a before-and-after median are not the same kind of evidence, and a blended total hides which component is wrong.
- **Durable docs carry no clock.** "Currently", "recently", "soon", "for now", "the new endpoint", "at the time of writing" date a sentence to the day it was typed and read as wrong the day after. State what is true without the temporal frame; where a change is the point, tie it to the version or date that carries it.
- **A deliverable ships bare.** When the output *is* the artifact — a drafted message, a release note, a summary someone will paste onward — it arrives with nothing wrapped around it: no "Here's the draft", no note on the approach taken, no closing offer to revise. The wrapper makes the reader dig the artifact out, and it travels with the artifact into wherever it lands next. The one exception is a flag line: where a cap could only be met by dropping a qualifier, scope condition, number, or safety condition, keep the longer sentence and name the trade-off in one line **after** the artifact, never wrapped around it. (Rewriting existing prose, that is the preservation contract's own rule; [references/edit-and-detect.md](references/edit-and-detect.md) states it there.)
- **Protect the specific fact.** Don't smooth "cut review time from 30 minutes to 8" into "significantly improves review efficiency" — the edit that generalizes a detail is a deletion wearing a rewrite's clothes.
- **Verbs, not nominalizations.** "Validates", not "performs a validation of"; the nominalized verb is where long sentences come from.
- **Everyday word over formal word.** "Use" not "utilize", "help" not "facilitate", "about" not "approximately". The test: would you say it to a colleague out loud?
- **Paragraphs hold one topic, at most 5 sentences**, and the topic sentences alone must read as an outline of the document — check by reading only them.
- **Numerals for every number from 2 up** — "3 retries", not "three retries" — except at a sentence start.

## Prose that already exists has two modes

**Edit** rewrites it; **Detect** audits it, naming patterns without rewriting. Both answer to the preservation contract, which a fresh draft has no source for. Both are in [references/edit-and-detect.md](references/edit-and-detect.md) — open it when the text in hand was already written, by someone else or by an earlier run; a first draft from nothing reaches neither mode.

## Long documents

A document over three planned sections, or of a kind that section names, lands section by section under `handoff` § Where to write it (`~/.claude/skills/handoff/SKILL.md`), as the global rule `~/.claude/rules/large-write-chunking.md` forwards; a truncated artifact is discarded, never shown.

## Boundary

Documents that exist to be *obeyed* — a skill body, `CLAUDE.md`, a reference an agent follows as process — are `writing-for-agents`', and the split is the document's function, never its reader. This discipline deletes persuasion by design: marketing, brand, and campaign copy are out of scope — say so and offer to apply it to the factual parts only. Copy a member, patient, or subscriber has to act on is `health-literacy`'s, which owns the define-at-first-use and next-step-with-a-date rules the register rows above do not carry; what data may appear in that copy is `phi-safe-code`'s.
