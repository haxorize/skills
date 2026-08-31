# Fixtures and test data

Open this only when the change creates or edits test data — a fixture, a seed, a demo or QA dataset, a synthetic recording, image, or scan, or a de-identification transform.

- **Synthetic, generated, never extracted.** Build every fixture with a generator and a fixed seed; never copy from production, a QA extract, or a support ticket. "Scrubbed" production data is still PHI — removing names does not de-identify a row. The code that did the transform does not get to certify it either: never let the job that transformed data set a flag, column, or header asserting the result is de-identified — label a scrubber's output by what the transform did, which fields it dropped, never by what it claims the result now is.
- **Realistic means realistic in shape,** not in identity: a member ID in the project's format for a person who does not exist, a date of birth that validates, a claim that exercises the branch; and for a recording, image, or scan, a synthetic file of the right format, size, and duration, never a redacted production one, which is a scrubbed extract under the rule above.
