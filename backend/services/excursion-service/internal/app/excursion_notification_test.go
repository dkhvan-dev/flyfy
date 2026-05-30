package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

type excursionNotificationGatewayStub struct {
	send func(ctx context.Context, input port.ExcursionNotificationInput) error
}

func (s excursionNotificationGatewayStub) SendExcursionNotification(
	ctx context.Context,
	input port.ExcursionNotificationInput,
) error {
	if s.send != nil {
		return s.send(ctx, input)
	}
	return nil
}

func TestCreateExcursionBookingNotifiesGuide(t *testing.T) {
	t.Parallel()

	productID := uuid.New()
	offerID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	notifications := make(chan port.ExcursionNotificationInput, 1)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Title:          "Big Almaty Lake",
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    120,
			Currency:       "USD",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithNotificationGateway(excursionNotificationGatewayStub{
			send: func(ctx context.Context, input port.ExcursionNotificationInput) error {
				notifications <- input
				return nil
			},
		})

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:  touristUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: scheduledFor,
		Adults:       2,
		Children:     1,
	})
	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking == nil {
		t.Fatal("booking is nil")
	}

	got := waitExcursionNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != guideUserID {
		t.Fatalf("recipient user ids = %v, want guide %s", got.RecipientUserIDs, guideUserID)
	}
	if got.Category != "excursion" || got.Priority != "normal" {
		t.Fatalf("category/priority = %q/%q, want excursion/normal", got.Category, got.Priority)
	}
	if got.DeepLink != "/me/excursions" {
		t.Fatalf("deep link = %q, want /me/excursions", got.DeepLink)
	}
	if got.Data["excursionEvent"] != "booking_created" ||
		got.Data["bookingId"] != booking.ID.String() ||
		got.Data["touristUserId"] != touristUserID.String() ||
		got.Data["totalSeats"] != "3" {
		t.Fatalf("notification data = %#v", got.Data)
	}
}

func TestCancelGuideScheduleSlotNotifiesBookedTourists(t *testing.T) {
	t.Parallel()

	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	activeTouristID := uuid.New()
	cancelledTouristID := uuid.New()
	startAt := time.Now().UTC().Add(6 * time.Hour)
	notifications := make(chan port.ExcursionNotificationInput, 1)
	cancelledAt := time.Now().UTC()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          startAt.Add(2 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
			Title:          "Kok-Tobe walk",
		},
		listBookingItems: []*model.ExcursionBookingListItem{
			{
				Booking: &model.ExcursionBooking{
					ID:             uuid.New(),
					ProductID:      productID,
					OfferID:        offerID,
					ScheduleSlotID: &slotID,
					GuideProfileID: uuid.New(),
					GuideUserID:    guideUserID,
					TouristUserID:  activeTouristID,
					ScheduledFor:   startAt,
					Adults:         2,
					TotalSeats:     2,
					Currency:       "KZT",
					Status:         enum.ExcursionBookingStatusRequested,
				},
			},
			{
				Booking: &model.ExcursionBooking{
					ID:             uuid.New(),
					ProductID:      productID,
					OfferID:        offerID,
					ScheduleSlotID: &slotID,
					GuideProfileID: uuid.New(),
					GuideUserID:    guideUserID,
					TouristUserID:  cancelledTouristID,
					ScheduledFor:   startAt,
					Adults:         1,
					TotalSeats:     1,
					Currency:       "KZT",
					Status:         enum.ExcursionBookingStatusCancelled,
					CancelledAt:    &cancelledAt,
				},
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithNotificationGateway(excursionNotificationGatewayStub{
			send: func(ctx context.Context, input port.ExcursionNotificationInput) error {
				notifications <- input
				return nil
			},
		})

	slot, err := uc.CancelGuideScheduleSlot(context.Background(), guideUserID, slotID, "Weather alert")
	if err != nil {
		t.Fatalf("CancelGuideScheduleSlot() error = %v", err)
	}
	if slot.Status != enum.ExcursionScheduleSlotStatusCancelled {
		t.Fatalf("slot status = %q, want cancelled", slot.Status)
	}

	got := waitExcursionNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != activeTouristID {
		t.Fatalf("recipient user ids = %v, want active tourist %s", got.RecipientUserIDs, activeTouristID)
	}
	if got.Priority != "high" {
		t.Fatalf("priority = %q, want high", got.Priority)
	}
	if got.Data["excursionEvent"] != "schedule_slot_cancelled" ||
		got.Data["scheduleSlotId"] != slotID.String() ||
		got.Data["reason"] != "Weather alert" {
		t.Fatalf("notification data = %#v", got.Data)
	}
}

func TestAutoCompleteDueExcursionScheduleSlotsNotifiesParticipantsToReview(t *testing.T) {
	t.Parallel()

	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	touristUserID := uuid.New()
	startAt := time.Now().UTC().Add(-3 * time.Hour)
	notifications := make(chan port.ExcursionNotificationInput, 1)
	repo := &excursionRepoStub{
		completedScheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             slotID,
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        startAt,
				EndAt:          startAt.Add(2 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       6,
				BookedSeats:    1,
				Status:         enum.ExcursionScheduleSlotStatusCompleted,
				Title:          "City stories",
			},
		},
		listBookingItems: []*model.ExcursionBookingListItem{
			{
				Booking: &model.ExcursionBooking{
					ID:             uuid.New(),
					ProductID:      productID,
					OfferID:        offerID,
					ScheduleSlotID: &slotID,
					GuideProfileID: uuid.New(),
					GuideUserID:    guideUserID,
					TouristUserID:  touristUserID,
					ScheduledFor:   startAt,
					Adults:         1,
					TotalSeats:     1,
					Currency:       "KZT",
					Status:         enum.ExcursionBookingStatusRequested,
				},
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithNotificationGateway(excursionNotificationGatewayStub{
			send: func(ctx context.Context, input port.ExcursionNotificationInput) error {
				notifications <- input
				return nil
			},
		})

	count, err := uc.AutoCompleteDueExcursionScheduleSlots(context.Background(), 50)
	if err != nil {
		t.Fatalf("AutoCompleteDueExcursionScheduleSlots() error = %v", err)
	}
	if count != 1 {
		t.Fatalf("count = %d, want 1", count)
	}

	got := waitExcursionNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != touristUserID {
		t.Fatalf("recipient user ids = %v, want tourist %s", got.RecipientUserIDs, touristUserID)
	}
	if got.Data["excursionEvent"] != "schedule_slot_completed" ||
		got.Data["scheduleSlotId"] != slotID.String() {
		t.Fatalf("notification data = %#v", got.Data)
	}
}

func waitExcursionNotification(
	t *testing.T,
	ch <-chan port.ExcursionNotificationInput,
) port.ExcursionNotificationInput {
	t.Helper()

	select {
	case got := <-ch:
		return got
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for excursion notification")
	}
	return port.ExcursionNotificationInput{}
}
