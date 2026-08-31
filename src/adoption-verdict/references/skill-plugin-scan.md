# Skill and plugin scan

Run a heuristic injection scan over the candidate's directory before install. The skills repo ships one as `scripts/security.sh`; from another project, reach it as:

```
"$(dirname "$(dirname "$(readlink ~/.claude/skills/adoption-verdict)")")"/scripts/security.sh --path <dir>
```

The `readlink` is needed because the skills are symlinked in and a bare `scripts/` resolves only from that repo's root. An entry that is a real directory rather than a link makes `readlink` print nothing — then run the script from a checkout of the skills repo instead.
