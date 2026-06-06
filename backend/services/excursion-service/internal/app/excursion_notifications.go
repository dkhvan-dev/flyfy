package app

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

const (
	excursionNotificationCategory = "excursion"
	excursionNotificationNormal   = "normal"
	excursionNotificationHigh     = "high"

	excursionNotificationTimeout = 3 * time.Second
	excursionNotificationTTL     = 6 * time.Hour
)

func (u *ExcursionUseCase) WithNotificationGateway(gateway port.ExcursionNotificationGateway) *ExcursionUseCase {
	u.notificationGateway = gateway
	return u
}

func (u *ExcursionUseCase) notifyExcursionBookingCreated(
	ctx context.Context,
	booking *model.ExcursionBooking,
	offer *model.ExcursionOffer,
	slot *model.ExcursionScheduleSlot,
) {
	if u.notificationGateway == nil || booking == nil || booking.GuideUserID == uuid.Nil {
		return
	}
	if booking.GuideUserID == booking.TouristUserID {
		return
	}

	dispatchExcursionNotification(ctx, u.notificationGateway, port.ExcursionNotificationInput{
		IdempotencyKey:   fmt.Sprintf("excursion:booking:%s:created", booking.ID),
		RecipientUserIDs: []uuid.UUID{booking.GuideUserID},
		Category:         excursionNotificationCategory,
		Priority:         excursionNotificationNormal,
		Title:            "New excursion booking",
		Body: fmt.Sprintf(
			"%s has a new booking for %s.",
			excursionNotificationTitleFromOffer(offer, booking),
			excursionSeatsLabel(booking.TotalSeats),
		),
		DeepLink:    excursionBookingsDeepLink(),
		Data:        excursionBookingNotificationData("booking_created", booking, slot),
		CollapseKey: fmt.Sprintf("excursion:booking:%s", booking.ID),
		TTL:         24 * time.Hour,
	})
}

func (u *ExcursionUseCase) notifyExcursionModerationApproved(
	ctx context.Context,
	item *model.Excursion,
) {
	u.notifyExcursionModerationDecision(
		ctx,
		item,
		"moderation_approved",
		"Excursion published",
		fmt.Sprintf("%s is now live.", excursionNotificationTitleFromExcursion(item)),
	)
}

func (u *ExcursionUseCase) notifyExcursionModerationRejected(
	ctx context.Context,
	item *model.Excursion,
) {
	u.notifyExcursionModerationDecision(
		ctx,
		item,
		"moderation_rejected",
		"Excursion needs changes",
		fmt.Sprintf("%s was not approved. Check the review notes.", excursionNotificationTitleFromExcursion(item)),
	)
}

func (u *ExcursionUseCase) notifyExcursionModerationDecision(
	ctx context.Context,
	item *model.Excursion,
	event string,
	title string,
	body string,
) {
	if u.notificationGateway == nil || item == nil || item.GuideUserID == uuid.Nil {
		return
	}

	data := map[string]string{
		"excursionEvent": event,
		"excursionId":    item.ID.String(),
		"guideUserId":    item.GuideUserID.String(),
		"status":         string(item.Status),
	}
	if len(item.ModerationReasonCodes) > 0 {
		data["reasonCodes"] = strings.Join(item.ModerationReasonCodes, ",")
	}

	dispatchExcursionNotification(ctx, u.notificationGateway, port.ExcursionNotificationInput{
		IdempotencyKey:   fmt.Sprintf("excursion:%s:%s:%d", item.ID, event, item.Revision),
		RecipientUserIDs: []uuid.UUID{item.GuideUserID},
		Category:         excursionNotificationCategory,
		Priority:         excursionNotificationNormal,
		Title:            title,
		Body:             body,
		DeepLink:         excursionBookingsDeepLink(),
		Data:             data,
		CollapseKey:      fmt.Sprintf("excursion:%s:moderation", item.ID),
		TTL:              24 * time.Hour,
	})
}

func (u *ExcursionUseCase) notifyExcursionBookingGuestsUpdated(
	ctx context.Context,
	booking *model.ExcursionBooking,
	oldSeats int,
) {
	if u.notificationGateway == nil || booking == nil || booking.GuideUserID == uuid.Nil {
		return
	}
	if booking.GuideUserID == booking.TouristUserID {
		return
	}

	slot := u.excursionBookingScheduleSlotForNotification(ctx, booking)
	data := excursionBookingNotificationData("booking_guests_updated", booking, slot)
	data["oldSeats"] = strconv.Itoa(oldSeats)

	dispatchExcursionNotification(ctx, u.notificationGateway, port.ExcursionNotificationInput{
		IdempotencyKey:   fmt.Sprintf("excursion:booking:%s:guests:%d", booking.ID, booking.TotalSeats),
		RecipientUserIDs: []uuid.UUID{booking.GuideUserID},
		Category:         excursionNotificationCategory,
		Priority:         excursionNotificationNormal,
		Title:            "Booking guests updated",
		Body:             fmt.Sprintf("Guest count changed to %s.", excursionSeatsLabel(booking.TotalSeats)),
		DeepLink:         excursionBookingsDeepLink(),
		Data:             data,
		CollapseKey:      fmt.Sprintf("excursion:booking:%s", booking.ID),
		TTL:              24 * time.Hour,
	})
}

func (u *ExcursionUseCase) notifyExcursionBookingCancelled(
	ctx context.Context,
	booking *model.ExcursionBooking,
) {
	if u.notificationGateway == nil || booking == nil || booking.GuideUserID == uuid.Nil {
		return
	}
	if booking.GuideUserID == booking.TouristUserID {
		return
	}

	slot := u.excursionBookingScheduleSlotForNotification(ctx, booking)
	data := excursionBookingNotificationData("booking_cancelled_by_tourist", booking, slot)
	if booking.CancelReason != nil {
		data["reason"] = strings.TrimSpace(*booking.CancelReason)
	}
	if booking.RefundPolicyCode != nil {
		data["refundPolicyCode"] = strings.TrimSpace(*booking.RefundPolicyCode)
	}
	if booking.RefundStatus != nil {
		data["refundStatus"] = strings.TrimSpace(*booking.RefundStatus)
	}

	dispatchExcursionNotification(ctx, u.notificationGateway, port.ExcursionNotificationInput{
		IdempotencyKey:   fmt.Sprintf("excursion:booking:%s:cancelled", booking.ID),
		RecipientUserIDs: []uuid.UUID{booking.GuideUserID},
		Category:         excursionNotificationCategory,
		Priority:         excursionNotificationHigh,
		Title:            "Excursion booking cancelled",
		Body:             fmt.Sprintf("A traveler cancelled %s.", excursionNotificationTitleFromBooking(booking)),
		DeepLink:         excursionBookingsDeepLink(),
		Data:             data,
		CollapseKey:      fmt.Sprintf("excursion:booking:%s", booking.ID),
		TTL:              24 * time.Hour,
	})
}

func (u *ExcursionUseCase) notifyExcursionScheduleSlotCancelled(
	ctx context.Context,
	slot *model.ExcursionScheduleSlot,
) {
	u.dispatchExcursionSlotNotification(ctx, slot, excursionSlotNotification{
		Event:       "schedule_slot_cancelled",
		Priority:    excursionNotificationHigh,
		Title:       "Excursion cancelled",
		Body:        fmt.Sprintf("%s was cancelled by the guide.", excursionNotificationTitleFromSlot(slot)),
		TTL:         24 * time.Hour,
		CollapseKey: fmt.Sprintf("excursion:slot:%s:lifecycle", slotIDString(slot)),
	})
}

func (u *ExcursionUseCase) notifyExcursionScheduleSlotClosed(
	ctx context.Context,
	slot *model.ExcursionScheduleSlot,
) {
	u.dispatchExcursionSlotNotification(ctx, slot, excursionSlotNotification{
		Event:       "schedule_slot_closed",
		Priority:    excursionNotificationHigh,
		Title:       "Excursion starts soon",
		Body:        fmt.Sprintf("%s is confirmed. The booking window is closed.", excursionNotificationTitleFromSlot(slot)),
		TTL:         excursionNotificationTTL,
		CollapseKey: fmt.Sprintf("excursion:slot:%s:lifecycle", slotIDString(slot)),
	})
}

func (u *ExcursionUseCase) notifyExcursionScheduleSlotCompleted(
	ctx context.Context,
	slot *model.ExcursionScheduleSlot,
) {
	u.dispatchExcursionSlotNotification(ctx, slot, excursionSlotNotification{
		Event:       "schedule_slot_completed",
		Priority:    excursionNotificationNormal,
		Title:       "How was your excursion?",
		Body:        fmt.Sprintf("%s is complete. You can leave a review.", excursionNotificationTitleFromSlot(slot)),
		TTL:         24 * time.Hour,
		CollapseKey: fmt.Sprintf("excursion:slot:%s:lifecycle", slotIDString(slot)),
	})
}

func (u *ExcursionUseCase) notifyExcursionAttendanceCheckedIn(
	ctx context.Context,
	booking *model.ExcursionBooking,
) {
	if u.notificationGateway == nil || booking == nil || booking.GuideUserID == uuid.Nil {
		return
	}
	if booking.GuideUserID == booking.TouristUserID {
		return
	}

	slot := u.excursionBookingScheduleSlotForNotification(ctx, booking)
	data := excursionBookingNotificationData("attendance_checked_in", booking, slot)
	if booking.CheckedInAt != nil {
		data["checkedInAt"] = booking.CheckedInAt.UTC().Format(timeRFC3339)
	}

	dispatchExcursionNotification(ctx, u.notificationGateway, port.ExcursionNotificationInput{
		IdempotencyKey:   fmt.Sprintf("excursion:booking:%s:checked-in", booking.ID),
		RecipientUserIDs: []uuid.UUID{booking.GuideUserID},
		Category:         excursionNotificationCategory,
		Priority:         excursionNotificationNormal,
		Title:            "Traveler checked in",
		Body:             fmt.Sprintf("A traveler checked in for %s.", excursionNotificationTitleFromBooking(booking)),
		DeepLink:         excursionBookingsDeepLink(),
		Data:             data,
		CollapseKey:      fmt.Sprintf("excursion:slot:%s:attendance", scheduleSlotIDString(booking.ScheduleSlotID)),
		TTL:              time.Hour,
	})
}

type excursionSlotNotification struct {
	Event       string
	Priority    string
	Title       string
	Body        string
	TTL         time.Duration
	CollapseKey string
}

func (u *ExcursionUseCase) dispatchExcursionSlotNotification(
	ctx context.Context,
	slot *model.ExcursionScheduleSlot,
	notification excursionSlotNotification,
) {
	if u.notificationGateway == nil || u.repo == nil || slot == nil || slot.ID == uuid.Nil {
		return
	}

	go func() {
		notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), excursionNotificationTimeout)
		defer cancel()

		recipients, err := u.loadExcursionScheduleSlotRecipients(notifyCtx, slot.ID)
		if err != nil {
			log.Warn().
				Err(err).
				Str("schedule_slot_id", slot.ID.String()).
				Str("event", notification.Event).
				Msg("failed to load excursion notification recipients")
			return
		}
		if len(recipients) == 0 {
			return
		}

		if err = u.notificationGateway.SendExcursionNotification(notifyCtx, port.ExcursionNotificationInput{
			IdempotencyKey:   fmt.Sprintf("excursion:slot:%s:%s", slot.ID, notification.Event),
			RecipientUserIDs: recipients,
			Category:         excursionNotificationCategory,
			Priority:         notification.Priority,
			Title:            notification.Title,
			Body:             notification.Body,
			DeepLink:         excursionBookingsDeepLink(),
			Data:             excursionSlotNotificationData(notification.Event, slot),
			CollapseKey:      notification.CollapseKey,
			TTL:              notification.TTL,
		}); err != nil {
			log.Warn().
				Err(err).
				Str("schedule_slot_id", slot.ID.String()).
				Str("event", notification.Event).
				Msg("failed to send excursion schedule notification")
		}
	}()
}

func (u *ExcursionUseCase) loadExcursionScheduleSlotRecipients(
	ctx context.Context,
	slotID uuid.UUID,
) ([]uuid.UUID, error) {
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		ScheduleSlotID: &slotID,
		Statuses:       []enum.ExcursionBookingStatus{enum.ExcursionBookingStatusRequested},
		Limit:          500,
	})
	if err != nil {
		return nil, fmt.Errorf("list excursion slot bookings: %w", err)
	}
	return activeExcursionBookingTouristUserIDs(items), nil
}

func activeExcursionBookingTouristUserIDs(items []*model.ExcursionBookingListItem) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(items))
	recipients := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item == nil || item.Booking == nil {
			continue
		}
		booking := item.Booking
		if booking.Status != enum.ExcursionBookingStatusRequested ||
			booking.CancelledAt != nil ||
			booking.TouristUserID == uuid.Nil ||
			booking.TouristUserID == booking.GuideUserID {
			continue
		}
		if _, ok := seen[booking.TouristUserID]; ok {
			continue
		}
		seen[booking.TouristUserID] = struct{}{}
		recipients = append(recipients, booking.TouristUserID)
	}
	return recipients
}

func dispatchExcursionNotification(
	ctx context.Context,
	gateway port.ExcursionNotificationGateway,
	input port.ExcursionNotificationInput,
) {
	if gateway == nil || len(input.RecipientUserIDs) == 0 {
		return
	}

	go func() {
		notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), excursionNotificationTimeout)
		defer cancel()

		if err := gateway.SendExcursionNotification(notifyCtx, input); err != nil {
			log.Warn().
				Err(err).
				Str("idempotency_key", input.IdempotencyKey).
				Msg("failed to send excursion notification")
		}
	}()
}

func (u *ExcursionUseCase) excursionBookingScheduleSlotForNotification(
	ctx context.Context,
	booking *model.ExcursionBooking,
) *model.ExcursionScheduleSlot {
	if u == nil || u.repo == nil || booking == nil ||
		booking.ScheduleSlotID == nil || *booking.ScheduleSlotID == uuid.Nil {
		return nil
	}
	slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, *booking.ScheduleSlotID)
	if err != nil {
		log.Warn().
			Err(err).
			Str("booking_id", booking.ID.String()).
			Str("schedule_slot_id", booking.ScheduleSlotID.String()).
			Msg("failed to load excursion schedule slot for notification timezone")
		return nil
	}
	if slot == nil || slot.ProductID != booking.ProductID || slot.OfferID != booking.OfferID {
		return nil
	}
	return slot
}

func excursionBookingNotificationData(
	event string,
	booking *model.ExcursionBooking,
	slot *model.ExcursionScheduleSlot,
) map[string]string {
	data := map[string]string{
		"excursionEvent": event,
	}
	if booking == nil {
		return data
	}
	data["bookingId"] = booking.ID.String()
	data["productId"] = booking.ProductID.String()
	data["offerId"] = booking.OfferID.String()
	data["excursionId"] = booking.ProductID.String()
	data["guideUserId"] = booking.GuideUserID.String()
	data["touristUserId"] = booking.TouristUserID.String()
	scheduledFor := booking.ScheduledFor.UTC().Format(timeRFC3339)
	data["eventStartAt"] = scheduledFor
	data["startAt"] = scheduledFor
	data["scheduledFor"] = scheduledFor
	data["totalSeats"] = strconv.Itoa(booking.TotalSeats)
	data["adults"] = strconv.Itoa(booking.Adults)
	data["children"] = strconv.Itoa(booking.Children)
	data["status"] = string(booking.Status)
	if booking.ScheduleSlotID != nil {
		data["scheduleSlotId"] = booking.ScheduleSlotID.String()
	}
	addExcursionScheduleTimezoneData(data, slot)
	return data
}

func excursionSlotNotificationData(event string, slot *model.ExcursionScheduleSlot) map[string]string {
	data := map[string]string{
		"excursionEvent": event,
	}
	if slot == nil {
		return data
	}
	data["scheduleSlotId"] = slot.ID.String()
	data["productId"] = slot.ProductID.String()
	data["offerId"] = slot.OfferID.String()
	data["excursionId"] = slot.ProductID.String()
	data["guideUserId"] = slot.GuideUserID.String()
	startAt := slot.StartAt.UTC().Format(timeRFC3339)
	data["eventStartAt"] = startAt
	data["startAt"] = startAt
	data["endAt"] = slot.EndAt.UTC().Format(timeRFC3339)
	data["status"] = string(slot.Status)
	addExcursionScheduleTimezoneData(data, slot)
	if slot.CancelReason != nil {
		data["reason"] = strings.TrimSpace(*slot.CancelReason)
	}
	return data
}

func addExcursionScheduleTimezoneData(
	data map[string]string,
	slot *model.ExcursionScheduleSlot,
) {
	if data == nil || slot == nil {
		return
	}
	timezone := strings.TrimSpace(slot.Timezone)
	if timezone == "" {
		return
	}
	data["eventTimezone"] = timezone
	data["timezone"] = timezone
	data["slotTimezone"] = timezone
	data["scheduleTimezone"] = timezone
}

func excursionBookingsDeepLink() string {
	return "/me/excursions"
}

func excursionNotificationTitleFromOffer(
	offer *model.ExcursionOffer,
	booking *model.ExcursionBooking,
) string {
	if offer != nil {
		title := strings.TrimSpace(offer.Title)
		if title != "" {
			return title
		}
	}
	return excursionNotificationTitleFromBooking(booking)
}

func excursionNotificationTitleFromExcursion(item *model.Excursion) string {
	if item == nil {
		return "Your excursion"
	}
	title := strings.TrimSpace(item.Title)
	if title == "" {
		return "Your excursion"
	}
	return title
}

func excursionNotificationTitleFromBooking(booking *model.ExcursionBooking) string {
	if booking == nil {
		return "this excursion"
	}
	return "this excursion"
}

func excursionNotificationTitleFromSlot(slot *model.ExcursionScheduleSlot) string {
	if slot == nil {
		return "Your excursion"
	}
	title := strings.TrimSpace(slot.Title)
	if title == "" {
		return "Your excursion"
	}
	return title
}

func excursionSeatsLabel(seats int) string {
	if seats == 1 {
		return "1 guest"
	}
	return fmt.Sprintf("%d guests", seats)
}

func slotIDString(slot *model.ExcursionScheduleSlot) string {
	if slot == nil || slot.ID == uuid.Nil {
		return "unknown"
	}
	return slot.ID.String()
}

func scheduleSlotIDString(slotID *uuid.UUID) string {
	if slotID == nil || *slotID == uuid.Nil {
		return "none"
	}
	return slotID.String()
}
