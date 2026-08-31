# Media, free text, and SDK defaults

Two sink-table lookups for `phi-safe-code`. Open § Media and free text only when the change touches free text, a call recording, a photo, a scan, or a transcript — anything reaching a thumbnailer, OCR, speech, or transcription processor. Open § SDK auto-capture and query logging only when the change adds or reconfigures an error-reporting or APM SDK, a debug error page, or database query logging — the moment you are about to open a config file rather than a source file.

## Media and free text

Free-text fields (claim notes, appeal text, chat transcripts) drift into holding PHI whatever their schema says, and a recording, a photo, or a scan has no schema at all: a call recording is PHI before it is transcribed and its transcript is PHI after, and an uploaded photo holds whatever is printed on it. So treat every one of them as PHI at every sink. Route text only through the prompt builder's named fields and a provider past the external-sink gate. Check a recording, image, or scan by where its bytes go and who opens them: a hosted thumbnailer, OCR service, or speech vendor is an external sink under the BAA gate rather than an image pipeline — an in-process resize crosses no boundary and is not one — so name every processor in the data-flow row, past the gate where it is hosted, and never let the bytes reach a log, an analytics sink, a bucket or thumbnail cache, or an index outside the store's access control.

## SDK auto-capture and query logging

The defaults capture request bodies, headers, and local variables, and write bound parameters to the *database's* logs. The settings to check:

- Error reporting and APM: `send_default_pii`, `include_local_variables`, breadcrumbs, debug error pages.
- Database and ORM: `echo`, `show_sql`, `log_min_duration_statement`, slow-query logs, `pg_stat_statements`.

Prove each off by configuration — none of this passes through a call site a diff can show, so the diff-read that covers every other sink covers none of it.
