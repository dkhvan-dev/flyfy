package http

import (
	"errors"
	"net/http"
	"sort"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/stories-service/internal/app"
)

const (
	storyOperationAutosave = "autosave"
	storyOperationPatch    = "patch"
	storyOperationPublish  = "publish"

	storyMetricDraftCreated             = "stories_draft_created_total"
	storyMetricAutosaveSuccess          = "stories_autosave_success_total"
	storyMetricAutosaveFailure          = "stories_autosave_failure_total"
	storyMetricPublishValidationFailure = "stories_publish_validation_failure_total"
	storyMetricMediaValidationFailure   = "stories_media_validation_failure_total"
	storyMetricRevisionConflict         = "stories_revision_conflict_total"
)

func logStoryMetric(r *http.Request, metric string, storyID uuid.UUID) {
	event := log.Info().
		Str("metric", metric).
		Str("transport", "http")

	if r != nil {
		event = event.Str("request_id", RequestIDFromContext(r.Context()))
	}
	if storyID != uuid.Nil {
		event = event.Stringer("story_id", storyID)
	}

	event.Msg("stories-service metric")
}

func logStoryOperationMetric(
	r *http.Request,
	metric string,
	storyID uuid.UUID,
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
	if storyID != uuid.Nil {
		event = event.Stringer("story_id", storyID)
	}

	keys := make([]string, 0, len(attrs))
	for key := range attrs {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		event = event.Str(key, attrs[key])
	}

	event.Msg("stories-service metric")
}

func logStoryUseCaseErrorMetrics(r *http.Request, storyID uuid.UUID, operation string, err error) {
	if operation == storyOperationAutosave {
		logStoryOperationMetric(r, storyMetricAutosaveFailure, storyID, operation, map[string]string{
			"code": safeBusinessErrorCode(err),
		})
	}

	if errors.Is(err, app.ErrStoryRevisionConflict) {
		logStoryOperationMetric(r, storyMetricRevisionConflict, storyID, operation, map[string]string{
			"code": errorCodeStoryRevisionConflict,
		})
	}

	fields := validationFieldsForError(err)
	if operation == storyOperationPublish && len(fields) > 0 {
		logStoryValidationFieldMetrics(r, storyID, operation, fields)
	}
}

func logStoryValidationFieldMetrics(
	r *http.Request,
	storyID uuid.UUID,
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
			"field":  safeStoryValidationFieldLabel(field),
			"reason": reason,
		}
		logStoryOperationMetric(r, storyMetricPublishValidationFailure, storyID, operation, attrs)
		if isStoryMediaValidationField(field) {
			logStoryOperationMetric(r, storyMetricMediaValidationFailure, storyID, operation, attrs)
		}
	}
}

func logStoryAutosaveSuccess(r *http.Request, storyID uuid.UUID) {
	logStoryOperationMetric(r, storyMetricAutosaveSuccess, storyID, storyOperationAutosave, nil)
}

func safeBusinessErrorCode(err error) string {
	if mapped, ok := mapBusinessError(err); ok {
		return mapped.code
	}
	return errorCodeTechnical
}

func isStoryMediaValidationField(field string) bool {
	switch field {
	case "coverFileId":
		return true
	default:
		return false
	}
}

func safeStoryValidationFieldLabel(field string) string {
	switch field {
	case "contentBlocks":
		return "content"
	default:
		return field
	}
}
