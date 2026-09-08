# Runtime majors

Open this only for a major that moves the runtime itself — the language runtime, or the JDK. A framework or library major never reaches it.

## After a runtime major

Drop the backports the new runtime now ships (Python: `dataclasses`, `typing`, `pathlib`, `enum34`, `futures`, on the versions that include them) — a backport left pinned shadows the standard library, and the failure shows up as an import that resolves to the wrong module.

The inverse costs more and no manifest names it: a runtime major can also **stop shipping** a tool the build invokes. Corepack is distributed with Node.js from 14.19.0 up to but not including 25.0.0, so moving CI from Node 24 to 26 breaks every `corepack enable` step while `npm outdated`, `pnpm audit`, and every manifest stay silent — nothing lists it, because nothing depends on it. Before a runtime major, list what the current runtime bundles that this build invokes by name, and check each against the target's release notes; a tool that arrived with the runtime leaves with it and has no package to audit. On the JVM the same shape is the JDK: a major drops modules earlier releases still shipped (the `javax.*` set moved out to standalone artifacts), tightens strong encapsulation so reflective access that used to warn now fails, and retires tools the build shelled out to. The Gradle wrapper is its own major beside it, never folded in — [gradle.md](gradle.md) § Step 3: the wrapper and the toolchain are two different majors keeps the two apart, and its run-the-task-twice rule repeats at each intervening major a multi-major jump stops on.
