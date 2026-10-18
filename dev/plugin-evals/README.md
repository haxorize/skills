# Description trigger tests (development only)

A **Trigger test** suite, in the sense `DOMAIN.md` registers. It measures whether a model-invoked skill's `description` makes Claude pick the skill on a casual request, and stay away on a near miss. `run.sh` builds a throwaway plugin in a temp directory from the skills in `skills.txt` (plus their `requires:` skills), copies `evals/` into it, and runs `claude plugin eval` with `--ablation none --no-publish`. The suite is not distributed as a plugin and `scripts/install.sh` never links anything here.

- **Run:** `bash dev/plugin-evals/run.sh` for the whole suite (9 cases × 3 runs by default), or `--case '<glob>' --runs 1` for one. Each run is a paid `claude -p` child on your credential; `--max-cost-usd <n>` caps it.
- **Read:** the table on stdout, and `results/<timestamp>/report.html` (gitignored).
- **Add a case:** a directory under `evals/` with a `prompt.md` (the request, phrased the way a user types it, never naming the skill) and one grader. `graders/fired.md` asserts a `Skill` call for the skill. `graders/quiet.md` asserts none, with `min: 0` and `max: 0`. Add the skill to `skills.txt` if it is new here.
- **Isolation:** each run starts in an empty workspace with only this plugin loaded (no settings, `CLAUDE.md`, memory, or global rules), so the score is the description's alone. Skills are namespaced `skills-dev:<name>`; the graders' regex accepts both forms.

Hand-run and ungated: no lint walk, selftest, or hook reads `dev/`.
