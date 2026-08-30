---
name: clean-skill
# ok: uni-confusable
description: Security-scan fixture that must PASS (Ångström, café, Москва-based, 東京 are ordinary names). Nothing here runs.
---

# Clean skill (fixture)

Every annotated line is the benign neighbour of a rule; `<!-- ok: -->` names the rule the next line must not draw.

<!-- ok: md-remote-instructions -->
Read the reference at https://example.com/docs when the API changes, and fetch the latest release notes from the vendor page before a major upgrade: https://example.com/releases.

<!-- ok: inj-ignore -->
Ignore the noise in the build log; only the last line matters.

<!-- ok: md-htmlcomment -->
<!-- a rendering note that gives no instruction to anyone -->
<!-- ok: md-htmlcomment -->
<!-- upload it now -->

<!-- ok: uni-confusable -->
Names in a body — Ångström, café, Москва, 東京 — and Greek notation such as α_level or τ_max are ordinary text.

<!-- ok: md-b64 -->
Checksum: 14697440701c3885f7c8d5faa59f336b471ca86332034eff0d3fddc02dc93d7a14697440701c3885f7c8d5faa59f336b471ca86332034eff0d3fddc02dc93d7a
