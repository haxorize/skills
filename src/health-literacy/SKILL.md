---
name: health-literacy
description: Writing member-facing copy a person can act on — the term defined where it appears, the amount as the figure billed, not a formula, the next step with a date, and a way to get help. Use when writing or reviewing text a member, patient, or subscriber will read — an error or validation message, an in-app notice, banner, or form label, an email, letter, SMS, or EOB template, a denial, appeal, prior-authorization, or coverage-termination notice, a benefits, eligibility, or claim-status explanation, a cost-share breakdown. Also use when copy quotes plan documents or regulation, when a template variable can render empty or zero, when the copy will be translated or a reading-level score is run on a translation, or when a draft reads above the project's target. Also use when a bug report or finding is about a message a member sees. Not for internal-facing text (logs, developer errors, admin tooling) — writing-for-humans'. Not the approved-language list or reading-level policy — the convention skill's.
requires: writing-for-humans
---

# Health-literacy copy

**Member-facing copy** is any text a person reads about their own coverage, care, or money: an error on a form, a notice, banner, or form label in a portal, an SMS, a letter, a coverage-termination notice, a claim-status explanation, the rendered EOB. Its reader is reading at the moment something went wrong — a denial, a bill larger than expected, a login that failed before an appointment — often on a phone, often in a second language, sometimes about the condition the copy concerns. Its reading level decides whether the person gets the care they are owed.

The test every rule below serves is **the next move**: after one read, can this person say what happened, what it costs them, and what they do now? Copy that fails that test has failed even when every sentence in it is true.

The default draft fails it in four ways, and they are the domain's own rather than general bad writing: insurer terms left undefined, the action line passive, what to do next buried or absent, and money shown as a prose formula rather than a figure. Most of the rules below are one of those failures, stated as the move that prevents it; the rest — the translation rules, and the one term per concept across artifacts — are the ways the same copy fails once it leaves the one screen it was drafted on.

Three layers sit deliberately outside this skill. **What the copy must say** — the approved-language list, the reading-level target and how the project measures it, the sentences that are legally required verbatim (appeal rights, nondiscrimination and language-assistance notices, model language a regulator publishes), which of them apply to this piece, and where their published translations live — belongs to the project's convention skill for the `health-literacy` role, named in `CLAUDE.md`'s `## Convention skills` block, or to `CLAUDE.md` itself. Where no such skill exists, apply every rule below to what this change needs and raise the missing project answer as a finding; never invent a required sentence, and never reword a block that looks like one. **How the prose reads** — register, the five-question error-message shape, the AI tells — is `writing-for-humans`'s, which this skill sits on top of rather than restates: call the Skill tool with `writing-for-humans` at the first draft or review if it isn't already live. And **what data reaches the copy** is `phi-safe-code`'s: an error that names the member or echoes a subscriber ID is that skill's finding first, and this skill's second.

## Define the term in the sentence that needs it

- **A term the member did not choose is defined where it appears, or deleted.** Deductible, coinsurance, copay, out-of-pocket maximum, prior authorization, formulary, in-network, allowed amount, adjudicated, EOB, coordination of benefits: each is a word the industry chose. A glossary link, a tooltip, and an appendix are all the same failure — the person reading a denial does not click. The definition is one clause in the sentence that uses the term, and it says what the thing *does to this reader*, not what it is in general. A term the next move does not need is cut — copy earns nothing by teaching *adjudicated* to someone who only needs to know their claim was paid; the term stays only where the member will meet it again (the card, the portal, the phone), and then it is defined once and used consistently, never traded for a synonym. Two near neighbours are not this rule and are handled the other way round. A plan word that is also an ordinary English word — *cover*, *allowed*, *plan*, *claim*, *responsible*, *network*, *authorized* — is a term to define wherever the ordinary reading and the plan reading leave the member with different answers about what they owe or what they do next: "your plan covers this" lands as "you owe nothing", when what it means is that the treatment is a benefit and a share of it is still billed. The sentence that spells the consequence out has already discharged the rule — "your plan does not cover this treatment" needs nothing added, because both readings end in the same place. A word that is merely formal — *submit*, *obtain*, *determine*, *subsequent*, *incurred* — is not a term at all, and it is replaced with the everyday word rather than defined.
- **Plain sentence first, term second.** "Your plan has to approve this medicine before it will pay for it. That approval is called prior authorization." The term arrives as a label for something already understood, so a reader who skips it still has the meaning; the reverse order makes the term a gate in front of it.
- **A definition that reuses the word is not a definition.** "Your coinsurance is the coinsurance percentage you are responsible for" is the shape to catch. Say the thing itself: "You pay 20 percent of the cost of each visit."

## Show the money as a figure, never as a formula

Never leave the arithmetic for the member to do, in prose, about their own money.

> **Before:** You are responsible for coinsurance of 20% of the allowed amount after your annual deductible has been satisfied, subject to your out-of-pocket maximum.
>
> **After:** You owe $43.20 for this visit. That is 20 percent of the $216 your plan allows for it — the most it will pay a doctor for this kind of visit. You have already met your $2,000 deductible this year, so 20 percent is all you pay.

- **Do the arithmetic and print the result.** The figure the member will actually be billed comes first, in dollars and cents. A percentage, a rate, or a formula appears only after the figure, as the explanation of where it came from — never in place of it.
- **Show the running state.** "You have paid $1,240 of your $2,000 deductible" tells the reader where they stand; "after your deductible is met" does not, because they do not know whether it is met. The same holds for out-of-pocket maximums, visit limits, and remaining authorized units.
- **When the amount is not final, give the range and the reason.** "You may owe between $40 and $60, depending on what your doctor bills" is honest; a formula is not more honest for being unresolved. And when a document is not a bill, "This is not a bill" belongs beside the number, not in a footer under it.
- **A rate a reader cannot picture gets a comparison, not a decimal.** Where a rate is genuinely the point, "about 1 in 10 people" beats "approximately 9.7%".
- **Zero, negative, and missing amounts are copy, not arithmetic.** "You owe $0.00" is a bill for nothing; a credit is not a negative charge; an amount the system does not have yet is not $0. Each needs its own sentence.

## The action, the date, and the way out

- **The action is a sentence the member performs.** "Send us your doctor's notes by March 3." Not "Documentation must be received" — the passive hides who acts. Second person, one action per sentence, the verb early. It is the bare imperative: a required action carrying *should*, *may want to*, or a leading *please* reads as advice, and the member who takes it as advice loses the right the notice was sent to protect. Where the plan is the one acting, the subject is *we* — "we denied your claim", not "your claim has been denied", which hides the sender inside the sentence that carries the news.
- **A deadline is a date, computed.** "Within 60 days of the date of this notice" makes the reader do date arithmetic against a notice they may have opened late. Print the date. Where the deadline is set by the postmark or by receipt, say which. And say what happens if it passes — a right that expires silently is the one the notice exists to protect.
- **The next move goes where the eye lands, not at the end.** The order is `writing-for-humans`'s error-message shape — outcome first, then the action; in a notice the reasoning, the history, and the reference numbers come after both, because the reader scans and stops. The check is a deletion: strike every note, asterisk, footnote, and fine-print block, then read what is left. If the member can no longer take the action or learn a limit that binds them, what was struck was in the wrong place.
- **Every piece says how to get help, with a channel that works.** The number on the member's card, the hours it is answered, and at least one route that is not a phone call. "Contact us" is not a route.

## One term per concept, across every artifact

Two terms for one thing — doctor, physician, provider — is the failure a payer hits by default, and it hits worst across artifacts rather than within one: the portal says *member*, the letter says *subscriber*, the SMS says *enrollee*, and the person cannot tell whether all three mean them.

- **Pick the word the reader would use for themselves and keep it,** through the notice, the email that announces it, the portal screen it links to, and the letter that follows — and do not rename a concept the member already learned because a new template reads better with a different word. The one exception is a term policy constrains: where a regulator or the plan document fixes the word, it stays, defined where it appears.
- **Consistency across templates is a code fact, not an editorial one.** The same user-visible noun is one shared constant referenced by each template, not a word retyped in six files — that is the only form of the rule a review can check. `discoverable-code`'s one-definition-site rule covers symbols; this skill extends it to a member-facing noun.

## Do not quote the plan document or the regulation

Regulation is drafted to survive a challenge, not to be understood on a phone. Say what the rule means for this member, in this situation, and name where the full text lives for the reader who wants it.

- **Translate the rule into the member's situation.** Not "benefits are subject to the exclusions set forth in Section 7.3 of your Evidence of Coverage" but "Your plan does not cover this treatment. Your plan documents explain why, in the Exclusions section."
- **Required language is left exactly as written, and it is not the explanation.** Where a sentence must appear verbatim — appeal rights, nondiscrimination and language-assistance notices, a regulator's model paragraph — it is not paraphrased, softened, reordered, or summarised. Place the plain explanation first and the required block after it, so the reader meets the meaning before the mandated wording rather than instead of it. Which blocks are required, and where their published translations live, stays the convention skill's answer.
- **A reference number is not an explanation.** Claim numbers, denial codes, and policy sections belong in the copy, low on the page, for the phone call and the appeal — never carrying the burden of saying what happened.

## A template is a program, so its copy has branches

Copy held in code is rendered, and every rendering is a sentence a member reads.

- **Every variable has a rendering for empty, zero, negative, very long, and exactly one.** "Dear ," "You owe $0.00", "You have 1 days left", a name that overflows the address window. Each gets a synthetic fixture and an assertion on the rendered string, not on the data.
- **Never build a sentence by concatenating fragments across a conditional.** A clause assembled from pieces reads as grammar in English by luck and breaks in translation by rule. Branch on whole sentences.
- **Read every combination as prose.** Conditional blocks that each read well can contradict each other when two fire at once — a notice that says both "no action is needed" and "reply by March 3".
- **The channel truncates.** An SMS carries the outcome and the action in its first 160 characters; a plain-text email loses the layout that carried the hierarchy; print loses the link. The copy still has to work when the formatting is gone.

## Translation is part of the copy, not a step after it

The failures here are not bad translation. They are copy written as though the English rendering were the only one, in a repo where the Spanish notice is the one the member reads.

- **The copy will be translated, so idiom is a defect.** Idioms, colloquialisms, humour, unnecessary intensifiers, and the two-word verb — *fill out*, *turn in*, *sign up*, *pick up* — arrive wrong in translation, and the two-word verb is the one that survives an idiom sweep, because it reads as plain English. Write the literal sentence in an everyday verb rather than a formal one — "send us the form", "join the plan", "get your medicine at the pharmacy", "answer every question on the form" — because the formal words the define-or-delete rule bans (*submit*, *obtain*, *complete*) are the ones this rule reaches for first.
- **The language the member chose reaches every surface of the one interaction** — the notice, its form labels, its validation errors, and the email that follows — or the interaction is half-translated, and the member whose Spanish notice told them to appeal cannot finish the appeal.
- **A required block's translation is fetched, never generated.** It comes from the version its regulator published: a machine translation of a verbatim block is a paraphrase, and it is the form the required-language rule breaks in most often, because the translating happens in a different system from the one that rule was applied in.
- **A reading-level score on a translated rendering is not a signal.** A formula built on one language's syllables returns a number about the wrong language, and the failure is worse than no check, because a green figure lands on the copy read by the members with the least English. A translated notice is read by someone who reads that language, not scored by the pipeline.

## Reading level is a range, not a gate

- **The target is the project's; grade 6 to 8 is the fallback.** Which formula, which target, and what it is measured on are the convention skill's answers; where none is named, write against grade 6 to 8. The score is a signal read as a range, never the gate; the check below is.
- **The mechanical floor:** sentences of 20 words or fewer, one point per sentence, paragraphs of 2 or 3 sentences, most important information first, active voice, common everyday words, no undefined abbreviations, no noun stack longer than three words (*prior authorization request determination notice* is unwound into a sentence), and headings that make sense alone. For general word substitutions, the public-domain plainlanguage.gov list *Use simple words and phrases* is the lookup; the payer terms in this body are the ones that list does not carry.
- **The check that decides is the next move.** Read the draft aloud once as the member: what happened, what it costs, what I do now. Where the answer needs a second read, the copy is not finished, whatever it scores.

A rule above answered "no" for this change is a finding on it, the same as a failing check.

Sources: the cms.gov *Guidelines for effective writing* (sentence and paragraph length, active voice, scanning, one term per concept, the language to avoid — idiom, quoted regulation) and the CMS *Toolkit for Making Written Material Clear and Effective* (the comparison, the range, the running state, grade scores as ranges), both cited for their rules and never quoted.
