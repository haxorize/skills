# Logging

Open this only when the change adds or alters a log, trace, or error event; a change that touches no logger never needs it. The event shape (structured, never interpolated), the audit trail, and the failure-path test stay in the skill body.

- **Expected conditions are not errors.** A not-found, a validation rejection, an expired coverage is an event at `info`, with its reason code; `error` is for what the service could not do, and an error log that carries the rejected input to "help reproduce it" is the leak this skill exists to stop — reproduce from the request ID and the stored record, under access control.
- **A pipeline attaches only what operating the service needs.** A log pipeline that enriches events with user attributes "so we can filter later" is the minimum-necessary violation in pipeline form: enrichment adds fields nobody traced to a sink.
