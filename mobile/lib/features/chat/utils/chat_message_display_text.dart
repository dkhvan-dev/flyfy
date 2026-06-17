import '../../../core/network/file_api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/conversation_vm.dart';

String chatLastMessagePreviewText({
  required LastMessagePreview message,
  required AppLocalizations l10n,
  FileMetadataVm? attachmentMetadata,
  String? attachmentFileId,
}) {
  if (message.isDeleted) {
    return message.isHiddenByModerator
        ? l10n.chatMessageRemovedByModerator
        : l10n.chatMessageDeleted;
  }

  if (_isSystemMessage(message)) {
    return localizedChatSystemMessageText(
      content: message.contentPreview,
      senderName: message.senderDisplayName,
      l10n: l10n,
    );
  }

  final preview = chatLastMessagePreviewBody(
    message: message,
    l10n: l10n,
    attachmentMetadata: attachmentMetadata,
    attachmentFileId: attachmentFileId,
  );
  final sender = message.senderDisplayName.trim();
  if (sender.isEmpty) return preview;
  return '$sender: $preview';
}

String chatLastMessagePreviewBody({
  required LastMessagePreview message,
  required AppLocalizations l10n,
  FileMetadataVm? attachmentMetadata,
  String? attachmentFileId,
}) {
  if (message.isSticker) return l10n.chatStickerMessage;

  if (attachmentMetadata?.isAudio ?? false) return l10n.chatVoiceMessage;
  if (attachmentMetadata?.isImage ?? false) return l10n.chatLastMessagePhoto;
  if (attachmentMetadata?.isVideo ?? false) return l10n.chatLastMessageVideo;

  if (attachmentMetadata != null && message.hasFiles) {
    final name = _displayFileName(attachmentMetadata);
    return name.isEmpty
        ? l10n.chatSharedFileFallback(_shortId(attachmentFileId ?? ''))
        : name;
  }

  final contentPreview = _singleLinePreview(message.contentPreview);
  if (message.hasFiles && _looksLikeRecordedVoiceName(contentPreview)) {
    return l10n.chatVoiceMessage;
  }
  if (contentPreview.isNotEmpty) return contentPreview;
  if (message.hasFiles) return l10n.chatAttachmentFile;
  return message.contentPreview;
}

String localizedChatSystemMessageText({
  required String content,
  required String senderName,
  required AppLocalizations l10n,
}) {
  final text = _singleLinePreview(content);

  if (text == 'User joined' || text == 'User joined the chat') {
    final name = _isConcreteSenderName(senderName)
        ? senderName.trim()
        : l10n.chatUserFallbackName;
    return l10n.chatSystemUserJoined(name);
  }
  if (text == 'User left' || text == 'User left the chat') {
    final name = _isConcreteSenderName(senderName)
        ? senderName.trim()
        : l10n.chatUserFallbackName;
    return l10n.chatSystemUserLeft(name);
  }

  if (text.endsWith(' joined')) {
    final name = text.substring(0, text.length - ' joined'.length).trim();
    if (name.isNotEmpty) {
      return l10n.chatSystemUserJoined(name);
    }
  }
  if (text.endsWith(' left')) {
    final name = text.substring(0, text.length - ' left'.length).trim();
    if (name.isNotEmpty) {
      return l10n.chatSystemUserLeft(name);
    }
  }

  return text.isEmpty ? l10n.chatSystemUpdate : text;
}

bool _isSystemMessage(LastMessagePreview message) {
  return message.type.trim().toLowerCase() == 'system' ||
      message.senderDisplayName.trim().toLowerCase() == 'system';
}

bool _isConcreteSenderName(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty &&
      normalized != 'system' &&
      normalized != 'user';
}

bool _looksLikeRecordedVoiceName(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return RegExp(
    r'^(inflap_)?voice[_-].*\.(aac|flac|m4a|mp3|ogg|opus|wav)$',
  ).hasMatch(normalized);
}

String _singleLinePreview(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _shortId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

String _displayFileName(FileMetadataVm metadata) {
  final name = metadata.originalName.trim();
  if (name.isEmpty) return '';

  final extension = metadata.extensionLabel.trim().toLowerCase();
  if (extension.isEmpty || extension == 'file') return name;

  final lowerName = name.toLowerCase();
  if (lowerName.endsWith('.$extension')) return name;

  final lastSegment = name.split(RegExp(r'[/\\]')).last;
  if (lastSegment.contains('.')) return name;

  return '$name.$extension';
}
