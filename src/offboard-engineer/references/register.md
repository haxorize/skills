# The register, the ladder, and the runs without the engineer

Read this at the consent turn, before the first register write, again on a resume, and again at `stop`. `00-risk-register.md` is the live artifact of the whole run; this file is its layout, its states, how far down the ladder a budget reaches, and — in § Without the departing engineer — the three situations in which the normal capture does not happen at all. The consent turn is the earliest of those gates: a run refused there never reaches a register write, so a reader who waits for one has already passed the turn where the refusal had to be made.

## The ladder

Ordered by how fast the knowledge decays and how badly its loss hurts, never by how the code is organized. The human's triage in Triage outranks it, and a short budget works down it until time runs out and then flags the rest. A rung is **complete** when every register item in its category has reached one of the three closed states — **Closed**, **Deferred**, or **Unrecoverable** — and **incomplete** while any sits in the two open ones, **Open** or **Conflicts**. Both readings are reported, never hidden: "we ran out of time" is a real outcome, and so is "the author and the code still disagree"; a silently dropped item is neither.

| Rung | Done when |
| --- | --- |
| **Triage — scan, rank, agree the budget** | Every scanned item sits in the register with a rank and a category, the human has seen the top of it and reordered as they see fit, and the realistic reach of the budget has been said out loud |
| **In-flight and imminent — what is live now and dies on their last day** | Every unmerged branch, half-done migration, vendor thread, and dated obligation is named with its state, its deadline, and who now owns it — or is flagged as having no owner. First because it decays fastest: a landmine in old code is still there next quarter; a half-finished migration with an external deadline is not |
| **Landmines — the code that bites whoever touches it next** | Every high-rank workaround, uncommented constant, and retained dead-code block has a why, a "what happens if you change it", and a blast radius — or is `[unknown]` with the author on record as not knowing |
| **Operational reality — the runbook that never got written** | A successor could take the pager for this system and know what they would be walking into — what pages, what the alert means, the manual step, the order that matters — including the parts still uncovered |
| **Decisions and dead ends — why it is shaped this way, and what was already tried** | Each significant decision has a rationale or an honest `[unknown]`, and the "we tried this, it did not work, here is why" list exists — the cheapest knowledge to capture and the most expensive to rediscover |
| **Relationships and access — the humans and the accounts** | Every external dependency has a named human or an explicit "nobody", and every access path has a location and a rotator, with no secret value recorded |
| **Sole-ownership sweep — whatever remains** | Every remaining register item, the pasted KT map's `[unknown]`s included, is in one of the three states |

## Where the record lives

```
docs/offboarding/<departing-slug>-<yyyy-mm-dd>/
├── 00-risk-register.md   ← the live register: every item and its state, updated every turn
├── 01-capture.md         ← the tagged capture by area, hedges intact
└── offboarding.md        ← the successor document, written only at `stop`
```

A repo outlives any one departure, so each capture is namespaced by the departing engineer's name, lowercased with spaces to hyphens — a slug you derive, never the argument as typed — and the date the session started; a second departure next year does not overwrite the first. There is no index file: the directory is the list. **Before creating the folder, say that it will hold named contacts, the locations of access, and exactly where production is fragile, and wait** — a team may want it gitignored or elsewhere, and where the human names another directory, write there instead. **Stamp every file** one line under its heading with the commit (`git rev-parse --short HEAD`) and the date, noting that citations are line numbers at that commit; with no `.git`, stamp the date alone, say so, and say that the scan is leaning on code-shape signals with no history behind them.

**`00-risk-register.md` is the source of truth**, in five sections in this order — **Unrecoverable** (`[unknown]`, who was asked, a suggested next step), **Conflicts** (both sides, unresolved), **Open** (rank, category, `file:line`, why it is a risk), **Deferred** (why it was parked, by whom), **Closed** (an anchor into `01-capture.md`) — with the first two on top because they are the two things a successor must see on day one and the two things every other handover leaves out. The section an item sits in **is** its state, and the three the ladder calls closed are **Closed** (*answered*), **Deferred** (*deferred*) and **Unrecoverable** (*unrecoverable*) — the parentheticals are the only place the lowercase state word this skill reports coverage in (`Coverage: N answered · N deferred · N unrecoverable · N open · N conflicts`) is mapped onto the section name; **Open** (*open*) and **Conflicts** (*conflicts*) are the two the ladder does not call closed.

The register opens with a marker naming the rung in progress and the budget remaining, so a resumed session knows where the walk stopped from the disk alone; there is no separate progress file, because every item carries its own state. At `stop` the marker is **rewritten, never removed** — to a closed line naming the date, the coverage numbers, and whether anything is still out with `/ask-for-me`. A later session reopens **that same folder** by the departing engineer's name rather than starting a second one: answers arriving after `stop` are captured, the register updated, and `offboarding.md` rewritten from it and re-stamped, with the new date added to its closing line.

**Resuming:** read the register; where the stamp's commit differs from `git rev-parse --short HEAD`, say so in the first turn and re-verify the citations you build on before asking about them — and where the departing engineer is no longer reachable to confirm a drifted reading, flag that in the register rather than trusting the old citation.

## Without the departing engineer

Three situations end up here, none of them a normal capture.

**No unattended run.** A skill that reads a codebase can run its whole ladder alone, because the repo holds the answers. Here the human is the data source, so an unattended run is not a *faster* version of this skill — it is a different and worse one, producing an agenda that looks like a capture. That is why the body's remedy is an offer rather than a degraded run.

**When they have already left.** Run the scan, produce the register, and mark every item `[unknown]` with "author unavailable" against it. The output is a map of what the organization lost and where it is exposed — the input to deciding what to reverse-engineer first. Its title and first line say that nobody answered any of it.

**The async tail.** Where the session ends with items the departing engineer will answer in writing rather than in the room — the budget ran out, or the answer needs a file they have and you do not — say so at `stop` and suggest they run `/ask-for-me`, pasting those register items and their readings in as the subject. That skill interviews from scratch and has no intake, so the items are its raw material, not its input format; a user-invoked skill cannot be loaded on their behalf either way. Note in the register which items went out, and say that the questionnaire's deadline decides nothing here: an item still unanswered stays **Open**, never *unrecoverable*. The filled-in answers come back through `start` on the same folder, tagged `[human]` like any other.
