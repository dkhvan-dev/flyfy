You are a senior backend + mobile security engineer.

Design and implement an attendance check-in system for an activity/event app using the A+ offline-first approach.

Context:
- One user is the activity host.
- Other users are participants.
- After activity creation, the host sees a QR code.
- Participants scan the host QR in the mobile app to confirm they physically arrived.
- The system must work even if the participant temporarily has no internet connection.
- Final source of truth is the backend after sync.
- We want a practical production-ready MVP architecture, not overengineered cryptography.

Core requirements:
1. Use a short-lived signed QR code.
2. Use an offline queue on the participant device.
3. Prevent replay and duplicates using nonce/jti semantics.
4. Sync pending attendance proofs when internet becomes available.
5. Backend must validate and finalize attendance.
6. The design must be idempotent and resilient to retries.
7. Do not trust client clock blindly.
8. Keep local sensitive data minimal and stored securely.

What I want from you:
Produce a complete technical design and reference implementation plan.

Please return the answer in the following structure:

## 1. High-level architecture
Describe:
- host app responsibilities
- participant app responsibilities
- backend responsibilities
- security boundaries
- online flow
- offline flow
- sync flow

## 2. QR payload design
Propose a signed QR payload structure.
Include fields such as:
- activityId
- hostId
- jti or nonce
- iat
- exp
- aud
- version
Explain:
- why each field exists
- recommended TTL for QR rotation
- whether to use JWT/JWS or custom signed payload
- how signature validation works
- how replay prevention works

Constraints:
- QR must rotate every 30–60 seconds
- QR must be verifiable by backend
- do not put excessive personal data into the QR

## 3. Attendance proof design created on participant device
Define the local object saved after scanning.
Include fields like:
- activityId
- participantId
- qrJti or qrNonce
- scannedAtDevice
- scanId
- deviceId or installationId
- syncStatus
- createdAt
- retryCount
- optional location metadata
Explain which fields are authoritative and which are informational only.

## 4. Backend API contract
Design REST endpoints for:
- creating activity
- generating/fetching rolling QR data for host
- submitting a batch of pending attendance proofs
- querying sync status
For each endpoint provide:
- method + path
- request JSON
- response JSON
- validation rules
- idempotency strategy
- error cases

## 5. Database schema
Design PostgreSQL tables for:
- activities
- activity_participants
- qr_code_issues or qr_tokens
- attendance_attempts
- attendance_records
- device_installations (optional)
For each table provide:
- columns
- primary keys
- unique constraints
- indexes
- foreign keys
Also explain:
- how duplicates are prevented
- how replayed QR scans are detected
- what should be immutable

## 6. Validation and security rules
List exact backend checks, including:
- signature valid
- token not expired
- token audience matches
- token version supported
- participant belongs to activity
- duplicate scan detection
- idempotent batch handling
- suspicious cases
Also include:
- root/jailbreak is not a hard blocker for MVP
- server time is authoritative
- local storage should use secure platform storage where possible
- store the minimum necessary offline data

## 7. Offline queue behavior
Design the participant-side queue logic:
- when an item is created
- when it is marked pending/synced/failed
- retry strategy
- exponential backoff
- max retry count
- conflict resolution
- app restart persistence
- duplicate local submissions
Include pseudocode.

## 8. Host QR refresh strategy
Describe two possible approaches:
A. backend-generated rolling QR fetched periodically
B. pre-issued signed QR tokens for a limited time window
Compare tradeoffs and recommend one for MVP.

## 9. Idempotency and replay protection
Explain exactly how to combine:
- scanId
- qrJti/nonce
- participantId
- activityId
to make submissions safe under retries and network flakiness.

Provide concrete uniqueness rules, for example:
- unique(activity_id, participant_id)
or
- unique(activity_id, participant_id, qr_jti)
Explain which rule is better depending on business logic.

## 10. Failure scenarios
Cover:
- participant scanned offline and synced later
- participant scanned same QR multiple times
- two devices for same account
- host screenshot shared to another user
- QR expired before sync
- participant not registered
- batch partially succeeds
- server returns 409/422/500
For each case explain expected behavior.

## 11. Pseudocode / reference implementation
Provide concise but realistic pseudocode for:
- backend QR verification service
- backend attendance sync handler
- mobile queue repository
- mobile sync worker
Use clean architecture and separation of concerns.

## 12. Suggested tech stack
Recommend practical choices for:
- backend framework
- signing approach
- PostgreSQL constraints
- Redis usage if helpful
- mobile local database
- background sync mechanism
Keep recommendations pragmatic for an MVP.

## 13. What not to do
List anti-patterns such as:
- static QR
- trusting client time
- accepting attendance from activityId + participantId only
- storing too much sensitive data offline
- non-idempotent sync endpoint

## 14. Final recommendation
End with a recommended MVP design:
- exact QR TTL
- exact payload format
- exact deduplication rule
- exact sync strategy
- exact DB uniqueness constraints

Implementation preferences:
- prioritize clarity and production pragmatism
- use battle-tested patterns
- avoid unnecessary complexity
- assume backend is the source of truth
- assume mobile app may be offline for several hours
- assume user can retry many times
- assume malicious but not nation-state-level attackers

Important:
- explain tradeoffs, not only one option
- include concrete JSON examples
- include SQL DDL examples
- include pseudocode
- do not hand-wave security
- do not suggest static QR
- do not rely on uninterrupted internet
- do not use vague phrases like “just validate the token”
- make the answer implementation-ready