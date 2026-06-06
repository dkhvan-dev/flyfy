package grpc

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	activityv1 "kz/inflap/proto/gen/go/activity/v1"
)

type Server struct {
	activityv1.UnimplementedActivityServiceServer

	activityUC   *app.ActivityUseCase
	joinUC       *app.JoinUseCase
	searchUC     *app.SearchUseCase
	moderationUC *app.ModerationUseCase
}

func NewServer(
	activityUC *app.ActivityUseCase,
	joinUC *app.JoinUseCase,
	searchUC *app.SearchUseCase,
	moderationUC *app.ModerationUseCase,
) *Server {
	return &Server{
		activityUC:   activityUC,
		joinUC:       joinUC,
		searchUC:     searchUC,
		moderationUC: moderationUC,
	}
}

func (s *Server) GetActivityById(
	ctx context.Context,
	req *activityv1.GetActivityByIdRequest,
) (*activityv1.GetActivityByIdResponse, error) {
	activityID, err := uuid.Parse(strings.TrimSpace(req.GetActivityId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActivityID)
	}

	item, err := s.activityUC.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, mapError(err)
	}

	return &activityv1.GetActivityByIdResponse{
		Activity: toProtoActivity(item),
	}, nil
}

func (s *Server) ListActivities(
	ctx context.Context,
	req *activityv1.ListActivitiesRequest,
) (*activityv1.ListActivitiesResponse, error) {
	input := app.SearchActivitiesInput{
		Statuses: normalizeProtoStatuses(req.GetStatuses()),
		Limit:    int(req.GetLimit()),
		Offset:   int(req.GetOffset()),
	}

	if v := strings.TrimSpace(req.GetCategorySlug()); v != "" {
		input.CategorySlug = &v
	}
	if v := strings.TrimSpace(req.GetCountryCode()); v != "" {
		input.CountryCode = &v
	}
	if v := strings.TrimSpace(req.GetCityName()); v != "" {
		input.CityName = &v
	}
	if v := strings.TrimSpace(req.GetLanguageCode()); v != "" {
		input.LanguageCode = &v
	}
	if v := strings.TrimSpace(req.GetQuery()); v != "" {
		input.Query = &v
	}
	if v := strings.TrimSpace(req.GetHostUserId()); v != "" {
		if parsed, err := uuid.Parse(v); err == nil {
			input.HostUserID = &parsed
		}
	}

	items, err := s.searchUC.SearchActivities(ctx, input)
	if err != nil {
		return nil, mapError(err)
	}

	resp := &activityv1.ListActivitiesResponse{
		Items: make([]*activityv1.Activity, 0, len(items)),
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toProtoActivity(item))
	}

	return resp, nil
}

func (s *Server) JoinActivity(
	ctx context.Context,
	req *activityv1.JoinActivityRequest,
) (*activityv1.JoinActivityResponse, error) {
	activityID, err := uuid.Parse(strings.TrimSpace(req.GetActivityId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActivityID)
	}

	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidParticipantUserID)
	}

	item, err := s.joinUC.JoinActivity(ctx, app.JoinActivityInput{
		ActivityID: activityID,
		UserID:     userID,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &activityv1.JoinActivityResponse{
		Participant: toProtoParticipant(item),
	}, nil
}

func (s *Server) LeaveActivity(
	ctx context.Context,
	req *activityv1.LeaveActivityRequest,
) (*activityv1.LeaveActivityResponse, error) {
	activityID, err := uuid.Parse(strings.TrimSpace(req.GetActivityId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActivityID)
	}

	userID, err := uuid.Parse(strings.TrimSpace(req.GetUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidParticipantUserID)
	}

	reason := stringPtrOrNil(req.GetReason())

	item, err := s.joinUC.LeaveActivity(ctx, app.LeaveActivityInput{
		ActivityID: activityID,
		UserID:     userID,
		Reason:     reason,
	})
	if err != nil {
		return nil, mapError(err)
	}

	return &activityv1.LeaveActivityResponse{
		Participant: toProtoParticipant(item),
	}, nil
}

func (s *Server) ApproveActivityModeration(
	ctx context.Context,
	req *activityv1.ApproveActivityModerationRequest,
) (*activityv1.ApproveActivityModerationResponse, error) {
	activityID, err := uuid.Parse(strings.TrimSpace(req.GetActivityId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActivityID)
	}

	moderatorUserID, err := uuid.Parse(strings.TrimSpace(req.GetModeratorUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActorUserID)
	}

	item, err := s.moderationUC.ApproveActivity(ctx, activityID, moderatorUserID)
	if err != nil {
		return nil, mapError(err)
	}

	return &activityv1.ApproveActivityModerationResponse{
		Activity: toProtoActivity(item),
	}, nil
}

func (s *Server) RejectActivityModeration(
	ctx context.Context,
	req *activityv1.RejectActivityModerationRequest,
) (*activityv1.RejectActivityModerationResponse, error) {
	activityID, err := uuid.Parse(strings.TrimSpace(req.GetActivityId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActivityID)
	}

	moderatorUserID, err := uuid.Parse(strings.TrimSpace(req.GetModeratorUserId()))
	if err != nil {
		return nil, mapError(app.ErrInvalidActorUserID)
	}

	item, err := s.moderationUC.RejectActivity(ctx, activityID, moderatorUserID, req.GetPublicComment())
	if err != nil {
		return nil, mapError(err)
	}

	return &activityv1.RejectActivityModerationResponse{
		Activity: toProtoActivity(item),
	}, nil
}

func toProtoActivity(item *model.Activity) *activityv1.Activity {
	if item == nil {
		return nil
	}

	var sourceActivityID string
	if item.SourceActivityID != nil {
		sourceActivityID = item.SourceActivityID.String()
	}

	return &activityv1.Activity{
		Id:                             item.ID.String(),
		HostUserId:                     item.HostUserID.String(),
		SourceActivityId:               sourceActivityID,
		Title:                          item.Title,
		Description:                    item.Description,
		Format:                         string(item.Format),
		Status:                         string(item.Status),
		Visibility:                     string(item.Visibility),
		JoinMode:                       string(item.JoinMode),
		ModerationStatus:               string(item.ModerationStatus),
		CategorySlug:                   item.CategorySlug,
		LanguageCode:                   item.LanguageCode,
		Timezone:                       item.Timezone,
		StartAt:                        item.StartAt.UTC().Format(time.RFC3339),
		EndAt:                          item.EndAt.UTC().Format(time.RFC3339),
		RegistrationDeadline:           item.RegistrationDeadline.UTC().Format(time.RFC3339),
		CapacityType:                   string(item.CapacityType),
		MinParticipants:                int32PtrToValue(item.MinParticipants),
		MaxParticipants:                int32PtrToValue(item.MaxParticipants),
		PriceType:                      string(item.PriceType),
		PriceAmount:                    float64PtrToValue(item.PriceAmount),
		Currency:                       valueOrEmpty(item.Currency),
		PriceLockedAt:                  timePtrToValue(item.PriceLockedAt),
		RequiresProfileCompletion:      item.RequiresProfileCompletion,
		RequiresAttendanceConfirmation: item.RequiresAttendanceConfirmation,
		ConfirmationDeadline:           timePtrToValue(item.ConfirmationDeadline),
		CountryCode:                    valueOrEmpty(item.CountryCode),
		CityName:                       valueOrEmpty(item.CityName),
		AddressText:                    valueOrEmpty(item.AddressText),
		Latitude:                       float64PtrToValue(item.Latitude),
		Longitude:                      float64PtrToValue(item.Longitude),
		MapUrl:                         valueOrEmpty(item.MapURL),
		MeetingUrl:                     valueOrEmpty(item.MeetingURL),
		CancellationReason:             valueOrEmpty(item.CancellationReason),
		CancelledAt:                    timePtrToValue(item.CancelledAt),
		StartedAt:                      timePtrToValue(item.StartedAt),
		CompletedAt:                    timePtrToValue(item.CompletedAt),
		PublishedAt:                    timePtrToValue(item.PublishedAt),
		Revision:                       int32(item.Revision),
		CreatedAt:                      item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:                      item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func toProtoParticipant(item *model.ActivityParticipant) *activityv1.ActivityParticipant {
	if item == nil {
		return nil
	}

	return &activityv1.ActivityParticipant{
		Id:                    item.ID.String(),
		ActivityId:            item.ActivityID.String(),
		UserId:                item.UserID.String(),
		Status:                string(item.Status),
		JoinedAt:              item.JoinedAt.UTC().Format(time.RFC3339),
		ApprovedAt:            timePtrToValue(item.ApprovedAt),
		WaitlistedAt:          timePtrToValue(item.WaitlistedAt),
		PaymentDueAt:          timePtrToValue(item.PaymentDueAt),
		PaidAt:                timePtrToValue(item.PaidAt),
		AttendanceConfirmedAt: timePtrToValue(item.AttendanceConfirmedAt),
		CheckedInAt:           timePtrToValue(item.CheckedInAt),
		CancelledAt:           timePtrToValue(item.CancelledAt),
		CancelledByUserId:     uuidPtrToValue(item.CancelledByUserID),
		CancelReason:          valueOrEmpty(item.CancelReason),
		CreatedAt:             item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:             item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func normalizeProtoStatuses(items []string) []string {
	result := make([]string, 0, len(items))
	seen := make(map[string]struct{}, len(items))

	for _, item := range items {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		if _, exists := seen[item]; exists {
			continue
		}
		seen[item] = struct{}{}
		result = append(result, item)
	}

	return result
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
	return strings.TrimSpace(*v)
}

func timePtrToValue(v *time.Time) string {
	if v == nil {
		return ""
	}
	return v.UTC().Format(time.RFC3339)
}

func uuidPtrToValue(v *uuid.UUID) string {
	if v == nil {
		return ""
	}
	return v.String()
}

func int32PtrToValue(v *int) int32 {
	if v == nil {
		return 0
	}
	return int32(*v)
}

func float64PtrToValue(v *float64) float64 {
	if v == nil {
		return 0
	}
	return *v
}
