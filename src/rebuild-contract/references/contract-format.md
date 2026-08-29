# Writing `contract.md`

Read this at `stop`, before the contract's first line. Build from the trail, never from memory. It is the longest document this suite writes, so it lands section by section under the global large-write-chunking rule (`~/.claude/rules/large-write-chunking.md`) — the spine below is the section order, the in-progress marker on `01-behavior-index.md` is the resume pointer, and a section that came back cut is rewritten whole rather than appended to.

## 1. The coverage check, which can refuse

Take four numbers from `01-behavior-index.md` — **specified · excluded · deferred · unknown** — out of its total. They go in the contract's header, not a footnote; they are the most honest summary of the run.

Two conditions stop synthesis. **Any entry still `open`** — resolve it or move it to `deferred` with a reason; an `open` entry is coverage the contract claims and does not have. **Specified coverage under roughly half of the in-scope index** — do not produce a polished document. Say what is covered and what is not and offer three options: synthesize now with the gap stated in the header, keep working the index, or pause. Proceed only on a clear yes. Thin coverage is survivable when it is named; a contract that looks complete and is not will be believed by someone who was not here, and they discover the gap by shipping.

## 2. Two filters: confidence, then obligation

**Confidence.** Promote **[fact]** and **[human]** into the body as settled rules. Promote an **[inference]** only where it describes behavior you traced through an unambiguous path, never a purpose reconstructed from a name. Carry every **[unknown]** and every unpromoted [inference] into *Coverage & open questions*, each naming what would settle it. Preserve every **[conflict]** with both sides intact in *Suspect behaviors*. Drop dead-end explorations and anything about how the code is organized.

**Obligation.** **Unmarked reads as [contract]** — the safe default — so what gets marked is every departure from it: **[incidental]**, **[suspect]**, **[undefined]**, at the capability or on the individual rule, and more than one where more than one applies (a suspect behavior an outside caller can see is `[contract] [suspect]`). Telling the reimplementer what they are *free* to change is half the document's value and the half every other spec omits, so a missing mark is a real defect; tagging every line `[contract]` is not the fix.

## 3. The section spine

Fixed. Every section renders even when it is empty, because "none found" is information a reimplementer can act on and an absent section cannot be told from an oversight. Section 5's interior adapts to the system type; the spine does not.

```markdown
# <System> — rebuild contract
Coverage: N specified · N excluded · N deferred · N unknown (of N)
Source snapshot: commit <hash>, <date>. Describes behavior as of that snapshot.

1.  Purpose                     ← what this software is for, in a paragraph someone can repeat back
2.  Boundary & compatibility    ← the observers and their fidelity per surface; read before anything else
3.  Actors & permissions        ← every actor; the full actor × capability matrix, denials included
4.  Domain model & invariants   ← entities, identity, lifecycles with legal transitions, derived values with formulas
5.  Capabilities                ← the bulk: one entry per capability, uniform shape, stable IDs
6.  State & persistence         ← durability, consistency, observable atomicity, retention, deletion
7.  Integrations                ← each external dependency: what crosses, failure behavior, retries
8.  Background & scheduled      ← triggers, cadence, guarantees, idempotency, catch-up behavior
9.  Configuration surface       ← every behavior-changing key: default, precedence, absence behavior
10. Errors & edge cases         ← user-visible errors, codes, retryability; cross-cutting edge rules
11. Non-functional contract     ← limits, caps, timeouts, concurrency, retention, compliance, and every stack-behavior item from Stage 6, each stated or recorded as not found
12. Suspect behaviors           ← [suspect] and [conflict]: what happens, why it looks wrong, who can see it
13. Coverage & open questions   ← excluded, deferred, unknown; questions for a human, named plainly
Appendix A. Acceptance checklist
```

**Section 1 has no producing stage**, which is deliberate and the one place synthesis is asked for: write it from `00-boundary.md`'s observers and the capabilities in section 5, in one paragraph, and where the trail does not support even that, say what the system does for whom and stop. Do not improvise a mission statement. Section 2 sits near the top because it governs how every later section is read. Sections 12 and 13 sit at the end and are never trimmed for length: they are the two sections that tell a reader how far to trust the other eleven.

## 4. The capability entry

Same fields, same order, every time — a reader hunting one rule in a long document needs predictability more than prose. One entry, wrong and then right:

> **Wrong — a tour.** *"The `OrderService.cancel()` method in `services/order.py:214` handles cancellation. It checks the order status, calls the Stripe refund API, and publishes an `order.cancelled` event to the `orders` Kafka topic."* — names the class, the file, the vendor, the broker; a reimplementer on another stack learns nothing they can act on and cannot tell which parts they are obliged to reproduce.

```markdown
### C-014 · Cancel an order  ·  [contract]
**Actor:** the order's owner, or any support agent.
**Trigger:** an explicit cancel request naming the order.
**Preconditions:** the order is in `placed` or `paid`. Cancelling a `shipped` or already `cancelled` order fails with E-31 and changes nothing.
**Rules:** a paid order refunds the full captured amount to the original payment method; refunds are issued at most once per order however many times cancel is called. Cancellation within 30 minutes of placement is free; after that a 10% restocking fee is deducted from the refund and itemized in the refund record.
**Effects:** the order moves to `cancelled`; reserved stock is released; the refund is recorded with amount, reason, and timestamp.
**Outputs:** the updated order. A cancellation notice reaches the customer — not necessarily synchronously.
**Edge cases:** a refund rejected downstream still moves the order to `cancelled` and marks the refund `failed` for manual handling — cancellation is never blocked by a refund failure. Concurrent cancel requests produce exactly one refund.
**Undefined:** the ordering of the stock release relative to the refund. [undefined]
**Evidence:** trail `02-capabilities.md#C-014` — the 30-minute window is an [inference] from the code with no test covering it; flagged for a human.
```

The right one is longer, contains no implementation, and can be built in any language. Every rule executable, every obligation labelled, every gap named instead of smoothed — that difference is the whole skill.

## 5. The leak sweep: strip the implementation on the way out

The trail is full of citations, paths, class names, framework names, and none survive into the contract. Before finalizing, sweep for and remove: `file:line` references and function, class, module, and table names; framework, library, vendor, and language names; directory structure, layering vocabulary, and anything describing how code is organized; "the service", "the handler", "the model" as nouns — name the behavior, never the component. The test for a proper noun that wants to stay: would the reimplementer's system be observably different if they used something else? Where a name is the boundary — a table another team reads, a wire field, a URL path, a payment provider whose behavior the rebuild must match — keep it and say why it is fixed, so a reader can tell a constraint from a leak.

## 6. The self-audit, standing in for the acceptance test

Nobody will rebuild the system while you wait, so run the proxy, before declaring the contract finished:

- **Pass A — reconstruction questions.** Reread the contract as if the source did not exist. At every capability, write every question you would have to answer to write code — a value to invent, an ordering to guess, an error to design. Each is a hole to fill or a deliberate [undefined] to mark. This pass finds more real gaps than any other, because it moves you from the author's chair to the reader's.
- **Pass B — branch spot-check.** Pick a dozen behavior-bearing branches from the source at random — validation conditionals, error paths, permission checks, retry logic — and confirm each is stated or explicitly excluded. A miss rate above roughly one in six means Stage 2 was too shallow; go back rather than ship.
- **Pass C — the mechanical leak sweep.** Two greps, because the citation form is not the only mechanical leak and the one with no line number is the form a run actually produces:

  ```
  grep -nE '\.(py|pyi|ts|tsx|js|jsx|mjs|go|java|kt|rb|cs|rs|php|swift|scala|c|cc|cpp|h|hpp|sql|sh)\b' contract.md
  grep -nE '\b[a-z0-9_]+/[a-z0-9_./-]+\.[a-z]+' contract.md
  ```

  The first catches a source-file name with or without a `:42` after it; the second catches a bare path (`services/order.py`, `src/app/handlers`). Both over-match on purpose — a wire path or a table name will show up, and keeping it is the judgement the sweep above describes. What neither reaches is the subtle leak: framework nouns, vendor names, and layering vocabulary, found only by reading.
- **Pass D — the numbers.** Every threshold, timeout, limit, and percentage traces to a trail citation. A confidently stated number nobody verified is the single most damaging failure here, because it will be implemented exactly.

Report the audit in one line at `stop`: questions raised and resolved, spot-check miss rate, leaks removed.

## 7. Appendix A: the acceptance checklist

Close with a flat, checkable list — one line per [contract] behavior, phrased as a test a reimplementation passes or fails, each carrying its capability ID:

```markdown
- [ ] C-014 · Cancelling a `paid` order within 30 minutes refunds 100% of the captured amount.
- [ ] C-014 · Cancelling a `shipped` order fails with E-31 and changes no state.
- [ ] C-014 · Two concurrent cancels produce exactly one refund.
```

This converts the contract into an acceptance suite someone can work through and lets the reimplementer report coverage back in the document's own vocabulary. Derive it from the *Rules* and *Edge cases* fields — a rule that cannot be phrased as a checkable line was not finished in section 5. Leave out [incidental] and [undefined] items; include [suspect] ones, flagged, so nobody "fixes" one by accident.

## 8. What must not be in it

- **Secret values.** Kind, purpose, and absence behavior only. A credential that appeared in chat during the run does not enter the contract, and say plainly that it should be rotated.
- **Real data.** Every example value is invented.
- **Judgement about the people who wrote it.** "This appears unintended and any external caller can observe it" is a fact about the system; "this is a mess" is an opinion, unusable to a reimplementer, and ages badly in a document that outlives everyone's employment.
- **Architecture.** No module maps, dependency graphs, or layering diagrams; what is interesting and does not survive reimplementation belongs in a KT map.

## 9. Stamp and announce

The contract carries the same commit-and-date stamp as the trail, as provenance rather than citation support: which snapshot of which system it describes is the one thing a reimplementer needs to check whether the world moved underneath them. Then rewrite the in-progress marker in `01-behavior-index.md` to a closed line — the date, the four coverage numbers, and any entry still `deferred` or `unknown` — rather than removing it, so a later session extending the contract reopens this folder rather than starting a second one. Announce as the body's `stop` says.
