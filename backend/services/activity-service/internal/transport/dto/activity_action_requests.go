package dto

type PublishActivityRequest struct{}

type DuplicateActivityRequest struct {
	StartAt              string `json:"startAt"`
	EndAt                string `json:"endAt"`
	RegistrationDeadline string `json:"registrationDeadline"`
}

type CancelActivityRequest struct {
	Reason string `json:"reason"`
}

type CompleteActivityRequest struct {
	Reason string `json:"reason,omitempty"`
}

type ExtendActivityRequest struct {
	Minutes int `json:"minutes"`
}

type LeaveActivityRequest struct {
	Reason *string `json:"reason,omitempty"`
}
