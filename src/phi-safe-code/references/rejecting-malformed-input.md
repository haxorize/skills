# Rejecting malformed input

Open this only when the change parses, validates, or rejects inbound member or claim data — an EDI transaction, a batch feed, or a request body — never on a change that only logs, emits analytics, or builds a prompt. The body's rule stands everywhere: reject the failing unit whole, and never echo the value.

Reject **at the granularity the transaction defines**: a 50,000-claim file with one bad subscriber ID rejects that claim, not the file, because a silent pass on member data is a wrong payment or a wrong coverage decision that surfaces months later. Never skip, default, or partially load the failing unit.

Name in every rejection the file, the segment, the field position, and the reason code; report it on the acknowledgment the trading partner expects (TA1 at the interchange, 999 at the functional group and transaction set, 277CA per claim); and write it as its own audit event.

In logs, in internal error text, and to any caller that is not that acknowledgment, never echo the value — the value is the PHI. The 999's IK404 returns the offending element to the partner by spec, and that is the one place it belongs. The same holds for a single API request: tell the caller *which* field was wrong and *how*, by name, and nothing of what was sent. "Say exactly what was wrong" is the ask that produces `f"subscriber_id must be 6-15 characters, got {value!r}"` — the rule, the field, and the value, where the value is the one part that may not leave; `"subscriber_id must be 6-15 alphanumeric characters"` says everything the caller can act on.
