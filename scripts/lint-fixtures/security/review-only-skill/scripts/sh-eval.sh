#!/bin/sh
# Fixture only — never executed. One MEDIUM instance and nothing HIGH, so the
# directory grades REVIEW and never RISK: the --fail-on rows in
# scripts/security-selftest.sh grade the review threshold apart from the risk
# one against it. The annotation grader never walks this directory; the
# exit-code rows are its whole grading.
eval "$cmd"
