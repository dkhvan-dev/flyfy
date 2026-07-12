package http

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/api-gateway/internal/adapter"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

type submitRestrictionAppealRequest struct {
	ReasonCode     string `json:"reasonCode"`
	UserMessage    string `json:"userMessage"`
	IdempotencyKey string `json:"idempotencyKey"`
}

type trustProfilePayload struct {
	UserID       string `json:"userId"`
	Score        int32  `json:"score"`
	Band         string `json:"band"`
	Status       string `json:"status"`
	CalculatedAt string `json:"calculatedAt,omitempty"`
	UpdatedAt    string `json:"updatedAt,omitempty"`
}

type activeRestrictionPayload struct {
	RestrictionID   string `json:"restrictionId"`
	RestrictionCode string `json:"restrictionCode"`
	ReasonCode      string `json:"reasonCode,omitempty"`
	ExpiresAt       string `json:"expiresAt,omitempty"`
	CreatedAt       string `json:"createdAt,omitempty"`
}

type restrictionAppealPayload struct {
	AppealID           string `json:"appealId"`
	RestrictionID      string `json:"restrictionId"`
	Status             string `json:"status"`
	ReasonCode         string `json:"reasonCode"`
	UserMessage        string `json:"userMessage"`
	DecisionReasonCode string `json:"decisionReasonCode,omitempty"`
	CreatedAt          string `json:"createdAt,omitempty"`
	UpdatedAt          string `json:"updatedAt,omitempty"`
	DecidedAt          string `json:"decidedAt,omitempty"`
}

func (h *ProxyHandler) dispatchTrust(w http.ResponseWriter, r *http.Request, policy *RoutePolicy) {
	if h.trustClient == nil {
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUpstreamUnavailable)
		return
	}

	switch policy.Name {
	case "trust-profile":
		h.getTrustProfile(w, r)
	case "trust-appeals-list":
		h.listTrustAppeals(w, r)
	case "trust-appeals-submit":
		h.submitTrustAppeal(w, r)
	default:
		writeBusinessError(w, r, http.StatusNotFound, errorCodeRouteNotFound)
	}
}

func (h *ProxyHandler) getTrustProfile(w http.ResponseWriter, r *http.Request) {
	userID, subject, ok := h.authenticatedUserID(w, r)
	if !ok {
		return
	}

	resp, err := h.trustClient.GetTrustProfile(r.Context(), userID, RequestIDFromContext(r.Context()), subject)
	if err != nil {
		h.writeTrustError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"profile":            trustProfileFromProto(resp.GetProfile()),
		"activeRestrictions": activeRestrictionsFromProto(resp.GetActiveRestrictions()),
	})
}

func (h *ProxyHandler) listTrustAppeals(w http.ResponseWriter, r *http.Request) {
	userID, subject, ok := h.authenticatedUserID(w, r)
	if !ok {
		return
	}

	resp, err := h.trustClient.ListRestrictionAppeals(
		r.Context(),
		userID,
		restrictionAppealStatusFromQuery(r.URL.Query().Get("status")),
		RequestIDFromContext(r.Context()),
		subject,
	)
	if err != nil {
		h.writeTrustError(w, r, err)
		return
	}

	items := make([]restrictionAppealPayload, 0, len(resp.GetAppeals()))
	for _, appeal := range resp.GetAppeals() {
		items = append(items, restrictionAppealFromProto(appeal))
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"items": items,
	})
}

func (h *ProxyHandler) submitTrustAppeal(w http.ResponseWriter, r *http.Request) {
	userID, subject, ok := h.authenticatedUserID(w, r)
	if !ok {
		return
	}

	restrictionID := restrictionIDFromAppealPath(r.URL.Path, h.cfg.Routes.APIPrefix)
	if restrictionID == "" {
		writeBusinessError(w, r, http.StatusBadRequest, errorCodeInvalidRequest)
		return
	}

	var payload submitRestrictionAppealRequest
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeBusinessError(w, r, http.StatusBadRequest, errorCodeInvalidRequest)
		return
	}

	resp, err := h.trustClient.SubmitRestrictionAppeal(
		r.Context(),
		&trustv1.SubmitRestrictionAppealRequest{
			UserId:         userID,
			RestrictionId:  restrictionID,
			ReasonCode:     strings.TrimSpace(payload.ReasonCode),
			UserMessage:    strings.TrimSpace(payload.UserMessage),
			IdempotencyKey: strings.TrimSpace(payload.IdempotencyKey),
		},
		RequestIDFromContext(r.Context()),
		subject,
	)
	if err != nil {
		h.writeTrustError(w, r, err)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"appeal": restrictionAppealFromProto(resp.GetAppeal()),
	})
}

func (h *ProxyHandler) authenticatedUserID(w http.ResponseWriter, r *http.Request) (string, string, bool) {
	claims := ClaimsFromContext(r.Context())
	if claims == nil {
		writeBusinessError(w, r, http.StatusUnauthorized, errorCodeAuthRequired)
		return "", "", false
	}

	subject := strings.TrimSpace(claims.Subject)
	roles := adapter.NormalizeRoles(claims.Roles, "")
	userID := strings.TrimSpace(claims.UserID)
	needsResolve := subject != "" && (userID == "" || userID == subject)
	if needsResolve && h.userIDResolver != nil {
		resolvedUserID, err := h.userIDResolver.ResolveUserID(
			r.Context(),
			subject,
			roles,
			RequestIDFromContext(r.Context()),
		)
		if err != nil {
			writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUserResolution)
			return "", "", false
		}
		userID = resolvedUserID
	}
	if userID == "" && h.userIDResolver == nil {
		userID = subject
	}
	if strings.TrimSpace(userID) == "" {
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUserResolution)
		return "", "", false
	}
	return userID, subject, true
}

func (h *ProxyHandler) writeTrustError(w http.ResponseWriter, r *http.Request, err error) {
	switch status.Code(err) {
	case codes.InvalidArgument:
		writeBusinessError(w, r, http.StatusBadRequest, errorCodeInvalidRequest)
	case codes.NotFound:
		writeBusinessError(w, r, http.StatusNotFound, errorCodeResourceNotFound)
	case codes.Unauthenticated, codes.PermissionDenied:
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUpstreamUnavailable)
	default:
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUpstreamUnavailable)
	}
}

func restrictionIDFromAppealPath(path string, apiPrefix string) string {
	prefix := strings.TrimRight(strings.TrimSpace(apiPrefix), "/")
	if prefix == "" {
		prefix = "/api/v1"
	}
	path = strings.SplitN(path, "?", 2)[0]
	path = strings.TrimPrefix(path, prefix+"/trust/restrictions/")
	restrictionID, ok := strings.CutSuffix(path, "/appeals")
	if !ok {
		return ""
	}
	restrictionID = strings.TrimSpace(restrictionID)
	if restrictionID == "" || strings.Contains(restrictionID, "/") {
		return ""
	}
	return restrictionID
}

func restrictionAppealStatusFromQuery(value string) trustv1.RestrictionAppealStatus {
	switch strings.ToUpper(strings.TrimSpace(value)) {
	case "PENDING", "OPEN":
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING
	case "APPROVED":
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED
	case "REJECTED":
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_REJECTED
	default:
		return trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_UNSPECIFIED
	}
}

func trustProfileFromProto(profile *trustv1.TrustProfile) trustProfilePayload {
	if profile == nil {
		return trustProfilePayload{}
	}
	return trustProfilePayload{
		UserID:       profile.GetUserId(),
		Score:        profile.GetScore(),
		Band:         strings.TrimPrefix(profile.GetBand().String(), "TRUST_BAND_"),
		Status:       strings.TrimPrefix(profile.GetStatus().String(), "TRUST_STATUS_"),
		CalculatedAt: timestampProtoString(profile.GetCalculatedAt()),
		UpdatedAt:    timestampProtoString(profile.GetUpdatedAt()),
	}
}

func activeRestrictionsFromProto(items []*trustv1.ActiveRestriction) []activeRestrictionPayload {
	result := make([]activeRestrictionPayload, 0, len(items))
	for _, item := range items {
		if item == nil || strings.TrimSpace(item.GetRestrictionId()) == "" || strings.TrimSpace(item.GetRestrictionCode()) == "" {
			continue
		}
		result = append(result, activeRestrictionPayload{
			RestrictionID:   item.GetRestrictionId(),
			RestrictionCode: item.GetRestrictionCode(),
			ReasonCode:      item.GetReasonCode(),
			ExpiresAt:       timestampProtoString(item.GetExpiresAt()),
			CreatedAt:       timestampProtoString(item.GetCreatedAt()),
		})
	}
	return result
}

func restrictionAppealFromProto(appeal *trustv1.RestrictionAppeal) restrictionAppealPayload {
	if appeal == nil {
		return restrictionAppealPayload{}
	}
	return restrictionAppealPayload{
		AppealID:           appeal.GetAppealId(),
		RestrictionID:      appeal.GetRestrictionId(),
		Status:             strings.TrimPrefix(appeal.GetStatus().String(), "RESTRICTION_APPEAL_STATUS_"),
		ReasonCode:         appeal.GetReasonCode(),
		UserMessage:        appeal.GetUserMessage(),
		DecisionReasonCode: appeal.GetDecisionReasonCode(),
		CreatedAt:          timestampProtoString(appeal.GetCreatedAt()),
		UpdatedAt:          timestampProtoString(appeal.GetUpdatedAt()),
		DecidedAt:          timestampProtoString(appeal.GetDecidedAt()),
	}
}

func timestampProtoString(value *timestamppb.Timestamp) string {
	if value == nil {
		return ""
	}
	return timestampString(value.AsTime())
}

func timestampString(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}
