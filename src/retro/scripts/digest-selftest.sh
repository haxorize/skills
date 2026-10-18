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
# firing, and clean neighbours that do not: a phrase inside a pasted block, a
# harness-injected <command-name> turn, a helper transcript's turn, and three
# near misses. An interrupt, a denied tool call, two rename-safety blocks in one
# session (a repeat) and one inline PreToolUse:Edit block, one other tool error,
# a Bash command repeated, a git restore, a file Read three times, one
# message's usage written on two entries (counted once), a closing claim after
# an edit with no check (counted) and one after a check (not counted),
# session-meta's would-prompt count, facets' friction (written as a Python dict
# repr, the way the insights command writes it), one Revert commit in the repo
# the session ran in, and six control rows (held, failed, open, unmeasured, a
# surface key holding level, a baseline row). Corrections the keywords miss: a
# question right after a closing claim (and a plain turn after one, not
# counted), the turn after an interrupt, a concession (and a mid-sentence
# "you're right", not counted), a skill load charged for a correction inside
# three human turns (a Skill call, a slash command, a fourth-turn correction
# not charged, /clear never a load), and a second session the facets flag that
# nothing caught. Repeats: a prompt typed in three sessions (a slash command
# and a short prompt, not listed) and one long Bash shape across three
# sessions. Hooks: runs and milliseconds from a Stop summary and a
# hook_success, and the bytes two hooks added. Result bytes against a sum the
# fixture computes. A compaction. A memory index with an orphan, a dead link
# and a dead path. Secrets in a quote, a facet detail and a hook message come
# out masked. --counts-only drops the quotes and the Read path. Exit codes: 0
# for the fixture, 2 PARTIAL for an unparsable line and for an absent projects
# directory, 3 for no mode, both modes, a bad date, a bad session id, a missing
# --controls file and an unknown flag, 0 for --help.
#
# Mutation table: each alternative of SIGNALS dropped in turn (21 mutants), and
# the paste strip, the injected-turn skip, the denial prefix, the repeat
# threshold, the message-id dedupe, the counts-only quote guard, the held
# comparison and every new guard each broken (the list at the foot); every
# mutant must red its row.
#
# NOT covered, so a clean run here is not a claim about them: exit 4 (the
# script crashing), --surface (it runs the whole lint), the 12 KB re-render at
# one pointer, and skill fit's content beyond the section rendering.
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
mkdir -p "$proj/$sid/subagents" "$proj/memory" "$tmp/usage/session-meta" "$tmp/usage/facets" "$tmp/repo"
git -C "$tmp/repo" init -q
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
         "<pasted_content id='x'>from now on, always</pasted_content> thoughts?",
         "<command-name>/x</command-name> I said so"]
out = []
shape_cmd = "git -C /repo log --oneline --since=2026-10-%02d --format='%%h %%s' | grep -v -e Merge -e fixup | head -n %d"
def user(text):
    out.append({"type": "user", "cwd": cwd, "message": {"role": "user", "content": text}})
def asst(blocks, mid, usage=None):
    out.append({"type": "assistant", "cwd": cwd, "message": {"id": mid, "role": "assistant", "content": blocks, "usage": usage or {}}})
def result(tid, text, err=True):
    out.append({"type": "user", "cwd": cwd, "message": {"role": "user", "content": [{"type": "tool_result", "tool_use_id": tid, "is_error": err, "content": text}]}})
def tool(tid, name, inp, mid):
    asst([{"type": "tool_use", "id": tid, "name": name, "input": inp}], mid)
tool("s1", "Skill", {"skill": "tdd"}, "ms1")
for s in samples + quiet + ["<command-name>/clear</command-name>"]:
    user(s)
user("[Request interrupted by user]")
user("do the work with ghp_ABCDEFGHIJKLMNOPQRSTUVWX1234 on retro-improvements-for-round-2026-10-12 at /a/Users-Abc-0123456789-abcdefghijklmnop")
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
for t in ("fine one", "fine two", "fine three", "ok wait, why is that red"):
    user(t)
tool("b1", "Bash", {"command": shape_cmd % (1, 5)}, "mb1")
result("b1", "", err=False)
tool("g1", "Grep", {"pattern": "x"}, "mg1")
result("g1", "y" * 1000, err=False)
def write(path, rows):
    with open(path, "w") as f:
        f.write("\n".join(json.dumps(e) for e in rows) + "\n")
write(os.path.join(proj, sid + ".jsonl"), out)
results = sum(len(b["content"]) for e in out if e["type"] == "user" and isinstance(e["message"]["content"], list)
              for b in e["message"]["content"] if b.get("type") == "tool_result")
for k, other in ((2, "bbbbbbbb-1111-2222-3333-444444444444"), (3, "cccccccc-1111-2222-3333-444444444444")):
    rows = [{"type": "user", "cwd": cwd, "message": {"role": "user", "content": "please continue" if k == 2 else "ok hold up there"}},
            {"type": "assistant", "cwd": cwd, "message": {"id": "o%d" % k, "role": "assistant", "content": [
                {"type": "tool_use", "id": "o%d" % k, "name": "Bash", "input": {"command": shape_cmd % (k, k + 5)}}]}}]
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
            "| C5 | `surface.hook_context.bytes` | 15 | abc1234 | open |\n| C6 | `hook_blocks` | 5 | baseline | open |\n\n## Next\n")
EOF

args=(--since 2000-01-01 --projects "$tmp/projects" --usage-data "$tmp/usage" --history "$tmp/history.jsonl" --controls "$tmp/prev-retro.md")

# run_digest <script> [extra args…] — the digest on stdout, the exit code in rc
run_digest() { local s="$1"; shift; out=$(python3 -I "$s" "${args[@]}" "$@" 2>/dev/null); rc=$?; }

# grade_counts <script> — the rows every mutant targets one of
grade_counts() {
  run_digest "$1"
  expect_row "$out" "signals: 21 alternatives, one late turn and a second session fire, 5 quiet turns and the helper do not" "signals 23"
  expect_row "$out" "interrupts" "interrupts 1"
  expect_row "$out" "denials" "denials 1"
  expect_row "$out" "rename-safety blocks" "hook.rename-safety 2"
  expect_in "$out" "repeat per session" "rename-safety blocked (1 sessions, 1 with a repeat): 2"
  expect_row "$out" "inline hook" "hook.PreToolUse:Edit 1"
  expect_row "$out" "other tool errors" "tool_errors 1"
  expect_row "$out" "bash retry" "bash_retries 1"
  expect_row "$out" "restores" "restores 1"
  expect_row "$out" "files read over twice" "files_read_over_twice 1"
  expect_row "$out" "one message id counted once" "tokens.total 450"
  expect_row "$out" "claim with an edit and no check" "claims.main.edit_no_check 1"
  expect_in "$out" "claim after a check" "check-after-last-edit 1"
  expect_row "$out" "would-prompt" "meta.bash_would_prompt_count 4"
  expect_in "$out" "facet friction" "friction: buggy_code 2"
  expect_row "$out" "revert commit" "reverts 1"
  expect_row "$out" "control held" "| C1 | \`signals\` | 99 | 23 | held |"
  expect_row "$out" "control failed" "| C2 | \`denials\` | 0 | 1 | failed |"
  expect_row "$out" "control open" "| C3 | \`signals\` | 99 | 23 | open |"
  expect_row "$out" "a surface key holding level is held" "| C5 | \`surface.hook_context.bytes\` | 15 | 15 | held |"
  expect_row "$out" "a baseline row is graded" "| C6 | \`hook_blocks\` | 5 | 3 | held |"
  expect_row "$out" "controls tally" "- held 3, failed 1, open 1, unmeasured 1"
  expect_row "$out" "question after a closing claim; a plain turn after one is not" "after_claim 1"
  expect_row "$out" "the turn after an interrupt" "after_interrupt 1"
  expect_row "$out" "a concession opens the turn; mid-sentence does not" "concessions 1"
  expect_row "$out" "skill loads charged inside three turns, /clear and a fourth-turn correction not" "skill_corrections 2"
  expect_in "$out" "a Skill call charged" "tdd 1 of 1 loads"
  expect_row "$out" "a flagged session nothing caught; one a signal caught is not" "facet_missed 1"
  expect_in "$out" "its facet detail, masked" "token=[masked]"
  expect_row "$out" "a prompt typed in three sessions; a slash command and a short one not" "history_repeats 1"
  expect_row "$out" "a long Bash shape across three sessions" "bash_shapes_repeated 1"
  expect_row "$out" "hook runs from a Stop summary" "hookrun.context-nudge 2"
  expect_in "$out" "hook milliseconds" "context-nudge ran 2 times in 1 sessions, 100 ms in all, blocked 0"
  expect_row "$out" "hook runs from a hook_success" "hookrun.rename-safety 1"
  expect_row "$out" "bytes hooks added" "surface.hook_context.bytes 15"
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
  expect_row "$out" "counts-only still counts" "signals 23"
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
expect_in "$out" "session mode reads the session" "signals 22"
expect_in "$out" "session mode reads only that session's history" "history_repeats 0"
expect_in "$out" "session mode scope" "# Retro digest: session aaaaaaaa"

# Mutants run from a copy of the tree that holds what the script reaches
# (skill-usage.sh beside it, a src/ to read skills from), so the unmutated copy
# and every mutant see the same sources.
root="$tmp/root"
mkdir -p "$root/scripts" "$root/src/retro/scripts"
cp scripts/skill-usage.sh "$root/scripts/"
cp src/retro/SKILL.md "$root/src/retro/"
cp "$script" "$root/src/retro/scripts/digest.py"
m="$root/src/retro/scripts/mutant.py"
target="$root/src/retro/scripts/digest.py"
grade_target() { grade_counts "$target"; }
alts=$(python3 -I -c 'import re,sys; s=open(sys.argv[1]).read(); b=s[s.index("SIGNALS = ["):s.index("]\nSIG =")]; [print(l.strip()) for l in b.splitlines()[1:] if l.strip().startswith("r\"")]' "$script")
n=0
while IFS= read -r alt; do
  [ -n "$alt" ] || continue
  n=$((n + 1))
  selftest_mutate "$script" "$m" "    $alt" "    r\"(?!x)x\"," || continue
  selftest_expect_killed --mutant target "$m" "drop SIGNALS alternative $n" grade_target
done <<< "$alts"
expect_rc "21 SIGNALS alternatives found to mutate" 21 "$n"

mutate_and_kill() {   # <label> <from> <to>
  selftest_mutate "$script" "$m" "$2" "$3" || return 0
  selftest_expect_killed --mutant target "$m" "$1" grade_target
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
mutate_and_kill "key=value mask" 'KEYVAL.sub(r"\1\2[masked]", ' '('

mutate_and_kill "facet repr parse" 'fc = ast.literal_eval(fc)' 'fc = None'
mutate_and_kill "claim question test" '("?" in flat or SIG.search(flat))' '(SIG.search(flat))'
mutate_and_kill "claim test" 'if CLAIM.search(last_text) and not MARK.search(last_text) and' 'if True and'
mutate_and_kill "concession anchor" 'CONCEDE = re.compile(r"^\W*(' 'CONCEDE = re.compile(r"('
mutate_and_kill "skill window" 'TURN_WINDOW = 3 ' 'TURN_WINDOW = 4 '
mutate_and_kill "builtin commands" '"clear", "compact",' '"compact",'
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

selftest_close "digest-selftest clean: every counted shape fires, every quiet neighbour stays out, 48 mutants killed" "digest-selftest: PARTIAL"
