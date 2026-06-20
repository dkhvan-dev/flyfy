package http

import (
	"strings"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func chatMessagePreviewText(locale string, item *model.ChatMessageModerationItem) string {
	if item == nil {
		return "-"
	}
	content := strings.TrimSpace(item.Content)
	if content == "" {
		if value := chatMessageVisualKindText(locale, item.Type, len(item.FileIDs) > 0); value != "" {
			return value
		}
		return "-"
	}
	content = strings.Join(strings.Fields(content), " ")
	if len([]rune(content)) > 120 {
		runes := []rune(content)
		return string(runes[:120]) + "..."
	}
	return content
}

func chatMessageBodyText(item *model.ChatMessageModerationItem) string {
	if item == nil {
		return ""
	}
	return strings.TrimSpace(item.Content)
}

func chatMessageKindBadgeText(locale string, item *model.ChatMessageModerationItem) string {
	if item == nil {
		return ""
	}
	return chatMessageVisualKindText(locale, item.Type, len(item.FileIDs) > 0)
}

func chatMessageSenderText(item *model.ChatMessageModerationItem) string {
	if item == nil {
		return "-"
	}
	if value := strings.TrimSpace(item.SenderDisplayName); value != "" {
		return value
	}
	return "-"
}

func chatMessageConversationText(locale string, item *model.ChatMessageModerationItem) string {
	if item == nil {
		return "-"
	}
	parts := make([]string, 0, 2)
	if value := strings.TrimSpace(item.ConversationTitle); value != "" {
		parts = append(parts, value)
	}
	if value := strings.TrimSpace(item.ConversationType); value != "" {
		parts = append(parts, chatMessageTypeText(locale, value))
	}
	if len(parts) == 0 {
		return "-"
	}
	return strings.Join(parts, " · ")
}

func chatMessageSignalsText(locale string, item *model.ChatMessageModerationItem) string {
	if item == nil || len(item.ModerationReasonCodes) == 0 {
		return ""
	}
	labels := make([]string, 0, len(item.ModerationReasonCodes))
	for _, code := range item.ModerationReasonCodes {
		code = strings.TrimSpace(code)
		if code == "" {
			continue
		}
		labels = append(labels, moderationSignalText(locale, code))
	}
	return strings.Join(labels, ", ")
}

func chatMessageDecisionLocked(item *model.ChatMessageModerationItem) bool {
	if item == nil {
		return false
	}
	status := strings.ToUpper(strings.TrimSpace(item.ModerationStatus))
	return status == "CLEARED" || status == "HIDDEN_BY_MODERATION"
}

func chatMessageTypeText(locale string, value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return "-"
	}
	key := "chat.type." + value
	translated := translate(locale, key)
	if translated == key {
		return value
	}
	return translated
}

func chatMessageVisualKindText(locale string, value string, hasFiles bool) string {
	value = strings.ToLower(strings.TrimSpace(value))
	switch value {
	case "sticker", "emoji", "file":
		return chatMessageTypeText(locale, value)
	}
	if hasFiles {
		return translate(locale, "chat.attachmentMessage")
	}
	return ""
}

func chatContextSenderText(item model.ChatMessageContextItem) string {
	if value := strings.TrimSpace(item.SenderDisplayName); value != "" {
		return value
	}
	return "-"
}

func chatContextBodyText(item model.ChatMessageContextItem) string {
	return strings.TrimSpace(item.Content)
}

func chatContextKindBadgeText(locale string, item model.ChatMessageContextItem) string {
	return chatMessageVisualKindText(locale, item.Type, len(item.FileIDs) > 0)
}

func chatContextContentText(locale string, item model.ChatMessageContextItem) string {
	if strings.TrimSpace(item.Content) != "" {
		return item.Content
	}
	if value := chatMessageVisualKindText(locale, item.Type, len(item.FileIDs) > 0); value != "" {
		return value
	}
	return "-"
}
