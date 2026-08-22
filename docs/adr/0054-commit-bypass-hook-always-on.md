# The commit-bypass hook ships always-on, tokenising the command line

## Context

The rename-safety hook ([ADR-0053](0053-global-rules-layer.md)) is opt-in by directory because an in-place edit is sometimes the right tool and the opt-in says "not here". The second hook a hook could enforce surfaced in the same usage window: commits made with `--no-verify` when a pre-commit hook failed, which is the "step around the gate" move `committing`'s blocked-action protocol forbids in prose. A pre-commit hook is how a project's warnings reach the person landing the change; there is no directory where an agent stepping around one is the right tool, so the opt-in has nothing to express.

The first build matched shapes on the command text after deleting quoted strings, copied from rename-safety. The B4a review executed eight bypasses that passed — a quoted flag, `bash -c '…'`, `eval`, a variable, `xargs`, a unique prefix (`--no-veri`), and a lowercase config key — because deleting quoted text deletes the flag too, and a regex over the raw line cannot see a string handed to a nested shell.

## Decision

- **Always on, no opt-in.** The hook blocks three command-line shapes on any git invocation the Bash tool runs: `--no-verify` (and the unique prefixes git accepts), `-n` on `git commit` (alone or in a cluster), and `-c core.hooksPath=…` (any letter case) on a subcommand that runs hooks. It fails open with a stderr breadcrumb, like rename-safety.
- **Tokenise, don't strip.** The command is tokenised as a shell would (`shlex`), split into segments at `; && || | & ( )` and newlines, and each git segment's argument tokens are checked; a string handed to `bash -c`, `sh -c`, `eval`, a shell-fed heredoc, or `xargs git` is tokenised in turn; a variable assigned a bypass value in the same command blocks. Text inside a commit message, a note, a grep pattern, or a heredoc no shell consumes is text.
- **The contract is the three shapes, stated as such.** `git config core.hooksPath …` writes, `GIT_CONFIG_*` environment overrides, and edits to `.git/hooks/` are outside it: `setup-hooks.sh` is a legitimate `git config core.hooksPath` writer, and the environment and filesystem routes are not bypass flags on a command line. The header, `global/README.md`, and the selftest say what the hook does not see, so a reader never takes "always on" for "airtight".
- **`committing` is the depending skill** under the `global/` admission rule: its blocked-action protocol names the hook as the mechanical half of "a failing hook is a blocked action, never a reason for `--no-verify`".

## Considered Options

- **Opt-in by directory, like rename-safety** — rejected: there is no directory where the bypass is legitimate, so the opt-in would only be a way to turn the check off.
- **Block `git config … core.hooksPath` writes too** — rejected for now: the one known caller is the repo's own `setup-hooks.sh`, and an allow-row for that path would be the only thing distinguishing it from a bypass. Unparks if a bypass through `git config` is observed.
- **Keep the quote-stripping strip and patch the regexes** — rejected: the strip's defect is structural (the flag and the mention are both "quoted text"), and every patched regex would still be blind to nested shells. The tokeniser replaces it; rename-safety keeps the strip because its shapes (`sed -i`) are rarely quoted, and porting the tokeniser there is the deferred item below.

## Consequences

- A machine-wide blocking surface on every Bash call, once the user pastes the snippet — the consent is the paste, and `install.sh` prints one JSON object holding both hooks.
- The two hooks now differ in their quote handling on purpose; their payload parse and heredoc handling are still copies, and the third hook (or the rename-safety port) is where a shared `hook-lib.sh` is extracted.
- `global/README.md` states the roster and each contract; `README.md` keeps only the pointer and the admission sentence.

## Deferred

- Porting the tokeniser to `rename-safety.sh` (its `bash -c 'sed -i …'` hole) — the batch plan's B4a deferrals list, with the `hook-lib.sh` extraction decided there.

## Amendments

- **2026-08-22** — The third hook, `review-receipt` ([ADR-0059](0059-review-receipt-hook.md)), shipped without the `hook-lib.sh` extraction this record scheduled for it; the scan was copied and extended instead, and the trigger moved to the rename-safety tokeniser port. `install.sh` now prints one object holding three hooks.
