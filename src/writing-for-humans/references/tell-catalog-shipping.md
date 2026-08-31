# The tell catalog — commit and PR family

The shipping-prose members of the tell catalog. Open this only when the prose is a commit message, PR body, review reply, or closing comment; the catalog's always-on families live in [tell-catalog.md](tell-catalog.md), whose citation and displacement-partner rules govern here too.

These fire in shipping prose — commit messages, PR bodies, review replies, closing comments — where the diff and the log sit right next to the words and expose them.

- **Commit self-narration** — "This commit adds…", "This PR fixes…", "In this change…". The message *is* the commit's; drop the frame and state the change: "Move the check to `finalize()`". The frame paired with a vague verb is the tell twice over — "addresses the issue by implementing a solution that…".
- **Trailing justification** — "…ensuring consistency", "improving maintainability", "for better readability" tacked onto a change description. Cut it; if the reason matters, state the concrete why as its own sentence — what broke, what it cost.
- **Landed-change hedging** — "This should fix…", "This may help…" about a change already made. The change exists; say what was verified, or state the untested part as untested.
- **File-listing narration** — a body that is one bullet per changed file, or a walk through the diff hunk by hunk. The diff already shows *what*; the body's only job is the *why* the diff cannot show.
- **Test enumeration** — "all 47 tests pass", "coverage: 92%". A commit body names what coverage changed, if anything; counts and percentages belong where they can carry the command and its verbatim output.
- **Verification-provenance compound** — "byte-identical", "re-derived", "re-measured", "re-verified", "cross-checked", "root-caused": a claim about method compressed into an adjective. Earned where the command and its output sit in the same paragraph (the global evidence rule's form, `~/.claude/rules/evidence.md`), or where the word names a mechanism the project runs (`byte-identical` is `scripts/lint-skills.sh`'s sibling check); an adjective standing with neither goes, and the method takes its place.
- **Changelog headings** — "### Added" / "### Fixed" sections inside a commit or PR body. That is a changelog's format; a commit explains one change in prose.
- **Shipping marketing** — "production-ready", "battle-tested", "enterprise-grade", "rock-solid", "carefully crafted". The slop-vocabulary list's shipping-flavored cousins; state what changed and what it now does.
- **Bumped dependencies** — the body as the bump list: "Bumped fastjson to 3.2.1, httpkit to 2.0.0, and updated the lockfile." The diff shows every version; the body says what changes for a caller and what was verified: "fastjson 3.2.1 closes the advisory on nested-array parsing; httpkit 2.0 drops the implicit retry, which `ApiClient` now sets explicitly; suite green after each step." (Fictional packages on purpose — the catalog never states facts about real ones it has not checked.)
- **Copy-pasted issue text** — the body is the ticket's text verbatim instead of the author's own account of the problem. Restate the cause and the fix in your words; link the ticket for the rest.
