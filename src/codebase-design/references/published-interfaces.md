# Changing a published interface

Open this only when a change touches an interface something outside the change consumes — an API, a schema, an exported symbol, an event shape, a CLI's flags or output — and the question is whether the change breaks a consumer, and what a deprecation owes them; or when this repo consumes an interface another repo owns. A change whose callers are all inside the diff never opens it.

## Breaking or not

Classify each edit before writing it. The consumer's side decides, not the author's intent.

| Non-breaking | Breaking |
|---|---|
| Adding an optional field, parameter, or flag | Removing or renaming anything a consumer names |
| Adding an endpoint, command, or event type | Changing a field's type, unit, or format |
| Adding an enum value, where consumers are known to ignore unknowns | Making an optional input required, or an optional output absent |
| Relaxing validation (accepting more) | Tightening validation (rejecting what was accepted) |
| Adding a key to a machine-shaped output | Changing an error's shape or code, or what a status means |
| Documenting behavior that already held | Adding a required input; changing a default; changing ordering a consumer sorts on |

Hyrum's law sits under the table: with enough consumers, every observable behavior is depended on, whether documented or not. "Undocumented" is a weaker guess about consumers, not a license. An edit the table does not place — a latency or throughput change, a rate limit, a retry or timeout default, a log line or metric name a consumer alerts on — is breaking until a consumer count says otherwise.

## Zero consumers licenses the break

Where the consumer count is zero — pre-production, a contract nothing has shipped against, an internal seam with no caller outside the change — make the break outright, in the same slice — `implement`'s compatibility rule is the one that removes the old path: remove the shim, the fallback, the dual-write path, the alias; leave one canonical contract. A compatibility layer added to shrink a diff nobody is on the other side of is a second interface to maintain. A zero counted only in this repo's source is not yet zero: search the repos `## Sibling repos` declares and everything this repo deploys or configures from — for example Dockerfiles, compose files, Kubernetes manifests and Helm charts, Terraform, CI workflows, and app config — since a route, an event name, or an env var with no caller in the code can be what another service or a deploy reads. The one guard that stays: zero consumers licenses breaking a contract, never destroying confirmed production data.

## Deprecating

Deprecation planning starts at design time — an interface that names its consumers, versions its shape, and states its notice period is one that can be retired; one that does not is retired by incident. Before announcing, answer five questions in writing:

1. Does it still deliver unique value, or does something else now cover it?
2. How many consumers, and which — counted, not estimated?
3. Does the replacement exist and cover every case the consumers use?
4. What does migration cost each consumer?
5. What does *not* deprecating cost — maintenance, security surface, the second contract?

An announcement is advisory; a migration is compulsory, and only the migration retires the interface. State the notice period, ship the replacement before the notice starts, and end a sunset with an explicit terminal response — `410 Gone` for an HTTP endpoint, a named error for a symbol — never a silent removal a consumer meets as a generic failure. The five questions are also the gate a decommission checklist opens with; that checklist is not this reference.

## An interface another repo owns

When this repo consumes a contract another repo owns — a vendored schema, a generated client, a shared event definition — the owner changes it, not this side. The copy records its source repo, path, and pinned revision; an update is a deliberate change, classified against the table above and reviewed in each consumer; nothing tracks the owner's latest silently. A change this repo needs goes to the owner first, agreed and versioned there, before this side builds on it.
