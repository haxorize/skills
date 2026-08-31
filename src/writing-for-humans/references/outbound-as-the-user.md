# Outbound as the user

Read this only when the artifact is a message drafted as the user — an email, Teams post, memo, proposal, or questionnaire.

The user's own voice and register: a writing sample the user supplies (a prior email, a Teams thread) sets the voice — read it first and match its sentence length, openers, punctuation, and recurring phrases. What the sample never does binds too: a greeting, a sign-off, a contraction, or a glyph absent from every sample is off-limits in the draft, and a pattern present in one sample and absent in another is named, never averaged. Where the user has already written or said the thing, keep their sentence and cut, rather than composing a better one — composing in their voice is imitation, and imitation is what reads as not theirs. The dash sweep still runs last and wins over anything a sample or a sentence of theirs contains: a dash inside a kept sentence is replaced with the user's own wording from elsewhere in the sample, or the sentence goes back to them, never composed over. No Markdown syntax in an email or Teams body (asterisks and pound signs render as symbols, and read as pasted). **No em dashes, none.** Sweep the full tell catalog at maximum strictness — the stake is authorship perception, not just clarity.

## The dash sweep

The mandatory last step on every outbound draft — the global rule `~/.claude/rules/outbound-dash-sweep.md` owns the gate; this section owns the pipeline it points here for. Search, never reread: write the draft to a file and run this pipeline, verbatim — the `sed` masks code spans and URLs (keeping the query string, where tracking residue lives), the `grep` finds em dashes, ` -- ` with a space or a no-break space on each side (a typography rule that shaped the text may have put U+00A0 there), an en dash not between digits (`pp. 3–4` is the one survivor), and tool residue (`utm_source=`, `oaicite`, `turn0search`, a bracketed placeholder like `[Your Name]`, a zero-width space); the no-break and zero-width spaces are written as bytes so BSD grep matches them too, and the `$'…'` that carries them is bash or zsh quoting, so the pipeline runs there and not under POSIX `sh`:

```
sed -E -e 's/`[^`]*`//g' -e 's#https?://[^ )>?]*##g' draft.md | grep -nE '—|( |'$'\xc2\xa0'')--( |'$'\xc2\xa0'')|[^0-9]–|–[^0-9]|–$|utm_source=|oaicite|turn0search|\[[A-Z][A-Za-z ]*\]|'$'\xe2\x80\x8b'
```

Quote every hit with its line number; an empty result is the only pass. Never reconstruct the pipeline from memory — the byte escapes are the part a session cannot re-derive, and a paraphrased regex is a silent pass.
