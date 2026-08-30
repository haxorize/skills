#!/bin/sh
# Fixture only — never executed. One annotated instance per alternative of the rule
# named in the file name; `# ruleid:` names the rule the next line must draw.
# ruleid: sh-eval
eval "$CMD"
# ruleid: sh-eval
eval $CMD
# ruleid: sh-eval
eval '$CMD'
