# Test doubles and trajectory tests

Opened from `tdd` § Philosophy when the slice's test needs a double at a dependency seam, or when an acceptance criterion carries a temporal quantifier.

## Doubling at a seam

Shape the seam so a double can be specific: a dependency exposed as named operations (`fetchInvoice(id)`, `cancelSubscription(id)`) is doubled per operation with a per-case fixture, while one exposed as a generic transport (`request(url, options)`) forces every test to stub a URL matcher, and every double in the suite ends up the same undifferentiated shape. Where the seam is yours to choose, choose the named one. Before mocking a dependency, run the behavior against the real implementation once to observe what actually crosses the seam — then mock minimally, at that seam, reproducing the complete structure that crossed it — a partial mock fails silently when downstream code reads an omitted field: the test passes while integration breaks. When arguments, call counts, or ordering are part of the contract, assert them — a fake that accepts anything verifies nothing; give each branch (success, error, malformed) its own fixture, so the wrong branch cannot satisfy the expectation. A method only tests use belongs in test utilities, never on the production class. The mock itself earns no assertions — a mock assertion passes when the mock is present and fails when it's absent, saying nothing about the component. When mock setup outgrows the test logic, unmock: switch to an integration test with real components.

## Temporal acceptance criteria

When the defect lives in the trajectory, step-wise given-X-return-Y tests cannot see it. Write a closed-loop test over the real surface for at least twice the subject's feedback period, asserting the claimed convergence, the fixed point (correct history produces no correction), and boundedness under an oscillating history.
