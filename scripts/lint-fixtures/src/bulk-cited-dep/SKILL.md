---
name: bulk-cited-dep
description: Fixture stand-in for a skill that cites its global rule in its opening lines and then carries a long body, so the citation check is graded on a stream the reader abandons before the producer has finished writing it.
disable-model-invocation: true
---

# Bulk cited dep (fixture)

This skill cites `~/.claude/rules/early-cited.md` here, in its opening lines, and then
carries three long reference files behind it.

An early citation followed by a long tail is the shape that broke the check: the reader
stopped at the first match and closed the pipe, and the producer — still holding writes it
had not made — died of SIGPIPE, so the pipeline reported the citation as missing. Each
reference file repeats the citation on its own third line, so the match lands early
whichever file the directory walk yields first. Three files rather than one because a
reference file caps at 200 lines and the tail has to outrun a Linux pipe's fixed 64 KiB,
not just a macOS pipe's initial 16 KiB; `scripts/lint-skills-selftest.sh` asserts that length.
