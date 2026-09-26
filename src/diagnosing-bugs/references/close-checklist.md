# Close checklist

The items `diagnosing-bugs` Phase 6 requires before a fix is declared done — opened once the fix is accepted, after [fix-acceptance.md](fix-acceptance.md), and before the why-chain in the body.

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or absence of seam is documented)
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix)
- [ ] Throwaway prototypes deleted (or moved to a clearly-marked debug location)
- [ ] The Phase 3 edit boundary held — or every widening is named with the reason it was asked for
- [ ] Sibling instances of the fixed bug's **class** swept within the change's scope — grep the pattern, check the other call sites; the second occurrence ships otherwise
- [ ] The bug's extent counted — how many records, callers, or environments it reached — since the reported case is a sample, not the boundary (one record or 19,000 changes the severity and often the fix)
- [ ] The hypothesis that turned out correct is stated in the commit / PR message — so the next debugger learns
- [ ] The fix is described by **behavior and contract**, not file paths and line numbers, so it stays valid through refactors
