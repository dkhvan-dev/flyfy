package repository

import (
	"os"
	"strings"
	"testing"
)

func TestChatReadPathPerformanceMigrationIndexes(t *testing.T) {
	t.Parallel()

	content, err := os.ReadFile("../../../migrations/014_chat_read_path_performance.up.sql")
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	upSQL := string(content)

	for _, want := range []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_message_files_message_position",
		"ON message_files (message_id, position)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_messages_unread_active_conversation_sent_id",
		"ON messages (conversation_id, sent_at, id)",
		"WHERE deleted_at IS NULL AND type <> 'system'",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_active_conversation_joined",
		"ON conversation_participants (conversation_id, joined_at)",
		"WHERE left_at IS NULL",
	} {
		if !strings.Contains(upSQL, want) {
			t.Fatalf("migration missing %q", want)
		}
	}

	downContent, err := os.ReadFile("../../../migrations/014_chat_read_path_performance.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}
	downSQL := string(downContent)
	for _, want := range []string{
		"DROP INDEX CONCURRENTLY IF EXISTS idx_cp_active_conversation_joined",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_messages_unread_active_conversation_sent_id",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_message_files_message_position",
	} {
		if !strings.Contains(downSQL, want) {
			t.Fatalf("down migration missing %q", want)
		}
	}
}
