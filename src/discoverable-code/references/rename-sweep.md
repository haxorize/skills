# The rename sweep

Run this mid-rename, after the new name is in place. A rename ends when every remaining hit of the old name is one you named as deliberate.

Search the whole repo for the old spelling — code, tests, docs, config, string literals — and stop only when the hit list is empty or each hit is named (a changelog entry, a `@deprecated` alias).

Where the rename inverts a sense — `bypass` → `verify`, `disable` → `enable`, `skip` → `run` — an empty hit list is not the end: every sentence that states the default ("off by default", "verification is skipped") was true under the old name and can now be false with no old spelling left to find. So grep the default-stating vocabulary (`by default`, `defaults to`, `enabled`, `disabled`, `on`, `off`) in the files the rename touched and read each hit against the code's default, which is the arbiter — a README that says TLS verification is off while the flag now defaults it on is the failure the zero-hit search passes.

Rename from the match list with an edit tool, one site at a time; a mass substitution (`sed -i`, `xargs perl`) rewrites what it never listed, and the rename-safety hook blocks it where installed.
