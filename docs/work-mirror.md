# Comparing the work mirror with home

The work machine reaches these skills through a mirror on the company's GitHub Enterprise. Files reach the mirror by a hand copy that replaces `src/`, `global/`, `scripts/` and `docs/`. The mirror has its own history, so the two repositories share no commit SHA.

Compare trees instead of commits:

1. On each machine, run `git rev-parse HEAD:src HEAD:global HEAD:scripts HEAD:docs`. Equal hashes mean equal bytes.
2. To find the home commit the mirror equals, walk `git log --format=%H` on home. For each commit, compare its four subtree hashes with the mirror's.
3. If no home commit matches, the mirror is ahead or has diverged. Carry its fix home before the next sync replaces it.
