# Outbound drafts end on a dash sweep

Depends: `writing-for-humans`, `ask-for-me`

A message drafted as the user — an email, a Teams post, a memo, a proposal, a questionnaire — is not done until one search over the draft comes back empty, whether or not any skill is loaded. The check is a grep, never a reread: write the draft to a file and run, verbatim, the pipeline in `writing-for-humans`' outbound reference (`~/.claude/skills/writing-for-humans/references/outbound-as-the-user.md` § The dash sweep) — it carries no-break and zero-width bytes you cannot re-derive, so never reconstruct it from memory. Quote every hit with its line number; an empty result is the only pass.

- **A hit means the draft is not done.** Rewrite the sentence — the appended clause, not the glyph — and search again. Never present a draft with a hit; never a score or a whole-draft rewrite.
- **A writing sample does not reopen this.** A sample the user supplies overrides register defaults; it never licenses a dash.
