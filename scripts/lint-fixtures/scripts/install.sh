#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Fixture installer: install.sh LEFT the exempt list on 2026-09-01, so this one
# owes a selftest and does not have one. The pair with setup-hooks.sh beside it
# is what discriminates a one-name exemption from a two-name one.
# The opt-in list lint reads: fixture-discipline is opt-in, and unused-dep,
# which requires it, is global, so that edge FAILs.
opt_in_skills="fixture-discipline"
exit 0
