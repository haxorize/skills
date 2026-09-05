# Public-repo scan

Runs only when the tracker is GitHub and repo visibility resolved to `PUBLIC` (SKILL step 7 owns the visibility read, including the `Visibility:`-line fallback, and dispatches here).

Scan the rendered body and repro steps for terms suggesting non-public content. Match case-insensitive against this keyword list:

- `customer`, `production`, `prod-`, `internal`, `corp`
- `credential`, `password`, `secret`, `api[_-]?key`
- The literal token `Bearer ` (with trailing space — auth-header prefix)
- The literal prefix `-----BEGIN` (PEM-encoded key marker)
- Hostname shapes: `*.internal.*`, `*.corp.*`

And against these secret shapes, case-sensitive:

- AWS access key: `AKIA[0-9A-Z]{16}`
- GitHub token: `gh[pousr]_[A-Za-z0-9]{36,}` or `github_pat_`
- JWT: `eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.`
- PEM block: `-----BEGIN [A-Z ]*PRIVATE KEY-----`
- URL-embedded credential: `[a-z][a-z0-9+.-]*://[^/\s:]+:[^@\s]+@`
- Slack webhook: `https://hooks.slack.com/services/`
- Google OAuth client secret: `GOCSPX-[A-Za-z0-9_-]{20,}`

On match, surface the matched terms and ask the user to confirm or abort. **Never block** — sometimes the term is benign (e.g., the word "customer" in a public-facing app description). The warning is informational; the user decides.
