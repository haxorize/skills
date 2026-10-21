# Admit `inventory-cvits` and `triage-cvits` as org-bound skills

Status: accepted (2026-10-10)

This amends [ADR-0062](0062-enterprise-repo-mine-two-skills-and-ecc-lineage.md) and [ADR-0055](0055-first-domain-skill-phi-safe-code.md). The two CVIT skills land here, in plain `src/`, though both are bound to one org's toolchain: ServiceNow CVIT exports, Twistlock/Prisma Cloud exports, the target org's ADO instance, and an npm-only resolver. ADR-0062 deferred the org-bound bucket — Twistlock CVE suppression among it — to "a separate home", and ADR-0055's Gap-and-stakes test admits only gaps that generalize past one employer. Neither test admits these skills, so this record does.

## Why here

Three premises moved since those records:

- **The repo is private and the Stormworks team's shared collection** ([ADR-0061](0061-marketing-artifacts-stay-company-neutral.md), amended 2026-10-10). The repo-agnostic framing stays for the process suite; it no longer bars an org-bound skill from sitting beside it.
- **The work machine's copy is replaced from this repo.** The hand sync replaces `src/ global/ scripts/ docs/` wholesale, so a skill that does not live here is deleted on the work machine at the next sync. ADR-0062's "separate home" would need its own sync path, and ADR-0055 already rejected a second repo on the ground that it would not be installed.
- **Only one ADO instance is targeted.** The skills write through that org's customized process, so the repo-agnostic requirement has no second consumer to protect.

`glapi-test-pass` already sits in `src/` on the same footing, unadmitted; this record names the class rather than adding a second silent case.

## What lands with them

- **The bucket definitions are local.** `src/triage-cvits/references/buckets.md` carries the six dispositions, the cascade, the resolver interface, and the image key, brought in from the stormworks-playbook's `docs/security/DOMAIN.md` (CVIT Buckets) and its ADR-0020, which superseded its ADR-0018. The skills no longer point at the playbook as their authority.
- **Every tracker write either skill makes goes through a publisher.** Each skill hands its drafts to `to-story` or `to-tasks`, whose Publish gate asks the human before each write ([ADR-0115](0115-the-to-publishers-are-model-invoked.md)). The one write left outside, a tag the title bracket and the `Additional tags:` line will not produce, is never made by a skill: `to-story` sets tags at creation only, so `inventory-cvits` prints a `tracker.py update` command for the human to run after the create. `inventory-cvits` owns the image Story's description; `triage-cvits` writes Tasks only, each covering the Story's AC1, so neither skill overwrites the other. This narrows the playbook's ADR-0018, under which triage also enriched the Story body.

## Considered Options

- **A separate org-bound repo or plugin** (ADR-0062's deferred form). Rejected: it needs its own sync to the work machine and its own install, and ADR-0055's reason — a repo with two skills in it is not installed — still holds.
- **Generalize the skills first** (configurable scanner, tracker, ecosystems). Rejected for now: no second org consumes them, and the resolver interface already names how a new ecosystem enters (`buckets.md` § The resolver interface).

## Revisit when:

A second org or tracker would consume these skills — then the org-bound values move to configuration, or the skills move to a home that org installs.
