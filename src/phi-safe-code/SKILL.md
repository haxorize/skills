---
name: phi-safe-code
description: Keeping member and patient data out of every surface it leaks into — logs, error text, URLs, file names, fixtures, analytics, crash reports, model prompts, embeddings, queues, caches, the clipboard, commits, tickets, and chat. Use when code touches member, subscriber, patient, claim, eligibility, enrollment, 834/837, FHIR, MRN, or date-of-birth data — adding logging or error handling, building fixtures, emitting analytics or telemetry, choosing an identifier for a URL, key, event, file name, or export path, indexing notes, publishing a rollup, sending data, a recording, photo, or scan to a vendor, model, OCR, or speech service, parsing a malformed file, or drafting a commit, ticket, screenshot, or chat reply from a repo holding it. Also when a security finding or audit gap names PHI, when adding or reviewing an audit trail, or when a real member turns up in a log, test, or commit. Not for provider-side data (NPI, facility records) — public. Not a regulation digest or the project's allowed-field list.
---

# PHI-Safe Code

The data class is **protected health information**: anything that identifies a person and connects them to health care, coverage, or payment. The statutory eighteen of Safe Harbor are one lookup away; what this skill governs is the *class*, because no denylist enumerates it: a payer's own identifiers (member ID, subscriber ID, group number, claim number, MRN) are as identifying as an SSN; the eighteenth identifier is "any other unique identifying number, characteristic, or code", which is why a surrogate key is a floor and not an exit; ZIP, date of birth, and sex together re-identify most of a population, so a row holding them was never de-identified to begin with, and a count does the same once the cell is small (the reporting row below). Some categories change how a sink may be used, not just what reaches it; which stricter categories apply here is the convention skill's answer, named in the Boundary below.

The default output gets this wrong in a specific way: it knows "don't log PHI" and then puts the member's name in a fixture, the subscriber ID in a URL, and the member record in a model prompt — each an incident the assessor rules on, none of them a typo. So run the discipline by **sink**, not by intent: trace every field that is PHI to every place it could land, and show each landing to be opaque-ID-only. One hard stop binds throughout: an external sink is blocked until the BAA gate below clears — an unanswered BAA column is a blocked change.

## Allow by name, never block by substring

- **Build a sink from named fields; drop everything else.** Build a log event, an analytics event, an error payload, a prompt from an explicit list of field names, and make the serializer for that sink accept only those names. A filter keyed on `password|ssn|card` passes `dob`, `mrn`, `member_id`, and every field named next quarter.
- **Never pass an object to a sink.** `log.info("lookup", request=req)`, `logger.error(f"failed for {member}")`, `track("checked", payload)` — a whole request body or a whole member object are the two shapes to look for. Whether an argument is an object is a type-level fact no grep settles, so read every logger, error-formatter, analytics, and prompt-builder call site the change touches — the grep (`log\.|logger\.|track\(|capture`) finds the call sites; the read decides. Bound payload sizes at the serializer; a free-text field is a payload.

## Identifiers

- **An opaque internal ID is the only identifier that travels.** Put surrogate keys for members, claims, and enrollments in URLs, path and query parameters, log events, cache keys, queue payloads, and analytics; never MRN, SSN, subscriber ID, member ID, name, or date of birth — not as a key, not as a "harmless" label, not in a file name, an export path, or an object key — a file name survives every allow-list, read by listings, manifests, and mail headers that never see the file's contents — not Base64'd, not hashed (member IDs have a known format and low entropy, so a plain SHA-256 of one is a dictionary lookup back to the original), and not embedded: inversion attacks recover text from vectors, so an index built over claim notes or member records is a PHI store on the same terms as the table it was built from. Treat a keyed pseudonym (HMAC, tokenization) as an opaque ID only when the key lives outside every sink that holds the output, and treat the mapping itself as PHI.
- **An opaque ID confines re-identification; it does not end it.** The mapping is the re-identification key, so a sink holding surrogate IDs beside health events is still a PHI store — access-controlled, retained on the project's schedule, audited, and listed as a sink in the data-flow row.
- **Correlate with request and trace IDs, never with the person.** Mint a `request_id`/`trace_id` at the boundary and propagate it through every call, async job, and retry, so you answer a production question by correlation, not by searching logs for a member.

## Trace every field to every sink

For each PHI field the change touches, name each sink it can reach and the guarantee at that crossing. The sinks the default forgets:

| Sink | What reaches it | The check |
|---|---|---|
| **Logs, traces, crash reports** | opaque IDs, named non-PHI fields, the skeleton (`timestamp`, `level`, snake_case `event`, `request_id`/`trace_id`, `service`, `environment`) | structured key-value events only, per § Logging and the audit trail |
| **Error text** | **internal:** field name and position; **returned to the caller:** what was wrong, by field name, never the value | § Logging and the audit trail's failure-path test |
| **URLs, query strings, headers, browser storage** | opaque IDs only | grep routes and fetch calls for the identifier fields |
| **Caches, search indexes, queue payloads, backups, exports** | the same allow-list as the store they copy; a copy inherits no fewer obligations | each copy named in the data-flow row |
| **Product analytics** | event name and opaque properties, separated from engineering diagnostics so one pipeline's relaxation never leaks into the other | the event schema is the allow-list |
| **Reporting, dashboards, and scheduled extracts (BI tools, embedded charts, an aggregate mailed to a partner)** | rollups with small cells and their complements suppressed; never a row-level extract behind an aggregate label | the suppression rule, the drill-through, and the rollup's data-flow row: [references/reporting-and-rollups.md](references/reporting-and-rollups.md), opened when the change emits a count, chart, dashboard, or extract |
| **Model prompts and LLM telemetry** | minimum necessary for the task; prompt and completion payloads stay local or are explicitly gated out of telemetry | the prompt builder takes named fields, and the provider passes the external-sink gate |
| **Outbound HTTP (vendors, SaaS, observability, model providers)** | nothing until the BAA gate below clears | the external-sink row names the counterparty and its BAA status |
| **Free-text and unstructured payloads (claim notes, appeal text, chat transcripts, recordings, images, scans)** | they drift into holding PHI whatever their schema says — treat all of them as PHI at every sink, and any hosted processor (thumbnailer, OCR, speech) as an external sink under the gate below | where the bytes go and who opens them, every processor in the data-flow row (§ Media and free text in [references/media-and-free-text.md](references/media-and-free-text.md), opened when the change touches free text, a recording, an image, or a transcript) |
| **SDK auto-capture and query logging** | nothing — the defaults capture request bodies, headers, local variables, and bound parameters | proven off by configuration, since none of it passes through a call site a diff can show ([references/media-and-free-text.md](references/media-and-free-text.md) § SDK auto-capture and query logging, opened on an error-reporting or APM SDK, a debug error page, or query logging) |
| **Reverse proxy, load balancer, CDN access logs** | the path and query string as sent, outside the app and outside its allow-list | the URL rule above holds at the edge too, and the edge's own retention is the project's |
| **Session replay and RUM on a member portal** | nothing until masking is proven per field | the vendor is an external sink like any other |
| **Templates and rendering (email, SMS, push, print, PDF, EOB)** | the minimum the document needs, addressed to the right member | the mis-mailing path is tested; a template variable is an allow-list entry |
| **CI logs, test output, notebooks** | synthetic fixtures only — a failing assertion prints the diff, and `.ipynb` caches its outputs | fixtures are generated ([references/fixtures.md](references/fixtures.md)), and notebook outputs are cleared before commit |
| **Feature-flag and experiment context, alert payloads (Slack, Teams, PagerDuty), heap and core dumps, temp files, the clipboard and the share sheet** | opaque IDs and non-PHI attributes | each named in the data-flow row; a targeting attribute is a sink, not config; a clipboard write or share-sheet payload carries only what the person asked to share, never whatever else the screen was holding |
| **Your own tool output** | nothing — `cat` of a log, a fixture, or a record ships it to the model provider, and a scan, lint, or grep *finding* is this sink in a report's shape: name the rule and `file:line`, never the value (`gitleaks --redact`, `grep -l`), because a quoted line lands in the transcript the summary, the commit message, and the ticket are then drafted from | an external sink under the BAA gate below, and the one you are likeliest to cross; read a finding for what it quotes before pasting it anywhere |

## Logging and the audit trail

- **Structured events, never interpolated strings.** `log.info("eligibility_lookup_failed", request_id=rid, product_code=pc, reason="subscriber_not_found")`, not `log.info(f"lookup failed for {subscriber_id} dob {dob}")`. The reason is a code from a closed set, never the input that caused it.
- **Expected conditions are not errors, and a pipeline attaches only what operating the service needs** — the rationalizations that argue past both are in [references/logging.md](references/logging.md), opened when the change adds or alters a log, trace, or error event.
- **Every read, write, delete, and export of PHI is an audit event,** written to an insert-only store, never the application log; reading is an event too. The store shape, keys, granularity, and retention: [references/audit-trail.md](references/audit-trail.md), opened when the change adds, alters, or reviews an audit trail, or a finding names one.
- **The failure path emits sanitized diagnostics, as a test.** Write a test that raises the exception on real-shaped input and asserts the log and the caller's error body carry the request ID and field names and none of the input values.

## Fixtures and test data

- **Synthetic, generated, never extracted.** Build every fixture, seed, and demo dataset with a generator and a fixed seed; never copy from production, a QA extract, or a support ticket. "Scrubbed" production data is still PHI, and the transform never certifies its own output. Recipes, the labeling rule, and synthetic media: [references/fixtures.md](references/fixtures.md), opened when the change creates or edits test data or a de-identification transform.

## Malformed input: an error, never a silent pass

Reject a unit that fails validation — the claim in an 837, the member record in an 834, the request on an API — whole, never skipped, defaulted, or partially loaded, and never echo the value, because the value is the PHI; the Error text row above holds the caller-facing shape. The granularity and the acknowledgment routing (TA1/999/277CA): [references/rejecting-malformed-input.md](references/rejecting-malformed-input.md), opened when the change parses or validates inbound member or claim data, never on one that only logs or builds a prompt.

## The repo and the conversation

- **The conversation is private; the repo is not.** Never write a member named in a chat turn, a support thread, or a pasted log anywhere durable: not a commit message, branch name, PR or work-item body, test name, comment, screenshot, or terminal excerpt in a report. Reproduce the case with a synthetic record and refer to the real one by ticket number.
- **A PHI value already landed where it should not be is an incident, not a typo** — in published history, a running log, a store, a ticket. Raise it through the project's incident path before touching it: a quiet delete destroys the evidence of scope, and the retention window is the owner's call. On all four surfaces, never delete the log lines, purge the rows, or edit the ticket — report, and the owner decides what is scrubbed. **Published history is the one surface with a procedure**: never run your own amend, tip-edit, or force-push; take the steps in [references/history-incident.md](references/history-incident.md).

## External sinks and the BAA gate

Any external sink that receives PHI is blocked by default until its business-associate status is clear; answer [references/baa-gate.md](references/baa-gate.md)'s five questions, in order, before the first byte. The one audit input you produce from a repo is the **data-flow row**, one per PHI field: field class, source, each sink or boundary crossed, the guarantee at that crossing, and BAA yes/no for each external sink. A rollup's row is keyed by its population instead ([references/reporting-and-rollups.md](references/reporting-and-rollups.md), opened when the change emits a rollup, chart, or extract).

## Boundary

Two layers are deliberately outside this skill. The org's own allowed-field list, its retention figures, its policy numbers, and which stricter categories apply (psychotherapy notes, HIV status, minors' records, 42 CFR Part 2 programs, state law such as CMIA and MHMDA) belong to the project's convention skill for the `phi` role — named in `CLAUDE.md`'s `## Convention skills` block — or to `CLAUDE.md` itself; read those for the *what*, this for the *how*. And what lies past the data-flow row above — risk assessment, control mapping, attestation — is the assessor's, never an engineer's output from a repo. Where no such convention skill exists, every deferring rule degrades the same way: apply the rule to what this change needs and raise the missing project answer as a finding rather than guessing a number.

The member-facing surface is two siblings' ground: what data reaches the copy is this skill's; whether the member can understand and act on it is `health-literacy`'s; whether a person can operate it is `accessible-ui`'s.

A rule above answered "no" for this change is a finding on it, the same as a failing check.
