package http

import (
	"bytes"
	"embed"
	"fmt"
	"html/template"
	"io/fs"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

//go:embed templates/*.html templates/*/*.html static/css/*.css static/js/*.js static/vendor/maplibre/*.css static/vendor/maplibre/*.js
var embeddedFiles embed.FS

type Renderer struct {
	templates *template.Template
	static    fs.FS
}

func NewRenderer() (*Renderer, error) {
	funcs := template.FuncMap{
		"csrfField": func(token string) template.HTML {
			return template.HTML(`<input type="hidden" name="csrf_token" value="` + template.HTMLEscapeString(token) + `">`)
		},
		"formatTime": formatTemplateTime,
		"shortID":    shortTemplateID,
		"t": func(locale any, key string) string {
			return translate(fmt.Sprint(locale), key)
		},
		"feedQualitySurface": func(locale any, value any) string {
			return feedQualitySurfaceText(fmt.Sprint(locale), value)
		},
		"feedQualityBlockType": func(locale any, value any) string {
			return feedQualityBlockTypeText(fmt.Sprint(locale), value)
		},
		"feedQualityAction": func(locale any, value any) string {
			return feedQualityActionText(fmt.Sprint(locale), value)
		},
		"localeURL": localeURL,
		"urlQuerySuffix": func(query string) template.URL {
			query = strings.TrimSpace(query)
			if query == "" {
				return ""
			}
			return template.URL("?" + query)
		},
		"statusText": func(locale any, status any) string {
			return translateStatus(fmt.Sprint(locale), status)
		},
		"roleText": func(locale any, role any) string {
			return translateRole(fmt.Sprint(locale), role)
		},
		"userRoleText": func(locale any, role any) string {
			return translateUserRole(fmt.Sprint(locale), role)
		},
		"hasStaffRole": func(staff *model.StaffUser, role enum.StaffRole) bool {
			return staff != nil && staff.HasRole(role)
		},
		"hasPermission": func(staff *model.StaffUser, permission any) bool {
			return staff != nil && staff.HasPermission(enum.Permission(fmt.Sprint(permission)))
		},
		"staffTimezone": func(staff *model.StaffUser) string {
			if staff == nil {
				return model.DefaultStaffTimezone
			}
			return staff.EffectiveTimezone()
		},
		"permissionText": func(locale any, permission enum.Permission) string {
			return translatePermission(fmt.Sprint(locale), permission)
		},
		"excursionTitle": func(locale any, item *model.ExcursionModerationItem, fallback ...string) string {
			value := ""
			if len(fallback) > 0 {
				value = fallback[0]
			}
			return excursionTitleText(fmt.Sprint(locale), item, value)
		},
		"excursionAttractions": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionAttractionsText(fmt.Sprint(locale), item)
		},
		"excursionGuidePrimary": func(item *model.ExcursionModerationItem) string {
			return excursionGuidePrimaryText(item)
		},
		"excursionGuideFullName": func(item *model.ExcursionModerationItem) string {
			return excursionGuideFullNameText(item)
		},
		"excursionLocation": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionLocationText(fmt.Sprint(locale), item)
		},
		"excursionSummary": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionSummaryText(fmt.Sprint(locale), item)
		},
		"excursionDescription": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionDescriptionText(fmt.Sprint(locale), item)
		},
		"excursionDuration": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionDurationText(fmt.Sprint(locale), item)
		},
		"excursionMaxGroup": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionMaxGroupText(fmt.Sprint(locale), item)
		},
		"excursionLanguages": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionLanguagesText(fmt.Sprint(locale), item)
		},
		"excursionMeetingPoint": func(locale any, item *model.ExcursionModerationItem) string {
			return excursionMeetingPointText(fmt.Sprint(locale), item)
		},
		"excursionMeetingMap": func(locale any, item *model.ExcursionModerationItem) *meetingMapViewData {
			return excursionMeetingMap(fmt.Sprint(locale), item)
		},
		"excursionIncludedItems": func(locale any, item *model.ExcursionModerationItem) []string {
			return excursionIncludedItems(fmt.Sprint(locale), item)
		},
		"activityLocation": func(locale any, item *model.ActivityModerationItem) string {
			return activityLocationText(fmt.Sprint(locale), item)
		},
		"activitySchedule": func(locale any, item *model.ActivityModerationItem) string {
			return activityScheduleText(fmt.Sprint(locale), item)
		},
		"activityDuration": func(locale any, item *model.ActivityModerationItem) string {
			return activityDurationText(fmt.Sprint(locale), item)
		},
		"activityCapacity": func(locale any, item *model.ActivityModerationItem) string {
			return activityCapacityText(fmt.Sprint(locale), item)
		},
		"activityPrice": func(locale any, item *model.ActivityModerationItem) string {
			return activityPriceText(fmt.Sprint(locale), item)
		},
		"activityMeeting": activityMeetingText,
		"activityMeetingMap": func(locale any, item *model.ActivityModerationItem) *meetingMapViewData {
			return activityMeetingMap(fmt.Sprint(locale), item)
		},
		"meetingMapCoordinateText": meetingMapCoordinateText,
		"activityMapURL":           activityMapURL,
		"activityDecisionLocked":   activityDecisionLocked,
		"activityCategory": func(locale any, item *model.ActivityModerationItem) string {
			return activityCategoryText(fmt.Sprint(locale), item)
		},
		"activityModerationTriggeredAt": activityModerationTriggeredAt,
		"chatMessagePreview": func(locale any, item *model.ChatMessageModerationItem) string {
			return chatMessagePreviewText(fmt.Sprint(locale), item)
		},
		"chatMessageSender": chatMessageSenderText,
		"chatMessageConversation": func(locale any, item *model.ChatMessageModerationItem) string {
			return chatMessageConversationText(fmt.Sprint(locale), item)
		},
		"chatMessageSignals": func(locale any, item *model.ChatMessageModerationItem) string {
			return chatMessageSignalsText(fmt.Sprint(locale), item)
		},
		"chatMessageDecisionLocked": chatMessageDecisionLocked,
		"chatMessageType": func(locale any, value string) string {
			return chatMessageTypeText(fmt.Sprint(locale), value)
		},
		"chatContextSender": chatContextSenderText,
		"chatContextContent": func(locale any, item model.ChatMessageContextItem) string {
			return chatContextContentText(fmt.Sprint(locale), item)
		},
		"guideApplicationPrimary": func(item *model.GuideApplicationModerationItem) string {
			return guideApplicationPrimaryText(item)
		},
		"guideApplicationFullName": func(item *model.GuideApplicationModerationItem) string {
			return guideApplicationFullNameText(item)
		},
		"guideApplicationType": func(locale any, item *model.GuideApplicationModerationItem) string {
			return guideApplicationTypeText(fmt.Sprint(locale), item)
		},
		"guideApplicationLocation": func(locale any, item *model.GuideApplicationModerationItem) string {
			return guideApplicationLocationText(fmt.Sprint(locale), item)
		},
		"guideApplicationExperience": func(locale any, item *model.GuideApplicationModerationItem) string {
			return guideApplicationExperienceText(fmt.Sprint(locale), item)
		},
		"guideApplicationRating": func(locale any, item *model.GuideApplicationModerationItem) string {
			return guideApplicationRatingText(fmt.Sprint(locale), item)
		},
		"guideApplicationLanguages": func(locale any, item *model.GuideApplicationModerationItem) []string {
			return guideApplicationLanguageList(fmt.Sprint(locale), item)
		},
		"guideApplicationSpecializations": func(locale any, item *model.GuideApplicationModerationItem) []string {
			return guideApplicationSpecializationList(fmt.Sprint(locale), item)
		},
		"guideApplicationDocumentType": func(locale any, documentType string) string {
			return guideApplicationDocumentTypeText(fmt.Sprint(locale), documentType)
		},
		"guideApplicationDocumentURL":    guideApplicationDocumentURL,
		"guideApplicationServices":       guideApplicationServiceList,
		"guideApplicationDecisionLocked": guideApplicationDecisionLocked,
		"guideApplicationCanRevoke":      guideApplicationCanRevoke,
		"attractionCategory": func(locale any, category string) string {
			return attractionCategoryText(fmt.Sprint(locale), category)
		},
		"attractionCity": func(locale any, countryCode string, cityID string) string {
			return attractionCityText(fmt.Sprint(locale), countryCode, cityID)
		},
		"attractionCountry": func(locale any, countryCode string) string {
			return countryText(fmt.Sprint(locale), countryCode)
		},
		"countryWithCode": func(locale any, countryCode string) string {
			return countryTextWithCode(fmt.Sprint(locale), countryCode)
		},
		"attractionCityName": func(locale any, cityID string) string {
			return attractionCityNameText(fmt.Sprint(locale), cityID)
		},
		"attractionCountrySearch": attractionCountrySearchText,
		"attractionCitySearch":    attractionCitySearchText,
		"attractionCurrency": func(locale any, currency string) string {
			return attractionCurrencyText(fmt.Sprint(locale), currency)
		},
		"attractionListMeta": func(locale any, item model.AdminAttraction) string {
			return attractionListMetaText(fmt.Sprint(locale), item)
		},
		"attractionPaginationSummary": func(locale any, pagination AttractionPaginationViewData) string {
			return attractionPaginationSummary(fmt.Sprint(locale), pagination)
		},
		"attractionMediaURL":               attractionMediaURL,
		"attractionMediaImageURL":          attractionMediaImageURL,
		"attractionMediaPosition":          attractionMediaPosition,
		"attractionTags":                   attractionTagsText,
		"attractionCityLinks":              attractionCityLinksText,
		"attractionTranslationTitle":       attractionTranslationTitle,
		"attractionTranslationDescription": attractionTranslationDescription,
		"attractionVisitInfoValue":         attractionVisitInfoValue,
		"attractionCategoryOptions":        attractionCategoryOptions,
		"attractionOptionalStringEquals":   attractionOptionalStringEquals,
		"moderationReasonOptions": func(locale any) []moderationReasonOption {
			return moderationReasonCodeOptions(fmt.Sprint(locale))
		},
		"selectedModerationReasonOptions": func(locale any, selected any) []moderationReasonOption {
			return moderationReasonCodeOptionsWithSelected(fmt.Sprint(locale), fmt.Sprint(selected))
		},
		"itineraryTitle": func(locale any, item model.ExcursionItineraryItem) string {
			return itineraryTitleText(fmt.Sprint(locale), item)
		},
		"itineraryDescription": func(locale any, item model.ExcursionItineraryItem) string {
			return itineraryDescriptionText(fmt.Sprint(locale), item)
		},
		"itineraryAttraction": itineraryAttractionText,
		"itineraryStart":      itineraryStartText,
		"itineraryDuration": func(locale any, value *int) string {
			return itineraryDurationText(fmt.Sprint(locale), value)
		},
		"itineraryTravel": func(locale any, value *int) string {
			return itineraryTravelText(fmt.Sprint(locale), value)
		},
		"newID": func() string {
			return uuid.NewString()
		},
		"statusClass": func(status any) string {
			switch strings.ToUpper(strings.TrimSpace(fmt.Sprint(status))) {
			case "OPEN", "PENDING_REVIEW", "SUBMITTED", "FLAGGED", "REVIEW", "CHALLENGE", "ESCALATED", "WAITING_USER", "WARNING", "REQUEST_VERIFICATION":
				return "badge badge-warn"
			case "IN_REVIEW", "UNDER_REVIEW", "DRAFT":
				return "badge badge-info"
			case "APPROVED", "PUBLISHED", "ACTIVE", "ENROLLMENT_OPEN", "CLEARED", "ALLOW", "FALSE_POSITIVE", "RESOLVED", "NO_ACTION", "REMOVE_RESTRICTION":
				return "badge badge-success"
			case "REJECTED", "REVOKED", "DISABLED", "LOCKED", "HIDDEN_BY_MODERATION", "BLOCK", "CONFIRMED_FRAUD", "SUSPEND", "PERMANENT_BLOCK":
				return "badge badge-danger"
			case "SUPERSEDED", "DISMISSED", "INTERNAL_NOTE":
				return "badge"
			default:
				return "badge"
			}
		},
		"join": strings.Join,
	}
	tmpl, err := template.New("admin").Funcs(funcs).ParseFS(embeddedFiles, "templates/*.html", "templates/*/*.html")
	if err != nil {
		return nil, err
	}
	static, err := fs.Sub(embeddedFiles, "static")
	if err != nil {
		return nil, err
	}
	return &Renderer{templates: tmpl, static: static}, nil
}

func (r *Renderer) Render(w http.ResponseWriter, status int, name string, data any) {
	var buffer bytes.Buffer
	if err := r.templates.ExecuteTemplate(&buffer, name, data); err != nil {
		locale := defaultLocale
		if page, ok := data.(PageData); ok && strings.TrimSpace(page.Locale) != "" {
			locale = page.Locale
		}
		http.Error(w, translate(locale, "error.generic"), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(status)
	_, _ = buffer.WriteTo(w)
}

func (r *Renderer) StaticHandler() http.Handler {
	return http.FileServer(http.FS(r.static))
}

func formatTemplateTime(value any, timezone ...string) string {
	location := templateTimeLocation(timezone...)
	switch typed := value.(type) {
	case time.Time:
		if typed.IsZero() {
			return "-"
		}
		return typed.In(location).Format("2006-01-02 15:04")
	case *time.Time:
		if typed == nil || typed.IsZero() {
			return "-"
		}
		return typed.In(location).Format("2006-01-02 15:04")
	default:
		return "-"
	}
}

func templateTimeLocation(timezone ...string) *time.Location {
	locationName := "UTC"
	if len(timezone) > 0 {
		locationName = strings.TrimSpace(timezone[0])
		if locationName == "" {
			locationName = model.DefaultStaffTimezone
		}
	}
	location, err := time.LoadLocation(locationName)
	if err != nil {
		return time.UTC
	}
	return location
}

func shortTemplateID(value any) string {
	switch typed := value.(type) {
	case uuid.UUID:
		raw := typed.String()
		if len(raw) > 8 {
			return raw[:8]
		}
		return raw
	case *uuid.UUID:
		if typed == nil {
			return "-"
		}
		raw := typed.String()
		if len(raw) > 8 {
			return raw[:8]
		}
		return raw
	case string:
		if len(typed) > 8 {
			return typed[:8]
		}
		return typed
	default:
		return fmt.Sprint(value)
	}
}
