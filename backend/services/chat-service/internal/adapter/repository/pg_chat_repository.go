package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

type PGChatRepository struct {
	pool *pgxpool.Pool
}

func NewPGChatRepository(pool *pgxpool.Pool) *PGChatRepository {
	return &PGChatRepository{pool: pool}
}

type pgChatTxRepository struct {
	tx pgx.Tx
}

func (r *PGChatRepository) WithTx(ctx context.Context, fn func(repo port.ChatTxRepository) error) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	txRepo := &pgChatTxRepository{tx: tx}
	if err = fn(txRepo); err != nil {
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}

const conversationColumns = `id, type, title, avatar_file_id, activity_id, excursion_schedule_slot_id, pinned_message_id, messaging_available_until, created_at, last_activity_at`
const conversationSelectColumns = `c.id, c.type, c.title, c.avatar_file_id, c.activity_id, c.excursion_schedule_slot_id, c.pinned_message_id, c.messaging_available_until, c.created_at, c.last_activity_at`
const messageColumns = `id, conversation_id, sender_user_id, client_message_id, type, content, sticker_id, sticker_file_id, sticker_payload, reply_to_message_id, story_reply, forwarded_from_message_id, forwarded_from_sender_user_id, forwarded_from_sender_name, forward_count, edited_at, deleted_at, moderation_status, moderation_reason_codes, moderation_risk_score, moderation_triggered_at, moderation_reviewed_at, moderation_reviewed_by, moderation_public_comment, moderation_internal_comment, moderation_revision, sent_at`
const messageSelectColumns = `m.id, m.conversation_id, m.sender_user_id, m.client_message_id, m.type, m.content, m.sticker_id, m.sticker_file_id, m.sticker_payload, m.reply_to_message_id, m.story_reply, m.forwarded_from_message_id, m.forwarded_from_sender_user_id, m.forwarded_from_sender_name, m.forward_count, m.edited_at, m.deleted_at, m.moderation_status, m.moderation_reason_codes, m.moderation_risk_score, m.moderation_triggered_at, m.moderation_reviewed_at, m.moderation_reviewed_by, m.moderation_public_comment, m.moderation_internal_comment, m.moderation_revision, m.sent_at`
const chatNotificationOutboxColumns = `id, event_type, conversation_id, message_id, actor_user_id, reaction_emoji, attempts, next_attempt_at, locked_at, processed_at, failed_at, last_error, created_at, updated_at`

func scanConversation(row pgx.Row) (*model.Conversation, error) {
	var c model.Conversation
	err := row.Scan(
		&c.ID, &c.Type, &c.Title, &c.AvatarFileID, &c.ActivityID,
		&c.ExcursionScheduleSlotID, &c.PinnedMessageID, &c.MessagingAvailableUntil, &c.CreatedAt, &c.LastActivityAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan conversation: %w", err)
	}
	return &c, nil
}

func (r *PGChatRepository) GetConversationByID(ctx context.Context, conversationID uuid.UUID) (*model.Conversation, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE id = $1`, conversationID)
	return scanConversation(row)
}

func (r *PGChatRepository) GetConversationByActivityID(ctx context.Context, activityID uuid.UUID) (*model.Conversation, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE activity_id = $1`, activityID)
	return scanConversation(row)
}

func (r *PGChatRepository) GetConversationByExcursionScheduleSlotID(ctx context.Context, slotID uuid.UUID) (*model.Conversation, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE excursion_schedule_slot_id = $1`, slotID)
	return scanConversation(row)
}

func (r *PGChatRepository) FindDirectConversation(ctx context.Context, userID1, userID2 uuid.UUID) (*model.Conversation, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT `+conversationColumns+`
		FROM conversations c
		WHERE c.type = 'direct'
		  AND EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = c.id AND user_id = $1 AND left_at IS NULL)
		  AND EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = c.id AND user_id = $2 AND left_at IS NULL)
		LIMIT 1
	`, userID1, userID2)
	return scanConversation(row)
}

func (r *PGChatRepository) ListConversationsByUserID(ctx context.Context, filter port.ConversationFilter) ([]*model.Conversation, error) {
	query := `
		SELECT ` + conversationSelectColumns + `
		FROM conversations c
		INNER JOIN conversation_participants cp ON cp.conversation_id = c.id
		WHERE cp.user_id = $1 AND cp.left_at IS NULL
	`
	args := []any{filter.UserID}
	argIdx := 2

	if filter.Type != nil {
		query += fmt.Sprintf(` AND c.type = $%d`, argIdx)
		args = append(args, *filter.Type)
		argIdx++
	}
	if filter.Cursor != nil {
		query += fmt.Sprintf(` AND c.last_activity_at < $%d`, argIdx)
		args = append(args, *filter.Cursor)
		argIdx++
	}

	query += ` ORDER BY c.last_activity_at DESC`
	query += fmt.Sprintf(` LIMIT $%d`, argIdx)
	args = append(args, filter.Limit)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list conversations: %w", err)
	}
	defer rows.Close()

	var convs []*model.Conversation
	for rows.Next() {
		var c model.Conversation
		if err := rows.Scan(
			&c.ID, &c.Type, &c.Title, &c.AvatarFileID, &c.ActivityID,
			&c.ExcursionScheduleSlotID, &c.PinnedMessageID, &c.MessagingAvailableUntil, &c.CreatedAt, &c.LastActivityAt,
		); err != nil {
			return nil, fmt.Errorf("scan conversation row: %w", err)
		}
		convs = append(convs, &c)
	}
	return convs, rows.Err()
}

func scanMessage(row pgx.Row) (*model.Message, error) {
	var m model.Message
	var stickerPayload []byte
	var storyReplyPayload []byte
	var forwardedFromSenderName *string
	var moderationStatus *string
	var moderationReasonCodes []string
	var moderationPublicComment *string
	var moderationInternalComment *string
	err := row.Scan(
		&m.ID, &m.ConversationID, &m.SenderUserID, &m.ClientMessageID, &m.Type, &m.Content,
		&m.StickerID, &m.StickerFileID, &stickerPayload,
		&m.ReplyToMessageID, &storyReplyPayload, &m.ForwardedFromMessageID,
		&m.ForwardedFromSenderUserID, &forwardedFromSenderName,
		&m.ForwardCount, &m.EditedAt, &m.DeletedAt,
		&moderationStatus, &moderationReasonCodes, &m.ModerationRiskScore,
		&m.ModerationTriggeredAt, &m.ModerationReviewedAt, &m.ModerationReviewedBy,
		&moderationPublicComment, &moderationInternalComment, &m.ModerationRevision,
		&m.SentAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan message: %w", err)
	}
	m.StickerPayload = decodeStickerPayload(stickerPayload)
	m.StoryReply = decodeStoryReplyContext(storyReplyPayload)
	if forwardedFromSenderName != nil {
		m.ForwardedFromSenderName = *forwardedFromSenderName
	}
	m.ModerationStatus = model.MessageModerationStatusVisible
	if moderationStatus != nil && strings.TrimSpace(*moderationStatus) != "" {
		m.ModerationStatus = strings.TrimSpace(*moderationStatus)
	}
	m.ModerationReasonCodes = append([]string(nil), moderationReasonCodes...)
	if moderationPublicComment != nil {
		m.ModerationPublicComment = *moderationPublicComment
	}
	if moderationInternalComment != nil {
		m.ModerationInternalComment = *moderationInternalComment
	}
	if m.ModerationRevision <= 0 {
		m.ModerationRevision = 1
	}
	return &m, nil
}

func scanMessageReaction(row pgx.Row) (*model.MessageReaction, error) {
	var reaction model.MessageReaction
	err := row.Scan(
		&reaction.MessageID,
		&reaction.UserID,
		&reaction.Emoji,
		&reaction.ReactedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan message reaction: %w", err)
	}
	return &reaction, nil
}

func scanChatNotificationOutbox(row pgx.Row) (*model.ChatNotificationOutbox, error) {
	var item model.ChatNotificationOutbox
	var reactionEmoji *string
	var lastError *string
	err := row.Scan(
		&item.ID,
		&item.EventType,
		&item.ConversationID,
		&item.MessageID,
		&item.ActorUserID,
		&reactionEmoji,
		&item.Attempts,
		&item.NextAttemptAt,
		&item.LockedAt,
		&item.ProcessedAt,
		&item.FailedAt,
		&lastError,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan chat notification outbox: %w", err)
	}
	if reactionEmoji != nil {
		item.ReactionEmoji = *reactionEmoji
	}
	if lastError != nil {
		item.LastError = *lastError
	}
	return &item, nil
}

func stickerPayloadJSON(payload *model.StickerPayload) any {
	if payload == nil {
		return nil
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return nil
	}
	return data
}

func storyReplyContextJSON(context *model.StoryReplyContext) any {
	if context == nil || context.IsZero() {
		return nil
	}
	data, err := json.Marshal(context)
	if err != nil {
		return nil
	}
	return data
}

func nullableString(value string) *string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func defaultMessageModerationStatus(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return model.MessageModerationStatusVisible
	}
	return value
}

func defaultMessageModerationRevision(value int) int {
	if value <= 0 {
		return 1
	}
	return value
}

func defaultMessageModerationReasonCodes(value []string) []string {
	if value == nil {
		return []string{}
	}
	return value
}

func decodeStickerPayload(data []byte) *model.StickerPayload {
	if len(data) == 0 {
		return nil
	}
	var payload model.StickerPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		return nil
	}
	return &payload
}

func decodeStoryReplyContext(data []byte) *model.StoryReplyContext {
	if len(data) == 0 {
		return nil
	}
	var payload model.StoryReplyContext
	if err := json.Unmarshal(data, &payload); err != nil || payload.IsZero() {
		return nil
	}
	return &payload
}

func isDuplicateClientMessageID(err error) bool {
	if err == nil {
		return false
	}
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	return pgErr.Code == "23505" && pgErr.ConstraintName == "uq_messages_client_message_id"
}

func (r *PGChatRepository) GetMessageByID(ctx context.Context, messageID uuid.UUID) (*model.Message, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+messageColumns+` FROM messages WHERE id = $1`, messageID)
	return scanMessage(row)
}

func (r *PGChatRepository) GetMessageByClientMessageID(
	ctx context.Context,
	conversationID uuid.UUID,
	senderUserID uuid.UUID,
	clientMessageID uuid.UUID,
) (*model.Message, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT `+messageColumns+`
		FROM messages
		WHERE conversation_id = $1
		  AND sender_user_id = $2
		  AND client_message_id = $3
	`, conversationID, senderUserID, clientMessageID)
	return scanMessage(row)
}

func (r *PGChatRepository) ListMessages(ctx context.Context, filter port.MessageFilter) ([]*model.Message, error) {
	query := `SELECT ` + messageColumns + ` FROM messages WHERE conversation_id = $1`
	args := []any{filter.ConversationID}
	argIdx := 2

	if filter.Cursor != nil {
		if filter.Direction == "newer" {
			query += fmt.Sprintf(` AND (sent_at, id) > (
				SELECT sent_at, id FROM messages WHERE conversation_id = $1 AND id = $%d
			)`, argIdx)
		} else {
			query += fmt.Sprintf(` AND (sent_at, id) < (
				SELECT sent_at, id FROM messages WHERE conversation_id = $1 AND id = $%d
			)`, argIdx)
		}
		args = append(args, *filter.Cursor)
		argIdx++
	}

	if filter.Direction == "newer" {
		query += ` ORDER BY sent_at ASC, id ASC`
	} else {
		query += ` ORDER BY sent_at DESC, id DESC`
	}

	query += fmt.Sprintf(` LIMIT $%d`, argIdx)
	args = append(args, filter.Limit)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list messages: %w", err)
	}
	defer rows.Close()

	var msgs []*model.Message
	for rows.Next() {
		var m model.Message
		var stickerPayload []byte
		var storyReplyPayload []byte
		var forwardedFromSenderName *string
		var moderationStatus *string
		var moderationReasonCodes []string
		var moderationPublicComment *string
		var moderationInternalComment *string
		if err := rows.Scan(
			&m.ID, &m.ConversationID, &m.SenderUserID, &m.ClientMessageID, &m.Type, &m.Content,
			&m.StickerID, &m.StickerFileID, &stickerPayload,
			&m.ReplyToMessageID, &storyReplyPayload, &m.ForwardedFromMessageID,
			&m.ForwardedFromSenderUserID, &forwardedFromSenderName,
			&m.ForwardCount, &m.EditedAt, &m.DeletedAt,
			&moderationStatus, &moderationReasonCodes, &m.ModerationRiskScore,
			&m.ModerationTriggeredAt, &m.ModerationReviewedAt, &m.ModerationReviewedBy,
			&moderationPublicComment, &moderationInternalComment, &m.ModerationRevision,
			&m.SentAt,
		); err != nil {
			return nil, fmt.Errorf("scan message row: %w", err)
		}
		m.StickerPayload = decodeStickerPayload(stickerPayload)
		m.StoryReply = decodeStoryReplyContext(storyReplyPayload)
		if forwardedFromSenderName != nil {
			m.ForwardedFromSenderName = *forwardedFromSenderName
		}
		m.ModerationStatus = model.MessageModerationStatusVisible
		if moderationStatus != nil && strings.TrimSpace(*moderationStatus) != "" {
			m.ModerationStatus = strings.TrimSpace(*moderationStatus)
		}
		m.ModerationReasonCodes = append([]string(nil), moderationReasonCodes...)
		if moderationPublicComment != nil {
			m.ModerationPublicComment = *moderationPublicComment
		}
		if moderationInternalComment != nil {
			m.ModerationInternalComment = *moderationInternalComment
		}
		if m.ModerationRevision <= 0 {
			m.ModerationRevision = 1
		}
		msgs = append(msgs, &m)
	}
	return msgs, rows.Err()
}

func (r *PGChatRepository) GetLastMessage(ctx context.Context, conversationID uuid.UUID) (*model.Message, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+messageColumns+` FROM messages WHERE conversation_id = $1 ORDER BY sent_at DESC, id DESC LIMIT 1`,
		conversationID)
	return scanMessage(row)
}

func (r *PGChatRepository) ListLastMessagesByConversationIDs(
	ctx context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID]*model.Message, error) {
	result := make(map[uuid.UUID]*model.Message, len(conversationIDs))
	if len(conversationIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT ON (conversation_id) `+messageColumns+`
		FROM messages
		WHERE conversation_id = ANY($1::uuid[])
		ORDER BY conversation_id, sent_at DESC, id DESC
	`, conversationIDs)
	if err != nil {
		return nil, fmt.Errorf("list last messages by conversation ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		message, err := scanMessage(rows)
		if err != nil {
			return nil, err
		}
		if message != nil {
			result[message.ConversationID] = message
		}
	}
	return result, rows.Err()
}

func (r *PGChatRepository) GetMessageFileIDs(ctx context.Context, messageID uuid.UUID) ([]string, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT file_id FROM message_files WHERE message_id = $1 ORDER BY position`, messageID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *PGChatRepository) ListMessageFileIDs(
	ctx context.Context,
	messageIDs []uuid.UUID,
) (map[uuid.UUID][]string, error) {
	result := make(map[uuid.UUID][]string, len(messageIDs))
	if len(messageIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT message_id, file_id
		FROM message_files
		WHERE message_id = ANY($1::uuid[])
		ORDER BY message_id, position
	`, messageIDs)
	if err != nil {
		return nil, fmt.Errorf("list message file ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var messageID uuid.UUID
		var fileID string
		if err := rows.Scan(&messageID, &fileID); err != nil {
			return nil, fmt.Errorf("scan message file id: %w", err)
		}
		result[messageID] = append(result[messageID], fileID)
	}
	return result, rows.Err()
}

func (r *PGChatRepository) ListMessageReactionSummaries(
	ctx context.Context,
	messageIDs []uuid.UUID,
	actorUserID uuid.UUID,
) (map[uuid.UUID][]model.MessageReactionSummary, error) {
	result := make(map[uuid.UUID][]model.MessageReactionSummary, len(messageIDs))
	if len(messageIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT
			message_id,
			emoji,
			COUNT(*)::int,
			BOOL_OR(user_id = $2) AS reacted_by_me,
			ARRAY_AGG(user_id::text ORDER BY reacted_at DESC) AS user_ids,
			ARRAY_AGG(reacted_at ORDER BY reacted_at DESC) AS reacted_ats
		FROM message_reactions
		WHERE message_id = ANY($1::uuid[])
		GROUP BY message_id, emoji
		ORDER BY message_id, MAX(reacted_at) DESC, COUNT(*) DESC, emoji
	`, messageIDs, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("list message reaction summaries: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var messageID uuid.UUID
		var summary model.MessageReactionSummary
		var reactedAts []time.Time
		if err := rows.Scan(
			&messageID,
			&summary.Emoji,
			&summary.Count,
			&summary.ReactedByMe,
			&summary.UserIDs,
			&reactedAts,
		); err != nil {
			return nil, fmt.Errorf("scan message reaction summary: %w", err)
		}
		summary.Users = make([]model.MessageReactionUserSummary, 0, len(summary.UserIDs))
		for i, userID := range summary.UserIDs {
			if i >= len(reactedAts) {
				break
			}
			summary.Users = append(summary.Users, model.MessageReactionUserSummary{
				UserID:    userID,
				ReactedAt: reactedAts[i],
			})
		}
		result[messageID] = append(result[messageID], summary)
	}
	return result, rows.Err()
}

func (r *PGChatRepository) ListMessageReadReceipts(
	ctx context.Context,
	messageIDs []uuid.UUID,
) (map[uuid.UUID][]model.MessageReadReceipt, error) {
	result := make(map[uuid.UUID][]model.MessageReadReceipt, len(messageIDs))
	if len(messageIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT message_id, user_id, read_at
		FROM message_read_receipts
		WHERE message_id = ANY($1::uuid[])
		ORDER BY message_id, read_at DESC, user_id
	`, messageIDs)
	if err != nil {
		return nil, fmt.Errorf("list message read receipts: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var receipt model.MessageReadReceipt
		if err := rows.Scan(
			&receipt.MessageID,
			&receipt.UserID,
			&receipt.ReadAt,
		); err != nil {
			return nil, fmt.Errorf("scan message read receipt: %w", err)
		}
		result[receipt.MessageID] = append(result[receipt.MessageID], receipt)
	}
	return result, rows.Err()
}

func (r *PGChatRepository) ListPinnedMessagesByConversationID(
	ctx context.Context,
	conversationID uuid.UUID,
) ([]*model.ConversationPin, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			cp.id,
			cp.conversation_id,
			cp.message_id,
			cp.pinned_by_user_id,
			cp.pinned_at,
			`+messageSelectColumns+`
		FROM conversation_pins cp
		INNER JOIN messages m
			ON m.id = cp.message_id
		   AND m.conversation_id = cp.conversation_id
		WHERE cp.conversation_id = $1
		  AND m.deleted_at IS NULL
		  AND m.moderation_status <> 'HIDDEN_BY_MODERATION'
		ORDER BY cp.pinned_at DESC, cp.id DESC
	`, conversationID)
	if err != nil {
		return nil, fmt.Errorf("list pinned messages: %w", err)
	}
	defer rows.Close()

	var pins []*model.ConversationPin
	for rows.Next() {
		pin := &model.ConversationPin{Message: &model.Message{}}
		var stickerPayload []byte
		var storyReplyPayload []byte
		var forwardedFromSenderName *string
		var moderationStatus *string
		var moderationReasonCodes []string
		var moderationPublicComment *string
		var moderationInternalComment *string
		if err := rows.Scan(
			&pin.ID,
			&pin.ConversationID,
			&pin.MessageID,
			&pin.PinnedByUserID,
			&pin.PinnedAt,
			&pin.Message.ID,
			&pin.Message.ConversationID,
			&pin.Message.SenderUserID,
			&pin.Message.ClientMessageID,
			&pin.Message.Type,
			&pin.Message.Content,
			&pin.Message.StickerID,
			&pin.Message.StickerFileID,
			&stickerPayload,
			&pin.Message.ReplyToMessageID,
			&storyReplyPayload,
			&pin.Message.ForwardedFromMessageID,
			&pin.Message.ForwardedFromSenderUserID,
			&forwardedFromSenderName,
			&pin.Message.ForwardCount,
			&pin.Message.EditedAt,
			&pin.Message.DeletedAt,
			&moderationStatus,
			&moderationReasonCodes,
			&pin.Message.ModerationRiskScore,
			&pin.Message.ModerationTriggeredAt,
			&pin.Message.ModerationReviewedAt,
			&pin.Message.ModerationReviewedBy,
			&moderationPublicComment,
			&moderationInternalComment,
			&pin.Message.ModerationRevision,
			&pin.Message.SentAt,
		); err != nil {
			return nil, fmt.Errorf("scan pinned message: %w", err)
		}
		pin.Message.StickerPayload = decodeStickerPayload(stickerPayload)
		pin.Message.StoryReply = decodeStoryReplyContext(storyReplyPayload)
		if forwardedFromSenderName != nil {
			pin.Message.ForwardedFromSenderName = *forwardedFromSenderName
		}
		pin.Message.ModerationStatus = model.MessageModerationStatusVisible
		if moderationStatus != nil && strings.TrimSpace(*moderationStatus) != "" {
			pin.Message.ModerationStatus = strings.TrimSpace(*moderationStatus)
		}
		pin.Message.ModerationReasonCodes = append([]string(nil), moderationReasonCodes...)
		if moderationPublicComment != nil {
			pin.Message.ModerationPublicComment = *moderationPublicComment
		}
		if moderationInternalComment != nil {
			pin.Message.ModerationInternalComment = *moderationInternalComment
		}
		if pin.Message.ModerationRevision <= 0 {
			pin.Message.ModerationRevision = 1
		}
		pins = append(pins, pin)
	}
	return pins, rows.Err()
}

func (r *PGChatRepository) ClaimDueChatNotificationOutbox(
	ctx context.Context,
	now time.Time,
	limit int,
) ([]*model.ChatNotificationOutbox, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM chat_notification_outbox
			WHERE processed_at IS NULL
			  AND failed_at IS NULL
			  AND next_attempt_at <= $1
			  AND (locked_at IS NULL OR locked_at < $1 - INTERVAL '2 minutes')
			ORDER BY next_attempt_at ASC, created_at ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE chat_notification_outbox outbox
		SET locked_at = $1,
		    attempts = attempts + 1,
		    updated_at = $1
		FROM due
		WHERE outbox.id = due.id
		RETURNING `+chatNotificationOutboxColumns+`
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("claim chat notification outbox: %w", err)
	}
	defer rows.Close()

	items := make([]*model.ChatNotificationOutbox, 0, limit)
	for rows.Next() {
		item, err := scanChatNotificationOutbox(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGChatRepository) MarkChatNotificationOutboxSent(
	ctx context.Context,
	outboxID uuid.UUID,
	sentAt time.Time,
) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE chat_notification_outbox
		SET processed_at = $2,
		    locked_at = NULL,
		    updated_at = $2
		WHERE id = $1
	`, outboxID, sentAt)
	return err
}

func (r *PGChatRepository) RetryChatNotificationOutbox(
	ctx context.Context,
	outboxID uuid.UUID,
	nextAttemptAt time.Time,
	lastError string,
) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE chat_notification_outbox
		SET next_attempt_at = $2,
		    locked_at = NULL,
		    last_error = NULLIF($3, ''),
		    updated_at = now()
		WHERE id = $1
		  AND processed_at IS NULL
		  AND failed_at IS NULL
	`, outboxID, nextAttemptAt, strings.TrimSpace(lastError))
	return err
}

func (r *PGChatRepository) FailChatNotificationOutbox(
	ctx context.Context,
	outboxID uuid.UUID,
	failedAt time.Time,
	lastError string,
) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE chat_notification_outbox
		SET failed_at = $2,
		    locked_at = NULL,
		    last_error = NULLIF($3, ''),
		    updated_at = $2
		WHERE id = $1
		  AND processed_at IS NULL
	`, outboxID, failedAt, strings.TrimSpace(lastError))
	return err
}

func (r *PGChatRepository) ListFlaggedMessagesForModeration(
	ctx context.Context,
	filter port.ChatModerationFilter,
) ([]*model.ChatMessageModerationItem, error) {
	if filter.Limit <= 0 || filter.Limit > 100 {
		filter.Limit = 50
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	rows, err := r.pool.Query(ctx, `
		SELECT
			`+messageSelectColumns+`,
			c.type,
			c.title,
			c.activity_id,
			c.excursion_schedule_slot_id
		FROM messages m
		INNER JOIN conversations c ON c.id = m.conversation_id
		WHERE m.moderation_status = 'FLAGGED'
		  AND m.deleted_at IS NULL
		ORDER BY m.moderation_risk_score DESC, m.sent_at DESC, m.id DESC
		LIMIT $1 OFFSET $2
	`, filter.Limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("list flagged chat messages: %w", err)
	}
	defer rows.Close()
	items := make([]*model.ChatMessageModerationItem, 0, filter.Limit)
	for rows.Next() {
		item, err := scanMessageWithTrailingConversation(rows)
		if err != nil {
			return nil, err
		}
		item.FileIDs, _ = r.GetMessageFileIDs(ctx, item.ID)
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGChatRepository) GetMessageForModeration(
	ctx context.Context,
	messageID uuid.UUID,
	before int,
	after int,
) (*model.ChatMessageModerationItem, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT
			`+messageSelectColumns+`,
			c.type,
			c.title,
			c.activity_id,
			c.excursion_schedule_slot_id
		FROM messages m
		INNER JOIN conversations c ON c.id = m.conversation_id
		WHERE m.id = $1
	`, messageID)
	item, err := scanMessageWithTrailingConversation(row)
	if err != nil {
		return nil, err
	}
	if item == nil {
		return nil, nil
	}
	item.FileIDs, _ = r.GetMessageFileIDs(ctx, item.ID)
	item.Participants, err = r.listModerationParticipants(ctx, item.ConversationID)
	if err != nil {
		return nil, err
	}
	item.ContextBefore, err = r.listModerationContextMessages(ctx, item.ConversationID, item.SentAt, item.ID, before, false)
	if err != nil {
		return nil, err
	}
	item.ContextAfter, err = r.listModerationContextMessages(ctx, item.ConversationID, item.SentAt, item.ID, after, true)
	if err != nil {
		return nil, err
	}
	return item, nil
}

func (r *PGChatRepository) UpdateMessageModeration(
	ctx context.Context,
	messageID uuid.UUID,
	status string,
	reasonCodes []string,
	publicComment string,
	internalComment string,
	moderatedBy uuid.UUID,
	now time.Time,
) (*model.Message, error) {
	row := r.pool.QueryRow(ctx, `
		UPDATE messages
		SET moderation_status = $2,
		    moderation_reason_codes = CASE
		        WHEN cardinality($3::text[]) > 0 THEN $3::text[]
		        ELSE moderation_reason_codes
		    END,
		    moderation_reviewed_at = $4,
		    moderation_reviewed_by = $5,
		    moderation_public_comment = NULLIF($6, ''),
		    moderation_internal_comment = NULLIF($7, ''),
		    moderation_revision = moderation_revision + 1
		WHERE id = $1
		RETURNING `+messageColumns+`
	`, messageID, status, reasonCodes, now, moderatedBy, strings.TrimSpace(publicComment), strings.TrimSpace(internalComment))
	return scanMessage(row)
}

func scanMessageWithTrailingConversation(row pgx.Row) (*model.ChatMessageModerationItem, error) {
	var message model.Message
	var stickerPayload []byte
	var storyReplyPayload []byte
	var forwardedFromSenderName *string
	var moderationStatus *string
	var moderationReasonCodes []string
	var moderationPublicComment *string
	var moderationInternalComment *string
	var conversationTitle *string
	item := &model.ChatMessageModerationItem{}
	err := row.Scan(
		&message.ID, &message.ConversationID, &message.SenderUserID, &message.ClientMessageID,
		&message.Type, &message.Content,
		&message.StickerID, &message.StickerFileID, &stickerPayload,
		&message.ReplyToMessageID, &storyReplyPayload, &message.ForwardedFromMessageID,
		&message.ForwardedFromSenderUserID, &forwardedFromSenderName,
		&message.ForwardCount, &message.EditedAt, &message.DeletedAt,
		&moderationStatus, &moderationReasonCodes, &message.ModerationRiskScore,
		&message.ModerationTriggeredAt, &message.ModerationReviewedAt, &message.ModerationReviewedBy,
		&moderationPublicComment, &moderationInternalComment, &message.ModerationRevision,
		&message.SentAt,
		&item.ConversationType, &conversationTitle, &item.ActivityID, &item.ExcursionScheduleSlotID,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan chat message moderation row: %w", err)
	}
	if forwardedFromSenderName != nil {
		message.ForwardedFromSenderName = *forwardedFromSenderName
	}
	message.StickerPayload = decodeStickerPayload(stickerPayload)
	message.StoryReply = decodeStoryReplyContext(storyReplyPayload)
	message.ModerationStatus = model.MessageModerationStatusVisible
	if moderationStatus != nil && strings.TrimSpace(*moderationStatus) != "" {
		message.ModerationStatus = strings.TrimSpace(*moderationStatus)
	}
	message.ModerationReasonCodes = append([]string(nil), moderationReasonCodes...)
	if moderationPublicComment != nil {
		message.ModerationPublicComment = *moderationPublicComment
	}
	if moderationInternalComment != nil {
		message.ModerationInternalComment = *moderationInternalComment
	}
	if message.ModerationRevision <= 0 {
		message.ModerationRevision = 1
	}
	item.ID = message.ID
	item.ConversationID = message.ConversationID
	if conversationTitle != nil {
		item.ConversationTitle = *conversationTitle
	}
	item.SenderUserID = message.SenderUserID
	item.SenderDisplayName = message.SenderDisplayName
	item.Type = message.Type
	item.Content = message.Content
	item.ModerationStatus = message.ModerationStatus
	item.ModerationRiskScore = message.ModerationRiskScore
	item.ModerationReasonCodes = message.ModerationReasonCodes
	item.ModerationTriggeredAt = message.ModerationTriggeredAt
	item.ModerationReviewedAt = message.ModerationReviewedAt
	item.Revision = message.ModerationRevision
	item.EditedAt = message.EditedAt
	item.DeletedAt = message.DeletedAt
	item.SentAt = message.SentAt
	item.CreatedAt = message.SentAt
	item.UpdatedAt = message.SentAt
	if item.ModerationReviewedAt != nil {
		item.UpdatedAt = *item.ModerationReviewedAt
	} else if item.EditedAt != nil {
		item.UpdatedAt = *item.EditedAt
	}
	return item, nil
}

func (r *PGChatRepository) listModerationParticipants(
	ctx context.Context,
	conversationID uuid.UUID,
) ([]model.ChatParticipantModerationItem, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT user_id, role
		FROM conversation_participants
		WHERE conversation_id = $1
		  AND left_at IS NULL
		ORDER BY role DESC, joined_at ASC
		LIMIT 20
	`, conversationID)
	if err != nil {
		return nil, fmt.Errorf("list chat moderation participants: %w", err)
	}
	defer rows.Close()
	var items []model.ChatParticipantModerationItem
	for rows.Next() {
		var item model.ChatParticipantModerationItem
		if err := rows.Scan(&item.UserID, &item.Role); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGChatRepository) listModerationContextMessages(
	ctx context.Context,
	conversationID uuid.UUID,
	sentAt time.Time,
	messageID uuid.UUID,
	limit int,
	after bool,
) ([]model.ChatMessageContextItem, error) {
	if limit <= 0 {
		return nil, nil
	}
	operator := "<"
	order := "DESC"
	if after {
		operator = ">"
		order = "ASC"
	}
	rows, err := r.pool.Query(ctx, fmt.Sprintf(`
		SELECT `+messageColumns+`
		FROM messages
		WHERE conversation_id = $1
		  AND (sent_at, id) %s ($2, $3)
		ORDER BY sent_at %s, id %s
		LIMIT $4
	`, operator, order, order), conversationID, sentAt, messageID, limit)
	if err != nil {
		return nil, fmt.Errorf("list chat moderation context: %w", err)
	}
	defer rows.Close()
	var items []model.ChatMessageContextItem
	for rows.Next() {
		message, err := scanMessage(rows)
		if err != nil {
			return nil, err
		}
		fileIDs, _ := r.GetMessageFileIDs(ctx, message.ID)
		items = append(items, model.ChatMessageContextItem{
			ID:                message.ID,
			SenderUserID:      message.SenderUserID,
			SenderDisplayName: message.SenderDisplayName,
			Type:              message.Type,
			Content:           message.Content,
			FileIDs:           fileIDs,
			EditedAt:          message.EditedAt,
			DeletedAt:         message.DeletedAt,
			SentAt:            message.SentAt,
		})
	}
	if !after {
		for left, right := 0, len(items)-1; left < right; left, right = left+1, right-1 {
			items[left], items[right] = items[right], items[left]
		}
	}
	return items, rows.Err()
}

func (r *PGChatRepository) GetParticipant(ctx context.Context, conversationID, userID uuid.UUID) (*model.Participant, error) {
	var p model.Participant
	err := r.pool.QueryRow(ctx, `
		SELECT id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at
		FROM conversation_participants
		WHERE conversation_id = $1 AND user_id = $2
		ORDER BY joined_at DESC LIMIT 1
	`, conversationID, userID).Scan(
		&p.ID, &p.ConversationID, &p.UserID, &p.Role, &p.LastReadMsgID,
		&p.MutedUntil, &p.JoinedAt, &p.LeftAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get participant: %w", err)
	}
	return &p, nil
}

func (r *PGChatRepository) ListParticipantsByConversationUserIDs(
	ctx context.Context,
	conversationIDs []uuid.UUID,
	userID uuid.UUID,
) (map[uuid.UUID]*model.Participant, error) {
	result := make(map[uuid.UUID]*model.Participant, len(conversationIDs))
	if len(conversationIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT ON (conversation_id)
		       id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at
		FROM conversation_participants
		WHERE conversation_id = ANY($1::uuid[])
		  AND user_id = $2
		  AND left_at IS NULL
		ORDER BY conversation_id, joined_at DESC
	`, conversationIDs, userID)
	if err != nil {
		return nil, fmt.Errorf("list participants by conversation user ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		participant, err := scanParticipant(rows)
		if err != nil {
			return nil, err
		}
		if participant != nil {
			result[participant.ConversationID] = participant
		}
	}
	return result, rows.Err()
}

func (r *PGChatRepository) ListParticipantsByConversationID(ctx context.Context, conversationID uuid.UUID) ([]*model.Participant, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at
		FROM conversation_participants
		WHERE conversation_id = $1 AND left_at IS NULL
		ORDER BY joined_at
	`, conversationID)
	if err != nil {
		return nil, fmt.Errorf("list participants: %w", err)
	}
	defer rows.Close()

	var participants []*model.Participant
	for rows.Next() {
		participant, err := scanParticipant(rows)
		if err != nil {
			return nil, err
		}
		participants = append(participants, participant)
	}
	return participants, rows.Err()
}

func (r *PGChatRepository) ListParticipantsByConversationIDs(
	ctx context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID][]*model.Participant, error) {
	result := make(map[uuid.UUID][]*model.Participant, len(conversationIDs))
	if len(conversationIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at
		FROM conversation_participants
		WHERE conversation_id = ANY($1::uuid[])
		  AND left_at IS NULL
		ORDER BY conversation_id, joined_at
	`, conversationIDs)
	if err != nil {
		return nil, fmt.Errorf("list participants by conversation ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		participant, err := scanParticipant(rows)
		if err != nil {
			return nil, err
		}
		if participant != nil {
			result[participant.ConversationID] = append(result[participant.ConversationID], participant)
		}
	}
	return result, rows.Err()
}

func (r *PGChatRepository) CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL`,
		conversationID).Scan(&count)
	return count, err
}

func (r *PGChatRepository) CountActiveParticipantsByConversationIDs(
	ctx context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID]int, error) {
	result := make(map[uuid.UUID]int, len(conversationIDs))
	if len(conversationIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT conversation_id, COUNT(*)::int
		FROM conversation_participants
		WHERE conversation_id = ANY($1::uuid[])
		  AND left_at IS NULL
		GROUP BY conversation_id
	`, conversationIDs)
	if err != nil {
		return nil, fmt.Errorf("count active participants by conversation ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var conversationID uuid.UUID
		var count int
		if err := rows.Scan(&conversationID, &count); err != nil {
			return nil, fmt.Errorf("scan participant count: %w", err)
		}
		result[conversationID] = count
	}
	return result, rows.Err()
}

func (r *PGChatRepository) GetUnreadCount(ctx context.Context, conversationID, userID uuid.UUID) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM messages m
		JOIN conversation_participants cp
		  ON cp.conversation_id = m.conversation_id
		 AND cp.user_id = $2
		 AND cp.left_at IS NULL
		LEFT JOIN messages last_read
		  ON last_read.id = cp.last_read_msg_id
		 AND last_read.conversation_id = m.conversation_id
		WHERE m.conversation_id = $1
		  AND m.sender_user_id != $2
		  AND m.type != 'system'
		  AND m.deleted_at IS NULL
		  AND (
		    cp.last_read_msg_id IS NULL
		    OR last_read.id IS NULL
		    OR (m.sent_at, m.id) > (last_read.sent_at, last_read.id)
		  )
	`, conversationID, userID).Scan(&count)
	return count, err
}

func (r *PGChatRepository) ListUnreadCountsByConversationIDs(
	ctx context.Context,
	conversationIDs []uuid.UUID,
	userID uuid.UUID,
) (map[uuid.UUID]int, error) {
	result := make(map[uuid.UUID]int, len(conversationIDs))
	if len(conversationIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT m.conversation_id, COUNT(*)::int
		FROM messages m
		JOIN conversation_participants cp
		  ON cp.conversation_id = m.conversation_id
		 AND cp.user_id = $2
		 AND cp.left_at IS NULL
		LEFT JOIN messages last_read
		  ON last_read.id = cp.last_read_msg_id
		 AND last_read.conversation_id = m.conversation_id
		WHERE m.conversation_id = ANY($1::uuid[])
		  AND m.sender_user_id != $2
		  AND m.type != 'system'
		  AND m.deleted_at IS NULL
		  AND (
		    cp.last_read_msg_id IS NULL
		    OR last_read.id IS NULL
		    OR (m.sent_at, m.id) > (last_read.sent_at, last_read.id)
		  )
		GROUP BY m.conversation_id
	`, conversationIDs, userID)
	if err != nil {
		return nil, fmt.Errorf("list unread counts by conversation ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var conversationID uuid.UUID
		var count int
		if err := rows.Scan(&conversationID, &count); err != nil {
			return nil, fmt.Errorf("scan unread count: %w", err)
		}
		result[conversationID] = count
	}
	return result, rows.Err()
}

func scanParticipant(row pgx.Row) (*model.Participant, error) {
	var p model.Participant
	if err := row.Scan(
		&p.ID, &p.ConversationID, &p.UserID, &p.Role, &p.LastReadMsgID,
		&p.MutedUntil, &p.JoinedAt, &p.LeftAt,
	); err != nil {
		return nil, fmt.Errorf("scan participant: %w", err)
	}
	return &p, nil
}

func (r *PGChatRepository) IsUserBlocked(ctx context.Context, blockerUserID, blockedUserID uuid.UUID) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1
			FROM chat_user_blocks
			WHERE blocker_user_id = $1 AND blocked_user_id = $2
		)
	`, blockerUserID, blockedUserID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check user block: %w", err)
	}
	return exists, nil
}

func (r *PGChatRepository) ListUserIDsBlockingUser(
	ctx context.Context,
	blockedUserID uuid.UUID,
	candidateBlockerUserIDs []uuid.UUID,
) (map[uuid.UUID]bool, error) {
	result := make(map[uuid.UUID]bool)
	if blockedUserID == uuid.Nil || len(candidateBlockerUserIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT blocker_user_id
		FROM chat_user_blocks
		WHERE blocked_user_id = $1
		  AND blocker_user_id = ANY($2::uuid[])
	`, blockedUserID, candidateBlockerUserIDs)
	if err != nil {
		return nil, fmt.Errorf("list users blocking user: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var blockerUserID uuid.UUID
		if err := rows.Scan(&blockerUserID); err != nil {
			return nil, fmt.Errorf("scan user block: %w", err)
		}
		result[blockerUserID] = true
	}
	return result, rows.Err()
}

func (r *PGChatRepository) UpsertUserBlock(ctx context.Context, block *model.UserBlock) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO chat_user_blocks (blocker_user_id, blocked_user_id, created_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (blocker_user_id, blocked_user_id) DO NOTHING
	`, block.BlockerUserID, block.BlockedUserID, block.CreatedAt)
	if err != nil {
		return fmt.Errorf("upsert user block: %w", err)
	}
	return nil
}

func (r *PGChatRepository) DeleteUserBlock(ctx context.Context, blockerUserID, blockedUserID uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `
		DELETE FROM chat_user_blocks
		WHERE blocker_user_id = $1 AND blocked_user_id = $2
	`, blockerUserID, blockedUserID)
	if err != nil {
		return fmt.Errorf("delete user block: %w", err)
	}
	return nil
}

func (tx *pgChatTxRepository) CreateConversation(ctx context.Context, conv *model.Conversation) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO conversations (id, type, title, avatar_file_id, activity_id, excursion_schedule_slot_id, pinned_message_id, messaging_available_until, created_at, last_activity_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`, conv.ID, conv.Type, conv.Title, conv.AvatarFileID, conv.ActivityID,
		conv.ExcursionScheduleSlotID, conv.PinnedMessageID, conv.MessagingAvailableUntil, conv.CreatedAt, conv.LastActivityAt)
	return err
}

func (tx *pgChatTxRepository) UpdateConversation(ctx context.Context, conv *model.Conversation) error {
	_, err := tx.tx.Exec(ctx, `
		UPDATE conversations
		SET title = $2, avatar_file_id = $3, pinned_message_id = $4, messaging_available_until = $5, last_activity_at = $6
		WHERE id = $1
	`, conv.ID, conv.Title, conv.AvatarFileID, conv.PinnedMessageID, conv.MessagingAvailableUntil, conv.LastActivityAt)
	return err
}

func (tx *pgChatTxRepository) GetConversationByIDForUpdate(ctx context.Context, conversationID uuid.UUID) (*model.Conversation, error) {
	row := tx.tx.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE id = $1 FOR UPDATE`, conversationID)
	return scanConversation(row)
}

func (tx *pgChatTxRepository) GetConversationByActivityIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Conversation, error) {
	row := tx.tx.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE activity_id = $1 FOR UPDATE`, activityID)
	return scanConversation(row)
}

func (tx *pgChatTxRepository) GetConversationByExcursionScheduleSlotIDForUpdate(ctx context.Context, slotID uuid.UUID) (*model.Conversation, error) {
	row := tx.tx.QueryRow(ctx,
		`SELECT `+conversationColumns+` FROM conversations WHERE excursion_schedule_slot_id = $1 FOR UPDATE`, slotID)
	return scanConversation(row)
}

func (tx *pgChatTxRepository) GetParticipantForUpdate(ctx context.Context, conversationID, userID uuid.UUID) (*model.Participant, error) {
	var p model.Participant
	err := tx.tx.QueryRow(ctx, `
		SELECT id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at
		FROM conversation_participants
		WHERE conversation_id = $1 AND user_id = $2
		ORDER BY joined_at DESC LIMIT 1
		FOR UPDATE
	`, conversationID, userID).Scan(
		&p.ID, &p.ConversationID, &p.UserID, &p.Role, &p.LastReadMsgID,
		&p.MutedUntil, &p.JoinedAt, &p.LeftAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get participant for update: %w", err)
	}
	return &p, nil
}

func (tx *pgChatTxRepository) CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error) {
	var count int
	err := tx.tx.QueryRow(ctx,
		`SELECT COUNT(*) FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL`,
		conversationID).Scan(&count)
	return count, err
}

func (tx *pgChatTxRepository) CreateParticipant(ctx context.Context, p *model.Participant) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO conversation_participants (id, conversation_id, user_id, role, last_read_msg_id, muted_until, joined_at, left_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`, p.ID, p.ConversationID, p.UserID, p.Role, p.LastReadMsgID, p.MutedUntil, p.JoinedAt, p.LeftAt)
	return err
}

func (tx *pgChatTxRepository) UpdateParticipant(ctx context.Context, p *model.Participant) error {
	_, err := tx.tx.Exec(ctx, `
		UPDATE conversation_participants
		SET role = $2, last_read_msg_id = $3, muted_until = $4, left_at = $5
		WHERE id = $1
	`, p.ID, p.Role, p.LastReadMsgID, p.MutedUntil, p.LeftAt)
	return err
}

func (tx *pgChatTxRepository) CreateMessage(ctx context.Context, msg *model.Message) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO messages (
			id, conversation_id, sender_user_id, client_message_id, type, content, sticker_id,
			sticker_file_id, sticker_payload, reply_to_message_id, story_reply,
			forwarded_from_message_id, forwarded_from_sender_user_id,
			forwarded_from_sender_name, forward_count, edited_at, deleted_at,
			moderation_status, moderation_reason_codes, moderation_risk_score,
			moderation_triggered_at, moderation_reviewed_at, moderation_reviewed_by,
			moderation_public_comment, moderation_internal_comment, moderation_revision,
			sent_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
		        $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27)
	`, msg.ID, msg.ConversationID, msg.SenderUserID, msg.ClientMessageID,
		msg.Type, msg.Content, msg.StickerID, msg.StickerFileID, stickerPayloadJSON(msg.StickerPayload),
		msg.ReplyToMessageID, storyReplyContextJSON(msg.StoryReply), msg.ForwardedFromMessageID,
		msg.ForwardedFromSenderUserID, nullableString(msg.ForwardedFromSenderName),
		msg.ForwardCount, msg.EditedAt, msg.DeletedAt,
		defaultMessageModerationStatus(msg.ModerationStatus),
		defaultMessageModerationReasonCodes(msg.ModerationReasonCodes),
		msg.ModerationRiskScore, msg.ModerationTriggeredAt, msg.ModerationReviewedAt,
		msg.ModerationReviewedBy, nullableString(msg.ModerationPublicComment),
		nullableString(msg.ModerationInternalComment), defaultMessageModerationRevision(msg.ModerationRevision),
		msg.SentAt)
	if isDuplicateClientMessageID(err) {
		return port.ErrDuplicateClientMessageID
	}
	return err
}

func (tx *pgChatTxRepository) UpdateMessage(ctx context.Context, msg *model.Message) error {
	_, err := tx.tx.Exec(ctx, `
		UPDATE messages
		SET content = $2, edited_at = $3, deleted_at = $4, forward_count = $5
		WHERE id = $1
	`, msg.ID, msg.Content, msg.EditedAt, msg.DeletedAt, msg.ForwardCount)
	return err
}

func (tx *pgChatTxRepository) DeleteMessage(ctx context.Context, messageID uuid.UUID) error {
	_, err := tx.tx.Exec(ctx, `DELETE FROM messages WHERE id = $1`, messageID)
	return err
}

func (tx *pgChatTxRepository) GetMessageReactionForUpdate(
	ctx context.Context,
	messageID uuid.UUID,
	userID uuid.UUID,
) (*model.MessageReaction, error) {
	row := tx.tx.QueryRow(ctx, `
		SELECT message_id, user_id, emoji, reacted_at
		FROM message_reactions
		WHERE message_id = $1 AND user_id = $2
		FOR UPDATE
	`, messageID, userID)
	return scanMessageReaction(row)
}

func (tx *pgChatTxRepository) SetMessageReaction(
	ctx context.Context,
	reaction *model.MessageReaction,
) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO message_reactions (message_id, user_id, emoji, reacted_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (message_id, user_id)
		DO UPDATE SET emoji = EXCLUDED.emoji, reacted_at = EXCLUDED.reacted_at
	`, reaction.MessageID, reaction.UserID, reaction.Emoji, reaction.ReactedAt)
	return err
}

func (tx *pgChatTxRepository) DeleteMessageReaction(
	ctx context.Context,
	messageID uuid.UUID,
	userID uuid.UUID,
) error {
	_, err := tx.tx.Exec(ctx, `
		DELETE FROM message_reactions
		WHERE message_id = $1 AND user_id = $2
	`, messageID, userID)
	return err
}

func (tx *pgChatTxRepository) CreateConversationPin(
	ctx context.Context,
	pin *model.ConversationPin,
) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO conversation_pins (id, conversation_id, message_id, pinned_by_user_id, pinned_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (conversation_id, message_id) DO NOTHING
	`, pin.ID, pin.ConversationID, pin.MessageID, pin.PinnedByUserID, pin.PinnedAt)
	return err
}

func (tx *pgChatTxRepository) DeleteConversationPin(
	ctx context.Context,
	conversationID, messageID uuid.UUID,
) (bool, error) {
	tag, err := tx.tx.Exec(ctx, `
		DELETE FROM conversation_pins
		WHERE conversation_id = $1
		  AND message_id = $2
	`, conversationID, messageID)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() > 0, nil
}

func (tx *pgChatTxRepository) DeleteConversationPinsByMessageID(
	ctx context.Context,
	messageID uuid.UUID,
) (int64, error) {
	tag, err := tx.tx.Exec(ctx, `DELETE FROM conversation_pins WHERE message_id = $1`, messageID)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

func (tx *pgChatTxRepository) CreateChatNotificationOutbox(
	ctx context.Context,
	item *model.ChatNotificationOutbox,
) error {
	if item == nil {
		return nil
	}
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO chat_notification_outbox (
			id, event_type, conversation_id, message_id, actor_user_id,
			reaction_emoji, attempts, next_attempt_at, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, NULLIF($6, ''), $7, $8, $9, $10)
		ON CONFLICT DO NOTHING
	`, item.ID, item.EventType, item.ConversationID, item.MessageID, item.ActorUserID,
		strings.TrimSpace(item.ReactionEmoji), item.Attempts, item.NextAttemptAt, item.CreatedAt, item.UpdatedAt)
	return err
}

func (tx *pgChatTxRepository) GetLastMessage(ctx context.Context, conversationID uuid.UUID) (*model.Message, error) {
	row := tx.tx.QueryRow(ctx,
		`SELECT `+messageColumns+` FROM messages WHERE conversation_id = $1 ORDER BY sent_at DESC, id DESC LIMIT 1`,
		conversationID)
	return scanMessage(row)
}

func (tx *pgChatTxRepository) GetPreviousMessage(
	ctx context.Context,
	conversationID uuid.UUID,
	sentAt time.Time,
	messageID uuid.UUID,
) (*model.Message, error) {
	row := tx.tx.QueryRow(ctx, `
		SELECT `+messageColumns+`
		FROM messages
		WHERE conversation_id = $1
		  AND (sent_at, id) < ($2, $3)
		ORDER BY sent_at DESC, id DESC
		LIMIT 1
	`, conversationID, sentAt, messageID)
	return scanMessage(row)
}

func (tx *pgChatTxRepository) HasReadByOtherParticipant(
	ctx context.Context,
	conversationID uuid.UUID,
	messageID uuid.UUID,
	actorUserID uuid.UUID,
) (bool, error) {
	var hasRead bool
	err := tx.tx.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM conversation_participants cp
			JOIN messages target
			  ON target.id = $2
			 AND target.conversation_id = cp.conversation_id
			LEFT JOIN messages last_read
			  ON last_read.id = cp.last_read_msg_id
			 AND last_read.conversation_id = cp.conversation_id
			WHERE cp.conversation_id = $1
			  AND cp.left_at IS NULL
			  AND cp.user_id <> $3
			  AND cp.last_read_msg_id IS NOT NULL
			  AND last_read.id IS NOT NULL
			  AND (last_read.sent_at, last_read.id) >= (target.sent_at, target.id)
		)
	`, conversationID, messageID, actorUserID).Scan(&hasRead)
	return hasRead, err
}

func (tx *pgChatTxRepository) ReplaceLastReadMessageID(
	ctx context.Context,
	conversationID uuid.UUID,
	fromMessageID uuid.UUID,
	toMessageID *uuid.UUID,
) error {
	_, err := tx.tx.Exec(ctx, `
		UPDATE conversation_participants
		SET last_read_msg_id = $3
		WHERE conversation_id = $1
		  AND last_read_msg_id = $2
	`, conversationID, fromMessageID, toMessageID)
	return err
}

func (tx *pgChatTxRepository) CreateReadReceiptsUpToMessage(
	ctx context.Context,
	conversationID uuid.UUID,
	readerUserID uuid.UUID,
	lastReadMessageID uuid.UUID,
	readAt time.Time,
) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO message_read_receipts (message_id, user_id, read_at)
		SELECT m.id, $2, $4
		FROM messages target
		JOIN messages m
		  ON m.conversation_id = target.conversation_id
		 AND (m.sent_at, m.id) <= (target.sent_at, target.id)
		WHERE target.conversation_id = $1
		  AND target.id = $3
		  AND m.sender_user_id <> $2
		  AND m.type <> 'system'
		  AND m.deleted_at IS NULL
		ON CONFLICT (message_id, user_id) DO NOTHING
	`, conversationID, readerUserID, lastReadMessageID, readAt)
	return err
}

func (tx *pgChatTxRepository) CreateMessageFiles(ctx context.Context, messageID uuid.UUID, fileIDs []string) error {
	for i, fileID := range fileIDs {
		_, err := tx.tx.Exec(ctx,
			`INSERT INTO message_files (message_id, file_id, position) VALUES ($1, $2, $3)`,
			messageID, fileID, i)
		if err != nil {
			return err
		}
	}
	return nil
}
