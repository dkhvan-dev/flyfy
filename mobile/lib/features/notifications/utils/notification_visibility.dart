import '../data/notification_api.dart';

List<NotificationCategorySummary> visibleNotificationCategories(
  List<NotificationCategorySummary> categories,
) {
  return categories
      .where((category) => !isChatNotificationCategorySummary(category))
      .toList(growable: false);
}

List<UserNotification> visibleUserNotifications(
  List<UserNotification> notifications,
) {
  return notifications
      .where((notification) => !isChatMessageNotification(notification))
      .toList(growable: false);
}

int visibleUnreadNotificationCount(
  List<NotificationCategorySummary> categories,
) {
  return visibleNotificationCategories(
    categories,
  ).fold<int>(0, (sum, category) => sum + _positiveCount(category.unreadCount));
}

bool isChatNotificationCategorySummary(NotificationCategorySummary summary) {
  return isChatNotificationCategory(summary.category) ||
      isChatMessageNotification(summary.latest);
}

bool isChatMessageNotification(UserNotification notification) {
  if (isSupportNotificationCategory(notification.category)) {
    return false;
  }
  if (isChatNotificationCategory(notification.category)) {
    return true;
  }

  final template = _notificationTemplateKey(notification.data);
  if (_chatTemplateKeys.contains(template)) {
    return true;
  }

  return notification.data['conversationId']?.trim().isNotEmpty == true &&
      !_looksLikeSupportEvent(template);
}

bool isChatNotificationCategory(String category) {
  final normalized = _normalizeToken(category);
  if (normalized.isEmpty || isSupportNotificationCategory(normalized)) {
    return false;
  }
  return normalized == 'chat' ||
      normalized == 'chats' ||
      normalized == 'message' ||
      normalized == 'messages' ||
      normalized == 'direct_chat' ||
      normalized == 'activity_chat' ||
      normalized == 'excursion_chat' ||
      normalized.endsWith('_chat') ||
      normalized.endsWith('_messages');
}

bool isSupportNotificationCategory(String category) {
  final normalized = _normalizeToken(category);
  return normalized == 'support' ||
      normalized == 'help' ||
      normalized == 'help_center';
}

String _notificationTemplateKey(Map<String, String> data) {
  for (final key in const [
    'templateKey',
    'template',
    'activityEvent',
    'excursionEvent',
    'chatEvent',
    'feedEvent',
    'supportEvent',
    'eventType',
    'event',
    'notificationType',
    'type',
    'action',
  ]) {
    final raw = data[key]?.trim();
    if (raw != null && raw.isNotEmpty) {
      return _normalizeToken(raw);
    }
  }
  return '';
}

bool _looksLikeSupportEvent(String template) {
  return template.startsWith('support_') || template.startsWith('ticket_');
}

String _normalizeToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('.', '_')
      .replaceAll(':', '_')
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

const _chatTemplateKeys = {
  'chat_message',
  'message',
  'message_sent',
  'direct_message',
  'direct_chat_message',
  'activity_chat_message',
  'activity_message',
  'excursion_chat_message',
  'excursion_message',
};

int _positiveCount(int value) {
  if (value <= 0) {
    return 0;
  }
  return value;
}
