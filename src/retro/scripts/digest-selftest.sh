#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/retro/scripts/digest.py counts what its header says, over a fixture
# projects directory, usage-data directory, history file, git repo and controls
# report built here, so a dropped alternative or a loosened guard reds a row.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
#
# What is graded. Signals: one human turn per SIGNALS alternative (21), each
# firing, a queued prompt firing, and clean neighbours that do not: a phrase
# inside a pasted block, a harness-injected <command-name> turn, an isMeta turn,
# a helper transcript's turn, and seven near misses (four of them the retired
# hook's false-positive guards). An interrupt, a denied tool call, two
# rename-safety blocks in one session (a repeat), one inline PreToolUse:Edit
# block and a Stop gate's blocking error, other tool errors, a Bash command
# repeated, a git restore, a file Read three times in one transcript (and one
# Read in each of three, not counted), one message's usage written on two
# entries (counted once), the closing-claim classes (edit with no check, check
# after the edit, an errored check, a check only before the edit, a marked
# claim, a helper's claim), session-meta's would-prompt count, facets'
# friction, one Revert commit in the repo the session ran in (also inside
# --since today), and seven control rows (held, failed, open on `-` and on
# `none`, unmeasured, a surface key holding level, a baseline row) plus a table
# whose columns are reordered. Corrections the keywords miss: a question right
# after a closing claim, the turn after an interrupt, a concession, skill loads
# charged inside three human turns (a Skill call, a slash command, an
# off-roster skill; a fourth-turn correction, /clear and /rename never), and a
# facet-flagged session nothing caught. Repeats: a prompt typed in three
# sessions and one long Bash shape across three sessions. Hooks: runs and
# milliseconds as a floor, never a Metrics key; the bytes three hooks added, an
# inline one under its event name; a sessions key for a hook past the top 8.
# Tokens, a workflow helper's included, peak context and the cache-read share.
# Result bytes against a sum the fixture computes. A compaction, and a helper's
# skipped. A memory index with an orphan, a dead link and a dead path, and one
# past 200 lines. Masking: every shape in the table masked and prose and paths
# kept; a hook message masked before its cut and a Bash shape before its digits
# flatten. A signed commit in a repo whose own config would run a program to
# check it, which never runs. --counts-only drops quotes, the Read path,
# program breakdowns and every off-roster skill or hook name. The window by
# mtime with a helper following its main session, --exclude-session on
# transcripts and history, the history window, --max-pointers, a --session
# prefix (none or two matches exit 3), and the 12 KB re-render at one pointer.
# PARTIAL for each source absent or failing: projects, usage-data, history, an
# unparsable line, an empty window, skill-usage.sh missing, failing or at a
# floor, a lint with no surface line, a Controls section missing (named in the
# banner). Exit codes 0, 2, 3 (no mode, both modes, a bad date, a bad session
# id, a negative --max-pointers, a missing --controls file, an unknown flag), 4
# for a crash. Skill fit's content and --surface, from stand-in producers.
#
# Mutation table: each alternative of SIGNALS dropped in turn (21 mutants), and
# one mutant per graded behaviour above (the list at the foot); every mutant
# must red its row, and the close line counts them.
#
# NOT covered, so a clean run here is not a claim about it: core.hooksPath,
# since neither git call the digest makes runs a hook, so its mutant is
# equivalent.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="src/retro/scripts/digest.py"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp=$(selftest_tmpdir) || selftest_no_tmpdir digest-selftest.sh
trap 'rm -rf "$tmp"' EXIT

sid=aaaaaaaa-1111-2222-3333-444444444444
proj="$tmp/projects/-fixture"
mkdir -p "$proj/$sid/subagents/workflows/w1" "$proj/memory" "$tmp/usage/session-meta" "$tmp/usage/facets" "$tmp/repo" \
  "$tmp/skills/tdd" "$tmp/skills/x" "$tmp/skills/late"
git -C "$tmp/repo" init -q
# A signed commit, and repo config that would run a program to check it: the digest's
# git calls must never fire it.
printf '#!/bin/sh\necho "[GNUPG:] SIG_CREATED " >&2\nprintf -- "-----BEGIN PGP SIGNATURE-----\\nx\\n-----END PGP SIGNATURE-----\\n"\n' > "$tmp/fake-gpg"
printf '#!/bin/sh\ntouch "%s/gpg-fired"\nexit 1\n' "$tmp" > "$tmp/marker-gpg"
chmod +x "$tmp/fake-gpg" "$tmp/marker-gpg"
git -C "$tmp/repo" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t -c gpg.program="$tmp/fake-gpg" -c user.signingkey=x \
  commit -q --allow-empty -S -m 'A signed commit'
git -C "$tmp/repo" config log.showSignature true
git -C "$tmp/repo" config gpg.program "$tmp/marker-gpg"
git -C "$tmp/repo" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t commit -q --allow-empty -m 'Revert "a change"'
git -C "$tmp/repo" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t commit -q --allow-empty -m 'Not a revert'

FIX="$tmp" SID="$sid" python3 -I - <<'EOF'
import json, os
fix, sid = os.environ["FIX"], os.environ["SID"]
proj = os.path.join(fix, "projects", "-fixture")
cwd = os.path.join(fix, "repo")
samples = ["ok no, don't touch that", "ok I said keep it", "ok don't do that again", "ok never do that",
           "ok from now on use bash", "ok that's not what I meant", "ok that is not what I asked",
           "ok undo that change", "ok revert it please", "ok I didn't ask for this", "ok why did you delete it",
           "ok stop adding comments", "ok hold up, one thing", "ok wait, why is it red", "ok I don't want follow-ups",
           "ok you didn't run the tests", "ok are you serious", "ok why would you push", "ok can't you just rerun it",
           "Shouldn't we review first?", "I wanted you to ask first"]
quiet = ["ok wait for the build", "ok I want to add a test", "now is fine",
         "hold on to that value for later", "I don't want to bother you", "you didn't do anything wrong",
         "so why would you need that",
         "<pasted_content id='x'>from now on, always</pasted_content> thoughts?",
         "<command-name>/x</command-name> I said so"]
out = []
shape_cmd = "git -C /repo log --oneline --since=2026-10-%02d --format='%%h %%s' | grep -v -e Merge -e fixup | head -n %d; curl -u me:Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z0Q"
def user(text):
    out.append({"type": "user", "cwd": cwd, "message": {"role": "user", "content": text}})
def asst(blocks, mid, usage=None):
    out.append({"type": "assistant", "cwd": cwd, "message": {"id": mid, "role": "assistant", "content": blocks, "usage": usage or {}}})
def result(tid, text, err=True):
    out.append({"type": "user", "cwd": cwd, "message": {"role": "user", "content": [{"type": "tool_result", "tool_use_id": tid, "is_error": err, "content": text}]}})
def tool(tid, name, inp, mid):
    asst([{"type": "tool_use", "id": tid, "name": name, "input": inp}], mid)
tool("s1", "Skill", {"skill": "tdd"}, "ms1")
for s in samples + quiet + ["<command-name>/clear</command-name>", "<command-name>/rename</command-name>"]:
    user(s)
open(os.path.join(fix, "first-signal-line"), "w").write("2")   # line 1 is the Skill call
user("[Request interrupted by user]")
open(os.path.join(fix, "interrupt-line"), "w").write("%d" % len(out))
user("do the work with ghp_ABCDEFGHIJKLMNOPQRSTUVWX1234 on retro-improvements-for-round-2026-10-12 at /a/Users-Abc-0123456789-abcdefghijklmnop")
out.append({"type": "attachment", "attachment": {"type": "queued_command", "commandMode": "prompt", "origin": {"kind": "human"}, "prompt": "ok stop using sed"}})
out.append({"type": "user", "isMeta": True, "cwd": cwd, "message": {"role": "user", "content": "ok I said so"}})
user("x" * 5001)
out.append({"type": "system", "subtype": "compact_boundary", "isSidechain": True, "compactMetadata": {"trigger": "auto"}})
out.append({"type": "attachment", "attachment": {"type": "hook_blocking_error", "hookName": "Stop", "blockingError": {
    "command": "bash /x/stop-gate.sh", "blockingError": "stop-gate: " + "x" * 85 + " ghp_ABCDEFGHIJKLMNOPQRSTUVWX1234 and AbCdEfGh1234567890AbCdEfGh12345678"}}})
tool("t1", "Bash", {"command": "rm x"}, "m1")
result("t1", "The user doesn't want to proceed with this tool use. Do it another way.")
tool("t2", "Bash", {"command": "sed -i s/a/b/ f"}, "m2")
result("t2", "PreToolUse:Bash hook error: [bash /x/global/hooks/rename-safety.sh]: rename-safety: blocked an in-place edit")
tool("t3", "Bash", {"command": "sed -i s/a/b/ f"}, "m3")
result("t3", "PreToolUse:Bash hook error: [bash /x/global/hooks/rename-safety.sh]: rename-safety: blocked an in-place edit")
tool("t4", "Edit", {"file_path": "/f"}, "m4")
result("t4", "PreToolUse:Edit hook error: blocked by policy")
tool("t5", "Bash", {"command": "false"}, "m5")
result("t5", "Exit code 1")
out.append({"type": "attachment", "attachment": {"type": "hook_success", "hookName": "PreToolUse:Bash", "command": "bash /x/global/hooks/rename-safety.sh", "durationMs": 10, "stdout": "12345", "content": ""}})
out.append({"type": "attachment", "attachment": {"type": "hook_additional_context", "hookName": "SessionStart", "content": ["abcdefghij"]}})
out.append({"type": "attachment", "attachment": {"type": "hook_success", "hookName": "PostToolUse:Edit", "command": "f() { echo; }", "stdout": "abc"}})
for i in range(2):
    out.append({"type": "system", "subtype": "stop_hook_summary", "hookInfos": [{"command": "bash /x/global/hooks/context-nudge.py", "durationMs": 50}]})
out.append({"type": "system", "subtype": "compact_boundary", "compactMetadata": {"trigger": "manual", "preTokens": 9, "postTokens": 1}})
tool("t6", "Bash", {"command": "git restore f"}, "m6")
result("t6", "", err=False)
for i in range(3):
    tool("r%d" % i, "Read", {"file_path": "/secret/path/notes.md"}, "mr%d" % i)
    result("r%d" % i, "text", err=False)
asst([{"type": "text", "text": "thinking"}], "mu", {"input_tokens": 100, "cache_read_input_tokens": 300, "cache_creation_input_tokens": 0, "output_tokens": 50})
asst([{"type": "text", "text": "same message"}], "mu", {"input_tokens": 100, "cache_read_input_tokens": 300, "cache_creation_input_tokens": 0, "output_tokens": 50})
user("fix it")
tool("e1", "Edit", {"file_path": "/a"}, "me1")
result("e1", "ok", err=False)
asst([{"type": "text", "text": "Done, all tests pass."}], "me2")
user("and the other")
tool("e2", "Edit", {"file_path": "/b"}, "me3")
result("e2", "ok", err=False)
tool("c1", "Bash", {"command": "bash scripts/lint-skills.sh"}, "me4")
result("c1", "OK", err=False)
asst([{"type": "text", "text": "Lint is clean."}], "me5")
user("did you run the selftest too?")
asst([{"type": "text", "text": "You're right, I skipped it."}], "me6")
asst([{"type": "text", "text": "I think you're right about the order."}], "me7")
tool("s2", "Skill", {"skill": "late"}, "ms2")
for t in ("fine one", "fine two", "fine three"):
    user(t)
tool("s3", "Skill", {"skill": "jane-doe-123"}, "ms3")
user("ok wait, why is that red")
tool("b1", "Bash", {"command": shape_cmd % (1, 5)}, "mb1")
result("b1", "", err=False)
tool("g1", "Grep", {"pattern": "x"}, "mg1")
result("g1", "y" * 1000, err=False)
tool("rs", "Read", {"file_path": "/shared/CLAUDE.md"}, "mrs")
result("rs", "z", err=False)
user("check it")
asst([{"type": "text", "text": "UNVERIFIED: tests pass"}], "mk1")
user("go")
tool("e3", "Edit", {"file_path": "/c"}, "mk2")
result("e3", "ok", err=False)
tool("k1", "Bash", {"command": "pytest -x"}, "mk3")
result("k1", "Exit code 1")
asst([{"type": "text", "text": "The tests pass."}], "mk4")
user("again")
tool("k2", "Bash", {"command": "pytest -q"}, "mk5")
result("k2", "ok", err=False)
tool("e4", "Edit", {"file_path": "/d"}, "mk6")
result("e4", "ok", err=False)
asst([{"type": "text", "text": "All green."}], "mk7")
def write(path, rows):
    with open(path, "w") as f:
        f.write("\n".join(json.dumps(e) for e in rows) + "\n")
write(os.path.join(proj, sid + ".jsonl"), out)
results = sum(len(b["content"]) for e in out if e["type"] == "user" and isinstance(e["message"]["content"], list)
              for b in e["message"]["content"] if b.get("type") == "tool_result")
for k, other in ((2, "bbbbbbbb-1111-2222-3333-444444444444"), (3, "cccccccc-1111-2222-3333-444444444444")):
    rows = [{"type": "user", "cwd": cwd, "message": {"role": "user", "content": "please continue" if k == 2 else "ok hold up, there"}},
            {"type": "assistant", "cwd": cwd, "message": {"id": "o%d" % k, "role": "assistant", "content": [
                {"type": "tool_use", "id": "o%d" % k, "name": "Bash", "input": {"command": shape_cmd % (k, k + 5)}},
                {"type": "tool_use", "id": "q%d" % k, "name": "Read", "input": {"file_path": "/shared/CLAUDE.md"}}]}}]
    write(os.path.join(proj, other + ".jsonl"), rows)
open(os.path.join(fix, "result-bytes"), "w").write(str(results))
json.dump({"friction_counts": "{'wrong_approach': 1}", "friction_detail": "Claude ignored the plan; token=supersecretvalue123 was in it"},
          open(os.path.join(fix, "usage", "facets", "bbbbbbbb-1111-2222-3333-444444444444.json"), "w"))
json.dump({"friction_counts": "{'wrong_approach': 1}", "friction_detail": "caught by a signal"},
          open(os.path.join(fix, "usage", "facets", "cccccccc-1111-2222-3333-444444444444.json"), "w"))
mem = os.path.join(proj, "memory")
open(os.path.join(mem, "MEMORY.md"), "w").write("# Memory\n\n- [A](a.md) — one\n- [Gone](missing.md) — two\n")
open(os.path.join(mem, "a.md"), "w").write("See /Users/nobody-zz/never/here.md and ~/.\n")
open(os.path.join(mem, "b.md"), "w").write("an orphan\n")
with open(os.path.join(proj, sid, "subagents", "agent-1.jsonl"), "w") as f:
    f.write(json.dumps({"type": "user", "message": {"role": "user", "content": "ok I said so"}}) + "\n")
write(os.path.join(proj, sid, "subagents", "workflows", "w1", "agent-2.jsonl"), [
    {"type": "user", "message": {"role": "user", "content": "do the step"}},
    {"type": "assistant", "message": {"id": "h1", "role": "assistant", "content": [{"type": "text", "text": "All tests pass."}],
                                      "usage": {"input_tokens": 10, "output_tokens": 5}}}])
json.dump({"bash_would_prompt_count": 4, "git_commits": 1, "git_pushes": 0}, open(os.path.join(fix, "usage", "session-meta", sid + ".json"), "w"))
json.dump({"friction_counts": "{'buggy_code': 2}", "friction_detail": "seen"}, open(os.path.join(fix, "usage", "facets", sid + ".json"), "w"))
with open(os.path.join(fix, "history.jsonl"), "w") as f:
    f.write(json.dumps({"display": "/retro", "timestamp": 1760000000000, "sessionId": sid}) + "\n")
    for k, s2 in enumerate((sid, "bbbbbbbb-1111-2222-3333-444444444444", "cccccccc-1111-2222-3333-444444444444")):
        for text in ("Address the parked items now, all of them", "/retro --round and then the whole audit", "short one"):
            f.write(json.dumps({"display": text + ("!" if k else ""), "timestamp": 1760000000000 + k, "sessionId": s2}) + "\n")
with open(os.path.join(fix, "prev-retro.md"), "w") as f:
    f.write("# prev\n\n## Controls\n\n| id | metric | value at proposal | landed sha | status |\n|---|---|---|---|---|\n"
            "| C1 | `signals` | 99 | abc1234 | open |\n| C2 | `denials` | 0 | abc1234 | open |\n"
            "| C3 | `signals` | 99 | - | open |\n| C4 | `nope` | 5 | abc1234 | open |\n"
            "| C5 | `surface.hook_context.bytes` | 18 | abc1234 | open |\n| C6 | `hook_blocks` | 5 | baseline | open |\n"
            "| C7 | `signals` | 99 | none | open |\n\n## Next\n")
with open(os.path.join(fix, "reordered-retro.md"), "w") as f:
    f.write("## Controls\n\n| metric | id | landed sha | value at proposal |\n|---|---|---|---|\n| `denials` | R1 | abc1234 | 0 |\n")
open(os.path.join(fix, "no-controls.md"), "w").write("# prev\n\n## Next\n")
EOF

args=(--since 2000-01-01 --projects "$tmp/projects" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" --controls "$tmp/prev-retro.md"
      --skills "$tmp/skills")

# run_digest <script> [extra args…] — the digest on stdout, the exit code in rc
run_digest() { local s="$1"; shift; out=$(python3 -I "$s" "${args[@]}" "$@" 2>/dev/null); rc=$?; }

# grade_counts <script> — the rows every mutant targets one of
grade_counts() {
  rm -f "$tmp/gpg-fired"
  run_digest "$1"
  selftest_check "no program from the repo's own git config runs" [ ! -e "$tmp/gpg-fired" ]
  expect_row "$out" "signals: 21 alternatives, a late turn, a queued prompt and a second session fire; 9 quiet turns, an isMeta turn and the helper do not" "signals 24"
  expect_row "$out" "a per-session key" "signals.per_session 8.0"
  expect_in "$out" "a session:line pointer" "- interrupts: 1 (aaaaaaaa:$(cat "$tmp/interrupt-line"))"
  expect_row "$out" "a paste over 5,000 characters" "pastes_over_5000 1"
  expect_row "$out" "peak context" "peak_context.max 400"
  expect_in "$out" "helper tokens, a workflow helper's included, and the cache-read share" "tokens: 450 main, 15 helpers; cache-read share 73%"
  expect_in "$out" "a workflow helper a directory deeper is read" "Sessions: 3 main, 2 helper transcripts."
  expect_row "$out" "a Stop gate's blocking error is a block" "hook.stop-gate 1"
  expect_row "$out" "block sessions, a key for every hook" "hook.rename-safety.sessions 1"
  expect_in "$out" "a hook message is quoted, masked before its cut" "1 x stop-gate: \"stop-gate: $(printf 'x%.0s' $(seq 85)) [ma\""
  reject_in "$out" "no token head survives a hook message's cut" "x ghp"
  reject_in "$out" "a Bash shape is masked before its digits flatten" "curl -u me:Ab"
  expect_in "$out" "an inline hook takes its event name" "PostToolUse:Edit 3 bytes over 1 events"
  expect_in "$out" "claim classes: marked, an errored check, a check before the edit" "- main: 5 closing claims; check-after-last-edit 1, check-only-before-edit-or-errored 2, edit-no-check 1, marked 1"
  expect_in "$out" "a helper's claim folds to the helper side" "- helper: 1 closing claims; no-edit-no-check 1"
  expect_row "$out" "the baseline rows, ready to paste" "| B3 | \`hook_blocks.per_session\` | 1.333 | baseline | open |"
  expect_row "$out" "memory index lines" "memory.index_lines 4"
  expect_in "$out" "an off-roster skill load in the full digest" "jane-doe-123 1 of 1 loads"
  mask_out=$(python3 -I - "$1" <<'PY'
import importlib.util, sys
sp = importlib.util.spec_from_file_location("digest", sys.argv[1]); d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
# Token shapes are joined at run time, as staged-secrets-selftest.sh builds its
# fixtures, so no committed line is token-shaped.
cases = {"sk" + "-abcdefghijklmnop1234": "abcdefghijklmnop", "AKIA" + "ABCDEFGHIJKLMNOP": "ABCDEFGHIJKLMNOP", "bearer abcdefghijklmnopqr": "abcdefghijklmnopqr",
         "eyJ" + "hbGciOiJI." + "eyJ" + "zdWIiOiIx.SflKxwRJSMeK": "SflKxw", "a" * 40: "a" * 40, "export GH_TOKEN=plainvalue": "plainvalue",
         "DB_PASSWORD=plainvalue": "plainvalue", "--password plainvalue": "plainvalue", "https://user:pa55@host": "pa55",
         "Authorization: Basic dXNlcjpwYXNz": "dXNlcjpwYXNz", "k wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY": "wJalrXUtnFEMI",
         "glpat" + "-abcdefghij1234567890": "abcdefghij12", "AIza" + "SyA1234567890abcdefghijklmnopqrstu": "SyA1234"}
bad = [k for k, v in cases.items() if v in d.mask(k)]
keep = ["a basic check of tokens: 5", "src/retro/scripts/digest.py", "retro-improvements-for-round-2026-10-12"]
bad += [k for k in keep if d.mask(k) != k]
print("mask-ok" if not bad else "unmasked or over-masked: %r" % bad)
PY
)
  expect_row "$mask_out" "every secret shape masked, prose and paths kept" "mask-ok"
  expect_row "$out" "interrupts" "interrupts 1"
  expect_row "$out" "denials" "denials 1"
  expect_row "$out" "rename-safety blocks" "hook.rename-safety 2"
  expect_in "$out" "repeat per session" "rename-safety blocked (1 sessions, 1 with a repeat): 2"
  expect_row "$out" "inline hook" "hook.PreToolUse:Edit 1"
  expect_row "$out" "other tool errors" "tool_errors 2"
  expect_row "$out" "bash retry" "bash_retries 1"
  expect_row "$out" "restores" "restores 1"
  expect_row "$out" "files read over twice in one transcript; once in each of three is not" "files_read_over_twice 1"
  expect_row "$out" "one message id counted once" "tokens.total 465"
  expect_row "$out" "claim with an edit and no check" "claims.main.edit_no_check 1"
  expect_in "$out" "claim after a check" "check-after-last-edit 1"
  expect_row "$out" "would-prompt" "meta.bash_would_prompt_count 4"
  expect_in "$out" "facet friction" "friction: buggy_code 2"
  expect_row "$out" "revert commit" "reverts 1"
  expect_row "$out" "control held" "| C1 | \`signals\` | 99 | 24 | held |"
  expect_row "$out" "control failed" "| C2 | \`denials\` | 0 | 1 | failed |"
  expect_row "$out" "control open" "| C3 | \`signals\` | 99 | 24 | open |"
  expect_row "$out" "control open on a none sha" "| C7 | \`signals\` | 99 | 24 | open |"
  expect_row "$out" "a surface key holding level is held" "| C5 | \`surface.hook_context.bytes\` | 18 | 18 | held |"
  expect_row "$out" "a baseline row is graded" "| C6 | \`hook_blocks\` | 5 | 4 | held |"
  expect_row "$out" "controls tally" "- held 3, failed 1, open 2, unmeasured 1"
  expect_row "$out" "question after a closing claim; a plain turn after one is not" "after_claim 1"
  expect_row "$out" "the turn after an interrupt" "after_interrupt 1"
  expect_row "$out" "a concession opens the turn; mid-sentence does not" "concessions 1"
  expect_row "$out" "skill loads charged inside three turns; /clear, /rename and a fourth-turn correction not" "skill_corrections 3"
  expect_in "$out" "a Skill call charged" "tdd 1 of 1 loads"
  expect_row "$out" "a flagged session nothing caught; one a signal caught is not" "facet_missed 1"
  expect_in "$out" "its facet detail, masked" "token=[masked]"
  expect_row "$out" "a prompt typed in three sessions; a slash command and a short one not" "history_repeats 1"
  expect_row "$out" "a long Bash shape across three sessions" "bash_shapes_repeated 1"
  expect_in "$out" "hook runs and milliseconds from a Stop summary, as a floor" "context-nudge ran 2+ times in 1+ sessions, 100+ ms in all, blocked 0"
  expect_in "$out" "hook runs from a hook_success" "rename-safety ran 1+ times in 1+ sessions, 10+ ms in all, blocked 2"
  reject_in "$out" "hook runs are never a Metrics key" "hookrun."
  expect_row "$out" "bytes hooks added" "surface.hook_context.bytes 18"
  expect_row "$out" "result bytes" "result_bytes.total $(cat "$tmp/result-bytes")"
  expect_row "$out" "a compaction" "compactions 1"
  expect_row "$out" "memory orphan" "memory.orphans 1"
  expect_row "$out" "memory dead link" "memory.dead_links 1"
  expect_row "$out" "memory dead path" "memory.dead_paths 1"
  expect_in "$out" "a secret is masked; a long lowercase name and a path segment are not" "do the work with [masked] on retro-improvements-for-round-2026-10-12 at /a/Users-Abc-0123456789-abcdefghijklmnop"
  reject_in "$out" "no secret survives" "ghp_ABCD"
  expect_row "$out" "control unmeasured" "| C4 | \`nope\` | 5 | - | unmeasured |"
  expect_in "$out" "a quote in the full digest" "\"ok I said keep it\""
  run_digest "$1" --counts-only
  reject_in "$out" "counts-only drops quotes" "keep it"
  reject_in "$out" "counts-only drops the Read path" "/secret/path"
  reject_in "$out" "counts-only drops hook messages" "blocked an in-place"
  reject_in "$out" "counts-only drops facet detail" "ignored the plan"
  reject_in "$out" "counts-only drops retyped prompts" "parked items"
  reject_in "$out" "counts-only drops command shapes" "grep -v"
  reject_in "$out" "counts-only drops Bash bytes by program" "Bash by program"
  reject_in "$out" "counts-only drops retries by program" "  - by program:"
  reject_in "$out" "counts-only holds no off-roster skill name" "jane-doe"
  reject_in "$out" "counts-only holds no off-roster hook name" "stop-gate"
  expect_in "$out" "counts-only names an off-roster skill other" "other 1 of 1 loads"
  expect_row "$out" "counts-only keys an off-roster hook other" "hook.other 1"
  expect_row "$out" "counts-only still counts" "signals 24"
  run_digest "$1" --controls "$tmp/reordered-retro.md"
  expect_row "$out" "a Controls table is read by its header, not its column order" "| R1 | \`denials\` | 0 | 1 | failed |"
}

grade_counts "$script"
run_digest "$script"
expect_rc "the fixture digests clean" 0 "$rc"

# Exit codes.
python3 -I "$script" --help >/dev/null 2>&1; expect_rc "--help" 0 $?
python3 -I "$script" >/dev/null 2>&1; expect_rc "no mode" 3 $?
python3 -I "$script" --since 2000-01-01 --session "$sid" >/dev/null 2>&1; expect_rc "both modes" 3 $?
python3 -I "$script" --since 2000-13-01 >/dev/null 2>&1; expect_rc "bad date" 3 $?
python3 -I "$script" --session '../x' >/dev/null 2>&1; expect_rc "bad session id" 3 $?
python3 -I "$script" --since 2000-01-01 --max-pointers -1 >/dev/null 2>&1; expect_rc "a negative --max-pointers" 3 $?
python3 -I "$script" --session zzzzzzzz --projects "$tmp/projects" >/dev/null 2>&1; expect_rc "a --session matching no session" 3 $?
out=$(python3 -I - "$script" "${args[@]}" 2>&1 <<'PY'
import json, runpy, sys
json.loads = None   # any crash inside the run
sys.argv = sys.argv[1:]
runpy.run_path(sys.argv[0], run_name="__main__")
PY
); expect_rc "the script crashing" 4 $?
expect_in "$out" "a crash names its exception" "digest.py: crashed (TypeError)"
out=$(python3 -I - "$script" "${args[@]}" 2>/dev/null <<'PY'
import importlib.util, sys
sp = importlib.util.spec_from_file_location("digest", sys.argv[1]); d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
d.MAX_BYTES = 2000
d.main(sys.argv[1:])
PY
)
expect_in "$out" "past the byte limit, one pointer per count, said in the header" "Pointers capped to 1 (12 KB limit)."
expect_row "$out" "the capped render keeps one pointer" "- correction-shaped human turns: 24 (aaaaaaaa:$(cat "$tmp/first-signal-line"))"
python3 -I "$script" --since 2000-01-01 --controls "$tmp/none.md" >/dev/null 2>&1; expect_rc "missing --controls" 3 $?
python3 -I "$script" --since 2000-01-01 --bogus >/dev/null 2>&1; expect_rc "unknown flag" 3 $?
out=$(python3 -I "$script" --since 2000-01-01 --projects "$tmp/absent" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" 2>/dev/null); expect_rc "absent projects dir" 2 $?
expect_in "$out" "absent projects named" "projects directory absent"
cp "$proj/$sid.jsonl" "$tmp/keep.jsonl"
printf '{"type": "user", "message":\n' >> "$proj/$sid.jsonl"
run_digest "$script"
expect_rc "an unparsable line" 2 "$rc"
expect_in "$out" "the unparsable line named" "1 unparsable line(s) in aaaaaaaa"
cp "$tmp/keep.jsonl" "$proj/$sid.jsonl"
out=$(python3 -I "$script" --session "$sid" --projects "$tmp/projects" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" 2>/dev/null)
expect_in "$out" "session mode reads the session" "signals 23"
expect_in "$out" "session mode reads only that session's history" "history_repeats 0"
expect_in "$out" "session mode scope" "# Retro digest: session aaaaaaaa"
expect_in "$out" "session mode prints skill fit as not measured" "not measured in --session mode"

# grade_variants <script> — the rows a second source tree or a flag changes
grade_variants() {
  run_digest "$1" --max-pointers 1
  expect_row "$out" "--max-pointers caps each count's pointers" "- correction-shaped human turns: 24 (aaaaaaaa:$(cat "$tmp/first-signal-line"))"
  run_digest "$1" --exclude-session cccccccc-1111-2222-3333-444444444444
  expect_row "$out" "--exclude-session drops a session's transcript" "signals 23"
  expect_row "$out" "--exclude-session drops a session's history" "history_repeats 0"
  run_digest "$1" --since 2026-01-01
  expect_row "$out" "the history window" "history_repeats 0"
  run_digest "$1" --since "$(date +%Y-%m-%d)"
  expect_row "$out" "a revert made earlier today is inside --since today" "reverts 1"
  out=$(python3 -I "$1" --since 2000-01-01 --projects "$tmp/projects" --usage-data "$tmp/absent" --history "$tmp/absent.jsonl" \
        --skills "$tmp/skills" --controls "$tmp/no-controls.md" 2>/dev/null); rc=$?
  expect_rc "absent sources and a report with no Controls section" 2 "$rc"
  expect_in "$out" "usage-data absent named" "usage-data directory absent"
  expect_in "$out" "history absent named" "history file absent"
  expect_in "$out" "facets under half" "under half covered"
  expect_in "$out" "the banner names a Controls partial too" "--controls report has no ## Controls section"
  run_digest "$1" --since 2099-01-01
  expect_in "$out" "an empty window named" "no transcript in the window"
  # p2: session c and the main session's first helper written in 2001, a second
  # session sharing the main one's prefix, and a memory index past 200 lines
  out=$(python3 -I "$1" --since 2010-01-01 --projects "$tmp/p2" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" --skills "$tmp/skills" 2>/dev/null)
  expect_in "$out" "the window reads by mtime, and a helper follows its main session" "Sessions: 3 main, 2 helper transcripts."
  expect_row "$out" "an old session is out of the window" "signals 23"
  expect_in "$out" "a memory index past 200 lines" "past 200, the rest does not load"
  out=$(python3 -I "$1" --session "$sid" --projects "$tmp/p2" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" --skills "$tmp/skills" 2>/dev/null)
  expect_in "$out" "session mode reads a helper whatever its mtime" "Sessions: 1 main, 2 helper transcripts."
  out=$(python3 -I "$1" --session aaaaaaaa --projects "$tmp/p2" 2>&1); rc=$?
  expect_rc "a --session prefix matching two sessions" 3 "$rc"
  expect_in "$out" "the matches are named" "--session matches 2 sessions: aaaaaaaa-1111-2222-3333-444444444444, aaaaaaaa-9999"
  out=$(python3 -I "$1" --since 2000-01-01 --projects "$tmp/p3" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" --skills "$tmp/skills" 2>/dev/null)
  expect_row "$out" "a hook past the top 8 still has its sessions key" "hook.h9.sessions 1"
}
cp -R "$tmp/projects" "$tmp/p2"
touch -t 200101010000 "$tmp/p2/-fixture/cccccccc-1111-2222-3333-444444444444.jsonl" "$tmp/p2/-fixture/$sid/subagents/agent-1.jsonl"
printf '{"type": "user", "message": {"role": "user", "content": "a quiet session"}}\n' > "$tmp/p2/-fixture/aaaaaaaa-9999-2222-3333-444444444444.jsonl"
seq 201 | sed 's/^/- line /' > "$tmp/p2/-fixture/memory/MEMORY.md"
mkdir -p "$tmp/p3/-fixture"
python3 -I - "$tmp/p3/-fixture/dddddddd-1111-2222-3333-444444444444.jsonl" <<'PY'
import json, sys
rows = []
for i in range(1, 10):
    rows.append({"type": "assistant", "message": {"id": "a%d" % i, "role": "assistant", "content": [{"type": "tool_use", "id": "t%d" % i, "name": "Bash", "input": {"command": "x"}}]}})
    rows.append({"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "tool_use_id": "t%d" % i, "is_error": True,
                 "content": "PreToolUse:Bash hook error: [bash /x/h%d.sh]: no" % i}]}})
open(sys.argv[1], "w").write("\n".join(json.dumps(r) for r in rows) + "\n")
PY
grade_variants "$script"

# Skill fit's content and --surface, from a tree whose two producer scripts are
# stand-ins printing a fixed answer.
fake="$tmp/fake"
mkdir -p "$fake/scripts" "$fake/src/retro/scripts"
cp "$script" "$fake/src/retro/scripts/digest.py"
printf '#!/bin/sh\necho %s\nexit 2\n' "'[{\"skill\": \"never\", \"typed\": 0, \"loaded\": 0}, {\"skill\": \"quiet\", \"typed\": 0, \"loaded\": 3}]'" > "$fake/scripts/skill-usage.sh"
printf '#!/bin/sh\necho "launch-loaded surface: 1234 bytes"\n' > "$fake/scripts/lint-skills.sh"
run_digest "$fake/src/retro/scripts/digest.py" --surface
expect_in "$out" "skill fit: typed and loaded none" "- typed 0 and loaded 0 (1): never"
expect_in "$out" "skill fit: loaded, never typed" "- loaded, never typed (1): quiet"
expect_in "$out" "skill-usage.sh's floor exit is a PARTIAL" "skill-usage.sh counted a floor (exit 2)"
expect_row "$out" "--surface reads the lint's surface line" "surface.bytes 1234"
printf '#!/bin/sh\necho "[]"\nexit 1\n' > "$fake/scripts/skill-usage.sh"
printf '#!/bin/sh\necho reworded\n' > "$fake/scripts/lint-skills.sh"
run_digest "$fake/src/retro/scripts/digest.py" --surface
expect_in "$out" "skill-usage.sh's failure is a PARTIAL" "skill-usage.sh exited 1"
expect_in "$out" "a reworded surface line is a PARTIAL" "lint-skills.sh printed no surface line"
rm "$fake/scripts/skill-usage.sh"
run_digest "$fake/src/retro/scripts/digest.py"
expect_in "$out" "skill-usage.sh missing is a PARTIAL" "skill-usage.sh not found beside this checkout"

# Mutants run from a copy of the tree that holds what the script reaches
# (skill-usage.sh beside it, a src/ to read skills from), so the unmutated copy
# and every mutant see the same sources.
root="$tmp/root"
mkdir -p "$root/scripts" "$root/src/retro/scripts" "$root/global/hooks"
cp scripts/skill-usage.sh "$root/scripts/"
for h in global/hooks/*.sh global/hooks/*.py; do : > "$root/$h"; done   # the hook roster is read by name
cp src/retro/SKILL.md "$root/src/retro/"
cp "$script" "$root/src/retro/scripts/digest.py"
m="$root/src/retro/scripts/mutant.py"
target="$root/src/retro/scripts/digest.py"
grade_target() { grade_counts "$target"; }
variants_target() { grade_variants "$target"; }
rows=0
alts=$(python3 -I -c 'import re,sys; s=open(sys.argv[1]).read(); b=s[s.index("SIGNALS = ["):s.index("]\nSIG =")]; [print(l.strip()) for l in b.splitlines()[1:] if l.strip().startswith("r\"")]' "$script")
n=0
while IFS= read -r alt; do
  [ -n "$alt" ] || continue
  n=$((n + 1))
  selftest_mutate "$script" "$m" "    $alt" "    r\"(?!x)x\"," || continue
  selftest_expect_killed --mutant target "$m" "drop SIGNALS alternative $n" grade_target
  rows=$((rows + 1))
done <<< "$alts"
expect_rc "21 SIGNALS alternatives found to mutate" 21 "$n"

mutate_and_kill() {   # <label> <from> <to> [grader, default grade_target]
  selftest_mutate "$script" "$m" "$2" "$3" || return 0
  selftest_expect_killed --mutant target "$m" "$1" "${4:-grade_target}"
  rows=$((rows + 1))
}
mutate_and_kill "paste strip" 'own = PASTED.sub(" ", t)' 'own = t'
mutate_and_kill "injected-turn skip" '"<local-command-caveat>", "<command-name>",' '"<local-command-caveat>",'
mutate_and_kill "denial prefix" "the user doesn't want to proceed with this tool use" "the user declined"
mutate_and_kill "repeat threshold" 'if v > 1)' 'if v > 2)'
mutate_and_kill "message-id dedupe" 'if mid not in seen_msg:' 'if True:'
mutate_and_kill "counts-only quote guard" 'if quote is not None and not self.a["counts_only"]:' 'if quote is not None:'
mutate_and_kill "held comparison" 'elif now < wasf or' 'elif now > wasf or'
mutate_and_kill "surface holds level" 'or metric.startswith("surface."))' ')'
mutate_and_kill "secret mask" 'SECRET.sub("[masked]", text)' 'text'
mutate_and_kill "key=value mask" 'KEYVAL.sub(r"\1[masked]", ' '('
mutate_and_kill "key=value: a prefixed name" '(\b[\w-]*?(?:password' '(\b(?:password'
mutate_and_kill "secret: sk-" 'r"(?i:\b(?:sk|pk|rk)-[a-z0-9_-]{16,}|' 'r"(?i:(?!x)x|'
mutate_and_kill "secret: AKIA" '|\b(?:AKIA|ASIA)[0-9A-Z]{16}\b' '|(?!x)x'
mutate_and_kill "secret: bearer" '|\bbearer\s+[\w.~+/=-]{12,}' ''
mutate_and_kill "secret: a JWT" '|\beyJ[\w-]{8,}\.[\w-]{8,}\.[\w-]{8,}' ''
mutate_and_kill "secret: 40 hex" '|\b[a-fA-F0-9]{40,}\b' ''
mutate_and_kill "secret: URL credentials" '|(?<=://)[^/\s:@]+:[^/\s@]+(?=@)' ''
mutate_and_kill "secret: a 40-character key with a slash" '[A-Za-z0-9+/]{40}(?![\w/.-])' '(?!x)x'
mutate_and_kill "hook message masked before its cut" 're.sub(r"\d+", "N", mask(msg))[:100]' 'mask(re.sub(r"\d+", "N", msg)[:100])'
mutate_and_kill "Bash shape masked before it flattens" 'sh = shape(mask(norm))' 'sh = shape(norm)'
selftest_mutate "$script" "$m.1" '"-c", "log.showSignature=false",' '' && selftest_mutate "$m.1" "$m" '"--no-show-signature", ' '' \
  && { selftest_expect_killed --mutant target "$m" "the signature check off, both guards" grade_target; rows=$((rows + 1)); }
mutate_and_kill "a Stop gate's blocking error" 'if at.get("type") == "hook_blocking_error":' 'if False:'
mutate_and_kill "a helper's compaction skipped" 'e.get("subtype") == "compact_boundary" and not e.get("isSidechain")' 'e.get("subtype") == "compact_boundary"'
mutate_and_kill "workflow helpers a directory deeper" 'recursive=True)]' 'recursive=False)]'
mutate_and_kill "a typed command is a load only on the roster" 'return (":" in name or name.split(":")[-1] in self.skill_roster' 'return (True'
mutate_and_kill "the counts-only label seam" 'if not self.a["counts_only"] or name in roster or HOOK_EVENT.match(name):' 'if True:'
mutate_and_kill "reads counted per transcript" 'self.reads[(sid, helper, inp["file_path"])] += 1' 'self.reads[(0, 0, inp["file_path"])] += 1'
mutate_and_kill "an inline hook's name" '", w)]' '", w) or True]'
mutate_and_kill "a queued prompt is a human turn" 'at.get("type") == "queued_command"' 'at.get("type") == "queued_x"'
mutate_and_kill "an isMeta turn skipped" 'if e.get("type") != "user" or e.get("isMeta") or' 'if e.get("type") != "user" or'
mutate_and_kill "the paste threshold" 'if len(t) > 5000:' 'if len(t) > 50000:'
mutate_and_kill "peak context" 'm["peak_context.max"] = max(self.peak.values())' 'm["peak_context.max"] = 0'
mutate_and_kill "cache-read share" 'share = (100 * self.c["tokens_cache_read"]' 'share = (0 * self.c["tokens_cache_read"]'
mutate_and_kill "helper tokens" 'tot_help = sum(v for (s, h), v in self.sess_tokens.items() if h)' 'tot_help = 0'
mutate_and_kill "memory index lines" 'idx = max(idx, len(text.splitlines()))' 'idx = 0'
mutate_and_kill "none as an open sha" 'if sha in ("", "-", "none"):' 'if sha in ("", "-"):'
mutate_and_kill "Controls read by header" 'cid, metric = cells[col["id"]], cells[col["metric"]].strip("`")' 'cid, metric = cells[0], cells[1].strip("`")'
mutate_and_kill "counts-only Bash bytes guard" 'if not co and self.bash_bytes:' 'if self.bash_bytes:'
mutate_and_kill "counts-only retry guard" 'if not co and self.retry_heads:' 'if self.retry_heads:'
mutate_and_kill "claims: an errored check is no check" 'after = [k for k in checks if k > lastedit and before[k][3] not in errs]' 'after = [k for k in checks if k > lastedit]'
mutate_and_kill "claims: a check before the edit" 'after = [k for k in checks if k > lastedit and' 'after = [k for k in checks if True and'
mutate_and_kill "claims: marked" 'if MARK.search(last[1]):' 'if False:'
mutate_and_kill "claims: the helper side" 'side = "helper" if helper else "main"' 'side = "main"'
mutate_and_kill "a pointer's line" 'return "%s:%d" % (sid[:8], line)' 'return "%s:%d" % (sid[:8], 0)'
mutate_and_kill "the per-session key" 'm[k + ".per_session"] = round(self.c[k] / n, 3)' 'pass'
mutate_and_kill "--exclude-session on transcripts" '            if sid == self.a["exclude"]:' '            if False:' variants_target
mutate_and_kill "--exclude-session on history" '                if sid == self.a["exclude"]:' '                if False:' variants_target
mutate_and_kill "the transcript window" 'if os.path.getmtime(f) < self.a["since_ts"]:' 'if False:' variants_target
mutate_and_kill "the history window" 'h["timestamp"] / 1000 < self.a["since_ts"]' 'h["timestamp"] / 1000 < 0' variants_target
mutate_and_kill "git --since from midnight" '"--since=%sT00:00" % self.a["since"]' '"--since=%s" % self.a["since"]' variants_target
mutate_and_kill "--max-pointers caps" 'if len(self.ptr[key]) < self.a["max_pointers"]:' 'if True:' variants_target
mutate_and_kill "facets under half" 'if n and facet_n * 2 < n:' 'if False:' variants_target
mutate_and_kill "every hook's sessions key" '        for name in self.hooks:
            self.c["hook.%s.sessions"' '        for name in list(self.hooks)[:8]:
            self.c["hook.%s.sessions"' variants_target
mutate_and_kill "a --session prefix resolves to one" 'if len(hits) != 1:' 'if not hits:' variants_target
mutate_and_kill "the memory past-200 note" 'if idx > 200 else' 'if idx > 2000 else' variants_target

mutate_and_kill "facet repr parse" 'fc = ast.literal_eval(fc)' 'fc = None'
mutate_and_kill "claim question test" '("?" in flat or SIG.search(flat))' '(SIG.search(flat))'
mutate_and_kill "claim test" 'if CLAIM.search(last_text) and not MARK.search(last_text) and' 'if True and'
mutate_and_kill "concession anchor" 'CONCEDE = re.compile(r"^\W*(' 'CONCEDE = re.compile(r"('
mutate_and_kill "skill window" 'TURN_WINDOW = 3 ' 'TURN_WINDOW = 4 '
mutate_and_kill "caught set" '                    if hit:
                        self.caught.add(sid)' '                    if False:
                        self.caught.add(sid)'
mutate_and_kill "repeat sessions" 'REPEAT_SESSIONS = 3 ' 'REPEAT_SESSIONS = 4 '
mutate_and_kill "slash prompts skipped" 'if len(t) < 25 or t.startswith("/"):' 'if len(t) < 25:'
mutate_and_kill "shape digits" 'c = re.sub(r"\b[0-9a-f]{7,}\b|\d+", "N", c)' 'c = c'
mutate_and_kill "hook name suffix" 'return re.sub(r"\.(sh|py)$", "",' 'return re.sub(r"\.(sh)$", "",'
mutate_and_kill "hook context list" 'body = "".join(x for x in body if isinstance(x, str))' 'body = ""'
mutate_and_kill "result bytes" 'self.result_bytes[name] += len(c.encode("utf-8", "replace"))' 'self.result_bytes[name] += 0'
mutate_and_kill "compaction subtype" 'e.get("subtype") == "compact_boundary"' 'e.get("subtype") == "compact"'
mutate_and_kill "token needs mixed case" '(?=[\w+-]*[A-Z])(?=[\w+-]*[a-z])' ''
mutate_and_kill "memory orphan" '                if b not in linked:' '                if False:'

selftest_close "digest-selftest clean: every counted shape fires, every quiet neighbour stays out, $rows mutants killed" "digest-selftest: PARTIAL"
