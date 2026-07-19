// Package platformpolicy provides fail-closed enforcement for access to
// platform personal data.
//
// The stable internal HTTP contract is GET EndpointPath with no request body
// or query parameters. A successful response uses application/json and has
// exactly this shape:
//
//	{
//	  "revision": 42,
//	  "state": "AVAILABLE",
//	  "issued_at": "2026-07-16T10:00:00Z",
//	  "valid_until": "2026-07-16T10:00:20Z"
//	}
//
// The endpoint is internal and must be authenticated by the caller-provided
// transport and/or TokenHeaderProvider. Consumers must use Checker.Guard or
// Checker.ValidateCommit for authorization; fetching or inspecting a Decision
// directly does not grant access.
package platformpolicy

// EndpointPath is the stable internal personal-data policy endpoint.
const EndpointPath = "/api/v1/internal/platform-policy/personal-data"
