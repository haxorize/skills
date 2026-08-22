# Outbound drafts end on a dash sweep

Depends: `writing-for-humans`, `ask-for-me`
Why not a hook or lint: the draft is chat output, or a file with no distinguishing name — a Write hook would have to fire on every file, code included, to catch it — and a Teams paste never passes through a tool.

A message drafted as the user — an email, a Teams post, a memo, a proposal, a questionnaire — is not done until one search over the draft comes back empty, whether or not any skill is loaded.

- **Search, never reread.** Write the draft to a file and run this pipeline, verbatim — the `sed` masks code spans and URLs (keeping the query string, where tracking residue lives), the `grep` finds em dashes, ` -- `, an en dash not between digits (`pp. 3–4` is the one survivor), and tool residue (`utm_source=`, `oaicite`, `turn0search`, a bracketed placeholder like `[Your Name]`, a zero-width space, written as bytes so BSD grep matches it too):

  ```
  sed -E -e 's/`[^`]*`//g' -e 's#https?://[^ )>?]*##g' draft.md | grep -nE '—| -- |[^0-9]–|–[^0-9]|–$|utm_source=|oaicite|turn0search|\[[A-Z][A-Za-z ]*\]|'$'\xe2\x80\x8b'
  ```

  Quote every hit with its line number; an empty result is the only pass.
- **A hit means the draft is not done.** Rewrite the sentence — the appended clause, not the glyph — and search again. Never present a draft with a hit; never a score or a whole-draft rewrite.
- **A writing sample does not reopen this.** A sample the user supplies overrides register defaults; it never licenses a dash.
