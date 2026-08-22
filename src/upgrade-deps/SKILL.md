---
name: upgrade-deps
description: Upgrade a project's dependencies in the safe order — security first, each major its own step with the changelog read and the suite run, then the minor/patch batch — with a supply-chain check on every package before it touches the lockfile. npm, pip/uv, and NuGet.
disable-model-invocation: true
requires: feedback-loops, adoption-verdict
argument-hint: "[<package> ...] — defaults to everything the manifest lists as outdated"
---

# Upgrade Deps

Dependency bumps are the change whose diff says nothing — a one-line manifest edit that can swap a maintainer, a licence, or a default under every caller. The skill is the order of work plus the check every bump passes before the lockfile moves.

## 0. Baseline

Each step below ends at a clean tree with the suite green, and the run is one commit per step — so the first thing this skill does is ask, once: "one commit per step, on this branch?" A yes is the ask the `committing` discipline needs for every step's commit; a no means the tree is left clean at each step and nothing is committed until asked. The push stays on the `Landing:` key or a separate ask. Before any bump: a green suite on the current tree (run the `/feedback-loops` skill — if you did not just see a `Launching skill: feedback-loops` line, stop and load it; a red baseline is fixed or named before anything else moves — an upgrade cannot be blamed for a failure it inherited) and a revertable point (a clean tree at a known commit, or a stash the close step names). Rollback is defined now, not at the failure: restore manifest plus lockfile together and re-run the suite to prove the restore, never the manifest alone.

## 1. Discover

List what is outdated and what is flagged, with the tool the repo already uses — `npm outdated` / `npm audit`, `pip list --outdated` / `pip-audit` (or `uv lock --upgrade --dry-run`), `dotnet list package --outdated` / `--vulnerable` / `--deprecated`. A package is classed once: security-flagged, major, below-major. Then by exposure: dev-only (type packages, test frameworks, formatters) updates freely; libraries the code calls directly and SDKs for third-party services get the changelog read; the build toolchain (the runtime, the compiler, the bundler, the SDK itself) gets the most caution, because breakage there reaches every output. Deferred bumps from a previous run resurface here from `docs/deps-deferred.md` with their review-by date.

## 2. Audit each package before it touches the lockfile

One verdict per package — **safe**, **review**, or **defer** — from facts looked up now, never from the package's reputation:

- **Publisher** — who published the target version against who published the current one (`npm view <pkg>@<v> _npmUser` per version — `maintainers` is the current list only; the NuGet gallery's owners and the package's signer; PyPI's release uploader). A new account is `review`; an unknown one is `defer`.
- **Publish age** — the floor is 7 days, this skill's default; a target younger than the floor is flagged: wait unless the bump is the security fix itself. Where the repo's `CLAUDE.md` `## Registry` block carries `Minimum release age:` (a curating proxy that refuses packages younger than it), that number replaces the floor and a younger target is not installable: pick the newest version older than the gate, or defer with a review-by date of publish date plus the gate.
- **Provenance** — an attestation present on the target version or noted absent, checked on the registry metadata before anything is installed (`npm view <pkg>@<v> dist.attestations`; download the `.nupkg` and `dotnet nuget verify <path>`; PyPI attestations on the release page). A claim resting on absent metadata earns no verdict of safe — and a lookup that failed is *no observation*, never a declared absence: `npm view` prints nothing and exits 0 when the field is absent (that is absence), and a non-zero exit is a failed lookup; say which.
- **Tarball diff** — what the published package actually changed (`npm diff --diff=<pkg>@<from> --diff=<pkg>@<to>`; unpack the two `.nupkg` or wheels and diff): new runtime dependencies, `eval`, network calls where none belonged, a diff larger than the changelog explains. Read the changelog first and check the tarball against it; a tarball that does more than the changelog says is `defer`.
- **Licence** — a licence that changed between versions is not this skill's to bump: run the `/adoption-verdict` skill on it (if you did not just see a `Launching skill: adoption-verdict` line, stop and load it) and take its verdict.

Run the audits in parallel, one subagent per package; an audit that did not complete is `defer`, never `safe`. A run where every audit is `defer` because the registry proxy refused the lookups is a tooling finding to report (which lookups, which proxy), not an upgrade to abandon — name the manual path and stop.

## 3. Upgrade in order

1. **Security-flagged packages first**, each its own step. Never `npm audit fix --force`, `pip install --upgrade` over a whole requirements file, or any equivalent that rewrites ranges the repo chose.
2. **Each major as its own step**: toolchain → framework → libraries → build tools. Read the migration guide or changelog before the bump — the Context7 MCP when it is present (`resolve-library-id`, then `query-docs` on the migration), else the registry's repository URL and its release notes — and grep every removed or changed API it names against this repo before bumping, so the breaking changes that reach callers here are listed up front and the ones that do not are named as not applicable. A multi-major jump stops at the last patch of each intervening major, never on a `.0`. Run published codemods before hand edits. Run the `/feedback-loops` skill after each step; a red step is fixed or reverted before the next begins.
3. **The below-major batch** — minors and patches together, one suite run.

Peer-dependency warnings are findings to resolve, never reasons for `--force` or `--legacy-peer-deps` by default; where one is unavoidable, it is named in the close with the package that needs it. Snapshot updates (`--updateSnapshot`, approval-test rewrites) are reviewed diff by diff, never auto-accepted.

## 4. Lockfile

The lockfile is part of the change: committed with the manifest, installed from in CI (`npm ci`, `uv sync --locked`, `dotnet restore --locked-mode` with `RestorePackagesWithLockFile`), and its diff read for transitive entries the manifest never named — a new transitive package gets the step-2 audit too.

## 5. Close

One table: package, from → to, class, verdict, what the suite did. Deferred packages carry a reason and a review-by date, written one line each to `docs/deps-deferred.md` in the target repo so the next run's step 1 greps them back. The commit body names what the upgrade changes for a caller and what was verified, never the list of bumps — the `writing-for-humans` commit family's "Bumped dependencies" pair is the shape to avoid and the one to write. The close's counts and "suite green" are bound by the global evidence rule (`~/.claude/rules/evidence.md`).
