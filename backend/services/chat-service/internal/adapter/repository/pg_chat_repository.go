package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
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

const conversationColumns = `id, type, title, avatar_file_id, activity_id, pinned_message_id, messaging_available_until, created_at, last_activity_at`
const conversationSelectColumns = `c.id, c.type, c.title, c.avatar_file_id, c.activity_id, c.pinned_message_id, c.messaging_available_until, c.created_at, c.last_activity_at`
const messageColumns = `id, conversation_id, sender_user_id, type, content, sticker_id, sticker_file_id, reply_to_message_id, edited_at, deleted_at, sent_at`
const messageSelectColumns = `m.id, m.conversation_id, m.sender_user_id, m.type, m.content, m.sticker_id, m.sticker_file_id, m.reply_to_message_id, m.edited_at, m.deleted_at, m.sent_at`

func scanConversation(row pgx.Row) (*model.Conversation, error) {
	var c model.Conversation
	err := row.Scan(
		&c.ID, &c.Type, &c.Title, &c.AvatarFileID, &c.ActivityID,
		&c.PinnedMessageID, &c.MessagingAvailableUntil, &c.CreatedAt, &c.LastActivityAt,
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
			&c.PinnedMessageID, &c.MessagingAvailableUntil, &c.CreatedAt, &c.LastActivityAt,
		); err != nil {
			return nil, fmt.Errorf("scan conversation row: %w", err)
		}
		convs = append(convs, &c)
	}
	return convs, rows.Err()
}

func scanMessage(row pgx.Row) (*model.Message, error) {
	var m model.Message
	err := row.Scan(
		&m.ID, &m.ConversationID, &m.SenderUserID, &m.Type, &m.Content,
		&m.StickerID, &m.StickerFileID,
		&m.ReplyToMessageID, &m.EditedAt, &m.DeletedAt, &m.SentAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("scan message: %w", err)
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

func (r *PGChatRepository) GetMessageByID(ctx context.Context, messageID uuid.UUID) (*model.Message, error) {
	row := r.pool.QueryRow(ctx,
		`SELECT `+messageColumns+` FROM messages WHERE id = $1`, messageID)
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
		if err := rows.Scan(
			&m.ID, &m.ConversationID, &m.SenderUserID, &m.Type, &m.Content,
			&m.StickerID, &m.StickerFileID,
			&m.ReplyToMessageID, &m.EditedAt, &m.DeletedAt, &m.SentAt,
		); err != nil {
			return nil, fmt.Errorf("scan message row: %w", err)
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
			BOOL_OR(user_id = $2) AS reacted_by_me
		FROM message_reactions
		WHERE message_id = ANY($1::uuid[])
		GROUP BY message_id, emoji
		ORDER BY message_id, COUNT(*) DESC, MAX(reacted_at) DESC, emoji
	`, messageIDs, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("list message reaction summaries: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var messageID uuid.UUID
		var summary model.MessageReactionSummary
		if err := rows.Scan(
			&messageID,
			&summary.Emoji,
			&summary.Count,
			&summary.ReactedByMe,
		); err != nil {
			return nil, fmt.Errorf("scan message reaction summary: %w", err)
		}
		result[messageID] = append(result[messageID], summary)
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
		ORDER BY cp.pinned_at DESC, cp.id DESC
	`, conversationID)
	if err != nil {
		return nil, fmt.Errorf("list pinned messages: %w", err)
	}
	defer rows.Close()

	var pins []*model.ConversationPin
	for rows.Next() {
		pin := &model.ConversationPin{Message: &model.Message{}}
		if err := rows.Scan(
			&pin.ID,
			&pin.ConversationID,
			&pin.MessageID,
			&pin.PinnedByUserID,
			&pin.PinnedAt,
			&pin.Message.ID,
			&pin.Message.ConversationID,
			&pin.Message.SenderUserID,
			&pin.Message.Type,
			&pin.Message.Content,
			&pin.Message.StickerID,
			&pin.Message.StickerFileID,
			&pin.Message.ReplyToMessageID,
			&pin.Message.EditedAt,
			&pin.Message.DeletedAt,
			&pin.Message.SentAt,
		); err != nil {
			return nil, fmt.Errorf("scan pinned message: %w", err)
		}
		pins = append(pins, pin)
	}
	return pins, rows.Err()
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
		var p model.Participant
		if err := rows.Scan(
			&p.ID, &p.ConversationID, &p.UserID, &p.Role, &p.LastReadMsgID,
			&p.MutedUntil, &p.JoinedAt, &p.LeftAt,
		); err != nil {
			return nil, fmt.Errorf("scan participant: %w", err)
		}
		participants = append(participants, &p)
	}
	return participants, rows.Err()
}

func (r *PGChatRepository) CountActiveParticipants(ctx context.Context, conversationID uuid.UUID) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL`,
		conversationID).Scan(&count)
	return count, err
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

func (tx *pgChatTxRepository) CreateConversation(ctx context.Context, conv *model.Conversation) error {
	_, err := tx.tx.Exec(ctx, `
		INSERT INTO conversations (id, type, title, avatar_file_id, activity_id, pinned_message_id, messaging_available_until, created_at, last_activity_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`, conv.ID, conv.Type, conv.Title, conv.AvatarFileID, conv.ActivityID,
		conv.PinnedMessageID, conv.MessagingAvailableUntil, conv.CreatedAt, conv.LastActivityAt)
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
		INSERT INTO messages (id, conversation_id, sender_user_id, type, content, sticker_id, sticker_file_id, reply_to_message_id, edited_at, deleted_at, sent_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`, msg.ID, msg.ConversationID, msg.SenderUserID, msg.Type, msg.Content,
		msg.StickerID, msg.StickerFileID, msg.ReplyToMessageID, msg.EditedAt, msg.DeletedAt, msg.SentAt)
	return err
}

func (tx *pgChatTxRepository) UpdateMessage(ctx context.Context, msg *model.Message) error {
	_, err := tx.tx.Exec(ctx, `
		UPDATE messages SET content = $2, edited_at = $3, deleted_at = $4 WHERE id = $1
	`, msg.ID, msg.Content, msg.EditedAt, msg.DeletedAt)
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
