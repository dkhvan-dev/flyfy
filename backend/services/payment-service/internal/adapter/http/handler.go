package http

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/payment-service/internal/app"
	"kz/inflap/backend/services/payment-service/internal/domain/enum"
	"kz/inflap/backend/services/payment-service/internal/domain/model"
	"kz/inflap/backend/services/payment-service/internal/domain/port"
	"kz/inflap/backend/services/payment-service/internal/transport/dto"
)

type Handler struct {
	useCase *app.PaymentUseCase
}

func NewHandler(useCase *app.PaymentUseCase) *Handler {
	return &Handler{useCase: useCase}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /v1/payments", h.ListPayments)
	mux.HandleFunc("POST /v1/payments/authorizations", h.Authorize)
	mux.HandleFunc("POST /v1/payments/charges", h.Charge)
	mux.HandleFunc("GET /v1/payments/", h.handlePaymentActions)
	mux.HandleFunc("POST /v1/payments/", h.handlePaymentActions)
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) Authorize(w http.ResponseWriter, r *http.Request) {
	input, ok := h.parseCreatePaymentInput(w, r)
	if !ok {
		return
	}

	item, err := h.useCase.Authorize(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to authorize payment")
		return
	}

	writeJSON(w, http.StatusCreated, toPaymentResponse(item))
}

func (h *Handler) Charge(w http.ResponseWriter, r *http.Request) {
	input, ok := h.parseCreatePaymentInput(w, r)
	if !ok {
		return
	}

	item, err := h.useCase.Charge(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to charge payment")
		return
	}

	writeJSON(w, http.StatusCreated, toPaymentResponse(item))
}

func (h *Handler) ListPayments(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()

	limit := parseIntOrDefault(q.Get("limit"), 20)
	if limit > 100 {
		limit = 100
	}
	filter := port.PaymentFilter{
		Limit:  limit + 1,
		Offset: parseIntOrDefault(q.Get("offset"), 0),
	}

	if v := strings.TrimSpace(q.Get("subjectType")); v != "" {
		normalized := model.NormalizePaymentCode(v)
		filter.SubjectType = &normalized
	}
	if v := strings.TrimSpace(q.Get("subjectId")); v != "" {
		parsed, err := uuid.Parse(v)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid subjectId")
			return
		}
		filter.SubjectID = &parsed
	}
	if v := strings.TrimSpace(q.Get("payerUserId")); v != "" {
		parsed, err := uuid.Parse(v)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid payerUserId")
			return
		}
		filter.PayerUserID = &parsed
	}
	if !IsInternalFromContext(r.Context()) {
		actorID, ok := actorUserIDFromRequest(w, r)
		if !ok {
			return
		}
		if filter.PayerUserID != nil && *filter.PayerUserID != actorID {
			writeError(w, http.StatusForbidden, "payment access denied")
			return
		}
		filter.PayerUserID = &actorID
	}
	if v := strings.TrimSpace(q.Get("operationType")); v != "" {
		operationType := enum.PaymentOperationType(model.NormalizePaymentCode(v))
		if !operationType.IsValid() {
			writeError(w, http.StatusBadRequest, "invalid operationType")
			return
		}
		filter.OperationType = &operationType
	}
	if v := strings.TrimSpace(q.Get("status")); v != "" {
		status := enum.PaymentStatus(model.NormalizePaymentCode(v))
		if !status.IsValid() {
			writeError(w, http.StatusBadRequest, "invalid status")
			return
		}
		filter.Status = &status
	}

	items, err := h.useCase.ListTransactions(r.Context(), filter)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list payments")
		return
	}

	hasMore := len(items) > limit
	if hasMore {
		items = items[:limit]
	}

	resp := dto.PaymentListResponse{
		Items:   make([]dto.PaymentResponse, 0, len(items)),
		HasMore: hasMore,
	}
	for _, item := range items {
		resp.Items = append(resp.Items, toPaymentResponse(item))
	}

	writeJSON(w, http.StatusOK, resp)
}

func (h *Handler) handlePaymentActions(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/v1/payments/")
	path = strings.Trim(path, "/")
	if path == "" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	parts := strings.Split(path, "/")
	transactionID, err := uuid.Parse(parts[0])
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid payment id")
		return
	}

	if len(parts) == 1 {
		if r.Method == http.MethodGet {
			h.GetPayment(w, r, transactionID)
			return
		}
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	if len(parts) != 2 || r.Method != http.MethodPost {
		writeError(w, http.StatusNotFound, "not found")
		return
	}

	switch parts[1] {
	case "capture":
		h.Capture(w, r, transactionID)
	case "refund":
		h.Refund(w, r, transactionID)
	case "void":
		h.Void(w, r, transactionID)
	default:
		writeError(w, http.StatusNotFound, "not found")
	}
}

func (h *Handler) GetPayment(w http.ResponseWriter, r *http.Request, transactionID uuid.UUID) {
	item, err := h.useCase.GetTransaction(r.Context(), transactionID)
	if err != nil {
		h.writeAppError(w, err, "failed to get payment")
		return
	}
	if !h.canReadPayment(w, r, item) {
		return
	}
	writeJSON(w, http.StatusOK, toPaymentResponse(item))
}

func (h *Handler) Capture(w http.ResponseWriter, r *http.Request, transactionID uuid.UUID) {
	if !requireInternalCaller(w, r) {
		return
	}

	input, ok := h.parseChildPaymentInput(w, r, transactionID)
	if !ok {
		return
	}

	item, err := h.useCase.Capture(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to capture payment")
		return
	}
	writeJSON(w, http.StatusCreated, toPaymentResponse(item))
}

func (h *Handler) Refund(w http.ResponseWriter, r *http.Request, transactionID uuid.UUID) {
	if !requireInternalCaller(w, r) {
		return
	}

	input, ok := h.parseChildPaymentInput(w, r, transactionID)
	if !ok {
		return
	}

	item, err := h.useCase.Refund(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to refund payment")
		return
	}
	writeJSON(w, http.StatusCreated, toPaymentResponse(item))
}

func (h *Handler) Void(w http.ResponseWriter, r *http.Request, transactionID uuid.UUID) {
	if !requireInternalCaller(w, r) {
		return
	}

	input, ok := h.parseChildPaymentInput(w, r, transactionID)
	if !ok {
		return
	}

	item, err := h.useCase.Void(r.Context(), input)
	if err != nil {
		h.writeAppError(w, err, "failed to void payment")
		return
	}
	writeJSON(w, http.StatusCreated, toPaymentResponse(item))
}

func (h *Handler) parseCreatePaymentInput(w http.ResponseWriter, r *http.Request) (app.CreatePaymentInput, bool) {
	var req dto.CreatePaymentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return app.CreatePaymentInput{}, false
	}

	subjectID, err := uuid.Parse(strings.TrimSpace(req.SubjectID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid subjectId")
		return app.CreatePaymentInput{}, false
	}

	payerUserID, ok := resolvePayerUserID(w, r, req.PayerUserID)
	if !ok {
		return app.CreatePaymentInput{}, false
	}
	requestedBy := resolveOptionalActorUserID(r)

	return app.CreatePaymentInput{
		IdempotencyKey:    req.IdempotencyKey,
		SubjectType:       req.SubjectType,
		SubjectID:         subjectID,
		Purpose:           req.Purpose,
		PayerUserID:       payerUserID,
		RequestedByUserID: requestedBy,
		AmountMinor:       req.AmountMinor,
		Currency:          req.Currency,
		Description:       req.Description,
		Metadata:          normalizeRawJSON(req.Metadata),
	}, true
}

func (h *Handler) parseChildPaymentInput(w http.ResponseWriter, r *http.Request, transactionID uuid.UUID) (app.ChildPaymentInput, bool) {
	var req dto.ChildPaymentRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return app.ChildPaymentInput{}, false
	}

	return app.ChildPaymentInput{
		ParentTransactionID: transactionID,
		IdempotencyKey:      req.IdempotencyKey,
		RequestedByUserID:   resolveOptionalActorUserID(r),
		AmountMinor:         req.AmountMinor,
		Description:         req.Description,
		Metadata:            normalizeRawJSON(req.Metadata),
	}, true
}

func resolvePayerUserID(w http.ResponseWriter, r *http.Request, requested *string) (uuid.UUID, bool) {
	if IsInternalFromContext(r.Context()) && requested != nil {
		parsed, err := uuid.Parse(strings.TrimSpace(*requested))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid payerUserId")
			return uuid.Nil, false
		}
		return parsed, true
	}

	actor := strings.TrimSpace(UserIDFromContext(r.Context()))
	parsed, err := uuid.Parse(actor)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return uuid.Nil, false
	}
	return parsed, true
}

func actorUserIDFromRequest(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	actor := strings.TrimSpace(UserIDFromContext(r.Context()))
	parsed, err := uuid.Parse(actor)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user")
		return uuid.Nil, false
	}
	return parsed, true
}

func resolveOptionalActorUserID(r *http.Request) *uuid.UUID {
	raw := strings.TrimSpace(UserIDFromContext(r.Context()))
	if raw == "" {
		return nil
	}
	parsed, err := uuid.Parse(raw)
	if err != nil {
		return nil
	}
	return &parsed
}

func (h *Handler) canReadPayment(w http.ResponseWriter, r *http.Request, item *model.PaymentTransaction) bool {
	if IsInternalFromContext(r.Context()) {
		return true
	}
	actorID, ok := actorUserIDFromRequest(w, r)
	if !ok {
		return false
	}
	if item.PayerUserID != actorID {
		writeError(w, http.StatusForbidden, "payment access denied")
		return false
	}
	return true
}

func requireInternalCaller(w http.ResponseWriter, r *http.Request) bool {
	if IsInternalFromContext(r.Context()) {
		return true
	}
	writeError(w, http.StatusForbidden, "internal payment operation required")
	return false
}

func toPaymentResponse(item *model.PaymentTransaction) dto.PaymentResponse {
	var parentID *string
	if item.ParentTransactionID != nil {
		value := item.ParentTransactionID.String()
		parentID = &value
	}
	var requestedBy *string
	if item.RequestedByUserID != nil {
		value := item.RequestedByUserID.String()
		requestedBy = &value
	}

	return dto.PaymentResponse{
		ID:                    item.ID.String(),
		IdempotencyKey:        item.IdempotencyKey,
		SubjectType:           item.SubjectType,
		SubjectID:             item.SubjectID.String(),
		Purpose:               item.Purpose,
		PayerUserID:           item.PayerUserID.String(),
		RequestedByUserID:     requestedBy,
		OperationType:         string(item.OperationType),
		Status:                string(item.Status),
		Provider:              string(item.Provider),
		ProviderTransactionID: item.ProviderTransactionID,
		ParentTransactionID:   parentID,
		AmountMinor:           item.AmountMinor,
		Currency:              item.Currency,
		Description:           item.Description,
		Metadata:              normalizeRawJSON(item.Metadata),
		FailureCode:           item.FailureCode,
		FailureMessage:        item.FailureMessage,
		CompletedAt:           formatOptionalTime(item.CompletedAt),
		CreatedAt:             item.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:             item.UpdatedAt.UTC().Format(time.RFC3339),
	}
}

func (h *Handler) writeAppError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case errors.Is(err, app.ErrInvalidPaymentID),
		errors.Is(err, app.ErrInvalidAmount),
		errors.Is(err, app.ErrInvalidActorUserID),
		errors.Is(err, app.ErrInvalidParentPayment),
		errors.Is(err, app.ErrPaymentCurrencyMismatch),
		errors.Is(err, app.ErrPaymentSubjectMismatch),
		errors.Is(err, app.ErrPaymentOperationUnsupported),
		errors.Is(err, model.ErrInvalidPaymentID),
		errors.Is(err, model.ErrInvalidIdempotencyKey),
		errors.Is(err, model.ErrInvalidPaymentSubject),
		errors.Is(err, model.ErrInvalidPaymentPurpose),
		errors.Is(err, model.ErrInvalidPayerUserID),
		errors.Is(err, model.ErrInvalidPaymentOperationType),
		errors.Is(err, model.ErrInvalidPaymentStatus),
		errors.Is(err, model.ErrInvalidPaymentProvider),
		errors.Is(err, model.ErrInvalidPaymentAmount),
		errors.Is(err, model.ErrInvalidPaymentCurrency),
		errors.Is(err, model.ErrInvalidPaymentMetadata),
		errors.Is(err, model.ErrInvalidParentPaymentReference):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, app.ErrPaymentNotFound):
		writeError(w, http.StatusNotFound, err.Error())
	case errors.Is(err, app.ErrPaymentAlreadyFinalized),
		errors.Is(err, app.ErrPaymentAmountExceeded):
		writeError(w, http.StatusConflict, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, fallback)
	}
}

func decodeBody(r *http.Request, dest any) error {
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dest); err != nil {
		if errors.Is(err, io.EOF) {
			return errors.New("request body is required")
		}
		return errors.New("invalid request body")
	}
	return nil
}

func normalizeRawJSON(v []byte) []byte {
	if len(v) == 0 || !json.Valid(v) {
		return []byte(`{}`)
	}
	return v
}

func parseIntOrDefault(v string, fallback int) int {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(strings.TrimSpace(v))
	if err != nil {
		return fallback
	}
	return parsed
}

func formatOptionalTime(v *time.Time) *string {
	if v == nil {
		return nil
	}
	value := v.UTC().Format(time.RFC3339)
	return &value
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, buildErrorResponse("payment", status, message))
}

type errorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code"`
	Kind    string `json:"kind"`
}

func buildErrorResponse(service string, status int, message string) errorResponse {
	if status >= http.StatusInternalServerError {
		return errorResponse{
			Error:   "Техническая ошибка",
			Message: "На сервере возникла проблема. Попробуйте позже.",
			Code:    service + ".technical",
			Kind:    "technical",
		}
	}
	title, publicMessage := localizedBusinessError(status)
	return errorResponse{
		Error:   title,
		Message: publicMessage,
		Code:    service + "." + errorCodeFromMessage(message),
		Kind:    "business",
	}
}

func localizedBusinessError(status int) (string, string) {
	switch status {
	case http.StatusUnauthorized:
		return "Требуется авторизация", "Войдите в аккаунт и повторите запрос."
	case http.StatusForbidden:
		return "Недостаточно прав", "У вас нет доступа к этому действию."
	case http.StatusNotFound:
		return "Данные не найдены", "Запрошенные данные не найдены."
	case http.StatusConflict:
		return "Конфликт данных", "Данные уже изменились или действие недоступно в текущем состоянии."
	case http.StatusTooManyRequests:
		return "Слишком много запросов", "Попробуйте повторить запрос чуть позже."
	default:
		return "Некорректный запрос", "Проверьте данные запроса и попробуйте снова."
	}
}

func errorCodeFromMessage(message string) string {
	message = strings.ToLower(strings.TrimSpace(message))
	var builder strings.Builder
	previousUnderscore := false
	for _, r := range message {
		isAlphaNumeric := (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if isAlphaNumeric {
			builder.WriteRune(r)
			previousUnderscore = false
			continue
		}
		if !previousUnderscore && builder.Len() > 0 {
			builder.WriteByte('_')
			previousUnderscore = true
		}
	}
	code := strings.Trim(builder.String(), "_")
	if code == "" {
		return "business_error"
	}
	return code
}
