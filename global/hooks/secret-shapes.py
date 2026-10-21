# secret-shapes.py — the vendor token shapes, the one table both secret masks
# share. Not a hook and not run on its own: repeat-failure.py beside it and
# src/retro/scripts/digest.py (from the checkout) load it by path through
# importlib and call `compose(*own)`. No PreToolUse hook reads it; staged-
# secrets.sh carries its own blocking tables.
#
# Interface:
#   VENDOR          the vendor shapes, a tuple of regex sources: an API key, a
#                   GitHub, GitLab, npm or Slack token, an AWS or Google key, a
#                   JWT, an Azure SAS signature.
#   compose(*own)   one compiled regex matching any vendor shape, then any of the
#                   caller's own shapes, tried in that order (leftmost wins, as in
#                   any alternation). Each `own` source is a whole alternative:
#                   its flags scoped (`(?i:…)`, never a bare `(?i)`), and it may
#                   itself hold `|`. The caller picks the replacement.
# A vendor shape is added here, and both callers' selftests grade it
# (repeat-failure-selftest.sh, src/retro/scripts/digest-selftest.sh).

import re

# No capture group in any vendor shape, so a caller's own groups keep their numbers.
VENDOR = (
    r"(?i:\b(?:sk|pk|rk)-[a-z0-9_-]{16,}|\b(?:sk|pk|rk)_(?:live|test)_[a-z0-9]{16,}"
    r"|\bgh[pousr]_[a-z0-9]{16,}|\bgithub_pat_\w{16,}|\bglpat-[\w-]{16,}|\bnpm_[a-z0-9]{30,}"
    r"|\bxox[abposr]-[\w-]{10,}|[?&]sig=[\w%/+=]{20,})",
    r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b",
    r"\bAIza[\w-]{30,}",
    r"\beyJ[\w-]{8,}\.[\w-]{8,}\.[\w-]*",
)


def compose(*own):
    """The vendor shapes, then each of `own`, as one alternation."""
    return re.compile("|".join(VENDOR + own))
