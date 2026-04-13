package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/port"
)

type GuideAggregate struct {
	Profile             *model.GuideProfile
	VerificationRequest *model.GuideVerificationRequest
	Documents           []*model.GuideDocument
	Languages           []*model.GuideLanguage
	Specializations     []*model.GuideSpecialization
}

type GuideUseCase struct {
	repo       port.GuideRepository
	userClient UserServiceClient
	fileClient FileManagerClient
}

func NewGuideUseCase(
	repo port.GuideRepository,
	userClient UserServiceClient,
	fileClient FileManagerClient,
) *GuideUseCase {
	return &GuideUseCase{
		repo:       repo,
		userClient: userClient,
		fileClient: fileClient,
	}
}

type InitGuideProfileInput struct {
	UserID uuid.UUID
	Type   string
}

func (u *GuideUseCase) GetOrCreateGuideProfile(ctx context.Context, input InitGuideProfileInput) (*GuideAggregate, error) {
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidGuideUserID
	}

	if u.userClient == nil {
		return nil, fmt.Errorf("user service client is not configured")
	}
	if err := u.userClient.ValidateUserExists(ctx, input.UserID); err != nil {
		return nil, err
	}

	existing, err := u.repo.GetGuideProfileByUserID(ctx, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by user id: %w", err)
	}
	if existing != nil {
		return u.GetGuideAggregateByProfileID(ctx, existing.ID)
	}

	guideType := enum.GuideType(strings.TrimSpace(input.Type))
	if !guideType.IsValid() {
		return nil, model.ErrInvalidGuideType
	}

	profile, err := model.NewGuideProfile(model.NewGuideProfileParams{
		UserID: input.UserID,
		Type:   guideType,
	})
	if err != nil {
		return nil, fmt.Errorf("new guide profile: %w", err)
	}

	if err = u.repo.CreateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("create guide profile: %w", err)
	}

	return &GuideAggregate{
		Profile:         profile,
		Documents:       []*model.GuideDocument{},
		Languages:       []*model.GuideLanguage{},
		Specializations: []*model.GuideSpecialization{},
	}, nil
}

func (u *GuideUseCase) GetGuideAggregateByProfileID(ctx context.Context, profileID uuid.UUID) (*GuideAggregate, error) {
	if profileID == uuid.Nil {
		return nil, ErrInvalidGuideProfileID
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	latestRequest, err := u.repo.GetLatestVerificationRequestByGuideProfileID(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("get latest verification request: %w", err)
	}

	var documents []*model.GuideDocument
	if latestRequest != nil {
		documents, err = u.repo.ListGuideDocumentsByVerificationRequestID(ctx, latestRequest.ID)
		if err != nil {
			return nil, fmt.Errorf("list guide documents: %w", err)
		}
	}

	languages, err := u.repo.ListGuideLanguages(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("list guide languages: %w", err)
	}

	specializations, err := u.repo.ListGuideSpecializations(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("list guide specializations: %w", err)
	}

	return &GuideAggregate{
		Profile:             profile,
		VerificationRequest: latestRequest,
		Documents:           documents,
		Languages:           languages,
		Specializations:     specializations,
	}, nil
}

func (u *GuideUseCase) GetGuideAggregateByUserID(ctx context.Context, userID uuid.UUID) (*GuideAggregate, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidGuideUserID
	}

	profile, err := u.repo.GetGuideProfileByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by user id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func (u *GuideUseCase) ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error) {
	if u.userClient == nil {
		return uuid.Nil, fmt.Errorf("user service client is not configured")
	}

	return u.userClient.ResolveUserIDBySubject(ctx, subject)
}

type UpdateGuideProfileInput struct {
	ProfileID               uuid.UUID
	Headline                *string
	About                   *string
	ExperienceYears         *int
	BaseCityID              *uuid.UUID
	IsPrivateGuideAvailable *bool
	IsActivityHostAvailable *bool
	IsTourGuideAvailable    *bool
	Languages               []GuideLanguageInput
	Specializations         []GuideSpecializationInput
}

type GuideLanguageInput struct {
	LanguageCode     string
	ProficiencyLevel string
}

type GuideSpecializationInput struct {
	SpecializationCode string
}

func (u *GuideUseCase) UpdateGuideProfile(ctx context.Context, input UpdateGuideProfileInput) (*GuideAggregate, error) {
	if input.ProfileID == uuid.Nil {
		return nil, ErrInvalidGuideProfileID
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, input.ProfileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	if err = profile.ApplyUpdate(model.UpdateGuideProfileParams{
		Headline:                input.Headline,
		About:                   input.About,
		ExperienceYears:         input.ExperienceYears,
		BaseCityID:              input.BaseCityID,
		IsPrivateGuideAvailable: input.IsPrivateGuideAvailable,
		IsActivityHostAvailable: input.IsActivityHostAvailable,
		IsTourGuideAvailable:    input.IsTourGuideAvailable,
	}); err != nil {
		return nil, fmt.Errorf("apply guide profile update: %w", err)
	}

	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}

	if input.Languages != nil {
		items := make([]*model.GuideLanguage, 0, len(input.Languages))
		for _, lang := range input.Languages {
			item, createErr := model.NewGuideLanguage(model.NewGuideLanguageParams{
				GuideProfileID:   profile.ID,
				LanguageCode:     lang.LanguageCode,
				ProficiencyLevel: lang.ProficiencyLevel,
			})
			if createErr != nil {
				return nil, fmt.Errorf("new guide language: %w", createErr)
			}
			items = append(items, item)
		}

		if err = u.repo.ReplaceGuideLanguages(ctx, profile.ID, items); err != nil {
			return nil, fmt.Errorf("replace guide languages: %w", err)
		}
	}

	if input.Specializations != nil {
		items := make([]*model.GuideSpecialization, 0, len(input.Specializations))
		for _, spec := range input.Specializations {
			item, createErr := model.NewGuideSpecialization(model.NewGuideSpecializationParams{
				GuideProfileID:     profile.ID,
				SpecializationCode: spec.SpecializationCode,
			})
			if createErr != nil {
				return nil, fmt.Errorf("new guide specialization: %w", createErr)
			}
			items = append(items, item)
		}

		if err = u.repo.ReplaceGuideSpecializations(ctx, profile.ID, items); err != nil {
			return nil, fmt.Errorf("replace guide specializations: %w", err)
		}
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

type CreateVerificationRequestInput struct {
	GuideProfileID uuid.UUID
	Comment        *string
}

func (u *GuideUseCase) CreateVerificationRequest(
	ctx context.Context,
	input CreateVerificationRequestInput,
) (*model.GuideVerificationRequest, error) {
	if input.GuideProfileID == uuid.Nil {
		return nil, ErrInvalidGuideProfileID
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, input.GuideProfileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	req, err := model.NewGuideVerificationRequest(model.NewGuideVerificationRequestParams{
		GuideProfileID: input.GuideProfileID,
		Comment:        input.Comment,
	})
	if err != nil {
		return nil, fmt.Errorf("new verification request: %w", err)
	}

	if err = req.Submit(input.Comment); err != nil {
		return nil, fmt.Errorf("submit verification request: %w", err)
	}

	if err = profile.SubmitForReview(); err != nil {
		return nil, fmt.Errorf("submit guide profile for review: %w", err)
	}

	if err = u.repo.CreateVerificationRequest(ctx, req); err != nil {
		return nil, fmt.Errorf("create verification request: %w", err)
	}
	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile status: %w", err)
	}

	return req, nil
}

type SubmitGuideApplicationInput struct {
	UserID                     uuid.UUID
	Type                       string
	Headline                   *string
	About                      *string
	ExperienceYears            *int
	BaseCityID                 *uuid.UUID
	IsPrivateGuideAvailable    *bool
	IsActivityHostAvailable    *bool
	IsTourGuideAvailable       *bool
	Comment                    *string
	IdentityDocumentFileID     uuid.UUID
	IdentityDocumentType       string
	ProfessionalDocumentFileID uuid.UUID
	ProfessionalDocumentType   string
	FirstAidCertificateFileID  *uuid.UUID
	LanguageCertificateFileID  *uuid.UUID
}

func (u *GuideUseCase) SubmitGuideApplication(
	ctx context.Context,
	input SubmitGuideApplicationInput,
) (*GuideAggregate, error) {
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidGuideUserID
	}
	if input.IdentityDocumentFileID == uuid.Nil ||
		input.ProfessionalDocumentFileID == uuid.Nil {
		return nil, ErrGuideDocumentsRequired
	}
	if strings.TrimSpace(input.IdentityDocumentType) == "" ||
		strings.TrimSpace(input.ProfessionalDocumentType) == "" {
		return nil, model.ErrInvalidGuideDocumentType
	}

	if u.userClient == nil {
		return nil, fmt.Errorf("user service client is not configured")
	}
	if err := u.userClient.ValidateUserExists(ctx, input.UserID); err != nil {
		return nil, err
	}
	if u.fileClient == nil {
		return nil, fmt.Errorf("file manager client is not configured")
	}

	profile, err := u.repo.GetGuideProfileByUserID(ctx, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by user id: %w", err)
	}
	isNewProfile := profile == nil

	var latestRequest *model.GuideVerificationRequest
	if profile != nil {
		latestRequest, err = u.repo.GetLatestVerificationRequestByGuideProfileID(ctx, profile.ID)
		if err != nil {
			return nil, fmt.Errorf("get latest verification request: %w", err)
		}
		if latestRequest != nil {
			switch latestRequest.Status {
			case enum.VerificationRequestStatusSubmitted, enum.VerificationRequestStatusUnderReview:
				return nil, ErrGuideApplicationPending
			}
		}
		if profile.Status == enum.GuideStatusActive {
			return nil, ErrGuideProfileAlreadyActive
		}
	}

	if err = u.fileClient.ValidateGuideDocumentFile(ctx, input.IdentityDocumentFileID); err != nil {
		return nil, err
	}
	if err = u.fileClient.ValidateGuideDocumentFile(ctx, input.ProfessionalDocumentFileID); err != nil {
		return nil, err
	}
	if input.FirstAidCertificateFileID != nil && *input.FirstAidCertificateFileID != uuid.Nil {
		if err = u.fileClient.ValidateGuideDocumentFile(ctx, *input.FirstAidCertificateFileID); err != nil {
			return nil, err
		}
	}
	if input.LanguageCertificateFileID != nil && *input.LanguageCertificateFileID != uuid.Nil {
		if err = u.fileClient.ValidateGuideDocumentFile(ctx, *input.LanguageCertificateFileID); err != nil {
			return nil, err
		}
	}

	if isNewProfile {
		guideType := enum.GuideType(strings.TrimSpace(input.Type))
		if !guideType.IsValid() {
			return nil, model.ErrInvalidGuideType
		}

		profile, err = model.NewGuideProfile(model.NewGuideProfileParams{
			UserID: input.UserID,
			Type:   guideType,
		})
		if err != nil {
			return nil, fmt.Errorf("new guide profile: %w", err)
		}
	}

	if err = profile.ApplyUpdate(model.UpdateGuideProfileParams{
		Headline:                input.Headline,
		About:                   input.About,
		ExperienceYears:         input.ExperienceYears,
		BaseCityID:              input.BaseCityID,
		IsPrivateGuideAvailable: input.IsPrivateGuideAvailable,
		IsActivityHostAvailable: input.IsActivityHostAvailable,
		IsTourGuideAvailable:    input.IsTourGuideAvailable,
	}); err != nil {
		return nil, fmt.Errorf("apply guide profile update: %w", err)
	}

	if isNewProfile {
		if err = u.repo.CreateGuideProfile(ctx, profile); err != nil {
			return nil, fmt.Errorf("create guide profile: %w", err)
		}
	} else if latestRequest != nil && latestRequest.Status == enum.VerificationRequestStatusDraft {
		if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
			return nil, fmt.Errorf("update guide profile: %w", err)
		}
	} else {
		if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
			return nil, fmt.Errorf("update guide profile: %w", err)
		}
	}

	request := latestRequest
	if request == nil || request.Status != enum.VerificationRequestStatusDraft {
		request, err = model.NewGuideVerificationRequest(model.NewGuideVerificationRequestParams{
			GuideProfileID: profile.ID,
			Comment:        input.Comment,
		})
		if err != nil {
			return nil, fmt.Errorf("new verification request: %w", err)
		}
		if err = u.repo.CreateVerificationRequest(ctx, request); err != nil {
			return nil, fmt.Errorf("create verification request: %w", err)
		}
	}

	existingDocs, err := u.repo.ListGuideDocumentsByVerificationRequestID(ctx, request.ID)
	if err != nil {
		return nil, fmt.Errorf("list guide documents: %w", err)
	}

	existingByFileID := make(map[uuid.UUID]struct{}, len(existingDocs))
	for _, item := range existingDocs {
		existingByFileID[item.FileID] = struct{}{}
	}

	documents := []struct {
		fileID       uuid.UUID
		documentType string
	}{
		{
			fileID:       input.IdentityDocumentFileID,
			documentType: input.IdentityDocumentType,
		},
		{
			fileID:       input.ProfessionalDocumentFileID,
			documentType: input.ProfessionalDocumentType,
		},
	}
	if input.FirstAidCertificateFileID != nil && *input.FirstAidCertificateFileID != uuid.Nil {
		documents = append(documents, struct {
			fileID       uuid.UUID
			documentType string
		}{
			fileID:       *input.FirstAidCertificateFileID,
			documentType: "FIRST_AID_CERTIFICATE",
		})
	}
	if input.LanguageCertificateFileID != nil && *input.LanguageCertificateFileID != uuid.Nil {
		documents = append(documents, struct {
			fileID       uuid.UUID
			documentType string
		}{
			fileID:       *input.LanguageCertificateFileID,
			documentType: "LANGUAGE_PROFICIENCY_CERTIFICATE",
		})
	}

	for _, item := range documents {
		if _, exists := existingByFileID[item.fileID]; exists {
			continue
		}

		doc, createErr := model.NewGuideDocument(model.NewGuideDocumentParams{
			VerificationRequestID: request.ID,
			FileID:                item.fileID,
			DocumentType:          item.documentType,
		})
		if createErr != nil {
			return nil, fmt.Errorf("new guide document: %w", createErr)
		}

		if err = u.repo.AddGuideDocument(ctx, doc); err != nil {
			return nil, fmt.Errorf("add guide document: %w", err)
		}
		if err = u.fileClient.BindGuideDocumentToVerificationRequest(
			ctx,
			item.fileID,
			request.ID,
			&input.UserID,
		); err != nil {
			return nil, fmt.Errorf("bind guide document in file-manager: %w", err)
		}
	}

	if err = request.Submit(input.Comment); err != nil {
		return nil, fmt.Errorf("submit verification request: %w", err)
	}
	if err = profile.SubmitForReview(); err != nil {
		return nil, fmt.Errorf("submit guide profile for review: %w", err)
	}

	if err = u.repo.UpdateVerificationRequest(ctx, request); err != nil {
		return nil, fmt.Errorf("update verification request: %w", err)
	}
	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile status: %w", err)
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

type AttachGuideDocumentInput struct {
	VerificationRequestID uuid.UUID
	FileID                uuid.UUID
	DocumentType          string
	CreatedByUserID       *uuid.UUID
}

func (u *GuideUseCase) AttachGuideDocument(
	ctx context.Context,
	input AttachGuideDocumentInput,
) (*model.GuideDocument, error) {
	if input.VerificationRequestID == uuid.Nil {
		return nil, ErrVerificationRequestNotFound
	}
	if input.FileID == uuid.Nil {
		return nil, ErrGuideDocumentFileNotFound
	}

	req, err := u.repo.GetVerificationRequestByID(ctx, input.VerificationRequestID)
	if err != nil {
		return nil, fmt.Errorf("get verification request by id: %w", err)
	}
	if req == nil {
		return nil, ErrVerificationRequestNotFound
	}

	if u.fileClient == nil {
		return nil, fmt.Errorf("file manager client is not configured")
	}
	if err = u.fileClient.ValidateGuideDocumentFile(ctx, input.FileID); err != nil {
		return nil, err
	}

	doc, err := model.NewGuideDocument(model.NewGuideDocumentParams{
		VerificationRequestID: input.VerificationRequestID,
		FileID:                input.FileID,
		DocumentType:          input.DocumentType,
	})
	if err != nil {
		return nil, fmt.Errorf("new guide document: %w", err)
	}

	if err = u.repo.AddGuideDocument(ctx, doc); err != nil {
		return nil, fmt.Errorf("add guide document: %w", err)
	}

	if err = u.fileClient.BindGuideDocumentToVerificationRequest(
		ctx,
		input.FileID,
		input.VerificationRequestID,
		input.CreatedByUserID,
	); err != nil {
		return nil, fmt.Errorf("bind guide document in file-manager: %w", err)
	}

	return doc, nil
}

func (u *GuideUseCase) ListPublicGuideProfiles(
	ctx context.Context,
	limit int,
	offset int,
) ([]*model.GuideProfile, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListPublicGuideProfiles(ctx, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list public guide profiles: %w", err)
	}

	return items, nil
}

type ReviewVerificationRequestInput struct {
	VerificationRequestID uuid.UUID
	ReviewerID            *uuid.UUID
	ReviewComment         *string
}

func (u *GuideUseCase) ApproveVerificationRequest(
	ctx context.Context,
	input ReviewVerificationRequestInput,
) (*GuideAggregate, error) {
	if input.VerificationRequestID == uuid.Nil {
		return nil, ErrVerificationRequestNotFound
	}

	req, err := u.repo.GetVerificationRequestByID(ctx, input.VerificationRequestID)
	if err != nil {
		return nil, fmt.Errorf("get verification request by id: %w", err)
	}
	if req == nil {
		return nil, ErrVerificationRequestNotFound
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, req.GuideProfileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	if err = req.Approve(input.ReviewerID, input.ReviewComment); err != nil {
		return nil, fmt.Errorf("approve verification request: %w", err)
	}

	if err = profile.Activate(); err != nil {
		return nil, fmt.Errorf("activate guide profile: %w", err)
	}

	if err = u.repo.UpdateVerificationRequest(ctx, req); err != nil {
		return nil, fmt.Errorf("update verification request: %w", err)
	}
	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}
	if u.userClient != nil {
		if err = u.userClient.GrantGuideRole(ctx, profile.UserID, input.ReviewerID); err != nil {
			return nil, fmt.Errorf("grant guide role: %w", err)
		}
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func (u *GuideUseCase) RejectVerificationRequest(
	ctx context.Context,
	input ReviewVerificationRequestInput,
) (*GuideAggregate, error) {
	if input.VerificationRequestID == uuid.Nil {
		return nil, ErrVerificationRequestNotFound
	}

	req, err := u.repo.GetVerificationRequestByID(ctx, input.VerificationRequestID)
	if err != nil {
		return nil, fmt.Errorf("get verification request by id: %w", err)
	}
	if req == nil {
		return nil, ErrVerificationRequestNotFound
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, req.GuideProfileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	if err = req.Reject(input.ReviewerID, input.ReviewComment); err != nil {
		return nil, fmt.Errorf("reject verification request: %w", err)
	}

	if err = profile.Reject(); err != nil {
		return nil, fmt.Errorf("reject guide profile: %w", err)
	}

	if err = u.repo.UpdateVerificationRequest(ctx, req); err != nil {
		return nil, fmt.Errorf("update verification request: %w", err)
	}
	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func (u *GuideUseCase) SuspendGuideProfile(
	ctx context.Context,
	profileID uuid.UUID,
) (*GuideAggregate, error) {
	if profileID == uuid.Nil {
		return nil, ErrInvalidGuideProfileID
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	profile.Status = enum.GuideStatusSuspended
	profile.UpdatedAt = time.Now().UTC()

	if err = profile.Validate(); err != nil {
		return nil, fmt.Errorf("validate suspended guide profile: %w", err)
	}

	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func (u *GuideUseCase) ActivateGuideProfile(
	ctx context.Context,
	profileID uuid.UUID,
) (*GuideAggregate, error) {
	if profileID == uuid.Nil {
		return nil, ErrInvalidGuideProfileID
	}

	profile, err := u.repo.GetGuideProfileByID(ctx, profileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}

	if err = profile.Activate(); err != nil {
		return nil, fmt.Errorf("activate guide profile: %w", err)
	}

	if err = u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}

	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func (u *GuideUseCase) ListPendingVerificationRequests(
	ctx context.Context,
	limit int,
	offset int,
) ([]*model.GuideVerificationRequest, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListVerificationRequestsByStatuses(ctx, []enum.VerificationRequestStatus{
		enum.VerificationRequestStatusSubmitted,
		enum.VerificationRequestStatusUnderReview,
	}, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list pending verification requests: %w", err)
	}

	return items, nil
}

type PublicGuideCard struct {
	GuideProfile *model.GuideProfile
	UserProfile  *PublicUserProfile
}

func (u *GuideUseCase) ListPublicGuideCards(
	ctx context.Context,
	limit int,
	offset int,
) ([]*PublicGuideCard, error) {
	items, err := u.ListPublicGuideProfiles(ctx, limit, offset)
	if err != nil {
		return nil, err
	}

	if len(items) == 0 {
		return []*PublicGuideCard{}, nil
	}

	if u.userClient == nil {
		result := make([]*PublicGuideCard, 0, len(items))
		for _, item := range items {
			result = append(result, &PublicGuideCard{
				GuideProfile: item,
			})
		}
		return result, nil
	}

	userIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		userIDs = append(userIDs, item.UserID)
	}

	userProfiles, err := u.userClient.GetPublicUserProfiles(ctx, userIDs)
	if err != nil {
		return nil, fmt.Errorf("get public user profiles: %w", err)
	}

	result := make([]*PublicGuideCard, 0, len(items))
	for _, item := range items {
		card := &PublicGuideCard{
			GuideProfile: item,
		}
		if profile, ok := userProfiles[item.UserID]; ok {
			p := profile
			card.UserProfile = &p
		}
		result = append(result, card)
	}

	return result, nil
}
