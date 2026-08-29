# The same words, with nothing anchoring them (fixture)

Nothing here names the artifact whose vocabulary this root's legend defines — no slug,
no path, no file name, not even the phrase in prose — and that is the point: two of its
three status words appear as `marketed` and `verified` in a sense this check must not
answer for. Drop the requirement that a file name the artifact before its statuses are
read, and this file starts failing, which is how a check that fires on every document
that says "verified" would look from the inside.

The collision is real rather than invented. `product-description` registers its own
`drafted`/`verified` pair, and `accessible-ui` records a criterion as verified; the
words are shared and the contracts are not.
