package grpc

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/model"
	guidev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/guide/v1"
)

type Server struct {
	guidev1.UnimplementedGuideServiceServer
	useCase *app.GuideUseCase
}

func NewServer(useCase *app.GuideUseCase) *Server {
	return &Server{useCase: useCase}
}

func (s *Server) GetOrCreateGuideProfile(
	ctx context.Context,
	req *guidev1.GetOrCreateGuideProfileRequest,
) (*guidev1.GetOrCreateGuideProfileResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideUserID)
	}

	aggregate, err := s.useCase.GetOrCreateGuideProfile(ctx, app.InitGuideProfileInput{
		UserID: userID,
		Type:   req.GetType(),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.GetOrCreateGuideProfileResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) GetGuideProfileById(
	ctx context.Context,
	req *guidev1.GetGuideProfileByIdRequest,
) (*guidev1.GetGuideProfileByIdResponse, error) {
	profileID, err := uuid.Parse(strings.TrimSpace(req.GetGuideProfileId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	aggregate, err := s.useCase.GetGuideAggregateByProfileID(ctx, profileID)
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.GetGuideProfileByIdResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) GetGuideProfileByUserId(
	ctx context.Context,
	req *guidev1.GetGuideProfileByUserIdRequest,
) (*guidev1.GetGuideProfileByUserIdResponse, error) {
	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideUserID)
	}

	aggregate, err := s.useCase.GetGuideAggregateByUserID(ctx, userID)
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.GetGuideProfileByUserIdResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) UpdateGuideProfile(
	ctx context.Context,
	req *guidev1.UpdateGuideProfileRequest,
) (*guidev1.UpdateGuideProfileResponse, error) {
	profileID, err := uuid.Parse(strings.TrimSpace(req.GetGuideProfileId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	baseCityID, err := parseOptionalUUID(req.GetBaseCityId())
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	languages := make([]app.GuideLanguageInput, 0, len(req.GetLanguages()))
	for _, item := range req.GetLanguages() {
		languages = append(languages, app.GuideLanguageInput{
			LanguageCode:     item.GetLanguageCode(),
			ProficiencyLevel: item.GetProficiencyLevel(),
		})
	}

	specializations := make([]app.GuideSpecializationInput, 0, len(req.GetSpecializations()))
	for _, item := range req.GetSpecializations() {
		specializations = append(specializations, app.GuideSpecializationInput{
			SpecializationCode: item.GetSpecializationCode(),
		})
	}

	aggregate, err := s.useCase.UpdateGuideProfile(ctx, app.UpdateGuideProfileInput{
		ProfileID:                 profileID,
		Headline:                  stringPtrOrNil(req.GetHeadline()),
		About:                     stringPtrOrNil(req.GetAbout()),
		ExperienceYears:           optionalInt32ToInt(req.ExperienceYears),
		BaseCityID:                baseCityID,
		IsPrivateGuideAvailable:   optionalBoolPtr(req.IsPrivateGuideAvailable),
		IsActivityHostAvailable:   optionalBoolPtr(req.IsActivityHostAvailable),
		IsExcursionGuideAvailable: optionalBoolPtr(req.IsExcursionGuideAvailable),
		Languages:                 languages,
		Specializations:           specializations,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.UpdateGuideProfileResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) CreateVerificationRequest(
	ctx context.Context,
	req *guidev1.CreateVerificationRequestRequest,
) (*guidev1.CreateVerificationRequestResponse, error) {
	profileID, err := uuid.Parse(strings.TrimSpace(req.GetGuideProfileId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	item, err := s.useCase.CreateVerificationRequest(ctx, app.CreateVerificationRequestInput{
		GuideProfileID: profileID,
		Comment:        stringPtrOrNil(req.GetComment()),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.CreateVerificationRequestResponse{
		VerificationRequest: toProtoVerificationRequest(item),
	}, nil
}

func (s *Server) AttachVerificationDocument(
	ctx context.Context,
	req *guidev1.AttachVerificationDocumentRequest,
) (*guidev1.AttachVerificationDocumentResponse, error) {
	verificationRequestID, err := uuid.Parse(strings.TrimSpace(req.GetVerificationRequestId()))
	if err != nil {
		return nil, mapError(app.ErrVerificationRequestNotFound)
	}

	fileID, err := uuid.Parse(strings.TrimSpace(req.GetFileId()))
	if err != nil {
		return nil, mapError(app.ErrGuideDocumentFileNotFound)
	}

	var createdByUserID *uuid.UUID
	if strings.TrimSpace(req.GetCreatedByUserId()) != "" {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(req.GetCreatedByUserId()))
		if parseErr != nil {
			return nil, mapError(app.ErrInvalidGuideUserID)
		}
		createdByUserID = &parsed
	}

	doc, err := s.useCase.AttachGuideDocument(ctx, app.AttachGuideDocumentInput{
		VerificationRequestID: verificationRequestID,
		FileID:                fileID,
		DocumentType:          req.GetDocumentType(),
		CreatedByUserID:       createdByUserID,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.AttachVerificationDocumentResponse{
		Document: toProtoGuideDocument(doc),
	}, nil
}

func (s *Server) ListPublicGuides(
	ctx context.Context,
	req *guidev1.ListPublicGuidesRequest,
) (*guidev1.ListPublicGuidesResponse, error) {
	result, err := s.useCase.ListPublicGuideCards(ctx, app.ListPublicGuidesInput{
		Limit:  int(req.GetLimit()),
		Offset: int(req.GetOffset()),
	})
	if err != nil {
		return nil, mapError(err)
	}

	resp := &guidev1.ListPublicGuidesResponse{
		Items: make([]*guidev1.PublicGuideCard, 0, len(result.Items)),
	}

	for _, item := range result.Items {
		card := &guidev1.PublicGuideCard{
			GuideProfile: toProtoGuideProfile(item.GuideProfile),
		}

		if item.UserProfile != nil {
			card.UserProfile = toProtoPublicUserProfile(item.UserProfile)
		}

		resp.Items = append(resp.Items, card)
	}

	return resp, nil
}

func toProtoAggregate(aggregate *app.GuideAggregate) *guidev1.GuideAggregate {
	resp := &guidev1.GuideAggregate{
		Profile:         toProtoGuideProfile(aggregate.Profile),
		Documents:       make([]*guidev1.GuideDocument, 0, len(aggregate.Documents)),
		Languages:       make([]*guidev1.GuideLanguage, 0, len(aggregate.Languages)),
		Specializations: make([]*guidev1.GuideSpecialization, 0, len(aggregate.Specializations)),
	}

	if aggregate.VerificationRequest != nil {
		resp.VerificationRequest = toProtoVerificationRequest(aggregate.VerificationRequest)
	}
	if aggregate.UserProfile != nil {
		resp.UserProfile = toProtoPublicUserProfile(aggregate.UserProfile)
	}
	for _, item := range aggregate.Documents {
		resp.Documents = append(resp.Documents, toProtoGuideDocument(item))
	}
	for _, item := range aggregate.Languages {
		resp.Languages = append(resp.Languages, toProtoGuideLanguage(item))
	}
	for _, item := range aggregate.Specializations {
		resp.Specializations = append(resp.Specializations, toProtoGuideSpecialization(item))
	}

	return resp
}

func toProtoPublicUserProfile(profile *app.PublicUserProfile) *guidev1.PublicUserProfile {
	if profile == nil {
		return nil
	}
	var avatarFileID string
	if profile.AvatarFileID != nil {
		avatarFileID = profile.AvatarFileID.String()
	}
	return &guidev1.PublicUserProfile{
		UserId:       profile.UserID.String(),
		DisplayName:  valueOrEmpty(profile.DisplayName),
		AvatarFileId: avatarFileID,
		CountryCode:  valueOrEmpty(profile.CountryCode),
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
		IsPublic:     profile.IsPublic,
		FirstName:    valueOrEmpty(profile.FirstName),
		LastName:     valueOrEmpty(profile.LastName),
	}
}

func toProtoGuideProfile(profile *model.GuideProfile) *guidev1.GuideProfile {
	var baseCityID string
	if profile.BaseCityID != nil {
		baseCityID = profile.BaseCityID.String()
	}

	return &guidev1.GuideProfile{
		Id:                        profile.ID.String(),
		UserId:                    profile.UserID.String(),
		Type:                      string(profile.Type),
		Status:                    string(profile.Status),
		Headline:                  valueOrEmpty(profile.Headline),
		About:                     valueOrEmpty(profile.About),
		ExperienceYears:           int32(profile.ExperienceYears),
		BaseCityId:                baseCityID,
		IsPrivateGuideAvailable:   profile.IsPrivateGuideAvailable,
		IsActivityHostAvailable:   profile.IsActivityHostAvailable,
		IsExcursionGuideAvailable: profile.IsExcursionGuideAvailable,
		RatingAvg:                 profile.RatingAvg,
		ReviewsCount:              int32(profile.ReviewsCount),
		CreatedAt:                 profile.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                 profile.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoVerificationRequest(item *model.GuideVerificationRequest) *guidev1.VerificationRequest {
	var submittedAt string
	if item.SubmittedAt != nil {
		submittedAt = item.SubmittedAt.UTC().Format(time.RFC3339)
	}

	var reviewedAt string
	if item.ReviewedAt != nil {
		reviewedAt = item.ReviewedAt.UTC().Format(time.RFC3339)
	}

	var reviewedBy string
	if item.ReviewedBy != nil {
		reviewedBy = item.ReviewedBy.String()
	}

	return &guidev1.VerificationRequest{
		Id:             item.ID.String(),
		GuideProfileId: item.GuideProfileID.String(),
		Status:         string(item.Status),
		Comment:        valueOrEmpty(item.Comment),
		ReviewComment:  valueOrEmpty(item.ReviewComment),
		SubmittedAt:    submittedAt,
		ReviewedAt:     reviewedAt,
		ReviewedBy:     reviewedBy,
		CreatedAt:      item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:      item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoGuideDocument(item *model.GuideDocument) *guidev1.GuideDocument {
	return &guidev1.GuideDocument{
		Id:                    item.ID.String(),
		VerificationRequestId: item.VerificationRequestID.String(),
		FileId:                item.FileID.String(),
		DocumentType:          item.DocumentType,
		CreatedAt:             item.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoGuideLanguage(item *model.GuideLanguage) *guidev1.GuideLanguage {
	return &guidev1.GuideLanguage{
		Id:               item.ID.String(),
		GuideProfileId:   item.GuideProfileID.String(),
		LanguageCode:     item.LanguageCode,
		ProficiencyLevel: item.ProficiencyLevel,
		CreatedAt:        item.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoGuideSpecialization(item *model.GuideSpecialization) *guidev1.GuideSpecialization {
	return &guidev1.GuideSpecialization{
		Id:                 item.ID.String(),
		GuideProfileId:     item.GuideProfileID.String(),
		SpecializationCode: item.SpecializationCode,
		CreatedAt:          item.CreatedAt.UTC().Format(time.RFC3339),
	}
}

func stringPtrOrNil(v string) *string {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil
	}
	return &v
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

func parseOptionalUUID(v string) (*uuid.UUID, error) {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil, nil
	}
	parsed, err := uuid.Parse(v)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func optionalBoolPtr(v *bool) *bool {
	if v == nil {
		return nil
	}
	b := *v
	return &b
}

func optionalInt32ToInt(v *int32) *int {
	if v == nil {
		return nil
	}
	i := int(*v)
	return &i
}

func (s *Server) ApproveVerificationRequest(
	ctx context.Context,
	req *guidev1.ApproveVerificationRequestRequest,
) (*guidev1.ApproveVerificationRequestResponse, error) {
	requestID, err := uuid.Parse(strings.TrimSpace(req.GetVerificationRequestId()))
	if err != nil {
		return nil, mapError(app.ErrVerificationRequestNotFound)
	}

	var reviewerID *uuid.UUID
	if strings.TrimSpace(req.GetReviewerId()) != "" {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(req.GetReviewerId()))
		if parseErr != nil {
			return nil, mapError(app.ErrInvalidGuideUserID)
		}
		reviewerID = &parsed
	}

	aggregate, err := s.useCase.ApproveVerificationRequest(ctx, app.ReviewVerificationRequestInput{
		VerificationRequestID: requestID,
		ReviewerID:            reviewerID,
		ReviewComment:         stringPtrOrNil(req.GetReviewComment()),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.ApproveVerificationRequestResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) RejectVerificationRequest(
	ctx context.Context,
	req *guidev1.RejectVerificationRequestRequest,
) (*guidev1.RejectVerificationRequestResponse, error) {
	requestID, err := uuid.Parse(strings.TrimSpace(req.GetVerificationRequestId()))
	if err != nil {
		return nil, mapError(app.ErrVerificationRequestNotFound)
	}

	var reviewerID *uuid.UUID
	if strings.TrimSpace(req.GetReviewerId()) != "" {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(req.GetReviewerId()))
		if parseErr != nil {
			return nil, mapError(app.ErrInvalidGuideUserID)
		}
		reviewerID = &parsed
	}

	aggregate, err := s.useCase.RejectVerificationRequest(ctx, app.ReviewVerificationRequestInput{
		VerificationRequestID: requestID,
		ReviewerID:            reviewerID,
		ReviewComment:         stringPtrOrNil(req.GetReviewComment()),
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.RejectVerificationRequestResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) SuspendGuideProfile(
	ctx context.Context,
	req *guidev1.SuspendGuideProfileRequest,
) (*guidev1.SuspendGuideProfileResponse, error) {
	profileID, err := uuid.Parse(strings.TrimSpace(req.GetGuideProfileId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	aggregate, err := s.useCase.SuspendGuideProfile(ctx, profileID)
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.SuspendGuideProfileResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) ActivateGuideProfile(
	ctx context.Context,
	req *guidev1.ActivateGuideProfileRequest,
) (*guidev1.ActivateGuideProfileResponse, error) {
	profileID, err := uuid.Parse(strings.TrimSpace(req.GetGuideProfileId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidGuideProfileID)
	}

	aggregate, err := s.useCase.ActivateGuideProfile(ctx, profileID)
	if err != nil {
		return nil, mapError(err)
	}

	return &guidev1.ActivateGuideProfileResponse{
		Aggregate: toProtoAggregate(aggregate),
	}, nil
}

func (s *Server) ListPendingVerificationRequests(
	ctx context.Context,
	req *guidev1.ListPendingVerificationRequestsRequest,
) (*guidev1.ListPendingVerificationRequestsResponse, error) {
	items, err := s.useCase.ListPendingVerificationRequests(ctx, int(req.GetLimit()), int(req.GetOffset()))
	if err != nil {
		return nil, mapError(err)
	}

	resp := &guidev1.ListPendingVerificationRequestsResponse{
		Items: make([]*guidev1.VerificationQueueItem, 0, len(items)),
	}

	for _, item := range items {
		var submittedAt string
		if item.SubmittedAt != nil {
			submittedAt = item.SubmittedAt.UTC().Format(time.RFC3339)
		}

		resp.Items = append(resp.Items, &guidev1.VerificationQueueItem{
			Id:             item.ID.String(),
			GuideProfileId: item.GuideProfileID.String(),
			Status:         string(item.Status),
			Comment:        valueOrEmpty(item.Comment),
			SubmittedAt:    submittedAt,
			CreatedAt:      item.CreatedAt.UTC().Format(time.RFC3339),
		})
	}

	return resp, nil
}
