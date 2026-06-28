package repository

import (
	"strings"
	"testing"
)

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
