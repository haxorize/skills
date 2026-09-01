# Risk signals: what to scan for before you ask anything

Read this in the **Triage rung** — the rung spans turns, so "in Triage" below means anywhere in it, not one turn. The job is to arrive at the interview already knowing what to ask about, so the departing engineer's time goes only on what the repo genuinely cannot answer. Three passes, in order: **identify the person**, **neutralize the traps**, **collect the signals**. Skipping the middle pass is how this scan produces a register full of confident noise.

## Pass 1 — identify the departing author

Sole ownership cannot be computed until you know which identities are theirs; people commit under a work email, a personal email, a laptop whose `user.name` was a nickname, a GitHub `noreply` address.

```bash
git shortlog -sne --all                                   # every author, with counts and emails
git log --all --format='%an <%ae>' | sort -u | grep -i -e "<name-fragment>"   # -e: a name that starts with - is a pattern, not a flag
cat .mailmap 2>/dev/null                                  # an existing identity mapping
```

Confirm the set with the human in Triage — "I am treating these three identities as yours, is that right?" — before ranking anything; a missed alias silently understates their ownership and can hide their most exclusive work. Note bot and service accounts (`dependabot`, `github-actions`, release bots) to exclude them.

## Pass 2 — neutralize the traps

Each of these makes someone look like the author of code they never wrote. Handle them before computing anything.

- **Mass mechanical commits.** A repo-wide reformat, a lint autofix, a license-header sweep, or a find-and-replace rename reassigns blame for thousands of lines to whoever ran it. Find commits with an enormous file count and a trivial message, then ignore them: `git blame -w --ignore-rev <sha> <file>` (`-w` also ignores whitespace-only changes); `cat .git-blame-ignore-revs 2>/dev/null` — the repo may already list them.
- **File moves and renames.** Plain `git log <file>` stops dead at the rename, making long-lived code look new and its real author uninvolved. `git log --follow -- <file>` follows the file; `git blame -C -C -- <file>` detects lines moved or copied from other files.
- **Squash merges.** Where the repo squash-merges pull requests, every line in a PR is attributed to whoever pressed merge. Check whether merge commits share one author while `%an` on the underlying work differs; where the repo squashes, say so and treat every authorship count as *low* confidence for the whole scan. Tell the human, because it changes how much any ownership claim is worth.
- **Generated, vendored, and build output.** `node_modules/`, `vendor/`, `dist/`, `*.pb.go`, lockfiles, migrations a framework wrote: high line counts, zero tribal knowledge. Exclude them: `git log --format='%an' -- . ':(exclude)vendor' ':(exclude)dist' ':(exclude)*.lock'`.
- **Shallow or absent history.** A shallow clone (`git rev-parse --is-shallow-repository`), an exported tarball, or a repo freshly imported from elsewhere makes every git-derived signal meaningless. Say so in the first turn, fall back to the code-shape signals below (marked workarounds, magic constants, operational docs), and lean harder on the human's own sense of what is unusual.

## Pass 3 — collect the signals

Each signal carries a **confidence**. Respect it: a high-confidence signal can be asserted as `[fact]`; a low-confidence one is `[inference]` at best and is offered as "this looked odd — is it?", never as "this is a workaround".

1. **Sole authorship · High.** Files or directories where they are effectively the only author. Per file: `git log --format='%an' --follow -- <file> | sort | uniq -c | sort -rn`. Candidates, ranked by their share: `git log --author="<email>" --name-only --format= --all | sort | uniq -c | sort -rn | head -50`. A file where they hold nearly every commit *and* nobody else has touched it in a year is the strongest single signal on this list.
2. **Recency-weighted exclusivity · High.** Code only they have modified in the last 6–12 months is knowledge not yet shared with anyone, whoever wrote it originally: `git log --since="12 months ago" --format='%an' --follow -- <file> | sort -u` — one name, and it is theirs, is a high rank.
3. **Marked workarounds · High, the cheapest win.** The comments where someone already told you there is a story: `grep -rniE "TODO|FIXME|HACK|XXX|WORKAROUND|GOTCHA|do not (touch|change|remove)|don't (touch|change)|temporary|for now|leave this|magic|careful" . | grep -v node_modules`. Cross-reference each hit against authorship; prioritize the ones with no explanation attached and the ones whose "temporary" is measured in years (`git log -S "<comment text>"` dates it).
4. **Undocumented magic values · Medium-high.** Constants, thresholds, timeouts, retry counts, buffer sizes, flag names, and cron expressions with no comment, no test explaining them, and no derivation. Find the constant, then date it: `git log -S "TIMEOUT = 300" --format='%h %an %ad %s' -- <file>`. **The commit it arrived in is the question**: a number introduced beside "handle Stripe 5xx on capture" tells you what reading to offer, which is what turns recall into recognition. Rank higher when the value is unusual (90 seconds, not 60; 4 retries, not 3) and nothing else in the repo shares its shape.
5. **Reverts and failed experiments · High, badly underused.** `git log --all --format='%h %an %ad %s' | grep -iE "revert|roll ?back|back out|undo|didn't work|abandon"`, plus directories that appear and disappear and dependencies added then removed (`git log -p -- package.json | grep -E '^[-+].*"'`). Each is a "we tried X" worth one question, and the list is what a successor otherwise spends a quarter re-running.
6. **Deliberately retained dead code · Medium.** Code that looks unreachable but survived several of the author's own later commits was usually *kept on purpose*, and the purpose lives only in a head. Grep the definition and count call sites, then check whether the author touched the file after the code went dead. Offer it as a question, because "unreachable" is easy to get wrong with reflection, DI, dynamic dispatch, or plugin loading.
7. **Unmarked workarounds · Low — ask, never assert.** Code unusually complex relative to its neighborhood, on a path they solely own, with thin test coverage: a function far longer than its siblings, nested conditionals guarding specific values, a comment explaining *what* rather than *why*, a `sleep` in production code, a retry around something that should not need one, an unusually specific error string. Surface at most a handful, always as "this looked unusual — is there a story?", and drop them quickly on a no.
8. **In-flight work · High, decays fastest.** Feeds the In-flight rung, so scan it early: `git branch -a --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(authorname)'`; `git branch -a --no-merged main`; `git log --all --author="<email>" --since="3 months ago" --format='%h %ad %s'`; and messages implying a sequel: `git log --all --author="<email>" --format='%h %s' | grep -iE "wip|draft|part 1|first pass|temp|follow.?up"`. Check the hosting platform for open draft PRs and assigned issues where it is reachable; where it is not, ask directly — one question with a high yield.
9. **Operational knowledge · Medium.** `grep -rniE "manually|by hand|ssh into|run this|remember to|make sure to|before deploying|after deploying" --include="*.md" --include="*.txt" .`; `ls scripts/ bin/ ops/ tools/ 2>/dev/null` — one-off scripts are runbooks in disguise; `grep -rniE "cron|schedule" --include="*.y*ml" --include="*.tf" .`; alert and monitor definitions (what does this alert *mean*, and what do you do about it); anything in CI marked `continue-on-error` or `allow_failure`; deploy steps that need a human.
10. **External relationships and access · Medium.** Third-party clients and SDK imports, webhook endpoints, callback URLs, config keys naming vendors, OAuth app registrations, service accounts, DNS and certificate config. Each names an external party where a human relationship may exist and is about to lapse. Record **locations only, never values**: the question is "who owns this account and who can rotate this key", never "what is the key". Read a config or env file through a mask — `sed -E 's/=.*/=<masked>/' .env` — and keep it out of every diff you print (`git show <sha> -- . ':(exclude).env'`): a bare `cat .env` or a `git show` of the commit that added it puts the value in the session, and the trail is then one paste away from holding it.
11. **Inherited `[unknown]`s · Highest when present.** Where the successor pasted a KT map from `/onboard-me`, every `[unknown]` in it is a question a careful reader already failed to answer from the code — a pre-filtered, high-value set. Put them straight into the register near the top.

## Ranking the register

Order by **exclusivity × cost**, never by how interesting the code is.

- **Exclusivity** — how likely this knowledge exists nowhere else. *High*: only recent author, nothing documented, no test explains it. *Medium*: shared authorship but dominant, or a stale doc exists. *Low*: several active authors, or well covered by tests and comments.
- **Cost if lost** — what it does to whoever inherits it. *High*: touches money, auth, data integrity, or production stability; on a deadline; or wrong silently rather than loudly. *Medium*: real debugging time. *Low*: annoying to rediscover, cheap once you do.

Anything high × high goes to the top regardless of category; below that, prefer the ladder's order, because in-flight work expires and old landmines do not. Two adjustments: **promote silence** — a loud failure (a crash, a page) teaches the successor eventually, a silent one (wrong numbers, dropped records, a retry that quietly gives up) never does, so a silent risk outranks a loud one of the same size; **demote what a test already documents** — where a test asserts the behavior and names why, the knowledge is captured, so spend the human's time elsewhere.

| Signal | Rung |
| --- | --- |
| **8 — In-flight work** | In-flight and imminent |
| **3, 4, 6, 7 — Workarounds, magic values, dead code** | Landmines |
| **9 — Operational knowledge** | Operational reality |
| **5 — Reverts and failed experiments** | Decisions and dead ends |
| **10 — External relationships and access** | Relationships and access |
| **1, 2, 11 — Sole authorship, exclusivity, inherited unknowns** | Sole-ownership sweep |

## Sizing the scan

Do not inventory everything. A register of 200 items is less useful than one of 25, because the ranking is what makes it actionable and 200 items cannot be ranked. Aim for **15–30**, weighted toward the top, and say in Triage what you did not scan. On a large repo, scope to the areas they owned rather than the whole tree; on a monorepo, ask which services are theirs before scanning at all.
