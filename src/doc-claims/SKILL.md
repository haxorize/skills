---
name: doc-claims
description: Checking what a document claims against what that document answers to — the code and tests it describes, the running product it describes, or the sources it was derived from — one verdict per claim rather than an impression of the whole. Use when judging whether a README, guide, reference, or spec is still true, when prose may have drifted after a refactor, rename, or removal, when a derived document (a distillation, a summary, a local rewrite of an upstream) needs grounding against its sources, when a periodic sweep or another skill needs per-claim verdicts it can act on, when someone asks whether the docs still match the code or the shipped product, or when an evaluation ledger's claim rows and their expiry dates need checking. Not for updating docs the current change just made stale, which is feedback-loops at every close. Not a merge gate — this judgment is fallible and runs as a triggered review, never as CI.
---

# Doc Claims

A **claim** is a checkable assertion a document makes about something outside itself: a signature, a default, a behavior, a return shape, a guarantee, a count, a version, an example that is supposed to run. The unit of this discipline is the claim, not the document — a doc is never "mostly accurate", it is a list of claims each of which holds or does not, and the finding names the one that does not.

There are no claim markers, no annotation DSL, no structured comments to key on: the thing being checked is the thing the human reads, and any scheme that checks a parallel annotation instead checks the wrong artifact.

This is the bare judgment. Orchestrators layer on top and choose which documents to check: `/verify-docs` ranks the verdicts that come back and offers the fixes, and where a repo keeps its own scheduled sweep — this one's `sweep-corpus`, over the four documents that claim what the suite is — that sweep is another. Both are user-invoked, so suggest them when the ask is a sweep over many documents rather than a judgment of one.

## Extract the claims

Go through the prose and write down every assertion that could be false. Include the ones carried by example code, by a table, and by a heading. Exclude what makes no factual claim about anything outside the document — intent, rationale, and register have nothing to check, and a document made only of those is reported as having no claims rather than passed.

## Judge each claim against what it answers to

**Authority differs by kind.** A document is authoritative for **decisions** — what was chosen, what was rejected, and why — because nothing else records them; the code cannot contradict a rationale. A document is *never* authoritative for **counts, versions, paths, names, and sizes**: measure those live, every time, and a doc that says "eleven rules" is evidence of nothing but what was true when someone last counted. Churn is not a claim either: a commit count, a file's age, or commits-since-last-edit contradicts nothing — staleness is asserted only from a claim that fails, and churn is at most the reason a document was read.

- **Judge against the code and the tests, not the code alone.** A claim the code satisfies but nothing tests is not the same as one a test protects, and the verdicts below keep them apart. Where the document describes what a product does for the person using it, the **running product** is a third thing it answers to — a behavior claim is settled by performing the interaction and watching, and one the code appears to support but the product contradicts is a **FAIL** against the product; what to do about the product is never a verdict this discipline softens.
- **A contradiction can mean the code regressed.** The document may be the only place the intended behavior is written down. Check which side is wrong before "fixing" the prose — a doc that caught a regression is the doc doing its job.
- **Ground against the artifact reopened now, never from memory of it.** Memory of a codebase or a corpus is where drift hides, and a claim judged from recall is a guess with a verdict attached. An evaluation ledger (`docs/evaluation/<slug>/ledger.md`) is a document already in claim form: a `verified` row is judged against the evidence its own row cites, and a row past its Expires date is **STALE** whatever its source still says.

## Verdicts

| Verdict | Meaning |
| --- | --- |
| **PASS** | Matches what it answers to, and is protected — exercised by a test; or, for a behavior claim, confirmed by performing the interaction against the running product; or, for a derived document, traced to a source passage or to a recorded decision |
| **FAIL** | The code, the running product, or the source contradicts the claim |
| **UNSUPPORTED** | Matches what it answers to, but nothing protects it — no test, no observed run, or no source passage behind it |
| **STALE** | Refers to something removed or renamed — or rests on a source whose currency has lapsed: an evaluation-ledger row past its Expires date, where the source is still there and no longer stands for what it did when it was read |

Every claim gets exactly one. **STALE** carries the whole "was true, is not now" class, expiry included; the fix for an expired row is a `check` that re-reads its source, not a rewrite of the prose. An **UNSUPPORTED** verdict is a missing protection — a missing test, or a behavior claim nobody has watched hold — reported as a candidate task rather than filed as a doc bug: the prose is fine, the protection is absent.

## Derived documents answer to their sources

Where a document was derived from something other than code, [references/derived-documents.md](references/derived-documents.md) owns the pass: which documents it covers, the source map, the three failure classes, drift in both directions, and the verdict for a source passage that has since vanished.

## Honest limits

This discipline does not verify the tests themselves — bad tests produce a confident, wrong **PASS**, and the upstream `tdd` discipline still matters. Where it reaches the running product, it inherits that run's limits: one build, one environment, one configuration, and a build that may not be the commit the document cites — so a product verdict names the build it was taken against, and a claim settled on a build that cannot be matched to the document's commit is **UNSUPPORTED**, never PASS. It reads prose, so it inherits prose's ambiguity: where a claim can be read two ways, report the ambiguity as the finding instead of picking a reading and grading it. And the judgment is fallible in both directions, which is why it runs as a triggered review and never as a merge gate.

## Boundary

This discipline judges what a document claims; it never rewrites the document. Updating docs the change in hand just made stale is `feedback-loops`' close, and drafting the prose is `writing-for-humans`'. Flipping a product description from `drafted` to `verified` stays `product-description`'s verification pass, which owns the footer this skill's verdicts inform.
