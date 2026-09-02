#!/bin/bash
# Right on purpose: an unpaired .sh under a repo-local skill directory that is
# NOT its scripts/ directory. The walk's path is `.claude/skills/*/scripts/*.sh`;
# loosening the directory segment (to `*/*/*.sh`, say) reaches this file, which
# has no selftest and no conventions pointer, so the clean root reds. Depth is
# graded here the way the file extension is graded by NOTES.txt beside it.
echo helper
