package savedlifecycle

type OutcomeCode string

const (
	OutcomeApplied                    OutcomeCode = "APPLIED"
	OutcomeAppliedSourceOnly          OutcomeCode = "APPLIED_SOURCE_ONLY"
	OutcomeIgnoredUnknownTarget       OutcomeCode = "IGNORED_UNKNOWN_TARGET"
	OutcomeIgnoredStaleRevision       OutcomeCode = "IGNORED_STALE_REVISION"
	OutcomeIgnoredPublicPayloadAbsent OutcomeCode = "IGNORED_PUBLIC_PAYLOAD_ABSENT"
	OutcomeDuplicate                  OutcomeCode = "DUPLICATE"
)

// Outcome keeps low-cardinality disposition and dimension flags separate so
// metrics can show partial revision progress without target identifiers.
type Outcome struct {
	Code              OutcomeCode
	OriginalCode      OutcomeCode
	SourceApplied     bool
	ProjectionApplied bool
	VisibilityApplied bool
}

func (o Outcome) IsValid() bool {
	switch o.Code {
	case OutcomeApplied:
		return o.ProjectionApplied || o.VisibilityApplied
	case OutcomeAppliedSourceOnly:
		return o.SourceApplied && !o.ProjectionApplied && !o.VisibilityApplied
	case OutcomeIgnoredUnknownTarget,
		OutcomeIgnoredStaleRevision,
		OutcomeIgnoredPublicPayloadAbsent:
		return !o.SourceApplied && !o.ProjectionApplied && !o.VisibilityApplied
	case OutcomeDuplicate:
		return o.OriginalCode.isPersisted() &&
			!o.SourceApplied && !o.ProjectionApplied && !o.VisibilityApplied
	default:
		return false
	}
}

func (c OutcomeCode) isPersisted() bool {
	switch c {
	case OutcomeApplied,
		OutcomeAppliedSourceOnly,
		OutcomeIgnoredUnknownTarget,
		OutcomeIgnoredStaleRevision,
		OutcomeIgnoredPublicPayloadAbsent:
		return true
	default:
		return false
	}
}
