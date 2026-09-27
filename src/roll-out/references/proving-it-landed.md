# Proving a rung landed

Open this only at step 5, after the dark deploy, and again whenever a rung needs a redeploy. A rung that changes only who is exposed, with no new deploy, never opens it.

A deploy command's exit code says the command finished. It does not say the new code is serving, that its configuration arrived, or that it works. Run the four checks below, and the one before, each with its evidence.

## Before the deploy: is the host what git says it is?

Where anyone can change the host by hand, read its working tree before pulling or building on it: `git status --porcelain` and `git log -1 --format=%H` in the deployed checkout. Anything uncommitted is a fix that is not in git — committed first, or reported as drift. It is never overwritten silently, and never left as the only copy.

## After the deploy: four checks

1. **Revision.** What is serving is the commit you meant. Read the live revision's image digest or tag and check it with `git merge-base --is-ancestor <commit> <sha>`; on a managed platform, the deployment's recorded commit; on a plain host, the process's start time after the deploy and a string the change introduced present in what it serves. A version endpoint that reports the commit beats all of these.
2. **Configuration.** The variables and secrets the new code reads are present in the **running process**, counted by name against the list the code expects. Print names only, never values: a secret read into the transcript has left the process it was meant for. In a container, read the environment of the process the entrypoint started, not a new shell opened inside the container: that shell does not inherit it. A deploy flag that sets environment variables may replace the whole set, so check the ones you did not name are still there.
3. **Function.** One request that does the product's job and returns something comparable to a known value. A health endpoint proves the process is up, nothing more; behind single sign-on, every path, real or not, answers the same redirect, which proves nothing about a route.
4. **Startup errors.** The new revision's logs since it started, at warning and above. Zero lines is a finding only when you saw logs flowing at all.

## The block

Write this into the plan under the rung, one line per check. A check you could not run is `UNVERIFIABLE` with the reason, never omitted and never `PASS`.

```
<service> @ <commit>
  revision : PASS — serving <revision or deployment id> built from <sha>
  config   : PASS — 14/14 expected variables present in the running process
  function : PASS — <request> → <response>, <the known value it matched>
  startup  : PASS — 0 warning-or-above lines since <time>
```

A `FAIL` on any line means the rung is not open, whatever the deploy printed.
