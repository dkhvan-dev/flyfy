package http

import (
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type QueueSignalOptionView struct {
	Code string
}

var moderationSignalCodesByTarget = map[model.ModerationTargetType][]string{
	model.ModerationTargetExcursion: {
		"guide_new",
		"departure_city_missing",
		"missing_license",
		"moderator_rejected",
		"TRUST_POLICY_REVIEW",
		"TRUST_POLICY_UNAVAILABLE",
	},
	model.ModerationTargetActivity: {
		"external_contact",
		"high_price",
		"burst_created",
		"TRUST_POLICY_REVIEW",
		"TRUST_POLICY_UNAVAILABLE",
	},
	model.ModerationTargetGuideApplication: {
		"new_guide",
		"documents_incomplete",
		"languages_missing",
		"specializations_missing",
	},
	model.ModerationTargetChatMessage: {
		"off_platform_contact",
		"phone_number",
		"external_link",
		"TRUST_POLICY_REVIEW",
		"TRUST_POLICY_UNAVAILABLE",
	},
	model.ModerationTargetPost: {
		"spam",
		"harassment",
		"hate",
		"sexual_content",
		"violence",
		"misinformation",
		"illegal",
		"other",
		"COMMUNITY_POST_REVIEW",
		"COMMUNITY_SCOPED",
	},
}

func queueSignalOptions(targetType model.ModerationTargetType, selected string) []QueueSignalOptionView {
	codes := append([]string(nil), moderationSignalCodesByTarget[targetType]...)
	selected = strings.TrimSpace(selected)
	if selected != "" && !containsSignalCode(codes, selected) {
		codes = append(codes, selected)
	}
	out := make([]QueueSignalOptionView, 0, len(codes))
	seen := make(map[string]struct{}, len(codes))
	for _, code := range codes {
		code = strings.TrimSpace(code)
		if code == "" {
			continue
		}
		key := strings.ToUpper(code)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, QueueSignalOptionView{Code: code})
	}
	return out
}

func containsSignalCode(codes []string, selected string) bool {
	selected = strings.TrimSpace(selected)
	for _, code := range codes {
		if strings.EqualFold(strings.TrimSpace(code), selected) {
			return true
		}
	}
	return false
}

func moderationSignalText(locale string, code string) string {
	code = strings.TrimSpace(code)
	if code == "" {
		return "-"
	}
	for _, key := range moderationSignalTranslationKeys(code) {
		translated := translate(locale, key)
		if translated != key {
			return translated
		}
	}
	return translate(locale, "reason.unknown")
}

func moderationSignalTranslationKeys(code string) []string {
	lower := strings.ToLower(strings.NewReplacer("-", "_", " ", "_").Replace(strings.TrimSpace(code)))
	exact := "reason." + strings.TrimSpace(code)
	normalized := "reason." + lower
	if exact == normalized {
		return []string{normalized}
	}
	return []string{exact, normalized}
}
