package app

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"
	"unicode"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

const (
	defaultChecklistNotificationScanLimit = 100
	maxChecklistNotificationScanLimit     = 500

	checklistNotificationCategory       = "checklist"
	checklistNotificationPriorityHigh   = "high"
	checklistNotificationPriorityNormal = "normal"
	checklistNotificationTTL            = 24 * time.Hour
)

func (uc *ChecklistUseCase) DispatchDueChecklistNotifications(
	ctx context.Context,
	input DispatchChecklistNotificationsInput,
) (DispatchChecklistNotificationsResult, error) {
	var result DispatchChecklistNotificationsResult
	if uc == nil || uc.repo == nil {
		return result, ErrChecklistPersistenceMissing
	}

	limit := clampChecklistNotificationLimit(input.Limit)
	checklists, err := uc.repo.ListTripChecklistInstances(ctx, limit)
	if err != nil {
		return result, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	now := uc.now().UTC()
	lang := normalizeChecklistNotificationLang(input.PreferredLanguage)
	for _, checklist := range checklists {
		result.Scanned++
		request, ok := buildChecklistNotificationRequest(checklist, now, lang)
		if !ok {
			result.Skipped++
			continue
		}
		if uc.notificationSender == nil {
			result.Skipped++
			continue
		}
		if err = uc.notificationSender.SendChecklistNotification(ctx, request); err != nil {
			return result, err
		}
		result.Sent++
	}

	return result, nil
}

type checklistNotificationKind string

const (
	checklistNotificationCriticalReadiness checklistNotificationKind = "critical_readiness"
	checklistNotificationLowReadiness      checklistNotificationKind = "low_readiness"
	checklistNotificationEssentials        checklistNotificationKind = "essentials_remaining"
	checklistNotificationFinalCheck        checklistNotificationKind = "final_check"
)

type checklistOpenSummary struct {
	Critical    int
	Essential   int
	Important   int
	FirstAction string
}

func buildChecklistNotificationRequest(
	checklist model.TripChecklist,
	now time.Time,
	lang string,
) (ChecklistNotificationRequest, bool) {
	userID := strings.TrimSpace(checklist.UserID)
	tripID := strings.TrimSpace(checklist.TripID)
	if userID == "" || tripID == "" || checklist.StartAt.IsZero() {
		return ChecklistNotificationRequest{}, false
	}
	endAt := checklist.EndAt
	if endAt.IsZero() {
		endAt = checklist.StartAt
	}
	checklist.EndAt = endAt
	if endAt.UTC().Before(now.Add(-2 * time.Hour)) {
		return ChecklistNotificationRequest{}, false
	}

	open := summarizeOpenChecklistItems(checklist, lang)
	if checklistNotificationIsReady(checklist, open) {
		return ChecklistNotificationRequest{}, false
	}

	daysUntil := calendarDaysBetween(now, checklist.StartAt)
	if daysUntil < 0 {
		daysUntil = 0
	}

	kind, priority, ok := selectChecklistNotificationKind(checklist, open, daysUntil)
	if !ok {
		return ChecklistNotificationRequest{}, false
	}

	title, body := checklistNotificationText(kind, checklist, open, daysUntil, lang)
	deepLink := checklistDeepLink(checklist)
	data := checklistNotificationData(checklist, open, kind, deepLink)

	return ChecklistNotificationRequest{
		IdempotencyKey:  checklistNotificationIdempotencyKey(userID, tripID, string(kind), now),
		RecipientUserID: userID,
		Category:        checklistNotificationCategory,
		Priority:        priority,
		Title:           title,
		Body:            body,
		DeepLink:        deepLink,
		Data:            data,
		CollapseKey:     truncateNotificationValue("checklist:"+sanitizeNotificationKeyPart(tripID, 96), 128),
		TTL:             checklistNotificationTTL,
	}, true
}

func summarizeOpenChecklistItems(checklist model.TripChecklist, lang string) checklistOpenSummary {
	var summary checklistOpenSummary
	record := func(priority model.ChecklistPriority, title string) {
		switch priority {
		case model.ChecklistPriorityCritical:
			summary.Critical++
		case model.ChecklistPriorityEssential:
			summary.Essential++
		case model.ChecklistPriorityImportant:
			summary.Important++
		default:
			return
		}
		if summary.FirstAction == "" {
			summary.FirstAction = strings.TrimSpace(title)
		}
	}

	for _, item := range checklist.Items {
		if item.Status != model.ChecklistItemOpen {
			continue
		}
		record(item.Priority, item.Title.Get(lang))
	}
	for _, item := range checklist.CustomItems {
		if item.Status != model.ChecklistItemOpen {
			continue
		}
		record(item.Priority, item.Title)
	}
	return summary
}

func checklistNotificationIsReady(checklist model.TripChecklist, open checklistOpenSummary) bool {
	requiredOpen := open.Critical + open.Essential
	if checklist.Readiness.Status == model.ReadinessStatusReady && requiredOpen == 0 {
		return true
	}
	return checklist.Readiness.Score >= 90 && requiredOpen == 0
}

func selectChecklistNotificationKind(
	checklist model.TripChecklist,
	open checklistOpenSummary,
	daysUntil int,
) (checklistNotificationKind, string, bool) {
	if open.Critical > 0 && daysUntil <= 30 {
		return checklistNotificationCriticalReadiness, checklistNotificationPriorityHigh, true
	}
	if checklist.Readiness.Score < 60 && daysUntil <= 14 {
		return checklistNotificationLowReadiness, checklistNotificationPriorityHigh, true
	}
	if open.Essential > 0 && daysUntil <= 7 {
		return checklistNotificationEssentials, checklistNotificationPriorityHigh, true
	}
	if open.Critical+open.Essential+open.Important > 0 && daysUntil <= 2 {
		return checklistNotificationFinalCheck, checklistNotificationPriorityNormal, true
	}
	return "", "", false
}

func checklistNotificationText(
	kind checklistNotificationKind,
	checklist model.TripChecklist,
	open checklistOpenSummary,
	daysUntil int,
	lang string,
) (string, string) {
	destination := checklistDestinationLabel(checklist.Destination)
	count := open.Critical + open.Essential
	if count == 0 {
		count = open.Important
	}
	action := open.FirstAction
	if action == "" {
		action = checklistFallbackAction(lang)
	}

	switch normalizeChecklistNotificationLang(lang) {
	case "ru":
		switch kind {
		case checklistNotificationCriticalReadiness:
			return "Проверьте документы для поездки",
				fmt.Sprintf("%s до поездки в %s. Осталось закрыть важных пунктов: %d. Начните с: %s.", checklistCountdownRU(daysUntil), destination, count, action)
		case checklistNotificationLowReadiness:
			return "Готовность к поездке низкая",
				fmt.Sprintf("%s до поездки в %s. В чек-листе еще есть важные пункты: %d. Начните с: %s.", checklistCountdownRU(daysUntil), destination, count, action)
		case checklistNotificationEssentials:
			return "Пора закрыть важные пункты",
				fmt.Sprintf("%s до поездки в %s. Проверьте обязательные вещи: %s.", checklistCountdownRU(daysUntil), destination, action)
		default:
			return "Финальная проверка чек-листа",
				fmt.Sprintf("Поездка в %s уже близко. Проверьте пункт: %s.", destination, action)
		}
	case "kk":
		switch kind {
		case checklistNotificationCriticalReadiness:
			return "Сапар құжаттарын тексеріңіз",
				fmt.Sprintf("%s кейін %s сапары басталады. Маңызды ашық тармақтар: %d. Алдымен: %s.", checklistCountdownKK(daysUntil), destination, count, action)
		case checklistNotificationLowReadiness:
			return "Сапарға дайындық төмен",
				fmt.Sprintf("%s кейін %s сапары басталады. Чек-листе маңызды тармақтар қалды: %d. Алдымен: %s.", checklistCountdownKK(daysUntil), destination, count, action)
		case checklistNotificationEssentials:
			return "Маңызды тармақтарды жабыңыз",
				fmt.Sprintf("%s кейін %s сапары басталады. Міндетті затты тексеріңіз: %s.", checklistCountdownKK(daysUntil), destination, action)
		default:
			return "Чек-листің соңғы тексерісі",
				fmt.Sprintf("%s сапары жақын. Мына тармақты тексеріңіз: %s.", destination, action)
		}
	default:
		switch kind {
		case checklistNotificationCriticalReadiness:
			return "Check your travel documents",
				fmt.Sprintf("%s until your trip to %s. %d important items are still open. Start with: %s.", checklistCountdownEN(daysUntil), destination, count, action)
		case checklistNotificationLowReadiness:
			return "Trip readiness is low",
				fmt.Sprintf("%s until your trip to %s. %d important checklist items are still open. Start with: %s.", checklistCountdownEN(daysUntil), destination, count, action)
		case checklistNotificationEssentials:
			return "Finish the essentials",
				fmt.Sprintf("%s until your trip to %s. Check this required item: %s.", checklistCountdownEN(daysUntil), destination, action)
		default:
			return "Final checklist check",
				fmt.Sprintf("Your trip to %s is close. Check this item: %s.", destination, action)
		}
	}
}

func checklistNotificationData(
	checklist model.TripChecklist,
	open checklistOpenSummary,
	kind checklistNotificationKind,
	deepLink string,
) map[string]string {
	return map[string]string{
		"type":               "checklist_" + string(kind),
		"checklistTripId":    checklist.TripID,
		"tripId":             checklist.TripID,
		"category":           checklistNotificationCategory,
		"deepLink":           deepLink,
		"countryCode":        strings.TrimSpace(checklist.Destination.CountryCode),
		"cityName":           strings.TrimSpace(checklist.Destination.CityName),
		"cityId":             strings.TrimSpace(checklist.Destination.CityID),
		"startAt":            checklist.StartAt.UTC().Format(time.RFC3339),
		"endAt":              checklist.EndAt.UTC().Format(time.RFC3339),
		"readinessScore":     strconv.Itoa(checklist.Readiness.Score),
		"openCriticalCount":  strconv.Itoa(open.Critical),
		"openEssentialCount": strconv.Itoa(open.Essential),
	}
}

func checklistDeepLink(checklist model.TripChecklist) string {
	values := url.Values{}
	values.Set("tripId", checklist.TripID)
	values.Set("countryCode", strings.TrimSpace(checklist.Destination.CountryCode))
	values.Set("cityName", strings.TrimSpace(checklist.Destination.CityName))
	if cityID := strings.TrimSpace(checklist.Destination.CityID); cityID != "" {
		values.Set("cityId", cityID)
	}
	values.Set("startAt", checklist.StartAt.UTC().Format(time.RFC3339))
	values.Set("endAt", checklist.EndAt.UTC().Format(time.RFC3339))
	values.Set("transportModes", string(model.TransportModeFlight))
	return "/travel-checklist?" + values.Encode()
}

func checklistNotificationIdempotencyKey(userID string, tripID string, kind string, now time.Time) string {
	key := fmt.Sprintf(
		"checklist:%s:%s:%s:%s",
		sanitizeNotificationKeyPart(userID, 48),
		sanitizeNotificationKeyPart(tripID, 80),
		sanitizeNotificationKeyPart(kind, 48),
		now.UTC().Format("2006-01-02"),
	)
	return truncateNotificationValue(key, 220)
}

func sanitizeNotificationKeyPart(value string, maxRunes int) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return "unknown"
	}
	var builder strings.Builder
	for _, r := range value {
		if unicode.IsLetter(r) || unicode.IsDigit(r) || r == '-' || r == '_' || r == ':' || r == '.' {
			builder.WriteRune(r)
			continue
		}
		builder.WriteRune('_')
	}
	return truncateNotificationValue(builder.String(), maxRunes)
}

func truncateNotificationValue(value string, maxRunes int) string {
	if maxRunes <= 0 {
		return ""
	}
	runes := []rune(value)
	if len(runes) <= maxRunes {
		return value
	}
	return string(runes[:maxRunes])
}

func calendarDaysBetween(from time.Time, to time.Time) int {
	from = from.UTC()
	to = to.UTC()
	fromYear, fromMonth, fromDay := from.Date()
	toYear, toMonth, toDay := to.Date()
	fromDate := time.Date(fromYear, fromMonth, fromDay, 0, 0, 0, 0, time.UTC)
	toDate := time.Date(toYear, toMonth, toDay, 0, 0, 0, 0, time.UTC)
	return int(toDate.Sub(fromDate).Hours() / 24)
}

func checklistDestinationLabel(destination model.TripDestination) string {
	city := strings.TrimSpace(destination.CityName)
	country := strings.TrimSpace(destination.CountryCode)
	if city != "" && country != "" {
		return city + ", " + country
	}
	if city != "" {
		return city
	}
	if country != "" {
		return country
	}
	return "destination"
}

func checklistFallbackAction(lang string) string {
	switch normalizeChecklistNotificationLang(lang) {
	case "ru":
		return "проверить чек-лист"
	case "kk":
		return "чек-листі тексеру"
	default:
		return "review your checklist"
	}
}

func checklistCountdownRU(daysUntil int) string {
	if daysUntil <= 0 {
		return "Сегодня"
	}
	return fmt.Sprintf("Через %d дн.", daysUntil)
}

func checklistCountdownKK(daysUntil int) string {
	if daysUntil <= 0 {
		return "Бүгін"
	}
	return fmt.Sprintf("%d күн", daysUntil)
}

func checklistCountdownEN(daysUntil int) string {
	if daysUntil <= 0 {
		return "Today"
	}
	if daysUntil == 1 {
		return "1 day"
	}
	return fmt.Sprintf("%d days", daysUntil)
}

func clampChecklistNotificationLimit(limit int) int {
	if limit <= 0 {
		return defaultChecklistNotificationScanLimit
	}
	if limit > maxChecklistNotificationScanLimit {
		return maxChecklistNotificationScanLimit
	}
	return limit
}

func normalizeChecklistNotificationLang(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "ru":
		return "ru"
	case "kk":
		return "kk"
	default:
		return "en"
	}
}
