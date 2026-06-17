import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/file_api.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/features/chat/utils/chat_message_display_text.dart';
import 'package:inflap/l10n/generated/app_localizations_ru.dart';

void main() {
  final l10n = AppLocalizationsRu();
  final sentAt = DateTime.parse('2026-06-17T09:00:00Z');

  test('last message preview uses localized voice label for audio files', () {
    final message = LastMessagePreview(
      id: 'message-1',
      senderUserId: 'user-1',
      senderDisplayName: 'Акаш',
      type: 'file',
      contentPreview: 'voice_1780000000_4s.m4a',
      fileIds: const ['file-1'],
      sentAt: sentAt,
    );

    final preview = chatLastMessagePreviewText(
      message: message,
      l10n: l10n,
      attachmentMetadata: const FileMetadataVm(
        id: 'file-1',
        originalName: 'voice_1780000000_4s.m4a',
        contentType: 'audio/mp4',
        sizeBytes: 12000,
      ),
      attachmentFileId: 'file-1',
    );

    expect(preview, 'Акаш: Голосовое сообщение');
  });

  test('last message preview localizes system joined messages', () {
    final message = LastMessagePreview(
      id: 'message-2',
      senderUserId: 'system',
      senderDisplayName: 'System',
      type: 'system',
      contentPreview: 'akashimo joined',
      sentAt: sentAt,
    );

    final preview = chatLastMessagePreviewText(message: message, l10n: l10n);

    expect(preview, 'akashimo присоединился');
  });
}
