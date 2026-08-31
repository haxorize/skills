# Writing `offboarding.md`

Read this at `stop`, before the record's first line. Build it from `00-risk-register.md` and `01-capture.md`, never from memory. It is long, so it lands section by section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`) — the spine below is the section order, and a section that came back cut is rewritten whole rather than appended to.

## 1. The inversion that governs everything here

A document that explains a system puts its unknowns near the end, because its point is what *is* understood. This document is the other way round: **what nobody knows goes first.** A successor inheriting a system needs the landmines before the tour — the thing nobody could explain, the place where the last expert and the code disagree, the deadline with no owner. Every other handover buries these or omits them, which is why they get discovered at 3am.

## 2. The coverage check, and its one floor

Thin coverage is **normal, not a failure**: this skill runs against a deadline that does not renew, and reaching `stop` with open items is the expected ending. Do not refuse to synthesize because the register is not empty; state the coverage plainly at the top and carry on. Report it as five numbers taken from the register, one per section — **answered · deferred · unrecoverable · open · conflicts** — the most honest summary of the session that exists. The last two are the ones every other handover omits, and they are why this one can be trusted.

One floor. Where **no human answers were captured at all** — a scan-only run, or the already-left mode — what you have is a question list, not an offboarding record, and its title and opening line say so. A register of unanswered questions formatted as a record is believed by someone who was not in the room.

## 3. The confidence filter

- **Promote** `[human]` and `[fact]` into the body as settled statements, and attribute every `[human]` (*"per <name>"*) so a successor knows a person said it, not a scan.
- **Keep every hedge.** Where they said "I *think* it was for the timezone bug", the document says that. Cleaning uncertainty into confidence is the one failure this whole method exists to prevent, and it is most tempting now, when the prose wants to be tidy.
- **Carry** every `[unknown]` into the opening section, each with who was asked, so the next person knows the door was tried rather than merely unopened.
- **Preserve** every `[conflict]` unresolved, both sides intact. Where it stayed unresolved in the room, it stays unresolved on the page.
- **Drop** unconfirmed `[inference]` — your guesses about a system you spent an hour on are worth nothing beside the register. An inference that matters and was never put to the human goes in *Not covered*, never in the body.

## 4. The section spine

Fixed. Sections 1 and 2 go first even when they are short — especially when they are short, since a two-line "gone for good" section is a two-line warning that would otherwise cost someone a week. Section 6's failed-experiment list is the cheapest thing in the document to write and the most expensive to rediscover; it is never trimmed for length.

```markdown
# Offboarding record — <system or area> · <departing name>
Coverage: N answered · N deferred · N unrecoverable · N open · N conflicts · session <date>, commit <hash>. Citations are line numbers at that commit.

1. Gone for good                            ← every [unknown]: what nobody, the author included, could explain, and who was asked
2. Where the author and the code disagree   ← every [conflict], both sides, unresolved
3. Live threads                             ← in-flight work: state, deadline, and who owns it now (or "nobody")
4. Landmines                                ← each with what it is, why it is there, and what breaks if you change it
5. Operating this                           ← the runbook that was in their head: what pages, what it means, the manual steps
6. Why it is like this                      ← decisions with their rationale, and the "we already tried that" list
7. People and access                        ← a named human per external dependency; where keys live and who rotates them
8. Not covered                              ← deferred items and what was never scanned, said plainly
```

The title carries no last day: the run never asks for one, and a date invented to fill a fixed title is the first false claim in a document whose whole point is not making any. Where the departing engineer volunteers it, it belongs in section 3 beside the dated obligations it actually governs.

## 5. Offer the departing engineer the last word

Before the document is treated as final, offer it to them to read, and say why: it is accurate, because they will catch the place where a hedge got hardened or where the intention was recorded rather than what shipped; and it is decent, because the document quotes a named person, will outlive their employment, and will be read by people who never met them. Where they decline or there is no time, the document notes that they did not review it.

## 6. What must not be in it

- **Secret values**, and **anything about the departure itself** — both are the body's hard stops, and this is where they are most tempting to break.
- **Blame.** The register surfaces undocumented, fragile, and strange code, much of it theirs. Describe the code and its risk, never the judgement: "uncommented, and only they have touched it" is a fact about the system; "they left a mess" is an opinion about a person, unusable to a successor, and it makes consent for every future run of this skill harder to get.

## 7. Close

Rewrite the in-progress marker in `00-risk-register.md` to a closed line — the date, the five coverage numbers, and whether anything is still out with `/ask-for-me` — rather than removing it, so a later session reopens this folder instead of starting a second one. Then announce the path, the five coverage numbers, and point at section 1 — the gone-for-good list is what the successor reads before anything else.
