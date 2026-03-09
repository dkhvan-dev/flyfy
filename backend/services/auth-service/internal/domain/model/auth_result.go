package model

type AuthResult struct {
	AccessToken      string  `json:"access_token"`
	RefreshToken     string  `json:"refresh_token"`
	IsNewUser        bool    `json:"is_new_user"`
	PrimaryPhoneHint *string `json:"primary_phone_hint,omitempty"`
	PrimaryEmailHint *string `json:"primary_email_hint,omitempty"`
}
