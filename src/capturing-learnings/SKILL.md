---
name: capturing-learnings
description: Capture a solved problem as a retrievable Learning doc in docs/solutions/, and search past learnings by symptom. Use when a hard-won fix is verified ("that worked", "it's fixed", a diagnosis loop just closed), when a resolved production incident owes its postmortem, or when another skill needs the retrieval protocol over past solved problems.
requires: writing-for-humans, work-item-shape
---

# Capturing Learnings

A solved problem dies with the session unless it lands where the next agent can grep it. This skill owns the **solved-problems store** — `docs/solutions/` at the target repo's root, one Learning doc per problem and one incident learning per incident — on both sides: capturing a new learning and retrieving past ones.

A resolved production incident is captured in the same store as the second document kind, the **incident learning** — its triggers, dated filename, sections, timeline rule, and the `work-item-shape` call behind its Action items are the reference's § The incident learning; the gate below applies, with the incident's resolution as criterion 1 and its trigger as criterion 2. The store is flat and lazily created at first capture. Doc format, filename, frontmatter fields, and update mechanics live in [references/learning-format.md](references/learning-format.md), opened at § Capture workflow steps 2-4 when a doc is actually being written — never by the retrieval protocol.

## The capture gate

All three must hold — confirm out loud which are met before drafting; if any is missing, say why and stop: "none this session: <the failing criterion>" is a result, while silence reads as the gate not having run.

1. **Verified** — the fix is in and the original symptom is confirmed gone (the reproduction loop re-ran green). Never capture an unverified theory.
2. **Expensive** — the diagnosis took real investigation: multiple hypotheses, failed attempts, a non-obvious root cause. If the error message alone led to the fix, a search engine already owns it.
3. **Recurrence-plausible** — the class of problem can bite again in this repo or its siblings: the pattern is used repeatedly, or the trigger is easy to re-create. Its sharper form is a **retention test** on the store: if this doc were deleted, would a future run be *steered differently*, or would only the history be lost? An account of what happened that changes nothing a later session does belongs in the commit log — the store exists to change behavior, not to remember. The "only the history" answer is given by naming and quoting the in-repo artifact whose own text already states the reasoning; topical overlap is not coverage, and an artifact you cannot quote is not one.

A direct ask ("the team documents every fix") doesn't waive the gate — name the failing criterion first and let the human overrule explicitly; a store padded with trivia buries the learnings worth retrieving.

## Capture workflow

1. **Apply the gate** (above).
2. **Search before writing.** Run the retrieval protocol (below) against the new problem, extending the grep with the now-known root cause (`root_cause:`, `tags:`) — an existing doc can share the root cause under different symptoms. No store yet → nothing to overlap; continue. The **overlap rule**, by kind: a Learning doc with the same root cause *and* same fix approach as an existing Learning doc → **update it** per [references/learning-format.md](references/learning-format.md); an incident learning with the same root cause *and* same failure mode as an existing incident learning → a **recurrence**: a new dated doc that links the earlier one, and the earlier one gains a link forward — never a merge; a Learning doc and an incident learning on one root cause **link to each other and stay separate**, since one records the fix and the other the event. Otherwise a new doc. Never write a duplicate — two docs describing one problem drift apart. When the search returns a candidate that is neither clearly the same problem nor clearly distinct, adjudicate per [references/learning-format.md](references/learning-format.md) § Overlap adjudication.
3. **Draft** per [references/learning-format.md](references/learning-format.md). Cite durably: confirm every cited path and line resolves in the current tree (a path cited from memory is how fabrication enters a trusted store), and reference landed work by PR or issue number, not commit SHA — a squash or rebase silently invalidates SHAs. The doc's prose follows the human-facing register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live; a future maintainer reads it cold.
4. **First capture in a repo.** If this doc creates the store, run the discoverability check in [references/learning-format.md](references/learning-format.md) § First capture in a repo; skip it on later captures.
5. **Show the draft** (plus the instruction-file line when step 4 produced one) and save on approval.

## Retrieval protocol

How any skill reads the store — grep-first, cheapest signal first:

1. If `docs/solutions/` doesn't exist, report that and end the search — absence is a valid result, not an error.
2. Grep recursively (the store may carry category subdirectories from other tooling), case-insensitive, one pass over the frontmatter: the observed error strings with synonyms OR-ed (`(timeout|hang|stall)`); rank hits by matched field — `symptoms:` strongest, then `tags:`, `root_cause:`, `title:`.
3. Read only the frontmatter (first ~15 lines) of candidate files; full-read only the strong matches.
4. Return at most 5 distilled matches — each distilled by kind, the kind read off the filename (an incident learning's slug opens with its date): a Learning doc as root cause + fix + what didn't work; an incident learning as root cause + action items with their status + contributing factors — with its freshness flagged (`last_updated:` if present, else `date:`) — never raw doc dumps.
5. A match **informs** the present investigation; it never overrides present evidence — a stale learning can be confidently wrong.

## Boundary

This skill owns the store of solved problems and how a stuck run finds one; it does not diagnose. Running the loop that produces the fix is `diagnosing-bugs`', which calls the retrieval protocol above at its start and this skill at its close. Whether a Learning doc is still true against the code it describes is `doc-claims`' work — it reads a Learning doc as a document already in claim form — but that skill is model-invoked and its description names no store, so it does not fire on this case by itself: point it at `docs/solutions/` when you want the sweep. An incident learning's Timeline and Impact answer to observability and the tracker, never to the code, so a check of those sections runs against those sources. A durable project decision and its rationale is an ADR, written by `adr`, never a Learning doc, and an incident learning's Action items are work items, never decision records — a decision an incident forces is an ADR the action item cites: this store holds what broke, what fixed it, and what an incident cost.
