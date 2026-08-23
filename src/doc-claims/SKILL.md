---
name: doc-claims
description: Checking what a document claims against what that document answers to — the code and tests it describes, or the sources it was derived from — one verdict per claim rather than an impression of the whole. Use when judging whether a README, guide, reference, or spec is still true, when prose may have drifted after a refactor, rename, or removal, when a derived document (a distillation, a summary, a local rewrite of an upstream) needs grounding against its sources, when a periodic sweep or another skill needs per-claim verdicts it can act on, or when someone asks whether the docs still match the code. Not for updating docs the current change just made stale, which is feedback-loops at every close. Not a merge gate — this judgment is fallible and runs as a triggered review, never as CI.
---

# Doc claims

A **claim** is a checkable assertion a document makes about something outside itself: a signature, a default, a behaviour, a return shape, a guarantee, a count, a version, an example that is supposed to run. The unit of this discipline is the claim, not the document — a doc is never "mostly accurate", it is a list of claims each of which holds or does not, and the finding names the one that does not.

Read the prose directly for meaning. There are no claim markers, no annotation DSL, no structured comments to key on: the thing being checked is the thing the human reads, and any scheme that checks a parallel annotation instead checks the wrong artifact.

## Extract the claims

Go through the prose and write down every assertion that could be false. Include the ones carried by example code, by a table, and by a heading. Exclude what makes no factual claim about anything outside the document — intent, rationale, and register have nothing to check, and a document made only of those is reported as having no claims rather than passed.

## Judge each claim against what it answers to

**Authority differs by kind.** A document is authoritative for **decisions** — what was chosen, what was rejected, and why — because nothing else records them; the code cannot contradict a rationale. A document is *never* authoritative for **counts, versions, paths, names, and sizes**: measure those live, every time, and a doc that says "eleven rules" is evidence of nothing but what was true when someone last counted.

- **Judge against the code and the tests, not the code alone.** A claim the code satisfies but nothing tests is not the same as one a test protects, and the verdicts below keep them apart.
- **A contradiction can mean the code regressed.** The document may be the only place the intended behaviour is written down. Check which side is wrong before "fixing" the prose — a doc that caught a regression is the doc doing its job.
- **Ground against the artifact reopened now, never from memory of it.** Memory of a codebase or a corpus is where drift hides, and a claim judged from recall is a guess with a verdict attached.

## Verdicts

| Verdict | Meaning |
| --- | --- |
| **PASS** | Matches what it answers to, and is exercised by a test (or, for a derived document, traced to a source passage or to a recorded decision) |
| **FAIL** | The code, or the source, contradicts the claim |
| **UNSUPPORTED** | Matches what it answers to, but nothing protects it — no test, or no source passage behind it |
| **STALE** | Refers to something removed or renamed |

Every claim gets exactly one. An **UNSUPPORTED** verdict is a missing test, reported as a candidate task rather than filed as a doc bug — the prose is fine, the protection is absent.

## Derived documents answer to their sources

Where a document was derived from something other than code — a guide distilled from a longer one, a summary of a spec, a local rewrite of an upstream — run the same pass with the sources in place of the code, and build a **source map** first: one row per section, and per distinct claim inside it, grounded as exactly one of a **source passage** (name the file and a few identifying words), a **recorded decision** (a deliberate departure someone signed off on), or **UNGROUNDED**.

Three failure classes come out of the map.

- **Ungrounded** — the writer invented it. Cut it, or get it signed off so it becomes a recorded decision. Verdict **UNSUPPORTED**.
- **Contradiction** — the derived document asserts what the source denies. Show both, side by side. Verdict **FAIL**.
- **Drift** — a paraphrase moved the meaning, scope, or strength. Verdict **FAIL**, quoting the passage it moved from.

**Drift runs in both directions.** A rule that came out *stronger* than its source is invented doctrine exactly as much as one that came out looser: "usually" promoted to "always", a two-condition rule that lost a condition, a narrow ban widened into a general one, a suggestion hardened into a prohibition. Each is a finding, and the direction is named in it.

A claim whose source passage no longer exists in the corpus is **STALE**, the same as one pointing at deleted code — where there is evidence the passage once existed (a prior source-map row, a history hit); with no such evidence it is **UNGROUNDED**, never both.

## Honest limits

This discipline does not verify the tests themselves — bad tests produce a confident, wrong **PASS**, and the upstream `tdd` discipline still matters. It reads prose, so it inherits prose's ambiguity: where a claim can be read two ways, report the ambiguity as the finding instead of picking a reading and grading it. And the judgment is fallible in both directions, which is why it runs as a triggered review and never as a merge gate.
