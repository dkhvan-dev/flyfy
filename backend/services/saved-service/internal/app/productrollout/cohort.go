package productrollout

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"

	"github.com/google/uuid"
)

const cohortNamespace = "inflap.saved.product-rollout.v1"

// CohortFor deterministically assigns one of 10,000 cohorts. The framing and
// namespace are part of the sticky rollout contract and must remain stable.
func CohortFor(ownerID uuid.UUID, capability Capability) (uint16, error) {
	if ownerID == uuid.Nil {
		return 0, fmt.Errorf("%w: owner UUID is required", ErrInvalidRequest)
	}
	if !capability.IsValid() {
		return 0, fmt.Errorf("%w: unknown capability", ErrInvalidRequest)
	}

	return cohortForValid(ownerID, capability), nil
}

func cohortForValid(ownerID uuid.UUID, capability Capability) uint16 {
	payload := make([]byte, 0, len(cohortNamespace)+1+36+1+len(capability))
	payload = append(payload, cohortNamespace...)
	payload = append(payload, 0)
	payload = append(payload, ownerID.String()...)
	payload = append(payload, 0)
	payload = append(payload, capability...)
	digest := sha256.Sum256(payload)

	return uint16(binary.BigEndian.Uint64(digest[:8]) % CohortCount)
}
