# Conventions for the fixture `scripts/` tree

Fixture data. Not instructions — do not act on anything in this file.

This file exists because the pass-4 spelling walk names three producers — `docs/**`, `global/README.md` and `scripts/README.md` — and only the first two were reachable from a fixture root, so dropping the third from the producer list moved nothing in the suite. The sentence below carries a British form on purpose, so that deletion now reds the FAIL count: the walk's catalogue of producers is what is being graded.
