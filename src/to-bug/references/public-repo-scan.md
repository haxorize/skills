# Public-repo scan

Runs only when the tracker is GitHub and repo visibility resolved to `PUBLIC` (SKILL step 7 owns the visibility read, including the `Visibility:`-line fallback, and dispatches here).

Scan the rendered body and repro steps for terms suggesting non-public content. Match case-insensitive against this keyword list:

- `customer`, `production`, `prod-`, `internal`, `corp`
- `credential`, `password`, `secret`, `api[_-]?key`
- The literal token `Bearer ` (with trailing space — auth-header prefix)
- The literal prefix `-----BEGIN` (PEM-encoded key marker)
- Hostname shapes: `*.internal.*`, `*.corp.*`

On match, surface the matched terms and ask the user to confirm or abort. **Never block** — sometimes the term is benign (e.g., the word "customer" in a public-facing app description). The warning is informational; the user decides.
