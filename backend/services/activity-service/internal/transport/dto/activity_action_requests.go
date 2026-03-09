package dto

type PublishActivityRequest struct {
	ReviewRequired *bool `json:"reviewRequired,omitempty"`
}

type DuplicateActivityRequest struct {
	StartAt              string `json:"startAt"`
	EndAt                string `json:"endAt"`
	RegistrationDeadline string `json:"registrationDeadline"`
}

type CancelActivityRequest struct {
	Reason string `json:"reason"`
}

type LeaveActivityRequest struct {
	Reason *string `json:"reason,omitempty"`
}
