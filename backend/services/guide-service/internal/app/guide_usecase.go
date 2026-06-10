package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

type GuideAggregate struct {
	Profile             *model.GuideProfile
	UserProfile         *PublicUserProfile
	VerificationRequest *model.GuideVerificationRequest
	Documents           []*model.GuideDocument
	Languages           []*model.GuideLanguage
	Specializations     []*model.GuideSpecialization
}

type GuideUseCase struct {
	repo            port.GuideRepository
	userClient      UserServiceClient
	fileClient      FileManagerClient
	excursionClient GuideExcursionCoverageClient
	fraud           port.FraudEvaluator
}

func NewGuideUseCase(
	repo port.GuideRepository,
	userClient UserServiceClient,
	fileClient FileManagerClient,
	excursionClients ...GuideExcursionCoverageClient,
) *GuideUseCase {
	return NewGuideUseCaseWithFraud(repo, userClient, fileClient, nil, excursionClients...)
}

func NewGuideUseCaseWithFraud(
	repo port.GuideRepository,
	userClient UserServiceClient,
	fileClient FileManagerClient,
	fraud port.FraudEvaluator,
	excursionClients ...GuideExcursionCoverageClient,
) *GuideUseCase {
	var excursionClient GuideExcursionCoverageClient
	if len(excursionClients) > 0 {
		excursionClient = excursionClients[0]
	}
	return &GuideUseCase{
		repo:            repo,
		userClient:      userClient,
		fileClient:      fileClient,
		excursionClient: excursionClient,
		fraud:           fraud,
	}
}

type GuideExcursionCityFilter struct {
	CityID      string
	CityName    string
	CountryCode string
}

type GuideExcursionCoverageClient interface {
	ListGuideUserIDsByCity(ctx context.Context, input GuideExcursionCityFilter) ([]uuid.UUID, error)
	ArchiveGuideExcursionOffers(ctx context.Context, guideUserID uuid.UUID) error
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

	aggregate := &GuideAggregate{
		Profile:             profile,
		VerificationRequest: latestRequest,
		Documents:           documents,
		Languages:           languages,
		Specializations:     specializations,
	}
	u.attachPublicUserProfile(ctx, aggregate)

	return aggregate, nil
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

func (u *GuideUseCase) GetVerificationRequestAggregateByID(
	ctx context.Context,
	verificationRequestID uuid.UUID,
) (*GuideAggregate, error) {
	if verificationRequestID == uuid.Nil {
		return nil, ErrVerificationRequestNotFound
	}
	req, err := u.repo.GetVerificationRequestByID(ctx, verificationRequestID)
	if err != nil {
		return nil, fmt.Errorf("get verification request by id: %w", err)
	}
	if req == nil {
		return nil, ErrVerificationRequestNotFound
	}
	return u.GetGuideAggregateByProfileID(ctx, req.GuideProfileID)
}

func (u *GuideUseCase) ListPendingVerificationApplicationAggregates(
	ctx context.Context,
	limit int,
	offset int,
) ([]*GuideAggregate, error) {
	requests, err := u.ListPendingVerificationRequests(ctx, limit, offset)
	if err != nil {
		return nil, err
	}
	result := make([]*GuideAggregate, 0, len(requests))
	for _, request := range requests {
		if request == nil {
			continue
		}
		aggregate, aggregateErr := u.GetGuideAggregateByProfileID(ctx, request.GuideProfileID)
		if aggregateErr != nil {
			return nil, aggregateErr
		}
		if aggregate.VerificationRequest != nil && aggregate.VerificationRequest.ID == request.ID {
			result = append(result, aggregate)
		}
	}
	return result, nil
}

func (u *GuideUseCase) CreateGuideDocumentDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	if fileID == uuid.Nil {
		return "", ErrGuideDocumentFileNotFound
	}
	if u.fileClient == nil {
		return "", fmt.Errorf("file manager client is not configured")
	}
	return u.fileClient.CreateGuideDocumentDownloadURL(ctx, fileID)
}

func (u *GuideUseCase) attachPublicUserProfile(ctx context.Context, aggregate *GuideAggregate) {
	if u.userClient == nil || aggregate == nil || aggregate.Profile == nil {
		return
	}

	profile, err := u.userClient.GetUserProfile(ctx, aggregate.Profile.UserID)
	if err == nil && profile != nil {
		aggregate.UserProfile = profile
		return
	}

	profiles, err := u.userClient.GetPublicUserProfiles(ctx, []uuid.UUID{aggregate.Profile.UserID})
	if err != nil {
		return
	}
	if profile, ok := profiles[aggregate.Profile.UserID]; ok {
		p := profile
		aggregate.UserProfile = &p
	}
}

func (u *GuideUseCase) ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error) {
	if u.userClient == nil {
		return uuid.Nil, fmt.Errorf("user service client is not configured")
	}

	return u.userClient.ResolveUserIDBySubject(ctx, subject)
}

type UpdateGuideProfileInput struct {
	ProfileID                 uuid.UUID
	Headline                  *string
	About                     *string
	ExperienceYears           *int
	BaseCityID                *uuid.UUID
	IsPrivateGuideAvailable   *bool
	IsActivityHostAvailable   *bool
	IsExcursionGuideAvailable *bool
	Languages                 []GuideLanguageInput
	Specializations           []GuideSpecializationInput
}

type GuideLanguageInput struct {
	LanguageCode     string
	ProficiencyLevel string
}

type GuideSpecializationInput struct {
	SpecializationCode string
}

type GuideRatingSnapshotInput struct {
	GuideProfileID uuid.UUID
	RatingAvg      float64
	ReviewsCount   int
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
		Headline:                  input.Headline,
		About:                     input.About,
		ExperienceYears:           input.ExperienceYears,
		BaseCityID:                input.BaseCityID,
		IsPrivateGuideAvailable:   input.IsPrivateGuideAvailable,
		IsActivityHostAvailable:   input.IsActivityHostAvailable,
		IsExcursionGuideAvailable: input.IsExcursionGuideAvailable,
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

func (u *GuideUseCase) ApplyGuideRatingSnapshots(ctx context.Context, items []GuideRatingSnapshotInput) error {
	for _, item := range items {
		if item.GuideProfileID == uuid.Nil {
			return ErrInvalidGuideProfileID
		}
		if item.RatingAvg < 0 || item.RatingAvg > 5 {
			return model.ErrInvalidRatingAverage
		}
		if item.ReviewsCount < 0 {
			return model.ErrInvalidReviewsCount
		}
		if err := u.repo.UpdateGuideRatingSnapshot(ctx, item.GuideProfileID, item.RatingAvg, item.ReviewsCount); err != nil {
			return fmt.Errorf("update guide rating snapshot: %w", err)
		}
	}
	return nil
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
	IsExcursionGuideAvailable  *bool
	Comment                    *string
	IdentityDocumentFileID     uuid.UUID
	IdentityDocumentType       string
	ProfessionalDocumentFileID uuid.UUID
	ProfessionalDocumentType   string
	FirstAidCertificateFileID  *uuid.UUID
	LanguageCertificateFileID  *uuid.UUID
	ClientIP                   string
	DeviceID                   string
	UserAgent                  string
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

	if err = u.enforceGuideFraud(ctx, port.FraudAssessmentInput{
		Action:      "GUIDE_APPLICATION",
		ActorUserID: input.UserID,
		SubjectType: "GUIDE_USER",
		SubjectID:   &input.UserID,
		ClientIP:    input.ClientIP,
		DeviceID:    input.DeviceID,
		UserAgent:   input.UserAgent,
		Metadata: map[string]any{
			"identityDocumentType":       input.IdentityDocumentType,
			"professionalDocumentType":   input.ProfessionalDocumentType,
			"hasFirstAidCertificate":     input.FirstAidCertificateFileID != nil && *input.FirstAidCertificateFileID != uuid.Nil,
			"hasLanguageCertificate":     input.LanguageCertificateFileID != nil && *input.LanguageCertificateFileID != uuid.Nil,
			"isPrivateGuideAvailable":    valueOrFalse(input.IsPrivateGuideAvailable),
			"isActivityHostAvailable":    valueOrFalse(input.IsActivityHostAvailable),
			"isExcursionGuideAvailable":  valueOrFalse(input.IsExcursionGuideAvailable),
			"identityDocumentFileId":     input.IdentityDocumentFileID.String(),
			"professionalDocumentFileId": input.ProfessionalDocumentFileID.String(),
		},
	}); err != nil {
		return nil, err
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
		Headline:                  input.Headline,
		About:                     input.About,
		ExperienceYears:           input.ExperienceYears,
		BaseCityID:                input.BaseCityID,
		IsPrivateGuideAvailable:   input.IsPrivateGuideAvailable,
		IsActivityHostAvailable:   input.IsActivityHostAvailable,
		IsExcursionGuideAvailable: input.IsExcursionGuideAvailable,
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
	ClientIP              string
	DeviceID              string
	UserAgent             string
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

	var actor uuid.UUID
	if input.CreatedByUserID != nil {
		actor = *input.CreatedByUserID
	}
	if err = u.enforceGuideFraud(ctx, port.FraudAssessmentInput{
		Action:      "GUIDE_DOCUMENT_ATTACH",
		ActorUserID: actor,
		SubjectType: "GUIDE_VERIFICATION_REQUEST",
		SubjectID:   &input.VerificationRequestID,
		ClientIP:    input.ClientIP,
		DeviceID:    input.DeviceID,
		UserAgent:   input.UserAgent,
		Metadata: map[string]any{
			"documentType": input.DocumentType,
			"fileId":       input.FileID.String(),
		},
	}); err != nil {
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

func (u *GuideUseCase) enforceGuideFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if u.fraud == nil {
		return nil
	}

	decision, err := u.fraud.AssessGuide(ctx, input)
	if err != nil {
		return fmt.Errorf("assess guide fraud: %w", err)
	}
	if decision == nil || decision.ShadowMode || decision.Decision == "" || decision.Decision == port.FraudDecisionAllow || decision.Decision == port.FraudDecisionReview {
		return nil
	}
	return ErrFraudRejected
}

func valueOrFalse(value *bool) bool {
	return value != nil && *value
}

type ListPublicGuidesInput struct {
	Query               string
	CityID              string
	CityName            string
	CityCountryCode     string
	CountryCodes        []string
	UserIDs             []uuid.UUID
	LanguageCodes       []string
	SpecializationCodes []string
	MinRating           *float64
	MinExperienceYears  *int
	Sort                string
	Limit               int
	Offset              int
}

func (u *GuideUseCase) ListPublicGuideProfiles(
	ctx context.Context,
	input ListPublicGuidesInput,
) (port.PublicGuideListResult, error) {
	filter := normalizePublicGuideListFilter(input)
	cityFilter := normalizeGuideExcursionCityFilter(input.CityID, input.CityName, input.CityCountryCode)
	if cityFilter.CityID != "" || cityFilter.CityName != "" {
		if u.excursionClient == nil {
			return port.PublicGuideListResult{}, fmt.Errorf("excursion coverage client is not configured")
		}
		guideUserIDs, err := u.excursionClient.ListGuideUserIDsByCity(ctx, cityFilter)
		if err != nil {
			return port.PublicGuideListResult{}, fmt.Errorf("list guide user ids by excursion city: %w", err)
		}
		guideUserIDs = uniqueGuideUserIDs(guideUserIDs)
		if len(guideUserIDs) == 0 {
			return port.PublicGuideListResult{
				Items: []*model.GuideProfile{},
				Total: 0,
			}, nil
		}
		filter.UserIDs = intersectGuideUserIDs(filter.UserIDs, guideUserIDs)
		if len(filter.UserIDs) == 0 {
			return port.PublicGuideListResult{
				Items: []*model.GuideProfile{},
				Total: 0,
			}, nil
		}
	}

	if len(filter.CountryCodes) > 0 {
		if u.userClient == nil {
			return port.PublicGuideListResult{}, fmt.Errorf("user service client is not configured")
		}

		userIDs, err := u.userClient.ListPublicUserIDsByCountryCodes(ctx, filter.CountryCodes)
		if err != nil {
			return port.PublicGuideListResult{}, fmt.Errorf("list public guide user ids by country codes: %w", err)
		}
		if len(userIDs) == 0 {
			return port.PublicGuideListResult{
				Items: []*model.GuideProfile{},
				Total: 0,
			}, nil
		}
		filter.UserIDs = intersectGuideUserIDs(filter.UserIDs, userIDs)
		if len(filter.UserIDs) == 0 {
			return port.PublicGuideListResult{
				Items: []*model.GuideProfile{},
				Total: 0,
			}, nil
		}
	}

	items, err := u.repo.ListPublicGuideProfiles(ctx, filter)
	if err != nil {
		return port.PublicGuideListResult{}, fmt.Errorf("list public guide profiles: %w", err)
	}

	return items, nil
}

func normalizePublicGuideListFilter(input ListPublicGuidesInput) port.PublicGuideListFilter {
	limit := input.Limit
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	return port.PublicGuideListFilter{
		Query:               strings.TrimSpace(input.Query),
		CountryCodes:        normalizePublicGuideCodes(input.CountryCodes),
		UserIDs:             uniqueGuideUserIDs(input.UserIDs),
		LanguageCodes:       normalizePublicGuideCodes(input.LanguageCodes),
		SpecializationCodes: normalizePublicGuideCodes(input.SpecializationCodes),
		MinRating:           input.MinRating,
		MinExperienceYears:  input.MinExperienceYears,
		Sort:                normalizePublicGuideSort(input.Sort),
		Limit:               limit,
		Offset:              offset,
	}
}

func normalizeGuideExcursionCityFilter(cityID string, cityName string, countryCode string) GuideExcursionCityFilter {
	return GuideExcursionCityFilter{
		CityID:      strings.ToLower(strings.TrimSpace(cityID)),
		CityName:    strings.TrimSpace(cityName),
		CountryCode: strings.ToUpper(strings.TrimSpace(countryCode)),
	}
}

func uniqueGuideUserIDs(ids []uuid.UUID) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(ids))
	seen := make(map[uuid.UUID]struct{}, len(ids))
	for _, id := range ids {
		if id == uuid.Nil {
			continue
		}
		if _, exists := seen[id]; exists {
			continue
		}
		seen[id] = struct{}{}
		result = append(result, id)
	}
	return result
}

func intersectGuideUserIDs(current []uuid.UUID, next []uuid.UUID) []uuid.UUID {
	next = uniqueGuideUserIDs(next)
	if len(current) == 0 {
		return next
	}
	allowed := make(map[uuid.UUID]struct{}, len(next))
	for _, id := range next {
		allowed[id] = struct{}{}
	}
	result := make([]uuid.UUID, 0, len(current))
	for _, id := range uniqueGuideUserIDs(current) {
		if _, ok := allowed[id]; ok {
			result = append(result, id)
		}
	}
	return result
}

func normalizePublicGuideSort(sort string) port.PublicGuideSort {
	switch port.PublicGuideSort(strings.TrimSpace(strings.ToLower(sort))) {
	case port.PublicGuideSortRatingAsc:
		return port.PublicGuideSortRatingAsc
	case port.PublicGuideSortExperienceDesc:
		return port.PublicGuideSortExperienceDesc
	case port.PublicGuideSortExperienceAsc:
		return port.PublicGuideSortExperienceAsc
	case port.PublicGuideSortNewestDesc:
		return port.PublicGuideSortNewestDesc
	case port.PublicGuideSortNewestAsc:
		return port.PublicGuideSortNewestAsc
	default:
		return port.PublicGuideSortRatingDesc
	}
}

func normalizePublicGuideCodes(codes []string) []string {
	seen := make(map[string]struct{}, len(codes))
	result := make([]string, 0, len(codes))
	for _, code := range codes {
		normalized := strings.TrimSpace(strings.ToLower(code))
		if normalized == "" {
			continue
		}
		if _, exists := seen[normalized]; exists {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	return result
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
	if !isVerificationRequestReviewable(req.Status) {
		return nil, ErrVerificationRequestNotReviewable
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
	if !isVerificationRequestReviewable(req.Status) {
		return nil, ErrVerificationRequestNotReviewable
	}
	if input.ReviewComment == nil || strings.TrimSpace(*input.ReviewComment) == "" {
		return nil, ErrReviewCommentRequired
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

type RevokeGuideStatusInput struct {
	VerificationRequestID uuid.UUID
	ReviewerID            *uuid.UUID
	PublicReason          string
}

type RevokeGuideProfileStatusInput struct {
	GuideProfileID uuid.UUID
	ReviewerID     *uuid.UUID
	PublicReason   string
}

func (u *GuideUseCase) RevokeGuideStatus(
	ctx context.Context,
	input RevokeGuideStatusInput,
) (*GuideAggregate, error) {
	if input.VerificationRequestID == uuid.Nil {
		return nil, ErrVerificationRequestNotFound
	}
	if strings.TrimSpace(input.PublicReason) == "" {
		return nil, ErrReviewCommentRequired
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
	return u.revokeGuideProfile(ctx, profile, input.ReviewerID, input.PublicReason)
}

func (u *GuideUseCase) RevokeGuideProfileStatus(
	ctx context.Context,
	input RevokeGuideProfileStatusInput,
) (*GuideAggregate, error) {
	if input.GuideProfileID == uuid.Nil {
		return nil, ErrGuideProfileNotFound
	}
	if strings.TrimSpace(input.PublicReason) == "" {
		return nil, ErrReviewCommentRequired
	}
	profile, err := u.repo.GetGuideProfileByID(ctx, input.GuideProfileID)
	if err != nil {
		return nil, fmt.Errorf("get guide profile by id: %w", err)
	}
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}
	return u.revokeGuideProfile(ctx, profile, input.ReviewerID, input.PublicReason)
}

func (u *GuideUseCase) revokeGuideProfile(
	ctx context.Context,
	profile *model.GuideProfile,
	reviewerID *uuid.UUID,
	publicReason string,
) (*GuideAggregate, error) {
	if profile == nil {
		return nil, ErrGuideProfileNotFound
	}
	if profile.Status != enum.GuideStatusActive {
		return nil, ErrGuideProfileNotActive
	}
	if err := profile.Revoke(publicReason, reviewerID); err != nil {
		return nil, fmt.Errorf("revoke guide profile: %w", err)
	}
	if u.excursionClient != nil {
		if err := u.excursionClient.ArchiveGuideExcursionOffers(ctx, profile.UserID); err != nil {
			return nil, fmt.Errorf("archive guide excursion offers: %w", err)
		}
	}
	if err := u.repo.UpdateGuideProfile(ctx, profile); err != nil {
		return nil, fmt.Errorf("update guide profile: %w", err)
	}
	if u.userClient != nil {
		if err := u.userClient.RevokeGuideRole(ctx, profile.UserID); err != nil {
			log.Ctx(ctx).Warn().
				Err(err).
				Stringer("guide_user_id", profile.UserID).
				Msg("failed to revoke guide role after guide status revocation")
		}
	}
	return u.GetGuideAggregateByProfileID(ctx, profile.ID)
}

func isVerificationRequestReviewable(status enum.VerificationRequestStatus) bool {
	return status == enum.VerificationRequestStatusSubmitted ||
		status == enum.VerificationRequestStatusUnderReview
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
	GuideProfile    *model.GuideProfile
	UserProfile     *PublicUserProfile
	Languages       []*model.GuideLanguage
	Specializations []*model.GuideSpecialization
}

type PublicGuideCardList struct {
	Items  []*PublicGuideCard
	Total  int
	Limit  int
	Offset int
}

func (u *GuideUseCase) ListPublicGuideCards(
	ctx context.Context,
	input ListPublicGuidesInput,
) (PublicGuideCardList, error) {
	profiles, err := u.ListPublicGuideProfiles(ctx, input)
	if err != nil {
		return PublicGuideCardList{}, err
	}

	items := profiles.Items
	if len(items) == 0 {
		filter := normalizePublicGuideListFilter(input)
		return PublicGuideCardList{
			Items:  []*PublicGuideCard{},
			Total:  profiles.Total,
			Limit:  filter.Limit,
			Offset: filter.Offset,
		}, nil
	}

	profileIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		profileIDs = append(profileIDs, item.ID)
	}

	languagesByProfileID, err := u.repo.ListGuideLanguagesByProfileIDs(ctx, profileIDs)
	if err != nil {
		return PublicGuideCardList{}, fmt.Errorf("list public guide languages: %w", err)
	}

	specializationsByProfileID, err := u.repo.ListGuideSpecializationsByProfileIDs(ctx, profileIDs)
	if err != nil {
		return PublicGuideCardList{}, fmt.Errorf("list public guide specializations: %w", err)
	}

	if u.userClient == nil {
		result := make([]*PublicGuideCard, 0, len(items))
		for _, item := range items {
			result = append(result, &PublicGuideCard{
				GuideProfile:    item,
				Languages:       languagesByProfileID[item.ID],
				Specializations: specializationsByProfileID[item.ID],
			})
		}
		filter := normalizePublicGuideListFilter(input)
		return PublicGuideCardList{
			Items:  result,
			Total:  profiles.Total,
			Limit:  filter.Limit,
			Offset: filter.Offset,
		}, nil
	}

	userIDs := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		userIDs = append(userIDs, item.UserID)
	}

	userProfiles, err := u.userClient.GetPublicUserProfiles(ctx, userIDs)
	if err != nil {
		return PublicGuideCardList{}, fmt.Errorf("get public user profiles: %w", err)
	}

	result := make([]*PublicGuideCard, 0, len(items))
	for _, item := range items {
		card := &PublicGuideCard{
			GuideProfile:    item,
			Languages:       languagesByProfileID[item.ID],
			Specializations: specializationsByProfileID[item.ID],
		}
		if profile, ok := userProfiles[item.UserID]; ok {
			p := profile
			card.UserProfile = &p
		}
		result = append(result, card)
	}

	filter := normalizePublicGuideListFilter(input)
	return PublicGuideCardList{
		Items:  result,
		Total:  profiles.Total,
		Limit:  filter.Limit,
		Offset: filter.Offset,
	}, nil
}

func (u *GuideUseCase) GetPublicGuideCardByUserID(
	ctx context.Context,
	userID uuid.UUID,
) (*PublicGuideCard, error) {
	if userID == uuid.Nil {
		return nil, ErrInvalidGuideUserID
	}

	result, err := u.ListPublicGuideCards(ctx, ListPublicGuidesInput{
		UserIDs: []uuid.UUID{userID},
		Limit:   1,
		Offset:  0,
	})
	if err != nil {
		return nil, err
	}
	if len(result.Items) == 0 {
		return nil, ErrGuideProfileNotFound
	}

	return result.Items[0], nil
}

func (u *GuideUseCase) ListPublicGuideFilterOptions(
	ctx context.Context,
) (port.PublicGuideFilterOptions, error) {
	options, err := u.repo.ListPublicGuideFilterOptions(ctx)
	if err != nil {
		return port.PublicGuideFilterOptions{}, fmt.Errorf("list public guide filter options: %w", err)
	}
	return options, nil
}
