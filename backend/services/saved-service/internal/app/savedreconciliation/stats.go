package savedreconciliation

import "time"

// Stats is the complete observability result. It deliberately contains only
// bounded aggregate counters and timing, never target/user IDs or error text.
type Stats struct {
	StartedAt           time.Time
	FinishedAt          time.Time
	CandidatesClaimed   int
	PublicApplied       int
	DenyApplied         int
	MetadataOnlyApplied int
	NoChange            int
	StaleIgnored        int
	PayloadsCleared     int
	SourceAdvanced      int
	ProjectionAdvanced  int
	VisibilityAdvanced  int
	NotFound            int
	UnsupportedType     int
	ResolutionFailures  int
	InvariantFailures   int
	ResolveRetries      int
	RepositoryRetries   int
	LeaseConflicts      int
	RetriesScheduled    int
	Quarantined         int
	CompletionFailures  int
	CommitUnknown       int
	Capped              bool
	HasMore             bool
}

func (s Stats) validate(config Config) error {
	outcomes := s.PublicApplied + s.DenyApplied + s.MetadataOnlyApplied +
		s.NoChange + s.StaleIgnored
	if s.StartedAt.IsZero() || s.FinishedAt.IsZero() ||
		s.FinishedAt.Before(s.StartedAt) || s.CandidatesClaimed < 0 ||
		s.CandidatesClaimed > config.BatchSize ||
		s.PublicApplied < 0 || s.DenyApplied < 0 ||
		s.MetadataOnlyApplied < 0 || s.NoChange < 0 ||
		s.StaleIgnored < 0 || s.PayloadsCleared < 0 ||
		s.SourceAdvanced < 0 || s.ProjectionAdvanced < 0 ||
		s.VisibilityAdvanced < 0 || s.NotFound < 0 ||
		s.UnsupportedType < 0 || s.ResolutionFailures < 0 || s.InvariantFailures < 0 ||
		s.ResolveRetries < 0 || s.RepositoryRetries < 0 ||
		s.LeaseConflicts < 0 || s.RetriesScheduled < 0 || s.Quarantined < 0 ||
		s.CompletionFailures < 0 || s.CommitUnknown < 0 ||
		s.ResolveRetries > config.BatchSize*config.RepositoryAttempts*(config.ResolveAttempts-1) ||
		s.RepositoryRetries > (2*config.BatchSize+1)*(config.RepositoryAttempts-1) ||
		outcomes != s.CandidatesClaimed ||
		s.PayloadsCleared > s.CandidatesClaimed ||
		s.SourceAdvanced > s.CandidatesClaimed ||
		s.ProjectionAdvanced > s.CandidatesClaimed ||
		s.VisibilityAdvanced > s.CandidatesClaimed ||
		s.NotFound+s.UnsupportedType+s.ResolutionFailures > s.CandidatesClaimed ||
		s.InvariantFailures > s.ResolutionFailures ||
		s.LeaseConflicts > s.CandidatesClaimed ||
		s.RetriesScheduled+s.Quarantined > s.UnsupportedType+s.ResolutionFailures ||
		s.CommitUnknown > s.CompletionFailures {
		return ErrDataInvariant
	}
	return nil
}

func (s *Stats) recordApply(result ApplyResult) {
	switch result.Outcome {
	case ApplyPublic:
		s.PublicApplied++
	case ApplyDeny:
		s.DenyApplied++
	case ApplyMetadataOnly:
		s.MetadataOnlyApplied++
	case ApplyStale:
		s.StaleIgnored++
	case ApplyNoChange:
		s.NoChange++
	}
	if result.PayloadCleared {
		s.PayloadsCleared++
	}
	if result.SourceAdvanced {
		s.SourceAdvanced++
	}
	if result.ProjectionAdvanced {
		s.ProjectionAdvanced++
	}
	if result.VisibilityAdvanced {
		s.VisibilityAdvanced++
	}
}
