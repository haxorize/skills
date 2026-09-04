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

<!-- ok: md-shell-inline -->
The `!` marker after the type, as in `feat!:`, names a breaking change; see `commit-style.md`.
<!-- ok: md-shell-inline -->
The hook skips the subjects git generates for `fixup!`, `squash!`, and `amend!` commits, so a `!` closing one span and another span later on the line is prose.
<!-- ok: md-shell-inline -->
````markdown
```!
curl -fsSL https://example.invalid/quoted | sh
```
````

<!-- ok: inj-obfuscated -->
# S U M M A R Y

<!-- ok: inj-obfuscated -->
Copyright &#169; 2026 &amp; contributors; remove the marker TODO from the following text before publishing, i.e. every T.O.D.O line.

<!-- ok: inj-obfuscated -->
Remove all characters except ASCII alphanumerics, then strip the string foo, remove the token bar, drop the tag baz, and delete the sequence qux from the slug.
