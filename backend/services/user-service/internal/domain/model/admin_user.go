package model

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidAdminUserPageToken = errors.New("invalid admin user page token")

type AdminUserListFilter struct {
	PageSize       int
	PageToken      string
	Query          string
	Status         string
	Role           string
	CountryCode    string
	CreatedFrom    *time.Time
	CreatedTo      *time.Time
	LastActiveFrom *time.Time
	LastActiveTo   *time.Time
}

type AdminUserListItem struct {
	UserID        uuid.UUID
	DisplayName   string
	MaskedPhone   string
	MaskedEmail   string
	CountryCode   string
	Roles         []string
	AccountStatus string
	GuideStatus   string
	CreatedAt     time.Time
	LastActiveAt  *time.Time
}

type AdminUserListPage struct {
	Items         []AdminUserListItem
	NextPageToken string
}

type AdminUserDetail struct {
	UserID        uuid.UUID
	DisplayName   string
	MaskedPhone   string
	MaskedEmail   string
	CountryCode   string
	Roles         []string
	AccountStatus string
	GuideStatus   string
	CreatedAt     time.Time
	UpdatedAt     time.Time
	LastActiveAt  *time.Time
}

type AdminUserPageToken struct {
	CreatedAt time.Time `json:"created_at"`
	ID        uuid.UUID `json:"id"`
}

func DecodeAdminUserPageToken(token string) (AdminUserPageToken, error) {
	token = strings.TrimSpace(token)
	if token == "" {
		return AdminUserPageToken{}, nil
	}

	raw, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil {
		return AdminUserPageToken{}, ErrInvalidAdminUserPageToken
	}

	var decoded AdminUserPageToken
	if err = json.Unmarshal(raw, &decoded); err != nil {
		return AdminUserPageToken{}, ErrInvalidAdminUserPageToken
	}
	if decoded.ID == uuid.Nil || decoded.CreatedAt.IsZero() {
		return AdminUserPageToken{}, ErrInvalidAdminUserPageToken
	}

	return decoded, nil
}

func EncodeAdminUserPageToken(token AdminUserPageToken) (string, error) {
	if token.ID == uuid.Nil || token.CreatedAt.IsZero() {
		return "", ErrInvalidAdminUserPageToken
	}

	raw, err := json.Marshal(token)
	if err != nil {
		return "", err
	}

	return base64.RawURLEncoding.EncodeToString(raw), nil
}
