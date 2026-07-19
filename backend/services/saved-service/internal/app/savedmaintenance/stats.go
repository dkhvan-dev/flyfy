package savedmaintenance

import "time"

type Stats struct {
	StartedAt  time.Time
	FinishedAt time.Time
	Ticks      int
	Capped     bool
	HasMore    bool

	PendingOperationsExpired     int64
	TerminalOperationsPurged     int64
	TerminalOutboxPurged         int64
	InboxDedupPurged             int64
	DeletedCollectionChildren    int64
	RemovedCollectionItemsPurged int64
	DeletedCollectionsPurged     int64
	RemovedSavedItemsPurged      int64
	ProjectionCandidatesMarked   int64
	EphemeralProjectionsPurged   int64
	StandardProjectionsPurged    int64
	SubjectPurgeRowsPurged       int64
	SubjectPurgePhasesAdvanced   int
	SubjectPurgesCompleted       int
	CompletedSubjectPurgesPurged int64
}

func (s Stats) TotalAffected() int64 {
	return s.PendingOperationsExpired +
		s.TerminalOperationsPurged +
		s.TerminalOutboxPurged +
		s.InboxDedupPurged +
		s.DeletedCollectionChildren +
		s.RemovedCollectionItemsPurged +
		s.DeletedCollectionsPurged +
		s.RemovedSavedItemsPurged +
		s.ProjectionCandidatesMarked +
		s.EphemeralProjectionsPurged +
		s.StandardProjectionsPurged +
		s.SubjectPurgeRowsPurged +
		s.CompletedSubjectPurgesPurged
}

func (s *Stats) add(other Stats) {
	if s.StartedAt.IsZero() || (!other.StartedAt.IsZero() && other.StartedAt.Before(s.StartedAt)) {
		s.StartedAt = other.StartedAt
	}
	if other.FinishedAt.After(s.FinishedAt) {
		s.FinishedAt = other.FinishedAt
	}
	s.Ticks += other.Ticks
	s.HasMore = other.HasMore
	s.PendingOperationsExpired += other.PendingOperationsExpired
	s.TerminalOperationsPurged += other.TerminalOperationsPurged
	s.TerminalOutboxPurged += other.TerminalOutboxPurged
	s.InboxDedupPurged += other.InboxDedupPurged
	s.DeletedCollectionChildren += other.DeletedCollectionChildren
	s.RemovedCollectionItemsPurged += other.RemovedCollectionItemsPurged
	s.DeletedCollectionsPurged += other.DeletedCollectionsPurged
	s.RemovedSavedItemsPurged += other.RemovedSavedItemsPurged
	s.ProjectionCandidatesMarked += other.ProjectionCandidatesMarked
	s.EphemeralProjectionsPurged += other.EphemeralProjectionsPurged
	s.StandardProjectionsPurged += other.StandardProjectionsPurged
	s.SubjectPurgeRowsPurged += other.SubjectPurgeRowsPurged
	s.SubjectPurgePhasesAdvanced += other.SubjectPurgePhasesAdvanced
	s.SubjectPurgesCompleted += other.SubjectPurgesCompleted
	s.CompletedSubjectPurgesPurged += other.CompletedSubjectPurgesPurged
}
