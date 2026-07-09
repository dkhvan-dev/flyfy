import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'chat gallery attachments use gallery pickers instead of recent files',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      expect(source, contains('case _AttachmentPickType.galleryImage:'));
      expect(source, contains('case _AttachmentPickType.galleryVideo:'));
      expect(source, contains('picker.pickMultiImage('));
      expect(source, contains('picker.pickMultiVideo('));
      expect(source, contains('ImagePicker()'));
      expect(source, isNot(contains('pickMultipleMedia(')));
    },
  );

  test(
    'chat attachment downloads are cancellable with inline progress',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final cacheSource = await File(
        'lib/core/files/chat_file_cache.dart',
      ).readAsString();
      final fileApiSource = await File(
        'lib/core/network/file_api.dart',
      ).readAsString();

      final attachmentsStateStart = source.indexOf(
        'class _MessageAttachmentsState',
      );
      final attachmentTileStart = source.indexOf('class _AttachmentTile');
      expect(attachmentsStateStart, isNonNegative);
      expect(attachmentTileStart, greaterThan(attachmentsStateStart));

      final stateSource = source.substring(
        attachmentsStateStart,
        attachmentTileStart,
      );
      final tapStart = stateSource.indexOf('Future<void> _handleAttachmentTap');
      final openStart = stateSource.indexOf(
        'Future<void> _openDownloadedAttachment',
      );
      expect(tapStart, isNonNegative);
      expect(openStart, greaterThan(tapStart));

      final tapSource = stateSource.substring(tapStart, openStart);

      expect(stateSource, contains('Map<String, _AttachmentDownloadProgress>'));
      expect(stateSource, contains('Map<String, CancelToken>'));
      expect(tapSource, contains('_cancelAttachmentDownload(item.fileId)'));
      expect(tapSource, contains('cancelToken: cancelToken'));
      expect(tapSource, contains('onReceiveProgress:'));
      expect(tapSource, isNot(contains('showSnackBar')));
      expect(tapSource, isNot(contains('chatAttachmentDownloaded')));
      expect(source, contains('_AttachmentDownloadProgressLabel('));
      expect(source, contains('_downloadProgressByFileId['));

      expect(cacheSource, contains('CancelToken? cancelToken'));
      expect(cacheSource, contains('ChatFileDownloadProgressCallback?'));
      expect(fileApiSource, contains('CancelToken? cancelToken'));
      expect(fileApiSource, contains('ProgressCallback? onReceiveProgress'));
    },
  );

  test(
    'chat sends attachments through server-side pending message flow',
    () async {
      final screenSource = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final providerSource = await File(
        'lib/providers/chat_provider.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/chat_api.dart',
      ).readAsString();
      final modelSource = await File(
        'lib/features/chat/models/message_vm.dart',
      ).readAsString();

      final sendStart = screenSource.indexOf('Future<void> _handleSend()');
      final pickerStart = screenSource.indexOf(
        '// _pickAttachments dispatches to the right native picker',
      );
      expect(sendStart, isNonNegative);
      expect(pickerStart, greaterThan(sendStart));

      final sendSource = screenSource.substring(sendStart, pickerStart);
      final createPendingIndex = sendSource.indexOf(
        'chatProvider.createPendingAttachmentMessage',
      );
      final localPreviewIndex = sendSource.indexOf(
        '_localPendingAttachmentsByMessageId[pendingMessage.id]',
      );
      final uploadIndex = sendSource.indexOf(
        '_fileApi.createChatAttachmentUpload',
      );
      final completeIndex = sendSource.indexOf(
        'chatProvider.completePendingMessageAttachments',
      );

      expect(
        screenSource,
        contains('Map<String, List<_PickedChatAttachment>>'),
      );
      expect(screenSource, contains('_localPendingAttachmentsByMessageId'));
      expect(
        screenSource,
        contains('Map<String, _PendingAttachmentSendState>'),
      );
      expect(screenSource, contains('_pendingAttachmentSendStateByMessageId'));
      expect(createPendingIndex, isNonNegative);
      expect(localPreviewIndex, greaterThan(createPendingIndex));
      expect(uploadIndex, greaterThan(localPreviewIndex));
      expect(completeIndex, greaterThan(uploadIndex));
      expect(screenSource, contains('pendingAttachmentsByMessageId:'));
      expect(screenSource, contains('_localPendingAttachmentsByMessageId'));
      expect(screenSource, contains('pendingSendStateByMessageId:'));
      expect(screenSource, contains('_pendingAttachmentSendStateByMessageId'));

      expect(providerSource, contains('createPendingAttachmentMessage('));
      expect(providerSource, contains('completePendingMessageAttachments('));
      expect(apiSource, contains('createPendingAttachmentMessage('));
      expect(apiSource, contains('completePendingMessageAttachments('));
      expect(apiSource, contains("'deferFileUpload': true"));
      expect(apiSource, contains('attachments/complete'));
      expect(modelSource, contains('final String sendStatus'));
      expect(modelSource, contains('bool get isPendingAttachmentUpload'));
    },
  );

  test('chat renders video attachments as inline video preview', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final previewFile = File(
      'lib/screens/chat/widgets/chat_video_preview.dart',
    );
    expect(previewFile.existsSync(), isTrue);
    final previewSource = await previewFile.readAsString();

    expect(source, contains('ChatVideoPreview'));
    expect(
      previewSource,
      contains("import 'package:video_player/video_player.dart';"),
    );
    expect(previewSource, contains('class ChatVideoPreview'));
    expect(previewSource, contains('VideoPlayerController.networkUrl'));
    expect(source, contains('if (isVideo)'));
    expect(source, isNot(contains('showPlay: isVideo')));
  });

  test(
    'chat video preview can fall back to local first-frame preview',
    () async {
      final previewSource = await File(
        'lib/screens/chat/widgets/chat_video_preview.dart',
      ).readAsString();

      expect(previewSource, contains('ChatFileCache'));
      expect(previewSource, contains('loadLocalPreview'));
      expect(previewSource, contains('_initializeLocalPreview'));
      expect(previewSource, contains('VideoPlayerController.file'));
    },
  );

  test('chat video preview opens fullscreen playback on tap', () async {
    final previewSource = await File(
      'lib/screens/chat/widgets/chat_video_preview.dart',
    ).readAsString();
    final viewerFile = File('lib/screens/chat/chat_video_viewer_screen.dart');

    expect(viewerFile.existsSync(), isTrue);
    final viewerSource = await viewerFile.readAsString();

    expect(previewSource, contains('ChatVideoViewerScreen'));
    expect(previewSource, contains('Navigator.of(context).push'));
    expect(viewerSource, contains('class ChatVideoViewerScreen'));
    expect(viewerSource, contains('ChatFileCache'));
    expect(viewerSource, contains('VideoPlayerController.file'));
  });

  test('fullscreen video viewer pauses playback while user scrubs', () async {
    final viewerSource = await File(
      'lib/screens/chat/chat_video_viewer_screen.dart',
    ).readAsString();

    expect(viewerSource, contains('_handleScrubStart'));
    expect(viewerSource, contains('_handleScrubEnd'));
    expect(viewerSource, contains('_resumeAfterScrub'));
    expect(viewerSource, contains('onChangeStart'));
    expect(viewerSource, contains('onChangeEnd'));
  });

  test('fullscreen video viewer can be dismissed by swiping down', () async {
    final viewerSource = await File(
      'lib/screens/chat/chat_video_viewer_screen.dart',
    ).readAsString();

    expect(viewerSource, contains('_dismissBySwipeDown'));
    expect(viewerSource, contains('onVerticalDragEnd'));
    expect(viewerSource, contains('primaryVelocity'));
    expect(viewerSource, contains('Navigator.of(context).pop'));
  });

  test(
    'chat file attachments open in swipe dismissible fullscreen preview',
    () async {
      final screenSource = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final sharedSource = await File(
        'lib/screens/chat/chat_shared_content_screen.dart',
      ).readAsString();
      final viewerFile = File('lib/screens/chat/chat_file_viewer_screen.dart');

      expect(viewerFile.existsSync(), isTrue);

      final viewerSource = await viewerFile.readAsString();

      expect(screenSource, contains("import 'chat_file_viewer_screen.dart';"));
      expect(sharedSource, contains("import 'chat_file_viewer_screen.dart';"));
      expect(
        screenSource,
        contains('ChatFileViewerScreen(downloaded: downloaded)'),
      );
      expect(
        sharedSource,
        contains('ChatFileViewerScreen(downloaded: downloaded)'),
      );
      expect(viewerSource, contains('class ChatFileViewerScreen'));
      expect(viewerSource, contains('AppFileOpener'));
      expect(viewerSource, contains('_dismissBySwipeDown'));
      expect(viewerSource, contains('onVerticalDragUpdate'));
      expect(viewerSource, contains('onVerticalDragEnd'));
      expect(viewerSource, contains('primaryVelocity'));
      expect(viewerSource, contains('Navigator.of(context).pop'));
    },
  );

  test(
    'chat attachment previews use shared cache and never show unknown while loading metadata',
    () async {
      final screenSource = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final cacheFile = File(
        'lib/features/chat/utils/chat_attachment_preview_cache.dart',
      );
      final en = await File('lib/l10n/app_en.arb').readAsString();
      final ru = await File('lib/l10n/app_ru.arb').readAsString();
      final kk = await File('lib/l10n/app_kk.arb').readAsString();
      final generated = await File(
        'lib/l10n/generated/app_localizations.dart',
      ).readAsString();

      expect(cacheFile.existsSync(), isTrue);
      final cacheSource = await cacheFile.readAsString();

      expect(
        screenSource,
        contains(
          "import '../../features/chat/utils/chat_attachment_preview_cache.dart';",
        ),
      );
      expect(
        screenSource,
        contains('_preloadAttachmentPreviews(chat.messages)'),
      );
      expect(screenSource, contains('ChatAttachmentPreviewCache.peek'));
      expect(screenSource, contains('ChatAttachmentPreviewCache.loadMany'));
      expect(
        screenSource,
        contains('ChatAttachmentPreviewCache.rememberDownloaded'),
      );
      expect(screenSource, contains('l10n.chatAttachmentLoadingPreview'));
      expect(
        screenSource,
        isNot(
          contains('metadata == null\n        ? l10n.chatSharedUnknownFile'),
        ),
      );
      expect(cacheSource, contains('class ChatAttachmentPreviewCache'));
      expect(cacheSource, contains('static ChatAttachmentPreviewData? peek'));
      expect(
        cacheSource,
        contains('static Future<List<ChatAttachmentPreviewData>> loadMany'),
      );
      expect(cacheSource, contains('static void rememberDownloaded'));
      expect(
        cacheSource,
        contains('Map<String, Future<ChatAttachmentPreviewData>>'),
      );
      expect(en, contains('"chatAttachmentLoadingPreview"'));
      expect(ru, contains('"chatAttachmentLoadingPreview"'));
      expect(kk, contains('"chatAttachmentLoadingPreview"'));
      expect(generated, contains('String get chatAttachmentLoadingPreview'));
    },
  );

  test('fullscreen video viewer uses adaptive V2 colors directly', () async {
    final viewerSource = await File(
      'lib/screens/chat/chat_video_viewer_screen.dart',
    ).readAsString();

    expect(viewerSource, contains('app_design_system.dart'));
    expect(viewerSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(viewerSource, contains('colors.backgroundDeep'));
    expect(viewerSource, contains('colors.primary'));
    expect(viewerSource, contains('colors.scrim'));
    expect(viewerSource, contains('colors.white'));
    expect(viewerSource, isNot(contains('AppPalette.')));
  });

  test(
    'pending video attachments use playable local preview before sending',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final viewerSource = await File(
        'lib/screens/chat/chat_video_viewer_screen.dart',
      ).readAsString();

      expect(source, contains('_PendingVideoAttachmentPreview'));
      expect(source, contains('VideoPlayerController.file'));
      expect(source, contains('ChatVideoViewerScreen.localFile'));
      expect(source, contains('chatLastMessageVideo'));
      expect(viewerSource, contains('ChatVideoViewerScreen.localFile'));
    },
  );

  test('conversation list uses media-aware last message previews', () async {
    final source = await File(
      'lib/screens/chat/conversations_screen.dart',
    ).readAsString();
    final previewSource = await File(
      'lib/screens/chat/widgets/chat_video_preview.dart',
    ).readAsString();
    final formatterSource = await File(
      'lib/features/chat/utils/chat_message_display_text.dart',
    ).readAsString();

    expect(source, contains('class _LastMessagePreviewLine'));
    expect(source, contains('chatLastMessagePreviewText'));
    expect(formatterSource, contains('chatLastMessagePhoto'));
    expect(formatterSource, contains('chatLastMessageVideo'));
    expect(formatterSource, contains('chatVoiceMessage'));
    expect(source, contains('_AttachmentPreviewThumb'));
    expect(source, contains('ChatVideoPreview'));
    expect(previewSource, contains('VideoPlayerController.networkUrl'));
    expect(formatterSource, contains('metadata.originalName.trim()'));
  });

  test('conversation list has no E2EE legacy decrypt path', () async {
    final source = await File(
      'lib/screens/chat/conversations_screen.dart',
    ).readAsString();
    final serviceFile = File(
      'lib/features/chat/services/chat_e2ee_service.dart',
    );

    expect(await serviceFile.exists(), isFalse);
    expect(source, isNot(contains('chat_e2ee_service.dart')));
    expect(source, isNot(contains('_decryptedPreviewFuture')));
    expect(source, isNot(contains('_decryptEncryptedPreview')));
    expect(source, isNot(contains('e2eeService')));
    expect(source, isNot(contains('peerPublicKeyBase64')));
    expect(source, isNot(contains('chatEncryptedMessage')));
  });

  test('conversation list exposes chat type tabs and shared search', () async {
    final source = await File(
      'lib/screens/chat/conversations_screen.dart',
    ).readAsString();
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();

    expect(
      source,
      contains(
        'enum _ConversationListTab { personal, activities, excursions }',
      ),
    );
    expect(source, contains('TabBar('));
    expect(source, contains('chatListPersonalTab'));
    expect(source, contains('chatListActivitiesTab'));
    expect(source, contains('chatListExcursionsTab'));
    expect(source, contains('chatListSearchHint'));
    expect(source, contains('_filterConversations('));
    expect(source, contains('_matchesSelectedTab('));
    expect(source, contains('_matchesSearchQuery('));

    expect(en, contains('"chatListPersonalTab": "Personal"'));
    expect(en, contains('"chatListActivitiesTab": "Activities"'));
    expect(en, contains('"chatListExcursionsTab": "Tours"'));
    expect(en, contains('"chatListSearchHint": "Chats"'));
    expect(en, contains('"chatListSearchEmpty": "No chats found"'));
    expect(ru, contains('"chatListPersonalTab": "Личные"'));
    expect(ru, contains('"chatListActivitiesTab": "Активности"'));
    expect(ru, contains('"chatListExcursionsTab": "Экскурсии"'));
    expect(ru, contains('"chatListSearchHint": "Чаты"'));
    expect(ru, contains('"chatListSearchEmpty": "Чаты не найдены"'));
    expect(kk, contains('"chatListPersonalTab": "Жеке"'));
    expect(kk, contains('"chatListActivitiesTab": "Белсенділіктер"'));
    expect(kk, contains('"chatListExcursionsTab": "Экскурсиялар"'));
    expect(kk, contains('"chatListSearchHint": "Чаттар"'));
    expect(kk, contains('"chatListSearchEmpty": "Чаттар табылмады"'));
  });

  test(
    'chat tgs stickers use robust lottie decoding and visible fallback',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      expect(source, contains('resolveStickerAssetContentFormat'));
      expect(source, contains('StickerAssetContentFormat.tgsGzip'));
      expect(source, contains('StickerAssetContentFormat.lottieJson'));
      expect(source, contains('LottieDecoder? get lottieDecoder'));
      expect(source, contains('LottieComposition.decodeGZip'));
      expect(source, contains('decoder: asset.lottieDecoder'));
      expect(source, contains('declaredContentType: sticker.contentType'));
      expect(source, contains('errorBuilder:'));
      expect(source, contains('class _StickerPlaceholder'));
      expect(source, contains('frameRate: const FrameRate(60)'));
      expect(source, isNot(contains('frameRate: FrameRate.max')));
      expect(source, isNot(contains('_hasGZipMagic(bytes)')));
    },
  );

  test(
    'chat mute and user block actions are wired through UI and API',
    () async {
      final conversationsSource = await File(
        'lib/screens/chat/conversations_screen.dart',
      ).readAsString();
      final chatSource = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final profileSource = await File(
        'lib/screens/profile/profile_screen.dart',
      ).readAsString();
      final apiSource = await File(
        'lib/core/network/chat_api.dart',
      ).readAsString();
      final providerSource = await File(
        'lib/providers/chat_provider.dart',
      ).readAsString();
      final en = await File('lib/l10n/app_en.arb').readAsString();
      final ru = await File('lib/l10n/app_ru.arb').readAsString();
      final kk = await File('lib/l10n/app_kk.arb').readAsString();
      final handlerSource = await File(
        '../backend/services/chat-service/internal/adapter/http/handler.go',
      ).readAsString();
      final gatewayRoutesSource = await File(
        '../backend/services/api-gateway/internal/adapter/http/routes.go',
      ).readAsString();

      expect(conversationsSource, contains('onLongPress'));
      expect(conversationsSource, contains('_showConversationActions'));
      expect(conversationsSource, contains('chatMuteNotificationsAction'));
      expect(conversationsSource, contains('chatUnmuteNotificationsAction'));
      expect(chatSource, contains('_showDirectChatActions'));
      expect(chatSource, contains('Icons.more_vert_rounded'));
      expect(chatSource, contains('chatBlockUserAction'));
      expect(chatSource, contains('chatUnblockUserAction'));
      expect(profileSource, contains('getUserBlockStatus'));
      expect(profileSource, contains('onToggleBlock'));
      expect(apiSource, contains('muteConversation('));
      expect(apiSource, contains('/chat/conversations/\$conversationId/mute'));
      expect(apiSource, contains('blockUser('));
      expect(apiSource, contains('/chat/users/\$userId/block'));
      expect(providerSource, contains('setConversationMuted('));
      expect(providerSource, contains('blockUser('));
      expect(providerSource, contains('unblockUser('));
      expect(handlerSource, contains('handleUserRoutes'));
      expect(handlerSource, contains('/v1/users/'));
      expect(gatewayRoutesSource, contains('"chat-users"'));
      expect(gatewayRoutesSource, contains('/chat/users'));

      expect(
        en,
        contains('"chatMuteNotificationsAction": "Mute notifications"'),
      );
      expect(
        en,
        contains('"chatUnmuteNotificationsAction": "Unmute notifications"'),
      );
      expect(en, contains('"chatBlockUserAction": "Block"'));
      expect(en, contains('"chatUnblockUserAction": "Unblock"'));
      expect(
        ru,
        contains('"chatMuteNotificationsAction": "Выключить уведомления"'),
      );
      expect(
        ru,
        contains('"chatUnmuteNotificationsAction": "Включить уведомления"'),
      );
      expect(ru, contains('"chatBlockUserAction": "Заблокировать"'));
      expect(ru, contains('"chatUnblockUserAction": "Разблокировать"'));
      expect(
        kk,
        contains('"chatMuteNotificationsAction": "Хабарландыруларды өшіру"'),
      );
      expect(
        kk,
        contains('"chatUnmuteNotificationsAction": "Хабарландыруларды қосу"'),
      );
    },
  );

  test(
    'conversation list video thumbnails can load local first frame',
    () async {
      final source = await File(
        'lib/screens/chat/conversations_screen.dart',
      ).readAsString();

      expect(source, contains('loadLocalPreview: true'));
      expect(source, contains('maxLocalPreviewBytes'));
      expect(source, contains('_videoPreviewDownloadLimitBytes'));
    },
  );

  test('shared chat content header opens direct peer profile', () async {
    final source = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(source, contains("import 'package:go_router/go_router.dart';"));
    expect(source, contains('profileUserId'));
    expect(source, contains("context.push('/users/\$profileUserId/profile')"));
    expect(source, contains('onTitleTap'));
  });

  test('shared chat content separates files from voice messages', () async {
    final source = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(source, contains('enum _SharedTab { media, links, files, voice }'));
    expect(source, contains('chatSharedVoiceTab'));
    expect(source, contains('final voiceMessages = _sharedFiles'));
    expect(
      source,
      contains('metadataKnown && (item.metadata?.isAudio ?? false)'),
    );
    expect(source, contains('metadataKnown && !_isSharedMediaOrAudio'));
    expect(source, contains('_buildVoiceSlivers'));
  });

  test(
    'shared content tabs scroll horizontally without clipping labels',
    () async {
      final source = await File(
        'lib/screens/chat/chat_shared_content_screen.dart',
      ).readAsString();

      expect(source, contains('SingleChildScrollView'));
      expect(source, contains('scrollDirection: Axis.horizontal'));
      expect(source, contains('mainAxisSize: MainAxisSize.min'));
      expect(
        source,
        isNot(contains('return Expanded(\n      child: GestureDetector(')),
      );
    },
  );

  test('shared media tab renders videos with preview thumbnails', () async {
    final source = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(source, contains("import 'widgets/chat_video_preview.dart';"));
    expect(source, contains('if (isVideo)'));
    expect(source, contains('ChatVideoPreview('));
    expect(source, contains('loadLocalPreview: true'));
  });

  test('inline video preview uses adaptive V2 colors directly', () async {
    final previewSource = await File(
      'lib/screens/chat/widgets/chat_video_preview.dart',
    ).readAsString();

    expect(previewSource, contains('app_design_system.dart'));
    expect(previewSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(previewSource, contains('colors.surfaceWarm'));
    expect(previewSource, contains('colors.backgroundDeep'));
    expect(previewSource, contains('colors.primary'));
    expect(previewSource, contains('colors.white'));
    expect(previewSource, isNot(contains('AppPalette.')));
  });

  test('shared voice messages use inline audio player', () async {
    final source = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();
    final playerSource = await File(
      'lib/screens/chat/widgets/chat_voice_attachment_player.dart',
    ).readAsString();

    expect(source, contains('ChatVoiceAttachmentPlayer'));
    expect(source, contains('_VoiceMessagesGroup'));
    expect(
      playerSource,
      contains("import 'package:just_audio/just_audio.dart';"),
    );
    expect(playerSource, contains('class ChatVoiceAttachmentPlayer'));
    expect(playerSource, contains('AudioPlayer'));
    expect(playerSource, contains('ChatFileCache'));
  });

  test('inline voice player uses adaptive V2 colors directly', () async {
    final playerSource = await File(
      'lib/screens/chat/widgets/chat_voice_attachment_player.dart',
    ).readAsString();

    expect(playerSource, contains('app_design_system.dart'));
    expect(playerSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(playerSource, contains('colors.transparent'));
    expect(playerSource, contains('colors.secondary'));
    expect(playerSource, contains('colors.onSecondary'));
    expect(playerSource, contains('colors.textSecondary'));
    expect(playerSource, isNot(contains('AppPalette.')));
  });

  test('shared voice tab is named audio messages in localizations', () async {
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();

    expect(en, contains('"chatSharedVoiceTab": "Audio messages"'));
    expect(ru, contains('"chatSharedVoiceTab": "Аудиосообщения"'));
    expect(kk, contains('"chatSharedVoiceTab": "Аудиохабарлар"'));
  });

  test('shared voice messages can prepare audio before seeking', () async {
    final playerSource = await File(
      'lib/screens/chat/widgets/chat_voice_attachment_player.dart',
    ).readAsString();

    expect(playerSource, contains('Future<bool> _prepareVoiceSource'));
    expect(playerSource, contains('seekFraction'));
    expect(playerSource, contains('await _prepareVoiceSource('));
    expect(playerSource, contains('durationStream'));
    expect(playerSource, contains('enabled: !_preparing'));
  });

  test('direct chat shared content hides participant count', () async {
    final source = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(
      source,
      contains('showParticipantCount: !widget.conversation.isDirect'),
    );
    expect(source, contains('final bool showParticipantCount'));
    expect(source, contains('if (showParticipantCount)'));
  });

  test('shared content items can return to source message', () async {
    final sharedSource = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();
    final chatSource = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final routerSource = await File(
      'lib/core/router/app_router.dart',
    ).readAsString();

    expect(sharedSource, contains('class ChatSharedContentResult'));
    expect(sharedSource, contains('chatSharedGoToMessageAction'));
    expect(sharedSource, contains('onLongPress'));
    expect(sharedSource, contains('Navigator.of('));
    expect(sharedSource, contains('ChatSharedContentResult.goToMessage'));
    expect(chatSource, contains('push<ChatSharedContentResult>'));
    expect(chatSource, contains('_scrollToMessage(result.messageId)'));
    expect(chatSource, contains('initialMessageId'));
    expect(routerSource, contains("state.uri.queryParameters['message']"));
  });

  test('shared content links warn before opening external resources', () async {
    final sharedSource = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(
      sharedSource,
      contains("import 'package:url_launcher/url_launcher.dart';"),
    );
    expect(sharedSource, contains('_handleSharedLinkTap'));
    expect(sharedSource, contains('_internalAppRouteForUrl'));
    expect(sharedSource, contains('context.push(internalRoute)'));
    expect(sharedSource, contains('chatExternalLinkTitle'));
    expect(sharedSource, contains('chatExternalLinkMessage'));
    expect(sharedSource, contains('LaunchMode.externalApplication'));
  });

  test('shared content links render as compact readable cards', () async {
    final sharedSource = await File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsString();

    expect(sharedSource, contains('class _CompactLinkCard'));
    expect(sharedSource, contains('Icons.open_in_new_rounded'));
    expect(sharedSource, contains('size: 40'));
    expect(sharedSource, contains('_linkHostLabel(item.url)'));
    expect(sharedSource, contains('maxLines: 2'));
  });

  test('chat message avatars open sender profile', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('_openUserProfile'));
    expect(source, contains("context.push('/users/\$encodedUserId/profile')"));
    expect(source, contains('onAvatarTap'));
    expect(source, contains('onDirectPeerAvatarTap'));
    expect(source, contains('Uri.encodeComponent(userId)'));
  });

  test(
    'chat message text renders tappable links with external warning',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final linkUtilsFile = File(
        'lib/features/chat/utils/chat_link_utils.dart',
      );
      expect(linkUtilsFile.existsSync(), isTrue);
      final linkUtils = await linkUtilsFile.readAsString();

      expect(source, contains("import 'package:flutter/gestures.dart';"));
      expect(
        source,
        contains("import 'package:url_launcher/url_launcher.dart';"),
      );
      expect(source, contains('_HyperlinkedMessageText'));
      expect(source, contains('TapGestureRecognizer'));
      expect(source, contains('_handleMessageLinkTap'));
      expect(source, contains('internalAppRouteForChatUrl'));
      expect(source, contains('chatExternalLinkTitle'));
      expect(source, contains('LaunchMode.externalApplication'));
      expect(linkUtils, contains('chatUrlRegex'));
      expect(linkUtils, contains('externalUriForChatUrl'));
    },
  );

  test(
    'chat message body uses adaptive foreground and blue link colors',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final designSystem = await File(
        'lib/core/ui/app_design_system.dart',
      ).readAsString();

      final colorsStart = source.indexOf('final class _ChatColors');
      final colorsEnd = source.indexOf('extension _ChatColorContext');
      final bubbleStart = source.indexOf('class _MessageBubble');
      final systemMessageStart = source.indexOf('class _SystemMessageDivider');

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(bubbleStart, isNonNegative);
      expect(systemMessageStart, greaterThan(bubbleStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final bubbleSource = source.substring(bubbleStart, systemMessageStart);
      final messageTextStart = bubbleSource.indexOf('_HyperlinkedMessageText(');
      final reactionsStart = bubbleSource.indexOf(
        'if (!isDeleted && message.reactions.isNotEmpty)',
      );

      expect(messageTextStart, isNonNegative);
      expect(reactionsStart, greaterThan(messageTextStart));

      final messageTextSource = bubbleSource.substring(
        messageTextStart,
        reactionsStart,
      );

      expect(designSystem, contains('required this.link'));
      expect(designSystem, contains('final Color link'));
      expect(designSystem, contains('link: AppPalette.blueLight01'));
      expect(designSystem, contains('link: AppPalette.blueSurfaceHigh10'));

      expect(
        colorsSource,
        contains('Color get messageText => colors.textPrimary'),
      );
      expect(colorsSource, contains('Color get messageLink => colors.link'));

      expect(
        messageTextSource,
        contains('color: context.chatColors.messageText'),
      );
      expect(
        messageTextSource,
        contains('color: context.chatColors.messageLink'),
      );
      expect(
        messageTextSource,
        contains('decorationColor: context.chatColors.messageLink'),
      );
      expect(
        messageTextSource,
        isNot(
          contains(
            'context.chatColors.white.withValues(\n                              alpha: 0.98',
          ),
        ),
      );
      expect(
        messageTextSource,
        isNot(contains('color: context.chatColors.primary')),
      );
    },
  );

  test(
    'chat messages use flat messenger rows and secondary media accents',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final playerSource = await File(
        'lib/screens/chat/widgets/chat_voice_attachment_player.dart',
      ).readAsString();

      final colorsStart = source.indexOf('final class _ChatColors');
      final colorsEnd = source.indexOf('extension _ChatColorContext');
      final bubbleStart = source.indexOf('class _MessageBubble');
      final systemMessageStart = source.indexOf('class _SystemMessageDivider');
      final fileRowStart = source.indexOf('class _AttachmentFileRow');
      final fileBadgeStart = source.indexOf('class _AttachmentDownloadBadge');

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(bubbleStart, isNonNegative);
      expect(systemMessageStart, greaterThan(bubbleStart));
      expect(fileRowStart, isNonNegative);
      expect(fileBadgeStart, greaterThan(fileRowStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final bubbleSource = source.substring(bubbleStart, systemMessageStart);
      final fileRowSource = source.substring(fileRowStart, fileBadgeStart);

      expect(colorsSource, contains('Color messageSurface(bool highlighted)'));
      expect(colorsSource, contains('Color messageBorder(bool highlighted)'));
      expect(
        colorsSource,
        contains('Color get onSecondary => colors.onSecondary'),
      );

      expect(
        bubbleSource,
        contains('color: context.chatColors.messageSurface(isHighlighted)'),
      );
      expect(
        bubbleSource,
        contains('color: context.chatColors.messageBorder(isHighlighted)'),
      );
      expect(
        bubbleSource,
        contains(
          'padding: isSticker\n                      ? AppEdgeInsets.zero\n                      : AppEdgeInsets.symmetric(',
        ),
      );
      expect(bubbleSource, isNot(contains('LinearGradient(')));
      expect(bubbleSource, isNot(contains('_formatTime(message.sentAt)')));
      expect(bubbleSource, isNot(contains("readByOthers ? '✓✓' : '✓'")));

      expect(fileRowSource, contains('color: context.chatColors.secondary'));
      expect(fileRowSource, contains('color: context.chatColors.onSecondary'));
      expect(fileRowSource, contains('color: context.chatColors.messageText'));
      expect(fileRowSource, contains('color: context.chatColors.textMuted'));
      expect(
        fileRowSource,
        contains('_formatAttachmentSize(metadata.sizeBytes)'),
      );
      expect(fileRowSource, contains('_downloadStatusLabel(downloadProgress)'));
      expect(fileRowSource, isNot(contains('_AttachmentDownloadBadge')));
      expect(fileRowSource, isNot(contains('metadata.extensionLabel')));

      expect(
        playerSource,
        contains('color: widget.backgroundColor ?? colors.transparent'),
      );
      expect(
        playerSource,
        contains('color: widget.borderColor ?? colors.transparent'),
      );
      expect(playerSource, contains('color: colors.secondary'));
      expect(playerSource, contains('color: colors.onSecondary'));
      expect(playerSource, isNot(contains('color: colors.primary')));
      expect(playerSource, isNot(contains('l10n.chatVoiceMessage')));
    },
  );

  test('message action sheet scrolls within available height', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('_messageActionSheetMaxHeightFactor'));
    expect(source, contains('isScrollControlled: true'));
    expect(source, contains('ConstrainedBox'));
    expect(source, contains('SingleChildScrollView'));
    expect(source, contains('MediaQuery.sizeOf(sheetContext).height'));
  });

  test('message actions expose copy forward and status details', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final modelSource = await File(
      'lib/features/chat/models/message_vm.dart',
    ).readAsString();
    final apiSource = await File(
      'lib/core/network/chat_api.dart',
    ).readAsString();
    final providerSource = await File(
      'lib/providers/chat_provider.dart',
    ).readAsString();

    expect(source, contains('_copyMessageText'));
    expect(source, contains('Clipboard.setData'));
    expect(source, contains('_showForwardMessageSheet'));
    expect(source, contains('_ForwardMessageSheet'));
    expect(source, contains('_MessageStatusPreview'));
    expect(source, contains('_reactionInfosForMessage'));
    expect(source, contains('_readReceiptsForMessage'));
    expect(source, contains('chatCopyAction'));
    expect(source, contains('chatForwardAction'));
    expect(source, contains('chatForwardedLabel'));
    expect(source, contains('chatForwardCount'));
    expect(modelSource, contains('final int forwardCount'));
    expect(modelSource, contains('final List<String> userIds'));
    expect(modelSource, contains('forwardedFromSenderName'));
    expect(apiSource, contains('forwardMessage'));
    expect(providerSource, contains('forwardMessageToConversation'));
  });

  test(
    'message status preview hides empty details and uses polished cards',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('if (!hasDetails) return const SizedBox.shrink();'),
      );
      expect(source, isNot(contains('l10n.chatNoStatusDetails')));
      expect(source, contains('class _StatusDetailCard'));
      expect(source, contains('class _StatusMetricCard'));
      expect(source, contains('Icons.keyboard_arrow_right_rounded'));
    },
  );

  test(
    'message read receipts are private to sender and open detailed sheet',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final modelSource = await File(
        'lib/features/chat/models/message_vm.dart',
      ).readAsString();
      final providerSource = await File(
        'lib/providers/chat_provider.dart',
      ).readAsString();

      expect(source, contains('_readReceiptsForMessage'));
      expect(source, contains('message.senderUserId != currentUserId'));
      expect(source, contains('_ReadReceiptSummary'));
      expect(source, contains('receipts.take(3)'));
      expect(source, contains('_showReadReceiptsSheet'));
      expect(source, contains('_ReadReceiptsSheet'));
      expect(source, contains('chatReadByCount'));
      expect(source, contains('chatReadAtSeparator'));
      expect(source, contains('_formatReadReceiptAt'));
      expect(source, contains('_openUserProfile(selectedUserId)'));
      expect(modelSource, contains('class MessageReadReceiptVm'));
      expect(modelSource, contains('final DateTime readAt'));
      expect(providerSource, contains('_updateMessageReadReceipts'));
    },
  );

  test(
    'message read receipt sheet prioritizes and shows participant reactions',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final ru = await File('lib/l10n/app_ru.arb').readAsString();
      final en = await File('lib/l10n/app_en.arb').readAsString();
      final kk = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('reactionEmoji: _reactionEmojiForUserId('));
      expect(source, contains('_readReceiptReactionPriority'));
      expect(source, contains('class _ReadReceiptReactionBadge'));
      expect(source, contains('receipt.reactionEmoji'));
      expect(source, contains('l10n.chatReactionCount(reactionInfos.length)'));
      expect(source, contains('class _ReactionUsersSheet'));
      expect(source, contains('chatReactionCount'));
      expect(ru, contains('"chatReactionCount"'));
      expect(ru, contains('one{{count} реакция}'));
      expect(en, contains('"chatReactionCount"'));
      expect(kk, contains('"chatReactionCount"'));
    },
  );

  test(
    'message action reaction summary shows one count and opens reaction users',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final modelSource = await File(
        'lib/features/chat/models/message_vm.dart',
      ).readAsString();

      expect(source, contains('class _ReactionInfo'));
      expect(source, contains('_reactionInfosForMessage'));
      expect(source, contains('_showReactionUsersSheet'));
      expect(source, contains('class _ReactionUsersSheet'));
      expect(source, contains('class _ReactionSummary'));
      expect(source, contains('reactionInfos.take(3)'));
      expect(source, contains('reactedAt'));
      expect(source, contains('b.reactedAt.compareTo(a.reactedAt)'));
      expect(
        source,
        contains('_formatReactionAt(context, reactionInfo.reactedAt)'),
      );
      expect(source, contains('l10n.chatReactionCount(reactionInfos.length)'));
      expect(modelSource, contains('class MessageReactionUserVm'));
      expect(source, isNot(contains('class _ReactionStatusRow')));
      expect(source, isNot(contains('reactionParticipantsByEmoji')));
      expect(source, isNot(contains('_ParticipantPillWrap')));
    },
  );

  test('chat code contains no E2EE implementation', () async {
    final chatSource = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final serviceFile = File(
      'lib/features/chat/services/chat_e2ee_service.dart',
    );
    final modelSource = await File(
      'lib/features/chat/models/conversation_vm.dart',
    ).readAsString();
    final apiSource = await File(
      'lib/core/network/chat_api.dart',
    ).readAsString();
    final providerSource = await File(
      'lib/providers/chat_provider.dart',
    ).readAsString();
    final messageModelSource = await File(
      'lib/features/chat/models/message_vm.dart',
    ).readAsString();
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();

    expect(await serviceFile.exists(), isFalse);
    expect(modelSource, isNot(contains('securityMode')));
    expect(modelSource, isNot(contains('encryptionVersion')));
    expect(messageModelSource, isNot(contains('encryptionVersion')));
    expect(messageModelSource, isNot(contains('isEncrypted')));
    expect(apiSource, isNot(contains('setConversationSecurityMode')));
    expect(apiSource, isNot(contains('registerE2EEDeviceKey')));
    expect(apiSource, isNot(contains('getE2EEDeviceKey')));
    expect(
      providerSource,
      isNot(contains('setActiveConversationSecurityMode')),
    );
    expect(chatSource, isNot(contains('_ChatSecurityButton')));
    expect(chatSource, isNot(contains('_showChatSecuritySheet')));
    expect(chatSource, isNot(contains('enable_private_e2ee')));
    expect(chatSource, isNot(contains('_EncryptedMessageText')));
    expect(chatSource, isNot(contains('chat_e2ee_service.dart')));
    expect(chatSource, isNot(contains('chatEncryptedMessage')));
    expect(chatSource, isNot(contains('chatPrivateMediaUnsupported')));
    expect(en, isNot(contains('chatEncryptedMessage')));
    expect(ru, isNot(contains('chatEncryptedMessage')));
    expect(kk, isNot(contains('chatEncryptedMessage')));
  });

  test('chat service has no E2EE schema or API surface', () async {
    final migrationFile = File(
      '../backend/services/chat-service/migrations/010_chat_e2ee_v1.up.sql',
    );
    final messageUseCaseSource = await File(
      '../backend/services/chat-service/internal/app/message_usecase.go',
    ).readAsString();
    final conversationUseCaseSource = await File(
      '../backend/services/chat-service/internal/app/conversation_usecase.go',
    ).readAsString();
    final messageDtoSource = await File(
      '../backend/services/chat-service/internal/transport/dto/message.go',
    ).readAsString();
    final conversationDtoSource = await File(
      '../backend/services/chat-service/internal/transport/dto/conversation.go',
    ).readAsString();
    final handlerSource = await File(
      '../backend/services/chat-service/internal/adapter/http/handler.go',
    ).readAsString();
    final messageModelSource = await File(
      '../backend/services/chat-service/internal/domain/model/message.go',
    ).readAsString();
    final conversationModelSource = await File(
      '../backend/services/chat-service/internal/domain/model/conversation.go',
    ).readAsString();
    final eventSource = await File(
      '../backend/services/chat-service/internal/event/types.go',
    ).readAsString();
    final gatewayRoutesSource = await File(
      '../backend/services/api-gateway/internal/adapter/http/routes.go',
    ).readAsString();
    final repositorySource = await File(
      '../backend/services/chat-service/internal/adapter/repository/pg_chat_repository.go',
    ).readAsString();

    expect(await migrationFile.exists(), isFalse);
    expect(
      messageUseCaseSource,
      isNot(contains('ErrEncryptedMessagesDisabled')),
    );
    expect(messageUseCaseSource, isNot(contains('validateMessageEncryption')));
    expect(messageUseCaseSource, isNot(contains('ErrCannotForwardEncrypted')));
    expect(messageUseCaseSource, isNot(contains('EncryptionVersion')));
    expect(conversationUseCaseSource, isNot(contains('SecurityMode')));
    expect(conversationUseCaseSource, isNot(contains('E2EE')));
    expect(messageDtoSource, isNot(contains('EncryptionVersion')));
    expect(conversationDtoSource, isNot(contains('SecurityMode')));
    expect(
      conversationDtoSource,
      isNot(contains('SetConversationSecurityModeRequest')),
    );
    expect(handlerSource, isNot(contains('/v1/e2ee')));
    expect(handlerSource, isNot(contains('GetE2EEDeviceKey')));
    expect(handlerSource, isNot(contains('conversationSecurityMode')));
    expect(messageModelSource, isNot(contains('EncryptionVersion')));
    expect(conversationModelSource, isNot(contains('SecurityMode')));
    expect(eventSource, isNot(contains('EncryptionVersion')));
    expect(gatewayRoutesSource, isNot(contains('chat-e2ee')));
    expect(repositorySource, isNot(contains('security_mode')));
    expect(repositorySource, isNot(contains('encryption_version')));
    expect(repositorySource, isNot(contains('chat_e2ee_device_keys')));
  });

  test('chat service stores per-message read receipt timestamps', () async {
    final migrationSource = await File(
      '../backend/services/chat-service/migrations/009_message_read_receipts.up.sql',
    ).readAsString();
    final modelSource = await File(
      '../backend/services/chat-service/internal/domain/model/message.go',
    ).readAsString();
    final dtoSource = await File(
      '../backend/services/chat-service/internal/transport/dto/message.go',
    ).readAsString();
    final usecaseSource = await File(
      '../backend/services/chat-service/internal/app/message_usecase.go',
    ).readAsString();
    final repositorySource = await File(
      '../backend/services/chat-service/internal/adapter/repository/pg_chat_repository.go',
    ).readAsString();
    final eventSource = await File(
      '../backend/services/chat-service/internal/event/types.go',
    ).readAsString();

    expect(migrationSource, contains('message_read_receipts'));
    expect(migrationSource, contains('PRIMARY KEY (message_id, user_id)'));
    expect(modelSource, contains('type MessageReadReceipt struct'));
    expect(dtoSource, contains('type MessageReadReceiptInfo struct'));
    expect(dtoSource, contains('ReadReceipts'));
    expect(usecaseSource, contains('CreateReadReceiptsUpToMessage'));
    expect(usecaseSource, contains('ListMessageReadReceipts'));
    expect(
      repositorySource,
      contains('ON CONFLICT (message_id, user_id) DO NOTHING'),
    );
    expect(eventSource, contains('ReadAt'));
    expect(eventSource, contains('json:"readAt"'));
  });

  test(
    'activity chat participants put current non-host user first in joined list',
    () async {
      final source = await File(
        'lib/screens/chat/chat_participants_screen.dart',
      ).readAsString();

      expect(source, contains('_currentUserFirstJoinedParticipants'));
      expect(source, contains('currentUserIsOrganizer'));
      expect(source, contains('currentParticipant'));
      expect(source, contains('return [currentParticipant, ...others]'));
    },
  );

  test('chat attachment sheet uses custom amber bottom sheet', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('class _AmberAttachmentSheet'));
    expect(source, contains('class _AmberAttachmentActionTile'));
    expect(source, contains('context.chatColors.primary'));
    expect(
      source,
      contains('barrierColor: context.chatColors.black.withValues'),
    );
    expect(source, contains('chatAttachmentCancel'));
    expect(source, isNot(contains('CupertinoActionSheet')));
  });

  test(
    'chat renders multiple image attachments as an adaptive collage',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      final messageAttachmentsStart = source.indexOf(
        'class _MessageAttachments',
      );
      final attachmentTileStart = source.indexOf('class _AttachmentTile');
      final collageStart = source.indexOf('class _MessageImageCollage');

      expect(messageAttachmentsStart, isNonNegative);
      expect(attachmentTileStart, greaterThan(messageAttachmentsStart));
      expect(collageStart, greaterThan(attachmentTileStart));

      final attachmentsSource = source.substring(
        messageAttachmentsStart,
        attachmentTileStart,
      );
      final collageSource = source.substring(collageStart);

      expect(attachmentsSource, contains('_imageAttachmentItems(items)'));
      expect(attachmentsSource, contains('_MessageImageCollage('));
      expect(attachmentsSource, contains('groupedFileIds'));
      expect(collageSource, contains('LayoutBuilder('));
      expect(collageSource, contains('_buildTwoImageGrid'));
      expect(collageSource, contains('_buildThreeImageCollage'));
      expect(collageSource, contains('_buildManyImageCollage'));
      expect(
        collageSource,
        contains('SliverGridDelegateWithFixedCrossAxisCount'),
      );

      final manyCollageStart = collageSource.indexOf(
        'Widget _buildManyImageCollage',
      );
      final manyCollageEnd = collageSource.indexOf(
        'class _MessageImageCollageTile',
      );
      expect(manyCollageStart, isNonNegative);
      expect(manyCollageEnd, greaterThan(manyCollageStart));

      final manyCollageSource = collageSource.substring(
        manyCollageStart,
        manyCollageEnd,
      );
      expect(manyCollageSource, contains('SizedBox(height: gap)'));
      expect(manyCollageSource, contains('padding: EdgeInsets.zero'));
      expect(
        collageSource,
        isNot(
          contains(
            'Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            for (var i = 0; i < items.length; i++)',
          ),
        ),
      );
    },
  );

  test('chat limits one message to ten image attachments', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();
    final generated = await File(
      'lib/l10n/generated/app_localizations.dart',
    ).readAsString();

    expect(source, contains('_maxChatImageAttachmentsPerMessage = 10'));
    expect(source, contains('_remainingImageAttachmentSlots('));
    expect(source, contains('_addPendingAttachmentsWithinMessageLimits('));
    expect(
      source,
      contains('chatAttachmentImageLimit(_maxChatImageAttachmentsPerMessage)'),
    );
    expect(en, contains('"chatAttachmentImageLimit"'));
    expect(ru, contains('"chatAttachmentImageLimit"'));
    expect(kk, contains('"chatAttachmentImageLimit"'));
    expect(generated, contains('chatAttachmentImageLimit(int count)'));
  });

  test('chat enforces ten minute voice and video duration limits', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('_maxChatVoiceRecordingDuration'));
    expect(source, contains('_maxChatVideoAttachmentDuration'));
    expect(source, contains('Duration(minutes: 10)'));
    expect(
      source,
      contains('maxVideoDuration: _maxChatVideoAttachmentDuration'),
    );
    expect(
      source,
      contains('_stopVoiceRecordingForPreview(maxDurationReached: true)'),
    );
    expect(source, contains('VideoPlayerController.file'));
    expect(source, contains('_localVideoDuration('));
    expect(source, contains('chatAttachmentVideoTooLong'));
    expect(en, contains('up to 10 minutes'));
    expect(ru, contains('до 10 минут'));
    expect(kk, contains('10 минутқа дейінгі'));
  });

  test('chat limits and groups files and video attachments', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();
    final en = await File('lib/l10n/app_en.arb').readAsString();
    final ru = await File('lib/l10n/app_ru.arb').readAsString();
    final kk = await File('lib/l10n/app_kk.arb').readAsString();
    final generated = await File(
      'lib/l10n/generated/app_localizations.dart',
    ).readAsString();

    expect(source, contains('_maxChatFileAttachmentsPerMessage = 10'));
    expect(source, contains('_maxChatVideoAttachmentsPerMessage = 10'));
    expect(source, contains('_remainingFileAttachmentSlots('));
    expect(source, contains('_remainingVideoAttachmentSlots('));
    expect(source, contains('chatAttachmentFileLimit('));
    expect(source, contains('chatAttachmentVideoLimit('));
    expect(source, contains('_videoAttachmentItems(items)'));
    expect(source, contains('_fileAttachmentItems(items)'));
    expect(source, contains('_MessageVideoCollage('));
    expect(source, contains('_MessageFileGroup('));
    expect(en, contains('"chatAttachmentFileLimit"'));
    expect(en, contains('"chatAttachmentVideoLimit"'));
    expect(ru, contains('"chatAttachmentFileLimit"'));
    expect(ru, contains('"chatAttachmentVideoLimit"'));
    expect(kk, contains('"chatAttachmentFileLimit"'));
    expect(kk, contains('"chatAttachmentVideoLimit"'));
    expect(generated, contains('chatAttachmentFileLimit(int count)'));
    expect(generated, contains('chatAttachmentVideoLimit(int count)'));
  });
}
