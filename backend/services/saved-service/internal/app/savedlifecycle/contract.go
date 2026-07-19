package savedlifecycle

import "kz/inflap/backend/services/saved-service/internal/domain"

const (
	ActivitySubjectV1   = "saved.source.activity.lifecycle.v1"
	AttractionSubjectV1 = "saved.source.attraction.lifecycle.v1"
	GuideSubjectV1      = "saved.source.guide.lifecycle.v1"

	activitySourceService   = "activity-service"
	attractionSourceService = "place-service"
	guideSourceService      = "guide-service"

	SchemaVersionV1 uint16 = 1
)

// SubjectContract is the closed source/subject/schema binding accepted by the
// Saved lifecycle consumer. Subject wildcards are never treated as trust.
type SubjectContract struct {
	Subject       string
	SourceService string
	EntityType    domain.EntityType
	SchemaVersion uint16
}

func ContractForSubject(subject string) (SubjectContract, bool) {
	switch subject {
	case ActivitySubjectV1:
		return SubjectContract{
			Subject:       ActivitySubjectV1,
			SourceService: activitySourceService,
			EntityType:    domain.EntityTypeActivity,
			SchemaVersion: SchemaVersionV1,
		}, true
	case AttractionSubjectV1:
		return SubjectContract{
			Subject:       AttractionSubjectV1,
			SourceService: attractionSourceService,
			EntityType:    domain.EntityTypeAttraction,
			SchemaVersion: SchemaVersionV1,
		}, true
	case GuideSubjectV1:
		return SubjectContract{
			Subject:       GuideSubjectV1,
			SourceService: guideSourceService,
			EntityType:    domain.EntityTypeGuide,
			SchemaVersion: SchemaVersionV1,
		}, true
	default:
		return SubjectContract{}, false
	}
}

func SubjectContracts() []SubjectContract {
	contracts := make([]SubjectContract, 0, 3)
	for _, subject := range []string{ActivitySubjectV1, AttractionSubjectV1, GuideSubjectV1} {
		contract, _ := ContractForSubject(subject)
		contracts = append(contracts, contract)
	}
	return contracts
}
