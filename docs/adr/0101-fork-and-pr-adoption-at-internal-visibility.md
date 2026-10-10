# Fork-and-pull-request adoption at internal visibility

Status: proposed (2026-10-10) — the organization's governance regime this decision leans on was not confirmed at decision time, and the move below has not happened

To let teams outside Stormworks use and contribute to the skills repository, we move it into the HumanaInnersource-EMU organization at **internal** visibility — readable across Humana, not on the public internet — and accept contributions through **fork and pull request** rather than granting consuming teams write access. A **consuming team** clones the repository and runs `scripts/install.sh`; a **contributing team** forks, opens a pull request, and a Stormworks reviewer merges. Approvals are to be restricted to the Stormworks team through a `CODEOWNERS` file, which the repository does not yet carry (see Deferred).

We rejected granting consuming teams write access, which a team would reasonably argue for on lower-friction grounds: fork-and-pull-request keeps the blast radius of an outside change to a branch on a fork the maintainers review before it can land, which matters more for a shared skills base than the friction it adds. We rejected internet-public visibility because nothing here needs an audience outside Humana, and open-sourcing enterprise code carries a separate legal review that internal visibility avoids.

The decision leans on the HumanaInnersource-EMU organization enforcing the September 2026 GitHub governance regime at the organization level: protected-branch pull requests, a minimum approver, mandatory comment resolution, and required status checks (Cycode Secrets, Greenlight API, ServiceNow Change Control). That regime was not confirmed to apply to the target organization at decision time, which is why this record is `proposed`.

## Considered Options

- **Grant write access to consuming teams** — lowest friction, but any team could push to shared skills; rejected for blast radius.
- **Co-maintainers with merge rights** — appropriate for a specific trusted team later, not the default for all consumers.
- **Fork-and-pull-request (chosen)** — lowest trust required of a contributor, composes with the organization's required-approver and status-check governance.

## Consequences

- The model governs outside teams contributing to the internal-organization copy. The Stormworks maintainers' own landing stays as this repository's `CLAUDE.md` `Landing:` key states it — trunk, no pull request required — so the pull-request gate applies to contributing teams, not to the maintainers.
- Until the move happens, this private GitHub repository is the canonical upstream, and the work machine reaches it through a hand-synced mirror that replaces `src/`, `global/`, `scripts/` and `docs/` on each sync. A pull request merged in the internal copy under that arrangement is overwritten by the next sync unless it is carried back here first.
- `scripts/install.sh` links skills live from a clone, so a merged pull request reaches every consuming team at its next `git pull`; nothing pins a version yet (see Deferred).

## Revisit when:

A consuming team needs write access for a sustained co-maintenance role, or the organization's governance regime turns out not to apply as assumed.

## Deferred

- Whether the HumanaInnersource-EMU organization enforces the governance regime above — settled by checking the organization's branch-protection and required-check settings, which moves this record to `accepted` or reopens it.
- The `CODEOWNERS` file restricting approvals to Stormworks — settled when the repository moves; none exists today.
- Which copy is canonical after the move, and how merged pull requests flow between it and this repository — settled by a later decision at move time.
- Versioned or pinned installs following semver, with changelogs and release announcements — settled by a later decision when the repository is treated as a product with versions.
- A skill-picker interface for installing a subset of skills — settled by a later decision when a consumer needs it.
