# Version gates

Three branch-gated rules for `upgrade-deps`, each opened from the step that names it.

## Registry release-age gate

Where the repo's `CLAUDE.md` `## Registry` block carries `Minimum release age:` (a curating proxy that refuses packages younger than it), that number replaces the 7-day floor, and a younger target is not merely held but uninstallable — the proxy will not serve it. Step 2's retarget then runs against the gate rather than the floor, and a package with no release clearing it defers with a review-by date of publish date plus the gate.

## Unattested publishers

Reached only by a package whose target carries no registry attestation and whose other checks are clean. The `## Registry` key `Unattested publishers: accept | ask | defer` settles it: `accept` takes the package on the tarball-versus-changelog result, recorded in the close, and clears the attestation together with the publisher identification that rests on it — on PyPI those are one fact, since the attestation is the only publisher source there. It never reaches a Publisher check that failed on its own: a lookup that errored, or the new or unknown account that bullet routes to **Review** and **Defer**, is untouched by this key, and on npm and NuGet the publisher is readable whether or not the release is attested; `defer` writes it to `docs/deps-deferred.md` ending `; no review-by date` in place of the date, since no date retires a missing attestation; `ask` — the value when the key is absent — puts the whole Review set to the user in one table at the end of step 2, each row carrying that tarball-versus-changelog result and any trusted-publishing workflow the source repo shows (`id-token: write` and a publish step), the evidence the user accepts in place of the registry's. The key never covers a target whose *previous* version was attested: that regression is **Review** under every value, because it is the one shape the attestation exists to catch.

## After a runtime major

Drop the backports the new runtime now ships (Python: `dataclasses`, `typing`, `pathlib`, `enum34`, `futures`, on the versions that include them) — a backport left pinned shadows the standard library, and the failure shows up as an import that resolves to the wrong module.
