# Remediation levers by bucket

Open this when drafting the Task body for a bucket — it maps each of the six buckets to the lever the Task proposes. What each bucket means, and the cascade that assigns it, is [buckets.md](buckets.md)'s; this file is the remediation half.

## Bucket A — base-image dependency the team cannot control

**Lever: reassign to the platform base-image team.** The Task names the platform team as owner and carries each finding's origin sub-tag — `os-package`, `tool-bundle`, `global-module`, or `runtime` — for the handoff; all four reassign the same way. A `global-module` finding is unconfirmed until the app Dockerfile is checked for an `npm install -g` of it, and a `runtime` finding until it is confirmed not to be an application component: either one the Dockerfile turns out to own is the team's, not the platform's.

## Bucket B — team-controlled base package

A base-image finding whose package the app Dockerfile's own `RUN` package operations name. **Lever: the team fixes it in its own Dockerfile** — bump the package in the `RUN` list, or bump the `FROM` tag, then rebuild. Not `/upgrade-deps` and not reassign.

## Bucket C — absent from both resolved trees

**Lever: file a scanner or curation exception.** The Task carries the evidence a human files — the package, version, finding path, and its absence from both the production and the development tree — for a finding that recurs scan over scan. The skill does not file the exception. A nested copy in this bucket is unconfirmed until the tree reduction is shown to have kept nested installs.

## Bucket D — non-production dependency installed into the image

**Lever: fix the build to exclude non-production dependencies.** One build-file change clears the bucket, so the Task proposes that change and lists the findings it clears. For npm, the change depends on the build's shape:

- **A multi-stage build** — install the production set in the runtime stage (`npm ci --omit=dev`) and copy only the built output across from the build stage.
- **A single-stage build** that compiles after install — keep `npm ci` for the build, then run `npm prune --omit=dev` after it. Swapping the install for `npm ci --omit=dev` there removes the compilers and bundlers the build step needs, and the image fails to build.

A dependency mislabeled development-only breaks the running application once excluded, so the Task is a proposal a human runs.

## Bucket E — production dependency at or above the fix

**Lever: request a rescan.** The Task cites the installed version as proof it is at or above the fix. A finding whose installed version equals the scanned version is unconfirmed — a rescan reports it again — and the Task asks a human to check the advisory's affected range instead.

## Bucket F — production dependency below the fix

**Lever: upgrade with `/upgrade-deps`.** The Task carries the command with the package names pre-filled from each finding's `matched_package` — `/upgrade-deps <name> [<name> ...]`. `upgrade-deps` takes package names only and picks each target version itself, so the Task names no version; in the target org, the registry's JFrog Compliant Version Selection feature governs which versions resolve. A finding with no published fix, or whose versions could not be compared, is unconfirmed and gets no upgrade line — the Task names it for a human to judge.
