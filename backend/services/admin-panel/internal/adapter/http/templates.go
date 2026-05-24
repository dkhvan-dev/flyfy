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

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

//go:embed templates/*.html templates/*/*.html static/css/*.css static/js/*.js
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
		"hasStaffRole": func(staff *model.StaffUser, role enum.StaffRole) bool {
			return staff != nil && staff.HasRole(role)
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
		"excursionIncludedItems": func(locale any, item *model.ExcursionModerationItem) []string {
			return excursionIncludedItems(fmt.Sprint(locale), item)
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
			case "OPEN", "PENDING_REVIEW":
				return "badge badge-warn"
			case "IN_REVIEW", "ESCALATED":
				return "badge badge-info"
			case "APPROVED", "PUBLISHED", "ACTIVE":
				return "badge badge-success"
			case "REJECTED", "DISABLED", "LOCKED":
				return "badge badge-danger"
			case "SUPERSEDED":
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
		http.Error(w, "template rendering failed", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(status)
	_, _ = buffer.WriteTo(w)
}

func (r *Renderer) StaticHandler() http.Handler {
	return http.FileServer(http.FS(r.static))
}

func formatTemplateTime(value any) string {
	switch typed := value.(type) {
	case time.Time:
		if typed.IsZero() {
			return "-"
		}
		return typed.UTC().Format("2006-01-02 15:04")
	case *time.Time:
		if typed == nil || typed.IsZero() {
			return "-"
		}
		return typed.UTC().Format("2006-01-02 15:04")
	default:
		return "-"
	}
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
