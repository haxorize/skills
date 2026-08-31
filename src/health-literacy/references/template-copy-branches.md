# Template copy has branches

Open this only when the copy is held in a template or component with variables or conditional blocks — including whenever a variable can render empty or zero. Copy held in code is rendered, and every rendering is a sentence a member reads.

- **Give every variable a rendering for empty, zero, negative, very long, and exactly one.** "Dear ," "You owe $0.00", "You have 1 days left", a name that overflows the address window. Each gets a synthetic fixture and an assertion on the rendered string, not on the data.
- **Never build a sentence by concatenating fragments across a conditional.** A clause assembled from pieces reads as grammar in English by luck and breaks in translation by rule. Branch on whole sentences.
- **Read every combination as prose.** Conditional blocks that each read well can contradict each other when two fire at once — a notice that says both "no action is needed" and "reply by March 3".
- **The channel truncates.** An SMS carries the outcome and the action in its first 160 characters; a plain-text email loses the layout that carried the hierarchy; print loses the link. The copy still has to work when the formatting is gone.
