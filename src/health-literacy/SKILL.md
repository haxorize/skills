---
name: health-literacy
description: Writing member-facing copy a person can act on — the insurance term defined in the sentence where it appears, the amount shown as the figure they will be billed, not a formula, the next step with a real date, and a way to get help that works. Use when writing or reviewing text a member, patient, or subscriber will read — an error or validation message, an in-app notice, banner, or form label, an email, letter, SMS, or EOB template held in code, a denial, appeal, prior-authorization, or coverage-termination notice, a benefits, eligibility, or claim-status explanation, a deductible, coinsurance, or cost-share breakdown. Also use when copy quotes plan documents or regulation at the reader, when a template variable can render empty or zero, or when a draft reads above the project's target (grade 8 by default). Not for internal-facing text (logs, developer errors, admin tooling), which is writing-for-humans alone. Not the approved-language list or reading-level policy, which are the project convention skill's.
requires: writing-for-humans
---

# Health-literacy copy

**Member-facing copy** is any text a person reads about their own coverage, care, or money: an error on a form, a notice, banner, or form label in a portal, an SMS, a letter, a coverage-termination notice, a claim-status explanation, the rendered EOB. Its reader is reading at the moment something went wrong — a denial, a bill larger than expected, a login that failed before an appointment — often on a phone, often in a second language, sometimes about the condition the copy concerns. Its reading level decides whether the person gets the care they are owed.

The test every rule below serves is **the next move**: after one read, can this person say what happened, what it costs them, and what they do now? Copy that fails that test has failed even when every sentence in it is true.

The default draft fails it in four ways, and they are the domain's own rather than general bad writing: insurer terms left undefined, the action line passive, what to do next buried or absent, and money shown as a prose formula rather than a figure. Each rule below is one of those failures, stated as the move that prevents it.

Three layers sit deliberately outside this skill. **What the copy must say** — the approved-language list, the reading-level target and how the project measures it, the sentences that are legally required verbatim (appeal rights, nondiscrimination and language-assistance notices, model language a regulator publishes), and which of them apply to this piece — belongs to the project's convention skill for the `health-literacy` role, named in `CLAUDE.md`'s `## Convention skills` block, or to `CLAUDE.md` itself. Where no such skill exists, apply every rule below to what this change needs and raise the missing project answer as a finding; never invent a required sentence, and never reword a block that looks like one. **How the prose reads** — register, the five-question error-message shape, the AI tells — is `writing-for-humans`'s, which this skill sits on top of rather than restates. And **what data reaches the copy** is `phi-safe-code`'s: an error that names the member or echoes a subscriber ID is that skill's finding first, and this skill's second.

## Define the term in the sentence that needs it

- **A term the member did not choose is defined where it appears, or deleted.** Deductible, coinsurance, copay, out-of-pocket maximum, prior authorization, formulary, in-network, allowed amount, adjudicated, EOB, coordination of benefits: each is a word the industry chose. A glossary link, a tooltip, and an appendix are all the same failure — the person reading a denial does not click. The definition is one clause in the sentence that uses the term, and it says what the thing *does to this reader*, not what it is in general. A term the next move does not need is cut — copy earns nothing by teaching *adjudicated* to someone who only needs to know their claim was paid; the term stays only where the member will meet it again (the card, the portal, the phone), and then it is defined once and used consistently, never traded for a synonym.
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

- **The action is a sentence the member performs.** "Send us your doctor's notes by March 3." Not "Documentation must be received" — the passive hides who acts. Second person, one action per sentence, the verb early.
- **A deadline is a date, computed.** "Within 60 days of the date of this notice" makes the reader do date arithmetic against a notice they may have opened late. Print the date. Where the deadline is set by the postmark or by receipt, say which. And say what happens if it passes — a right that expires silently is the one the notice exists to protect.
- **The next move goes where the eye lands, not at the end.** The order is `writing-for-humans`'s error-message shape — outcome first, then the action; in a notice the reasoning, the history, and the reference numbers come after both, because the reader scans and stops.
- **Every piece says how to get help, with a channel that works.** The number on the member's card, the hours it is answered, and at least one route that is not a phone call. "Contact us" is not a route.

## One term per concept, across every artifact

Two terms for one thing — doctor, physician, provider — is the failure a payer hits by default, and it hits worst across artifacts rather than within one: the portal says *member*, the letter says *subscriber*, the SMS says *enrollee*, and the person cannot tell whether all three mean them.

- **Pick the word the reader would use for themselves and keep it,** through the notice, the email that announces it, the portal screen it links to, and the letter that follows — and do not rename a concept the member already learned because a new template reads better with a different word. The one exception is a term policy constrains: where a regulator or the plan document fixes the word, it stays, defined where it appears.
- **Consistency across templates is a code fact, not an editorial one.** The same user-visible noun is one shared constant referenced by each template, not a word retyped in six files — that is the only form of the rule a review can check. `discoverable-code`'s one-definition-site rule covers symbols; this skill extends it to a member-facing noun.

## Do not quote the plan document or the regulation

Regulation is drafted to survive a challenge, not to be understood on a phone. Say what the rule means for this member, in this situation, and name where the full text lives for the reader who wants it.

- **Translate the rule into the member's situation.** Not "benefits are subject to the exclusions set forth in Section 7.3 of your Evidence of Coverage" but "Your plan does not cover this treatment. Your plan documents explain why, in the Exclusions section."
- **Required language is left exactly as written, and it is not the explanation.** Where a sentence must appear verbatim — appeal rights, nondiscrimination and language-assistance notices, a regulator's model paragraph — it is not paraphrased, softened, reordered, or summarised. Place the plain explanation first and the required block after it, so the reader meets the meaning before the mandated wording rather than instead of it.
- **A reference number is not an explanation.** Claim numbers, denial codes, and policy sections belong in the copy, low on the page, for the phone call and the appeal — never carrying the burden of saying what happened.

## A template is a program, so its copy has branches

Copy held in code is rendered, and every rendering is a sentence a member reads.

- **Every variable has a rendering for empty, zero, negative, very long, and exactly one.** "Dear ," "You owe $0.00", "You have 1 days left", a name that overflows the address window. Each gets a synthetic fixture and an assertion on the rendered string, not on the data.
- **Never build a sentence by concatenating fragments across a conditional.** A clause assembled from pieces reads as grammar in English by luck and breaks in translation by rule. Branch on whole sentences.
- **Read every combination as prose.** Conditional blocks that each read well can contradict each other when two fire at once — a notice that says both "no action is needed" and "reply by March 3".
- **The channel truncates.** An SMS carries the outcome and the action in its first 160 characters; a plain-text email loses the layout that carried the hierarchy; print loses the link. The copy still has to work when the formatting is gone.
- **The copy will be translated, so idiom is a defect.** Idioms, colloquialisms, humour, and unnecessary intensifiers arrive wrong in translation. Write the literal sentence.

## Reading level is a range, not a gate

- **The target is the project's; grade 6 to 8 is the fallback.** Which formula, which target, and what it is measured on are the convention skill's answers; where none is named, write against grade 6 to 8. The score is a signal read as a range, never the gate; the check below is.
- **The mechanical floor:** sentences of 20 words or fewer, one point per sentence, paragraphs of 2 or 3 sentences, most important information first, active voice, common everyday words, no undefined abbreviations, and headings that make sense alone. For general word substitutions, the public-domain plainlanguage.gov list *Use simple words and phrases* is the lookup; the payer terms in this body are the ones that list does not carry.
- **The check that decides is the next move.** Read the draft aloud once as the member: what happened, what it costs, what I do now. Where the answer needs a second read, the copy is not finished, whatever it scores.

A rule above answered "no" for this change is a finding on it, the same as a failing check.

Sources: the cms.gov *Guidelines for effective writing* (sentence and paragraph length, active voice, scanning, one term per concept, the language to avoid — idiom, quoted regulation) and the CMS *Toolkit for Making Written Material Clear and Effective* (the comparison, the range, the running state, grade scores as ranges), both cited for their rules and never quoted.
