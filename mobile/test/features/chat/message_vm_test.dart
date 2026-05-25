import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/chat/models/conversation_vm.dart';
import 'package:superapp/features/chat/models/message_vm.dart';

void main() {
  test('message hidden by moderator keeps public moderation comment', () {
    final message = MessageVm.fromJson({
      'id': 'message-1',
      'senderUserId': 'user-1',
      'senderDisplayName': 'Aigerim',
      'type': 'text',
      'content': '',
      'moderationStatus': 'HIDDEN_BY_MODERATION',
      'moderationPublicComment': 'Нельзя переводить общение за пределы FlyFy.',
      'deletedAt': '2026-05-25T12:30:00Z',
      'sentAt': '2026-05-25T12:00:00Z',
    });

    expect(message.isDeleted, isTrue);
    expect(message.isHiddenByModerator, isTrue);
    expect(
      message.moderationPublicComment,
      'Нельзя переводить общение за пределы FlyFy.',
    );
  });

  test('last message preview hidden by moderator is distinguishable', () {
    final preview = LastMessagePreview.fromJson({
      'id': 'message-1',
      'senderUserId': 'user-1',
      'senderDisplayName': 'Aigerim',
      'type': 'text',
      'contentPreview': '',
      'moderationStatus': 'HIDDEN_BY_MODERATION',
      'moderationPublicComment': 'Нельзя переводить общение за пределы FlyFy.',
      'deletedAt': '2026-05-25T12:30:00Z',
      'sentAt': '2026-05-25T12:00:00Z',
    });

    expect(preview.isDeleted, isTrue);
    expect(preview.isHiddenByModerator, isTrue);
    expect(
      preview.moderationPublicComment,
      'Нельзя переводить общение за пределы FlyFy.',
    );
  });
}
