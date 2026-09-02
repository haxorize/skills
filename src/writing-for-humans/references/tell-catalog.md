# The tell catalog

Named patterns that read as AI-generated: almost all because they are clarity failures — each performs insight, emphasis, or structure instead of delivering a fact — and a few (the Formatting glyph entries) because nobody typing by hand produces them. Cite by **name**, never by number or position. A fix is an instruction to recover the deleted information, never a synonym swap.

**Displacement partners.** Suppressing a tell relocates it: a model told not to write em dashes writes semicolons; told not to write "not X, it's Y" writes "no setup, no config". Where a partner is named, check for it in the same pass — a clean run on the tell with a dirty run on its partner is the same defect, evaded.

## Filler and puffery

- **Portability filler** — a sentence that fails the press-release test ("committed to excellence", "robust and scalable"). Cut, or replace with the specific fact.
- **Empty emphasis** — "really", "truly", "crucially", "importantly", "it's worth noting that". Delete; if the point matters, the surrounding facts must show it.
- **Importance puffery** — "stands as a testament", "plays a vital role", "pivotal", "underscores its significance". State the fact and let the reader judge the weight.
- **Capability filler** — "is designed to", "aims to", "has the ability to", "enables you to". Say what it does: "retries three times, then stops"; "you can".
- **Trailing participle analysis** — a comma plus "-ing" clause pretending to explain: "highlighting", "underscoring", "showcasing", "reflecting". Cut it, or state the plain reason with "so" or "because".
- **Slop vocabulary** — delve, tapestry, leverage, utilize, foster, empower, streamline, seamless, robust, comprehensive, cutting-edge, landscape, realm, journey, elevate, harness, deliver (for anything but goods), facilitate, key (as adjective), transform, game-changer. Use the ordinary verb, or delete and state the measurable property.
- **Audit-slop register** — the vocabulary of rigor standing in for the thing itself: evidence, receipt, authority, boundary, contract, durable, surface (as a verb), exact, signal; the structural metaphors load-bearing, spine, gate and gated, canonical, landed, cleanly, hard (stop, gate, boundary), provenance, drift; and the research register — floor, headline, regime, lower bound, clears, survives. Each of these names a real mechanism inside an agent-facing rule file, which is where they belong; in prose written for a person each stands in for the ordinary word or the concrete noun the reader would have understood — "the evidence" for *the failing log line*, "surfaced" for *showed*, "load-bearing" for *the rule the others depend on*, "landed" for *merged*, "clears" for *passes*, "cleanly" for *without an error*. Name the component and use the ordinary word.

## Fake structure

- **Contrastive formula** — "It's not just X; it's Y", "The question isn't X, it's Y", "Not a X. Not a Y. A Z." State Y directly. The negated half is a claim of its own, and one the source usually never made — "this isn't a bug fix, it's a rewrite" asserts that it is not a bug fix — so the formula fabricates as well as pads, and the negated half is cut as a fabrication, which the preservation contract permits. *Displacement partner:* **contrastive negation** — the telegraphic "no setup, no config, no hassle" cadence that appears once the formula is banned.
- **Dramatic label reveal** — a noun-phrase label, a colon, a punchy clause: "The catch: nothing persists." Fold the label into the sentence. *Displacement partner:* the **copula dodge** — a colon replacing "is" to evade weak-verb rules ("The candidate mechanism: a hook on Bash"); its verb form is the same dodge one rung up — "serves as", "stands as", "marks", "represents", "boasts" where "is" or "has" is meant ("the hook serves as the gate" → "the hook is the gate").
- **Mic-drop fragment** — "That's it. That's the whole thing.", "Simple, predictable, testable.", "Tools change. Principles don't." — and its in-line cousin, the demonstrative kicker: a mid-paragraph "This" or "That" plus a verdict fragment ("This is the whole problem."). Complete sentences; name what "this" is and state the consequence as a fact. *Displacement partner:* the verb-led contrastive sentence that appears once bare fragments are banned.
- **Fake-profound kicker** — the final "deep" line that turns the point into an aphorism or metaphor. Delete it — **do not rewrite it into a better metaphor, do not preserve the rhythm** — and end on the clearest concrete sentence already in the draft.
- **Rhetorical self-answer** — "The result? Faster builds.", stacked rhetorical questions, "What if I told you…". State the point as a sentence.
- **Count announcement** — "Three things to keep in mind:", "Two cautions." State the first point directly; if the count genuinely helps, use a bullet list instead of announcing the number in prose.
- **Summary-recap ending** — "In conclusion", "Ultimately", "Overall", or a closing paragraph restating the piece. The reader was just there; end when the content ends.
- **Tricolon habit** — nearly every enumeration having exactly three items, "X, Y, and Z" as a drumbeat. Rewrite some with two or four; an occasional triple is ordinary English, the uniform pattern is the tell.

## Metadiscourse

- **Interpretive metadiscourse** — prose stepping outside the subject to direct the reader: "The key point is", "As you can see", "This distinction matters", redundant "In other words". Cut; the emphasis must live in the facts.
- **Throat-clearing opener** — "Here's the thing,", "Let me be clear,", "To be clear,", "To be honest,". Cut and state the point.
- **Candor marker** — "honestly", "the honest answer is", "one honest caveat", "worth stating plainly", mid-sentence: labels one claim honest and, by implication, the rest not. Cut it — the label adds nothing the claim's evidence does not.
- **Faux-insight setup** — "What most people miss", "Here's what nobody tells you", "The uncomfortable truth is". Cut the setup; the claim stands on its own or it doesn't.
- **Structure announcement** — "Below you'll find", "This section covers", "Let's dive in", "Key takeaway:" bolded callouts, and the heading restated as the section's first sentence ("## Install" / "This section explains how to install"). Delete; headings and front-loading already do this job — start on the first fact.
- **Sycophantic frame** — "Great question!", "I hope this helps", "Feel free to reach out", "Happy coding". Cut entirely; warmth lives in usefulness, not pleasantries.

## Dodged agency and sourcing

- **Weasel attribution** — "experts agree", "studies show", "widely regarded as", "best practice suggests". Name the source or cut the claim; if there is no source, ask — never invent one.
- **Anthropomorphic justification** — "earns its place", "does the heavy lifting", "the data wants", "the benchmark settles the question", "emerged naturally". Say who did what, or state the property directly; a decision that "emerged" is a decision being dodged — name the decider and the reason.
- **Juridical register** — "refuses", "ruling", "carve-out", "obligation", "owed", "remedy", "ratified", "honors", said of a tool, a rule, or a document: the register borrows finality from a domain that has procedures for producing it — a linter does not *rule*, it exits non-zero. Use the ordinary verb for what happened ("the check fails", "the rule applies", "the record says"). Earned on *Invented compound jargon*'s test below — a dictionary sense, a `DOMAIN.md` row (**Scan verdict**), a bolded term in a skill body, or the project's code — and borrowed otherwise. A sentence that hands a non-agent an act is *Anthropomorphic justification* above, not this; a person's speech is *Attribution-verb spin* below.
- **Retrospective neatness** — a causal history tidier than the work was: each step following from the last, no dead ends, no backtracking, the conclusion arriving on schedule. Its twin is the plan narrated as an accomplished result ("we then migrated the remaining callers", written before anyone did). Say what was tried and abandoned, and keep a plan in the tense of a plan.
- **False balance** — "strike a balance", "both approaches have merit", "depends on various factors" in prose whose job is a verdict. Take the position or name the unresolved question explicitly.
- **Absolute inflation** — "cannot be overstated", "the single most important", "make no mistake", "has never been more critical". Verify the superlative or delete the intensity.
- **Hedge stack** — "may potentially", "it's possible that … might", "should generally". One qualifier maximum, chosen deliberately; state the unknown as "unknown" instead of fogging every clause.
- **Editorial scar tissue** — "A tempting approach would be X, but…" introducing an option no reader would have considered, rejecting it, and never mentioning it again: an old drafting idea left in the final text. Cut the rejected option unless a reader would actually reach for it.
- **Shadowboxing** — answering an objection nobody raised: "This isn't mainly about X", "I'm not saying", "Don't get me wrong" with no source for the objection. Cut; keep an objection only where the text names who raised it or answers it in full.
- **Cleft explainer lead** — "What this means is", "The reason this works is that", "What happened was": a clause that points at the explanation instead of being it. Start on the explanation.
- **Knowledge-cutoff residue** — "as of my last update", "while specific details are limited", "based on available information". Delete; state what is known and what was not checked.

## Cliché

- **Stale metaphor** — "perfect storm", "tip of the iceberg", "double-edged sword", "low-hanging fruit". Recover the deleted fact: say *which factors coincided*, *what remains hidden and how much*, *both effects*, *why this item is cheap*. Its cousin, the **corporate idiom**, names an action vaguely through a dead image — "circle back", "get the ball rolling", "on the same page" — so the deleted fact is the action itself: name what will actually happen, and when.
- **Evaluative adjective** — "an impressive 10% growth", "a disappointing result". Drop the verdict word and give the fact: "growth of 10%"; the reader judges.
- **Attribution-verb spin** — "admitted", "claimed", "revealed", "insisted" where "said" is meant; each smuggles a verdict. Use the ordinary verb unless the connotation is the point and is earned.
- **Double negative** — "not uncommon", "not dissimilar". Write "common", "similar".
- **Invented compound jargon** — hyphenated or fused terms coined mid-document and treated as established ("insight-driven remediation loop"). The test: is it in a dictionary, in `DOMAIN.md`, or in the project's code? If none, unpack it into plain words — or define it once and add it to `DOMAIN.md` if the concept genuinely recurs.

## Formatting

- **Em-dash habit** — budgeted, not banned: none in short copy, one or two in a long draft where they clearly beat commas or parentheses; delete clusters; the outbound row bans them outright, and the global dash-sweep rule enforces it. *Displacement partner chain:* em dash → semicolon → colon — the punchy appended clause survives the ban by swapping its glyph; fix the clause, not the mark.
- **Bold decoration** — bold sprinkled mid-sentence for emphasis, emoji in headings, "**Note:**" callouts. Bold names the subject a list item explains, nothing else; emphasis lives in word choice.
- **Bullet overuse** — prose chopped into bullets where two sentences read better. Keep a list when items are genuinely parallel, short, or sequential steps; convert to prose when the bullets are full sentences in costume, carry inline bold headers, or exist to look organized.
- **Heading title case** — "Everything You Need To Know". Sentence case, everywhere in human-facing prose, including titles. A `SKILL.md` H1 is the exception and not a counter-example: it is the skill's display name, takes title case, and `check_heading_case` enforces it.
- **Keyboard-unreachable glyphs** — `→`, `⇒`, `≠`, non-ASCII bullets in prose a person types into a plain-text surface (a commit body, a chat message, a terminal). Nobody reaches for them on a keyboard, so they read as generated (the em dash has its own entry under Em-dash habit). Plain ASCII: `->`, `!=`, `-` bullets. Curly quotes are not a tell: Outlook, Word, and Teams convert them automatically, so human mail is full of them.
- **Inline-header list** — "- **User experience:** significantly improved." — a bullet whose bold label repeats the pattern of its siblings. Either a real table or real prose.

## Commit and PR family

Ten tells that fire only in shipping prose — commit messages, PR bodies, review replies, closing comments — live in [tell-catalog-shipping.md](tell-catalog-shipping.md); open it only for that artifact family.

## Rate tells

Nine tells that fire on the run of the text, not on any one phrase — monotone openers, sustained passive, one-point dilution, and the rest — live in [tell-catalog-rate.md](tell-catalog-rate.md); open it only for a draft of a section or more.
