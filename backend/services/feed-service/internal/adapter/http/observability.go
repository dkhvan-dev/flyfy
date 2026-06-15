package http

import (
	"errors"
	"net/http"
	"sort"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/app"
)

const (
	postOperationAutosave = "autosave"
	postOperationPatch    = "patch"
	postOperationPublish  = "publish"

	postMetricDraftCreated             = "posts_draft_created_total"
	postMetricAutosaveSuccess          = "posts_autosave_success_total"
	postMetricAutosaveFailure          = "posts_autosave_failure_total"
	postMetricPublishValidationFailure = "posts_publish_validation_failure_total"
	postMetricMediaValidationFailure   = "posts_media_validation_failure_total"
	postMetricRevisionConflict         = "posts_revision_conflict_total"
)

func logPostMetric(r *http.Request, metric string, postID uuid.UUID) {
	event := log.Info().
		Str("metric", metric).
		Str("transport", "http")

	if r != nil {
		event = event.Str("request_id", RequestIDFromContext(r.Context()))
	}
	if postID != uuid.Nil {
		event = event.Stringer("post_id", postID)
	}

	event.Msg("feed-service metric")
}

func logPostOperationMetric(
	r *http.Request,
	metric string,
	postID uuid.UUID,
	operation string,
	attrs map[string]string,
) {
	event := log.Info().
		Str("metric", metric).
		Str("transport", "http").
		Str("operation", operation)

	if r != nil {
		event = event.Str("request_id", RequestIDFromContext(r.Context()))
	}
	if postID != uuid.Nil {
		event = event.Stringer("post_id", postID)
	}

	keys := make([]string, 0, len(attrs))
	for key := range attrs {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		event = event.Str(key, attrs[key])
	}

	event.Msg("feed-service metric")
}

func logPostUseCaseErrorMetrics(r *http.Request, postID uuid.UUID, operation string, err error) {
	if operation == postOperationAutosave {
		logPostOperationMetric(r, postMetricAutosaveFailure, postID, operation, map[string]string{
			"code": safeBusinessErrorCode(err),
		})
	}

	if errors.Is(err, app.ErrPostRevisionConflict) {
		logPostOperationMetric(r, postMetricRevisionConflict, postID, operation, map[string]string{
			"code": errorCodePostRevisionConflict,
		})
	}

	fields := validationFieldsForError(err)
	if operation == postOperationPublish && len(fields) > 0 {
		logPostValidationFieldMetrics(r, postID, operation, fields)
	}
}

func logPostValidationFieldMetrics(
	r *http.Request,
	postID uuid.UUID,
	operation string,
	fields map[string]string,
) {
	names := make([]string, 0, len(fields))
	for field := range fields {
		names = append(names, field)
	}
	sort.Strings(names)

	for _, field := range names {
		reason := fields[field]
		attrs := map[string]string{
			"field":  safePostValidationFieldLabel(field),
			"reason": reason,
		}
		logPostOperationMetric(r, postMetricPublishValidationFailure, postID, operation, attrs)
		if isPostMediaValidationField(field) {
			logPostOperationMetric(r, postMetricMediaValidationFailure, postID, operation, attrs)
		}
	}
}

func logPostAutosaveSuccess(r *http.Request, postID uuid.UUID) {
	logPostOperationMetric(r, postMetricAutosaveSuccess, postID, postOperationAutosave, nil)
}

func safeBusinessErrorCode(err error) string {
	if mapped, ok := mapBusinessError(err); ok {
		return mapped.code
	}
	return errorCodeTechnical
}

func isPostMediaValidationField(field string) bool {
	switch field {
	case "coverFileId":
		return true
	default:
		return false
	}
}

func safePostValidationFieldLabel(field string) string {
	switch field {
	case "contentBlocks":
		return "content"
	default:
		return field
	}
}
