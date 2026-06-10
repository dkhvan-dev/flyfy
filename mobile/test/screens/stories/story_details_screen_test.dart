import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/file_api.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/stories/story_details_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('StoryDetailsScreen', () {
    testWidgets('draft story images open through render-safe story media', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'draft-story',
            fileApi: _FakeStoryFileApi(),
            initialStory: _storyVm(
              status: 'DRAFT',
              contentBlocks: const [
                {
                  'id': 'image-1',
                  'type': 'image',
                  'image': {'fileId': 'story-inline-file-1'},
                },
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final image = find.byKey(
        const ValueKey('story-document-image-story-inline-file-1-0'),
      );
      await tester.ensureVisible(image);
      await tester.pump();
      await tester.tap(image);
      await tester.pump();

      final fullscreenImages = tester.widgetList<Image>(find.byType(Image));
      expect(
        fullscreenImages.any(
          (image) =>
              image.fit == BoxFit.contain &&
              image.width == null &&
              image.height == null,
        ),
        isTrue,
      );
      expect(find.byType(FutureBuilder<FileContentVm>), findsNothing);
    });

    testWidgets('draft story hides comments and related stories sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'draft-story',
            fileApi: _FakeStoryFileApi(),
            initialStory: _storyVm(status: 'DRAFT'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Leave a thoughtful comment'), findsNothing);
      expect(
        find.text('No comments yet. Start the conversation.'),
        findsNothing,
      );
      expect(find.text('Related Stories'), findsNothing);
      expect(find.text('No related stories yet'), findsNothing);
    });

    testWidgets(
      'fullscreen story gallery supports swipe navigation and close',
      (tester) async {
        await tester.pumpWidget(
          _app(
            StoryDetailsScreen(
              slug: 'draft-story',
              fileApi: _FakeStoryFileApi(),
              initialStory: _storyVm(
                status: 'DRAFT',
                contentBlocks: const [
                  {
                    'id': 'gallery-1',
                    'type': 'gallery',
                    'gallery': {
                      'images': [
                        {'fileId': 'story-inline-file-1'},
                        {'fileId': 'story-inline-file-2'},
                      ],
                    },
                  },
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        final firstImage = find.byKey(
          const ValueKey('story-document-image-story-inline-file-1-0'),
        );
        await tester.ensureVisible(firstImage);
        await tester.pump();
        await tester.tap(firstImage);
        await tester.pump();

        expect(find.text('1/2'), findsOneWidget);

        await tester.drag(find.text('1/2'), const Offset(-260, 0));
        await tester.pump();

        expect(find.text('2/2'), findsOneWidget);

        await tester.drag(find.text('2/2'), const Offset(0, 280));
        await tester.pumpAndSettle();

        expect(find.text('2/2'), findsNothing);
        expect(firstImage, findsOneWidget);
      },
    );
  });
}

Widget _app(Widget child) {
  return ChangeNotifierProvider<SessionProvider>(
    create: (_) => SessionProvider(),
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _FakeStoryFileApi extends FileApi {
  @override
  Future<FileContentVm> downloadContent(String fileId) async {
    return FileContentVm(
      bytes: Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
        ),
      ),
      contentType: 'image/png',
    );
  }
}

StoryVm _storyVm({
  String id = 'story-1',
  String title = 'Draft story',
  String status = 'DRAFT',
  List<Map<String, dynamic>> contentBlocks = const [],
}) {
  return StoryVm(
    id: id,
    slug: id,
    title: title,
    excerpt: '',
    content: '',
    format: 'STORY',
    contentBlocks: contentBlocks,
    revision: 1,
    category: 'JOURNAL',
    status: status,
    coverFileId: null,
    placeName: 'Almaty',
    placeCountryCode: 'KZ',
    placeCityId: 'almaty',
    tags: const ['mountains'],
    stats: StoryStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: '',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 8),
  );
}
