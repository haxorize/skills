# Outbound drafts end on a dash sweep

Depends: `writing-for-humans`, `ask-for-me`
Why not a hook or lint: the draft is chat output, or a file no hook can tell from any other; nothing mechanical sees a Teams message before it is pasted.

A message drafted as the user — an email, a Teams post, a memo, a proposal, a questionnaire — is not done until one search over the draft comes back empty, whether or not any skill is loaded.

- **Search, never reread.** Write the draft to a file and run one `grep -nE` for `—`, ` -- `, and an en dash not between digits (`[^0-9]–|–[^0-9]`; `pp. 3–4` is the one survivor), with code spans and URLs masked, plus one alternation for tool residue (`utm_source=`, `oaicite`, `turn0search`, a bracketed placeholder like `[Your Name]`, a zero-width character). Quote every hit with its line number.
- **A hit means the draft is not done.** Rewrite the sentence — the appended clause, not the glyph — and search again. Never present a draft with a hit; never a score or a whole-draft rewrite.
- **A writing sample does not reopen this.** A sample the user supplies overrides register defaults; it never licenses a dash.
