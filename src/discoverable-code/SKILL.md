---
name: discoverable-code
description: Naming and placing code so a plain-text search finds it — identifiers as search queries, whole string literals, one definition site, a doc line the natural-language grep lands on. Use when naming or renaming an exported symbol, type, file, error message, event name, or flag, when moving code between files, when a search for a concept returns nothing or a wall of hits, when the code deliberately leaves out something a reader would search for, when reviewing a diff for names the next session will not find, or when another skill needs the discoverability vocabulary.
---

# Discoverable code

An agent finds code by searching for strings and reading a small window around each hit. It has no hover text, no jump-to-definition, and no memory of last session's tour of the repo. So every identifier is a **search query**, every log line is a query someone will paste back, and a name that greps to 40 hits costs the same reads as a name that greps to none. Write so one search resolves the question.

The rules below govern *findability*. How much behavior sits behind an interface, where the seam goes, and which types make a bad state unrepresentable are `codebase-design`'s questions — a deep module can carry an ungreppable name and a shallow one a perfect name.

## Names are search queries

- **Exported symbols get 2–4 words, at least one of them a domain word.** `diffUserObjects`, not `diff`; `queueEventForDispatch`, not `queue`. One-word exported names collide across a large repo far more often than three-word ones, and three words is where the curve flattens — take the shortest name that greps uniquely and put the rest in the doc line. In a language where the call site carries a qualifier — a Go package, a Python module — the qualifier is one of the words for the reader at the call site (`stripe.NewClient` reads as three, and `stripe.StripeClient` stutters), but the definition reads `func NewClient`, which a bare search reaches only through the package path; so the doc line on the definition carries the domain word the name dropped.
- **Give a generic verb its object.** `sanitizeEmailHtml`, not `sanitize`; `validateSmtpConfig`, not `validateConfig`. Qualify as far as uniqueness needs, then stop.
- **One definition site per symbol.** Never copy a function between files — move it and delete the original in the same change. A shared helper gets one concept-named home and is imported everywhere else.
- **Put the disambiguating context in the symbol, not the folder.** The import that tells `users/diff.ts` from `orders/diff.ts` sits at the top of the file; the search hit is at line 300. Name it `diffUserObjects`.
- **One concept, one spelling.** Pick `organizationId` or `orgId` and use it everywhere; each synonym splits every future search. Reuse the vocabulary already in the code you are editing rather than introducing a near-synonym, and follow a rigid repo-wide convention where one exists (every contract file exporting `Input`/`Output`) — an existing convention beats a locally better name.
- **Rename in the same change as the behavior.** A stale name is misinformation with a 100% open rate. That includes visibility markers: a `_private` helper other modules now import needs a public name.
- **A rename ends when every remaining hit of the old name is one you named as deliberate.** After renaming, search the whole repo for the old spelling — code, tests, docs, config, string literals — and stop only when the hit list is empty or each hit is named (a changelog entry, a `@deprecated` alias). Rename from the match list with an edit tool, one site at a time; a mass substitution (`sed -i`, `xargs perl`) rewrites what it never listed, and the rename-safety hook blocks it where installed.
- **Names carry durable vocabulary, not planning vocabulary.** `Phase2Handler`, `NewCheckoutService`, `v2Client` name a moment in a plan, and the plan ends while the name stays. Ticket IDs, migration phases, and rollout stages belong in the ticket and the ADR; the public name says what the thing does.
- **Filenames are names.** `config.ts`, `types.ts`, `utils.ts`, `helpers.ts`, `handlers.ts` say nothing in a result list and collide with every other module's copy of the same file. Prefix the domain: `billing-plan-config.ts`. `index.ts` earns its name only as a thin re-export entry point.
- **Name a type the way a compiler error will quote it.** The agent self-corrects from that error text; `OrgScopedDb` explains itself there, `Ctx2` does not.

## Say it where the search lands

- **One-line doc comment on every export, stating the sharpest thing the signature cannot show** — units, timezone, "source time, not insert time", who owns the returned object, ordering guarantees. The definition is where a name search lands, so that line is the whole message.
- **Write the plain-words phrase in that comment.** Searches arrive as ordinary language, and camelCase does not match a phrase grep: `RateLimiter` is invisible to a search for "rate limit". A `SessionExpiryChecker` whose comment reads *Checks whether the user session has expired* catches the grep for "session expired" that the identifier never would.
- **Keep strings whole.** Never build an event name, feature flag, or error code by interpolation — `` `github.${entity}.${action}` `` makes `github.pr.merged` unfindable. Write the full literal even where a loop feels DRYer.
- **Start error messages with a unique literal prefix**, so a message copied out of a log greps straight back to the throw site: ``throw new Error(`Webhook signature mismatch for ${id}`)``, never ``throw new Error(`${prefix}: mismatch`)``.
- **A module should read with its imports unopened.** Each imported name plus its doc line should carry enough that the reader never opens the source module; when they have to, the import's name failed, not the reader.
- **One searchable concept per file, and thin orchestrators.** The code answering "where is X done?" lives in a module named after X — the thing a reader would ask about, not the mechanism inside — never inline in a coordinator or service class. An orchestrator reads as a sequence of calls into well-named modules, each line one hop from the real implementation. Split until each question-sized concept has one home, then stop: a helper meaningful only inside one concept stays inline, and a file per tiny function scatters one answer across several reads.
- **Put tests where the repo already puts them**, and where nothing settles it, beside the source (`foo.test.ts` next to `foo.ts`) so one search finds the behavior and its specification together. A house layout the rest of the suite follows beats a locally better one, the same way an existing naming convention does.
- **Mark dead ends.** `@deprecated` on the old path, naming the new one, so the search hit that lands on it says so.
- **Write the deliberate absence where its search would land.** When the code leaves out something a reader would search for — a retry, a cache, a validation step, a timeout the neighbouring modules have — one line in the module or doc comment says so, in the words the search would use: "no retry here on purpose; the caller owns backoff". A search finds code and never the absence of code, and a well-organised repo keeps offering the reader one more plausible place to look.

## Before the change lands

1. Would one search for each new exported name reach its implementation, with no second definition of the same name competing for the reader?
2. Does every log and error string in the change exist verbatim in the source, uninterpolated at its front?
3. Is the one thing a caller must know that the signature cannot say written at the definition?
4. Did anything change behavior, audience, or visibility without changing its name?
5. Where code moved, is it gone from where it came from?
6. Where something was renamed, does the old name search to zero, with every remaining hit named as deliberate?
7. Where the change deliberately leaves out something a reader would search for, is the absence written where that search lands?

A "no" here is a finding on the change, the same as a failing check.
