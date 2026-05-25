package http

import (
	"net/http"
	"net/url"
	"strings"
)

var flashTranslationKeys = map[string]string{
	"moderation.decisionSaved":  "flash.moderationDecisionSaved",
	"moderation.queueSynced":    "flash.moderationQueueSynced",
	"staff.created":             "flash.staffCreated",
	"staff.passwordRegenerated": "flash.staffPasswordRegenerated",
	"staff.statusChanged":       "flash.staffStatusChanged",
	"staff.timezoneUpdated":     "flash.staffTimezoneUpdated",
	"staff.updated":             "flash.staffUpdated",
}

func flashMessageFromRequest(locale string, r *http.Request) string {
	if r == nil {
		return ""
	}
	return flashMessage(locale, r.URL.Query().Get("flash"))
}

func flashMessage(locale string, key string) string {
	key = strings.TrimSpace(key)
	if key == "" {
		return ""
	}
	translationKey, ok := flashTranslationKeys[key]
	if !ok {
		return ""
	}
	return translate(locale, translationKey)
}

func redirectWithFlash(path string, flashKey string) string {
	parsed, err := url.Parse(strings.TrimSpace(path))
	if err != nil {
		return path
	}
	query := parsed.Query()
	query.Set("flash", flashKey)
	parsed.RawQuery = query.Encode()
	return parsed.String()
}
