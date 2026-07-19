# Activity Saved lifecycle NATS contract v1

## Transport

- Subject: `saved.source.activity.lifecycle.v1`
- Shared JetStream stream: `SAVED_SOURCE` (`saved.source.>`)
- NATS encoding: deterministic protobuf binary for `content.v1.SavedSourceLifecycleEvent`
- Delivery: at least once
- Deduplication key: `event_id` (UUID v4), also sent as the JetStream message ID

The transactional outbox stores a strict protobuf-JSON representation using
proto field names. Before publication it is validated against the immutable
outbox envelope and deterministically encoded as protobuf binary. Every
redelivery of one `event_id` therefore uses the same bytes and semantics.
Consumers must still persistently deduplicate by `event_id`; the JetStream
duplicate window is an additional optimization, not the consumer guarantee.

## Outbox JSON to protobuf mapping

| JSON field | Proto field | Activity rule |
|---|---|---|
| `event_id` | `event_id` | UUID v4 and stable across redelivery |
| `kind` | `kind` | Closed v1 enum value |
| `target.entity_type` | `target.entity_type` | Always `SAVED_ENTITY_TYPE_ACTIVITY` |
| `target.entity_id` | `target.entity_id` | Canonical `activities.id` UUID string |
| `revisions.source_revision` | `revisions.source_revision` | Independent nonzero monotonic revision |
| `revisions.projection_revision` | `revisions.projection_revision` | Independent nonzero monotonic revision |
| `revisions.visibility_revision` | `revisions.visibility_revision` | Independent nonzero monotonic revision |
| `occurred_at` | `occurred_at` | Source transition time in RFC 3339 JSON form |
| `visibility` | `visibility` | Closed v1 visibility enum value |
| `public_projection` | `public_projection` | Present only for `PUBLIC`; otherwise absent |

The outbox JSON encodes protobuf `uint64` fields as decimal strings. Unknown
fields and enum values are rejected before binary publication. NATS consumers
decode the resulting bytes directly as `content.v1.SavedSourceLifecycleEvent`.

## Event semantics

The closed event kinds are `PUBLISHED`, `UPDATED`, `UNAVAILABLE`, `DELETED`,
and `VISIBILITY_CHANGED`. The NATS payload uses their corresponding protobuf
enum names.

- `PUBLISHED` and `UPDATED` have `PUBLIC` visibility.
- `UNAVAILABLE` has `UNAVAILABLE` visibility.
- `DELETED` has `DELETED` visibility.
- `VISIBILITY_CHANGED` has `PUBLIC`, `PRIVATE`, or `RESTRICTED` visibility.
- A restored `PUBLIC` Activity carries a newly revisioned public projection.
- `PRIVATE`, `UNAVAILABLE`, `DELETED`, and `RESTRICTED` carry no public card,
  title, owner data, route, or media reference.

## Media privacy

PUBLIC projections may carry only the relative Activity cover endpoint:

`/api/v1/activities/{activity_id}/cover?saved_revision={projection_revision}`

The cover endpoint checks both current PUBLIC eligibility and the exact Saved
projection revision before reading media. A PUBLIC to non-PUBLIC transition
rotates the projection revision and denies Saved cover requests immediately.
Restoring PUBLIC rotates it again, so a previously revoked reference cannot
become valid again. The reference has a five-minute `valid_until`; expiration
never overrides source ACL or revision checks.

## Outbox lifecycle

The source write and outbox insert commit in one PostgreSQL transaction. A
bounded worker claims due rows with `FOR UPDATE SKIP LOCKED`, publishes the
immutable payload, and marks it `PUBLISHED`. Failures use exponential backoff
with deterministic jitter. Expired processing leases are recoverable. After
the configured maximum attempts, the row becomes the durable PostgreSQL
`DEAD` queue entry. Published and dead rows are retained for 14 days and then
removed in bounded batches.
