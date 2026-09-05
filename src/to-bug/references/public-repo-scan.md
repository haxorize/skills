# Public-repo scan

Runs only when the tracker is GitHub and repo visibility resolved to `PUBLIC` (SKILL step 7 owns the visibility read, including the `Visibility:`-line fallback, and dispatches here).

Scan the rendered body and repro steps for terms suggesting non-public content. Match case-insensitive against this keyword list:

- `customer`, `production`, `prod-`, `internal`, `corp`
- `credential`, `password`, `secret`, `api[_-]?key`
- The literal token `Bearer ` (with trailing space — auth-header prefix)
- The literal prefix `-----BEGIN` (PEM-encoded key marker)
- Hostname shapes: `*.internal.*`, `*.corp.*`

And against these secret shapes, case-sensitive, with `grep -E` — the interval quantifiers (`{16}`, `{36,}`) are ERE, and plain `grep` without `-E` reads them literally and returns a clean scan over a file holding a key:

- AWS access key: `AKIA[0-9A-Z]{16}`
- GitHub token: `gh[pousr]_[A-Za-z0-9]{36,}` or `github_pat_`
- JWT: `eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.`
- URL-embedded credential: `[a-z][a-z0-9+.-]*://[^/[:space:]:]+:[^@[:space:]]+@`
- Slack webhook: `https://hooks.slack.com/services/`
- Google OAuth client secret: `GOCSPX-[A-Za-z0-9_-]{20,}`

On a keyword hit, surface the matched terms and ask the user to confirm or abort — never block, since the term is sometimes benign (the word "customer" in a public-facing app description); the warning is informational and the user decides. On a secret-shape hit, abort the publish with no confirm path: report `file:line` and the credential type only — the value never enters the conversation or the report — and recommend rotation; the body is fixed and rescanned before any create.
