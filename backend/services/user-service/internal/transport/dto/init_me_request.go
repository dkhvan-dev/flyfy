package dto

type InitMeRequest struct {
	PrimaryPhone *string `json:"primaryPhone,omitempty"`
	PrimaryEmail *string `json:"primaryEmail,omitempty"`
}
