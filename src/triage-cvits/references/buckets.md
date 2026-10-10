# CVIT buckets

Open this when a bucket's meaning, the cascade's order, or the image key is in question — it is the home of the six dispositions `scripts/classify-cvit-findings.py` implements and `remediation-levers.md` maps to levers. Brought in from the stormworks-playbook's `docs/security/DOMAIN.md` (CVIT Buckets) and the playbook record that made the buckets ecosystem-neutral; this copy is the one the skill answers to.

## The six dispositions

Each bucket is defined by the remediation lever, not the package ecosystem, so the taxonomy holds across ecosystems.

- **Bucket A — base-image dependency the team cannot control.** In a base-image layer and not controlled by the repository's own Dockerfile. Disposition: reassign to the platform base-image team. Carries an origin sub-tag — `os-package`, `tool-bundle`, `global-module`, or `runtime` — for the platform handoff; the sub-tag is a reporting breakdown, not a separate bucket.
- **Bucket B — team-controlled base package.** A base-image finding whose package the repository's own Dockerfile names in a `RUN` package operation (the `controlled_packages` input). Disposition: the team fixes it in its own Dockerfile (bump in the `RUN` list, or bump the `FROM` tag, then rebuild). Not `upgrade-deps` and not reassign. That is the one team-control signal the script reads: a finding a newer `FROM` tag would fix, or a runtime the Dockerfile compiles, lands A, and moving it to B is a human's call.
- **Bucket C — absent from both resolved trees (scanner artifact).** An application-dependency finding whose package is in neither the production nor the development resolved tree — typically a range another package's manifest declares, which the scanner read as installed. Disposition: not affected; file a curation or scanner exception for findings that recur scan over scan. A nested copy (more than one `node_modules` segment in its path) absent from both flattened trees lands C unconfirmed.
- **Bucket D — non-production dependency installed into the image.** Present in the development resolved tree, absent from the production tree, but installed into the image because the build does not exclude non-production dependencies. Disposition: fix the build to exclude them — one build-file change clears the whole bucket.
- **Bucket E — production dependency at or above the fix.** Present in the production resolved tree at or above the fixed version; the scan predates the current lockfile. Disposition: request a rescan. An installed version equal to the scanned one lands E unconfirmed, since a rescan would report it again.
- **Bucket F — production dependency below the fix.** Present in the production resolved tree below the fixed version. Disposition: upgrade with `upgrade-deps`. A finding with no published fix, or whose installed and fixed versions cannot be ordered, lands here unconfirmed, with no upgrade to propose.

## The cascade

Three tiers, tested in order:

1. **Base-image layer?** A base finding the team cannot control is A; one the Dockerfile controls is B. Without the Dockerfile read, a base finding stays A unconfirmed — never B on a guess. A `global-module` or `runtime` finding is A unconfirmed even with the Dockerfile read, because its path cannot say whether the app installed it.
2. **In the resolved trees?** For a non-base finding: in neither tree is C, in the development tree only is D. A built-resolver ecosystem with no tree loaded (or both trees empty) gives `?`, needing a checkout; an ecosystem with no built resolver, an unknown PURL prefix, or an application path with no PURL gives `null`. Neither is one of the six. A package absent from both trees is C, never D — the two-tree differential is what separates "file an exception" from "fix the build", and a single "not installed" test cannot tell them apart.
3. **Version compare.** For a finding in the production tree: at or above the fix is E, below is F.

A team image builds on an inherited base but runs its own updates on top, so reassignment (A) is the exception: a base finding is B whenever the Dockerfile evidence shows the team controls it.

## The resolver interface

Each ecosystem supplies three primitives: a base-image-path test, the resolved production tree, and the resolved development tree with a version compare. npm is built (`npm ls --omit=dev --all` and `npm ls --all`, once per image). PyPI, NuGet, Gradle, and Maven are named and flagged when encountered; each resolver is built when a real image of its ecosystem first enters triage, because its expected-bucket fixture has to come from a real archived triage, not invented data.

Matching is name-exact — each name in a multi-name `Packages` cell against each tree key, never a substring, which produced the recorded false positive (`cssesc ^1.0.1` misread as `codecov 1.0.1`). The name that matched is the finding's `matched_package`, the only package field fit for a command.

## Guarding the destructive levers

The D lever (drop non-production dependencies) and the F lever (upgrade) can break a running application if the bucket is wrong. D requires positive evidence on both trees — present in development, absent from production — so the skill body passes both npm trees or neither: a failed production resolve beside a good development tree would read every production dependency as D. Every lever is a proposal a human runs; triage stops at disposition.

## Image identity

The key joining a ServiceNow CVIT row, a Twistlock/Prisma finding, and the image manifest is the bare image name: Twistlock `Repository` equals ServiceNow `image_repository` equals the manifest key. The Twistlock `Registry` host and `Tag` are not part of the key.
