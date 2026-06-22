package http

import (
	"net/http"
	"net/url"
	"strings"
)

var flashTranslationKeys = map[string]string{
	"moderation.decisionSaved":        "flash.moderationDecisionSaved",
	"moderation.queueSynced":          "flash.moderationQueueSynced",
	"staff.created":                   "flash.staffCreated",
	"staff.passwordRegenerated":       "flash.staffPasswordRegenerated",
	"staff.statusChanged":             "flash.staffStatusChanged",
	"staff.timezoneUpdated":           "flash.staffTimezoneUpdated",
	"staff.updated":                   "flash.staffUpdated",
	"place.created":                   "flash.placeCreated",
	"community.created":               "flash.communityCreated",
	"community.updated":               "flash.communityUpdated",
	"community.instancesMaterialized": "flash.communityInstancesMaterialized",
	"place.updated":                   "flash.placeUpdated",
	"place.mediaUpdated":              "flash.placeMediaUpdated",
	"fraud.blockReviewed":             "flash.fraudBlockReviewed",
	"users.caseCreated":               "flash.userCaseCreated",
	"users.caseResolved":              "flash.userCaseResolved",
	"users.restrictionCreated":        "flash.userRestrictionCreated",
	"users.restrictionLifted":         "flash.userRestrictionLifted",
	"userRoutes.reviewed":             "flash.userRouteReviewed",
	"trust.appealDecided":             "flash.trustAppealDecided",
	"operations.domainSaved":          "flash.operationsDomainSaved",
	"operations.featureFlagSaved":     "flash.operationsFeatureFlagSaved",
	"operations.techBreakSaved":       "flash.operationsTechBreakSaved",
	"operations.scopeSaved":           "flash.operationsScopeSaved",
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
