# The interface an agent-driven CLI must carry

When the caller of a script or CLI is an agent or a CI job rather than a person at a terminal, the **Interface** — everything a caller must know to use it correctly — has to be readable by something that cannot see a screen, cannot answer a prompt, and will paste the output straight back into its next command. Each item below is a fact the caller would otherwise have to guess, and a guessed fact is a second run.

- **`--help` at every level.** The root command and every subcommand answer `--help` with their arguments, flags, and one example; the agent reads help before it reads source, and a subcommand with no help text is an interface it has to reverse-engineer.
- **A machine shape on request.** `--json` (or an equivalent) on every command that returns data, with a stable field set; prose output is for the person, and an agent parsing prose breaks on the first wording change.
- **Data on stdout, everything else on stderr.** Progress, warnings, and prompts never share the data stream; a caller doing `$(cmd)` or piping into `jq` gets only the result.
- **Every create prints its identifier.** "Task created." with no id forces a lookup the caller cannot always make; print the id, the path, or the URL that names what was made, on stdout, on its own line where the output is prose.
- **Non-interactive fails fast.** With no TTY, or when `--yes` / `--non-interactive` is passed, a step that would prompt exits non-zero with the flag or value it needed named in the error — it never blocks on a question nobody will answer.
- **`NO_COLOR` and no TTY are honoured.** No ANSI codes, spinners, or cursor movement when stdout is not a terminal or `NO_COLOR` is set, so the captured output is what a reader sees.
- **An exit-code taxonomy.** 0 for success, one code for usage errors, one for a failed precondition, one for a failed operation — documented in `--help` — so a caller branches on the number instead of grepping the message.
- **Bodies come from files.** A flag that takes a long value — a description, a body, a message — accepts `@path` so the caller never pushes a multi-line string through the shell; a description that must be passed inline is the interface asking for the quoting bug, and a path the flag cannot open is an error, never passed through as the literal `@…` with exit 0 (the `to-*` publishers' `publishing.md` states the caller's side of this rule).
- **Errors name the fix.** An error line states what was wrong and the flag, value, or command that would make it right; a message that only names the failure sends the caller back to `--help`.

Apply the checklist to a new CLI before its first caller lands, and to an existing one when an agent's transcript shows it retrying the same command with different guesses — each retry is worth checking against this list.

Deliberately not here: `--version`, `--dry-run`, stdin as input, config precedence, and streaming output — real interface questions, but none an agent guesses differently from a person. A script that walks a *person* through steps is the inverse audience and is `wizard`'s.
