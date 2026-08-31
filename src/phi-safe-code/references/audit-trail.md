# The audit trail

Open this only when the change adds, alters, or reviews an audit trail, or when a security finding or audit gap names one. The body's rule stands everywhere: every read, write, delete, and export of PHI is an audit event, in an insert-only store, never the application log.

- **The store is insert-only:** an append-only table whose application role holds no `UPDATE`/`DELETE` grant, an append-only stream, or a hash-chained file — never the application log, and never a table the service can rewrite. Reading is an event too.
- **Key each event** by actor, resource (opaque ID), action, result, and time.
- **The granularity is the actor and the scope, not the row:** a nightly job over ten million claims writes one event naming the job, its query predicate, and the count, not ten million rows — a bulk export and a classification change are their own categories on the same rule.
- **A service account records the human or system it acts on behalf of.**
- **Allow-list the event's own fields like any other sink,** so there is no free-text reason column — and a wrong allow-list call here cannot be taken back, because "from where" on a member's own read is that member's IP address, a Safe Harbor identifier, written to a store nothing can delete from.
- **The retention period is the project's figure, not a guess.**
