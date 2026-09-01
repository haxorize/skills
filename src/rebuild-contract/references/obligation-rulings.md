# Obligation rulings: what goes in, what stays behind

Two halves, read on two different triggers.

**The quick table** — read it when the inclusion test lands close to the line, or the item is in one of its categories, the ones that are both behavior and implementation.

**Behavior that comes from the stack** — read and sweep it **unconditionally at Stage 6**, item by item. It is not a close-call reference: nobody decided these behaviors, so none of them presents as a judgment call, and that is exactly why a port diverges on them silently. Stage 6's criterion is not met until every item on that list is stated or recorded as not found.

## The quick table

| Category | In the contract | Left in the source |
| --- | --- | --- |
| **Domain data** | concepts, identity rules, invariants, lifecycles, derived-value formulas, required vs optional, value ranges | table layout, column types, indexes, ORM shape |
| **Database schema** | **only where a consumer you cannot redeploy reads it** — then verbatim, as `exact` | otherwise everything |
| **API surface** | paths, methods, status codes, request and response shapes, error bodies, pagination, versioning, idempotency keys | routing library, serializer, controller layout |
| **Auth** | who may do what, session and token lifetimes, expiry and refresh, lockout, revocation, what a failure looks like to the caller | JWT vs session vs opaque token, hashing library, middleware order |
| **Permissions** | the complete actor × capability matrix, deny cases included, and what a denial looks like | how the checks are wired |
| **Integrations** | what is sent and received and when, failure and retry semantics, idempotency, sandbox vs live differences, what happens when it is down | SDK choice, client wrapper, connection pooling |
| **Persistence** | durability and consistency guarantees, what survives a restart or crash, transaction boundaries *as observable atomicity*, retention | storage engine, migration history, caching layer |
| **Background work** | trigger, cadence, delivery guarantees, ordering, idempotency, observable effects, behavior on failure and on catch-up | the scheduler or queue technology |
| **Config** | every key that changes behavior, its default, its precedence, what changes when it is absent | file format, loading mechanism, secret store |
| **Errors** | user-visible messages and codes, which are retryable, what state is left behind | the exception hierarchy |
| **Migrations** | data-repair rules and compatibility windows still enforced | the migration history itself |
| **Caching** | only where observable — staleness windows, invalidation guarantees, what a user can see go stale | the cache |
| **Logging & metrics** | only what something outside depends on — an alert parsing a log line, a dashboard metric, an audit trail with a retention requirement | everything else |
| **Feature flags** | the behavior of each state, and which is the default | the flag system |

## Behavior that comes from the stack

Real, observable, and invisible to anyone reading a feature list; a reimplementer on a different stack reproduces these **only if told**. Check each against the system: where it is load-bearing, state it as [contract]; where it genuinely does not matter, mark it [undefined] so nobody spends a week matching it.

- **Numbers** — float vs decimal for money, rounding mode (half-up, half-even), where rounding happens in a chain, stored precision, integer overflow, division semantics. A system that handles money states this outright.
- **Strings** — case sensitivity in identifiers and lookups, collation and locale-dependent sort order, Unicode normalization (`é` as one code point or two), whitespace trimming, what "empty" means.
- **Dates and times** — the storage time zone, what "today" means for a user in another zone, DST at boundaries, week and month boundaries, whether range ends are inclusive, the format of anything a user or client sees.
- **Ordering of unordered things** — a query with no `ORDER BY` returns rows in an order stable in practice and undefined in theory; where users depend on it, write the sort as [contract], otherwise mark it [undefined].
- **Regex dialects** — greediness, anchoring, Unicode classes, and lookbehind differ by language; a user-visible pattern (validation, search, routing) gets its intent stated in words, never the pattern alone.
- **Encoding and size limits** — the character encoding of inputs and outputs, byte vs character limits on fields, and what happens past them (truncate, reject, error).
- **Concurrency** — the same entity modified twice at once: last-write-wins, optimistic locking with a visible conflict error, or a lock the user feels as a delay are three different products.
- **Null and empty** — whether null, empty string, and absent are distinguished, and what each means in a filter.

## Two rules that override the table

**Anything a consumer already depends on is contract, however wrong it looks.** A bug that clients have built around is the interface. Record it `[contract] [suspect]`, describe it exactly, say plainly that it appears unintended — and let the human decide whether the rebuild may fix it. Deciding that yourself, silently, breaks their integration on migration day.

**Silence reads as contract.** Anything left unmarked will be reproduced. That is why [incidental] and [undefined] are stated out loud: telling the reimplementer what they are free to change is as valuable as telling them what they must match, and it is the part every other specification omits.
