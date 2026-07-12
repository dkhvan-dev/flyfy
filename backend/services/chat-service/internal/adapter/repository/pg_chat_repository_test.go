package repository

import (
	"strings"
	"testing"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
)

func TestMessageScanDestinationsMatchSelectedColumns(t *testing.T) {
	t.Parallel()

	var message model.Message
	var values messageScanValues
	destinationCount := len(messageScanDestinations(&message, &values))

	for name, columns := range map[string]string{
		"messageColumns":       messageColumns,
		"messageSelectColumns": messageSelectColumns,
	} {
		columnCount := len(strings.Split(columns, ","))
		if destinationCount != columnCount {
			t.Fatalf(
				"%s has %d columns but message scanner has %d destinations",
				name,
				columnCount,
				destinationCount,
			)
		}
	}
}

func TestMessageScanValuesApplyLegacyDefaults(t *testing.T) {
	t.Parallel()

	var message model.Message
	var values messageScanValues
	values.apply(&message)

	if message.SendStatus != model.MessageSendStatusSent {
		t.Fatalf("expected default send status %q, got %q", model.MessageSendStatusSent, message.SendStatus)
	}
	if message.ModerationStatus != model.MessageModerationStatusVisible {
		t.Fatalf(
			"expected default moderation status %q, got %q",
			model.MessageModerationStatusVisible,
			message.ModerationStatus,
		)
	}
	if message.ModerationRevision != 1 {
		t.Fatalf("expected default moderation revision 1, got %d", message.ModerationRevision)
	}
}

func TestChatNotificationOutboxReturningColumnsAreQualified(t *testing.T) {
	t.Parallel()

	for _, column := range strings.Split(chatNotificationOutboxReturningColumns, ",") {
		column = strings.TrimSpace(column)
		if column == "" {
			t.Fatal("chat notification outbox returning columns contains an empty column")
		}
		if !strings.HasPrefix(column, "outbox.") {
			t.Fatalf("chat notification outbox returning column %q must be qualified with outbox alias", column)
		}
	}
}
