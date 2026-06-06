package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidActivityReviewID          = errors.New("invalid activity review id")
	ErrInvalidActivityReviewActivity    = errors.New("invalid activity review activity")
	ErrInvalidActivityReviewParticipant = errors.New("invalid activity review participant")
	ErrInvalidActivityReviewAuthor      = errors.New("invalid activity review author")
	ErrInvalidActivityReviewRating      = errors.New("invalid activity review rating")
	ErrInvalidActivityReviewComment     = errors.New("invalid activity review comment")
	ErrActivityReviewAlreadyExists      = errors.New("activity review already exists")

	ErrActivityOrganizerReviewAlreadyExists = errors.New("activity organizer review already exists")
	ErrActivityOrganizerReviewSelfReview    = errors.New("activity organizer review self review")
)

const maxActivityReviewCommentLength = 2000

type ActivityReviewAuthor struct {
	UserID       uuid.UUID
	Nickname     *string
	AvatarFileID *uuid.UUID
}

type ActivityReview struct {
	ID uuid.UUID

	ParticipantID uuid.UUID
	ActivityID    uuid.UUID
	HostUserID    uuid.UUID
	AuthorUserID  uuid.UUID
	Author        ActivityReviewAuthor

	Rating    float64
	Comment   string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}

type ActivityOrganizerReview struct {
	ID uuid.UUID

	ParticipantID uuid.UUID
	ActivityID    uuid.UUID
	HostUserID    uuid.UUID
	AuthorUserID  uuid.UUID
	Author        ActivityReviewAuthor

	Rating    float64
	Comment   string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}

type NewActivityReviewParams struct {
	Activity    *Activity
	Participant *ActivityParticipant
	Rating      float64
	Comment     string
}

type NewActivityOrganizerReviewParams struct {
	Activity    *Activity
	Participant *ActivityParticipant
	Rating      float64
	Comment     string
}

func NewActivityReview(params NewActivityReviewParams) (*ActivityReview, error) {
	now := time.Now().UTC()
	if params.Activity == nil || params.Activity.ID == uuid.Nil || params.Activity.HostUserID == uuid.Nil {
		return nil, ErrInvalidActivityReviewActivity
	}
	if params.Participant == nil || params.Participant.ID == uuid.Nil || params.Participant.ActivityID != params.Activity.ID {
		return nil, ErrInvalidActivityReviewParticipant
	}
	item := &ActivityReview{
		ID:            uuid.New(),
		ParticipantID: params.Participant.ID,
		ActivityID:    params.Activity.ID,
		HostUserID:    params.Activity.HostUserID,
		AuthorUserID:  params.Participant.UserID,
		Author: ActivityReviewAuthor{
			UserID: params.Participant.UserID,
		},
		Rating:    params.Rating,
		Comment:   strings.TrimSpace(params.Comment),
		CreatedAt: now,
		UpdatedAt: now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func NewActivityOrganizerReview(params NewActivityOrganizerReviewParams) (*ActivityOrganizerReview, error) {
	now := time.Now().UTC()
	if params.Activity == nil || params.Activity.ID == uuid.Nil || params.Activity.HostUserID == uuid.Nil {
		return nil, ErrInvalidActivityReviewActivity
	}
	if params.Participant == nil || params.Participant.ID == uuid.Nil || params.Participant.ActivityID != params.Activity.ID {
		return nil, ErrInvalidActivityReviewParticipant
	}
	if params.Participant.UserID == params.Activity.HostUserID {
		return nil, ErrActivityOrganizerReviewSelfReview
	}
	item := &ActivityOrganizerReview{
		ID:            uuid.New(),
		ParticipantID: params.Participant.ID,
		ActivityID:    params.Activity.ID,
		HostUserID:    params.Activity.HostUserID,
		AuthorUserID:  params.Participant.UserID,
		Author: ActivityReviewAuthor{
			UserID: params.Participant.UserID,
		},
		Rating:    params.Rating,
		Comment:   strings.TrimSpace(params.Comment),
		CreatedAt: now,
		UpdatedAt: now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (r *ActivityReview) Validate() error {
	if r.ID == uuid.Nil {
		return ErrInvalidActivityReviewID
	}
	if r.ActivityID == uuid.Nil || r.HostUserID == uuid.Nil {
		return ErrInvalidActivityReviewActivity
	}
	if r.ParticipantID == uuid.Nil {
		return ErrInvalidActivityReviewParticipant
	}
	if r.AuthorUserID == uuid.Nil {
		return ErrInvalidActivityReviewAuthor
	}
	if r.Rating < 1 || r.Rating > 5 {
		return ErrInvalidActivityReviewRating
	}
	r.Comment = strings.TrimSpace(r.Comment)
	if len([]rune(r.Comment)) > maxActivityReviewCommentLength {
		return ErrInvalidActivityReviewComment
	}
	return nil
}

func (r *ActivityReview) Update(rating float64, comment string) error {
	r.Rating = rating
	r.Comment = strings.TrimSpace(comment)
	r.UpdatedAt = time.Now().UTC()
	return r.Validate()
}

func (r *ActivityReview) SoftDelete() {
	now := time.Now().UTC()
	r.DeletedAt = &now
	r.UpdatedAt = now
}

func (r *ActivityOrganizerReview) Validate() error {
	if r.ID == uuid.Nil {
		return ErrInvalidActivityReviewID
	}
	if r.ActivityID == uuid.Nil || r.HostUserID == uuid.Nil {
		return ErrInvalidActivityReviewActivity
	}
	if r.ParticipantID == uuid.Nil {
		return ErrInvalidActivityReviewParticipant
	}
	if r.AuthorUserID == uuid.Nil {
		return ErrInvalidActivityReviewAuthor
	}
	if r.AuthorUserID == r.HostUserID {
		return ErrActivityOrganizerReviewSelfReview
	}
	if r.Rating < 1 || r.Rating > 5 {
		return ErrInvalidActivityReviewRating
	}
	r.Comment = strings.TrimSpace(r.Comment)
	if len([]rune(r.Comment)) > maxActivityReviewCommentLength {
		return ErrInvalidActivityReviewComment
	}
	return nil
}

func (r *ActivityOrganizerReview) Update(rating float64, comment string) error {
	r.Rating = rating
	r.Comment = strings.TrimSpace(comment)
	r.UpdatedAt = time.Now().UTC()
	return r.Validate()
}

func (r *ActivityOrganizerReview) SoftDelete() {
	now := time.Now().UTC()
	r.DeletedAt = &now
	r.UpdatedAt = now
}
