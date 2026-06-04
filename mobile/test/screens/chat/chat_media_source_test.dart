import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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

    expect(source, contains('class _LastMessagePreviewLine'));
    expect(source, contains('chatLastMessagePhoto'));
    expect(source, contains('chatLastMessageVideo'));
    expect(source, contains('_AttachmentPreviewThumb'));
    expect(source, contains('ChatVideoPreview'));
    expect(previewSource, contains('VideoPlayerController.networkUrl'));
    expect(source, contains('metadata.originalName.trim()'));
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
    expect(en, contains('"chatListSearchHint": "Search chats"'));
    expect(en, contains('"chatListSearchEmpty": "No chats found"'));
    expect(ru, contains('"chatListPersonalTab": "Личные"'));
    expect(ru, contains('"chatListActivitiesTab": "Активности"'));
    expect(ru, contains('"chatListExcursionsTab": "Экскурсии"'));
    expect(ru, contains('"chatListSearchHint": "Поиск чатов"'));
    expect(ru, contains('"chatListSearchEmpty": "Чаты не найдены"'));
    expect(kk, contains('"chatListPersonalTab": "Жеке"'));
    expect(kk, contains('"chatListActivitiesTab": "Белсенділіктер"'));
    expect(kk, contains('"chatListExcursionsTab": "Экскурсиялар"'));
    expect(kk, contains('"chatListSearchHint": "Чаттарды іздеу"'));
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
}
