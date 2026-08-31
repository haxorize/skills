# External-anchor currency checks

Run these when an audited skill's reference names an external anchor — an `owner/repo`, a package in an install command, a domain. Check that the anchor still resolves *and is still owned*, since a name can go dead while the file never changes and a dead name is one anybody can register.

- **Repo** — `gh api repos/<owner>/<repo> --jq .full_name`: a transferred repo answers with a different name; a 404 is gone.
- **Package** — `npm view <pkg> maintainers`: who owns it now.
- **Domain** — `whois <domain>` for who holds the registration, `dig +short <domain>` for whether it resolves at all.

A dead-but-claimable anchor is an **Improve** naming the check, never an Update. Where the lookup cannot run (no network, no `gh`), the row reads `UNVERIFIABLE` with the command that would settle it, never the clean outcome.
