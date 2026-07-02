import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/feed/widgets/story_tray_block.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('create story label can render full Russian text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        theme: AppDesignSystem.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryTrayBlock(
            viewerUserId: 'viewer',
            viewerInitials: 'ME',
            onCreateStory: () {},
            stories: const [],
          ),
        ),
      ),
    );

    final labelFinder = find.text('Ваша история');
    final avatarFinder = find.byKey(
      const ValueKey('open-feed-create-story-avatar'),
    );
    final avatarVisualFinder = find.byKey(
      const ValueKey('open-feed-create-story-visual'),
    );

    expect(labelFinder, findsOneWidget);
    expect(avatarFinder, findsOneWidget);
    expect(avatarVisualFinder, findsOneWidget);
    expect(tester.widget<Text>(labelFinder).maxLines, 1);
    expect(
      tester.renderObject<RenderParagraph>(labelFinder).didExceedMaxLines,
      isFalse,
    );

    final visibleLabelRect = _visibleTextPaintRect(tester, labelFinder);
    final avatarRect = tester.getRect(avatarFinder);
    final avatarVisualRect = tester.getRect(avatarVisualFinder);
    final itemRect = tester.getRect(
      find.byKey(const ValueKey('open-feed-create-story')),
    );
    final plusRect = tester.getRect(
      find.byKey(const ValueKey('open-feed-create-story-plus')),
    );

    final trayRect = tester.getRect(
      find.byKey(const ValueKey('feed-stories-circle-tray')),
    );

    expect(itemRect.left, closeTo(trayRect.left, 1));
    expect(visibleLabelRect.left, closeTo(trayRect.left, 1));
    expect(visibleLabelRect.center.dx, closeTo(itemRect.center.dx, 1));
    expect(
      (avatarRect.center.dx - visibleLabelRect.center.dx).abs(),
      lessThan(1),
    );
    expect(avatarVisualRect.width, closeTo(avatarRect.width, 1));
    expect(avatarVisualRect.center.dx, closeTo(itemRect.center.dx, 1));
    expect(avatarRect.center.dx, closeTo(itemRect.center.dx, 1));
    expect(avatarRect.center.dx, closeTo(avatarVisualRect.center.dx, 1));
    expect(plusRect.right, lessThanOrEqualTo(avatarRect.right + 1));
    expect(plusRect.bottom, lessThanOrEqualTo(avatarRect.bottom + 1));
    expect(plusRect.right, lessThanOrEqualTo(itemRect.right + 1));
    expect(plusRect.bottom, lessThanOrEqualTo(itemRect.bottom + 1));
    expect(plusRect.center.dx, greaterThan(visibleLabelRect.center.dx));
    expect(plusRect.left, greaterThan(avatarRect.center.dx));
  });

  testWidgets('create story avatar stays centered under label on home layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        theme: AppDesignSystem.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StoryTrayBlock(
                  viewerUserId: 'viewer',
                  viewerInitials: 'ME',
                  onCreateStory: () {},
                  stories: const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final labelRect = _visibleTextPaintRect(tester, find.text('Ваша история'));
    final avatarRect = tester.getRect(
      find.byKey(const ValueKey('open-feed-create-story-avatar')),
    );
    final avatarVisualRect = tester.getRect(
      find.byKey(const ValueKey('open-feed-create-story-visual')),
    );

    expect(avatarRect.center.dx, closeTo(labelRect.center.dx, 1));
    expect(avatarVisualRect.center.dx, closeTo(labelRect.center.dx, 1));
  });

  test('story tray item centers avatar and label inside its slot', () {
    final source = File(
      'lib/features/feed/widgets/story_tray_block.dart',
    ).readAsStringSync();

    final scaffoldStart = source.indexOf('class _StoryTrayScaffold');
    final circleStart = source.indexOf('enum _StoryCircleState');
    expect(scaffoldStart, isNonNegative);
    expect(circleStart, greaterThan(scaffoldStart));

    final scaffoldSource = source.substring(scaffoldStart, circleStart);

    expect(scaffoldSource, contains('Align('));
    expect(scaffoldSource, contains('alignment: Alignment.topCenter'));
    expect(scaffoldSource, contains('SizedBox('));
    expect(scaffoldSource, contains('width: constraints.maxWidth'));
    expect(scaffoldSource, contains('child: Center('));
    expect(scaffoldSource, contains('child: Text('));
    expect(scaffoldSource, contains('CrossAxisAlignment.center'));
    expect(scaffoldSource, isNot(contains('width: double.infinity')));
    expect(scaffoldSource, isNot(contains('Transform.translate')));
    expect(scaffoldSource, isNot(contains('labelInkCenterDelta')));
    expect(scaffoldSource, isNot(contains('CrossAxisAlignment.start')));
  });

  testWidgets(
    'own stories stay inside your story circle and plus opens camera',
    (tester) async {
      var createCount = 0;
      StoryVm? openedStory;
      int? openedIndex;
      List<StoryVm>? openedStories;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoryTrayBlock(
              viewerUserId: 'viewer',
              viewerInitials: 'ME',
              onCreateStory: () => createCount += 1,
              onStoryOpen: (story, stories, index) {
                openedStory = story;
                openedStories = stories;
                openedIndex = index;
              },
              stories: [
                _story('own-unseen', authorUserId: 'viewer'),
                _story('own-seen', authorUserId: 'viewer', seenByViewer: true),
                _story('other-story', authorUserId: 'other'),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('open-feed-tray-story-own-unseen')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('open-feed-tray-story-own-seen')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('open-feed-tray-story-other-story')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('feed-tray-story-seen-own-seen')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('open-feed-create-story-avatar')),
      );
      await tester.pump();

      expect(createCount, 0);
      expect(openedStory?.id, 'own-unseen');
      expect(openedIndex, 0);
      expect(openedStories?.map((story) => story.id), [
        'own-unseen',
        'own-seen',
      ]);

      await tester.tap(
        find.byKey(const ValueKey('open-feed-create-story-plus')),
      );
      await tester.pump();

      expect(createCount, 1);
    },
  );

  testWidgets('groups other stories by author and hides inactive authors', (
    tester,
  ) async {
    StoryVm? openedStory;
    List<StoryVm>? openedStories;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryTrayBlock(
            viewerUserId: 'viewer',
            onCreateStory: () {},
            onStoryOpen: (story, stories, index) {
              openedStory = story;
              openedStories = stories;
            },
            stories: [
              _story(
                'author-old',
                authorUserId: 'author',
                createdAt: DateTime.utc(2026, 1, 1),
              ),
              _story(
                'author-new',
                authorUserId: 'author',
                createdAt: DateTime.utc(2026, 1, 2),
              ),
              _story(
                'expired',
                authorUserId: 'expired-author',
                expiresAt: DateTime.utc(2020),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('open-feed-tray-story-author-new')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-feed-tray-story-author-old')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('open-feed-tray-story-expired')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('open-feed-tray-story-author-new')),
    );
    await tester.pump();

    expect(openedStory?.id, 'author-new');
    expect(openedStories?.map((story) => story.id), [
      'author-new',
      'author-old',
    ]);
  });

  testWidgets('orders unseen system stories before seen story circles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryTrayBlock(
            viewerUserId: 'viewer',
            onCreateStory: () {},
            stories: [
              _story(
                'seen-friend',
                authorUserId: 'friend',
                nickname: 'Friend',
                seenByViewer: true,
                views: 900,
              ),
              _story(
                'unseen-friend',
                authorUserId: 'popular',
                nickname: 'Popular',
                views: 1,
              ),
              _story(
                'system-unseen',
                authorUserId: 'system',
                nickname: 'Inflap',
                views: 1,
              ),
            ],
          ),
        ),
      ),
    );

    final systemX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-system-unseen')),
        )
        .dx;
    final unseenX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-unseen-friend')),
        )
        .dx;
    final seenX = tester
        .getTopLeft(
          find.byKey(const ValueKey('open-feed-tray-story-seen-friend')),
        )
        .dx;

    expect(systemX, lessThan(unseenX));
    expect(unseenX, lessThan(seenX));
  });
}

Rect _visibleTextPaintRect(WidgetTester tester, Finder finder) {
  final element = tester.element(finder);
  final widget = tester.widget<Text>(finder);
  final renderObject = tester.renderObject<RenderParagraph>(finder);
  final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
  final style = widget.style ?? DefaultTextStyle.of(element).style;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: widget.maxLines,
    textAlign: widget.textAlign ?? TextAlign.start,
    textDirection: Directionality.of(element),
    textScaler: MediaQuery.textScalerOf(element),
  )..layout(maxWidth: renderObject.size.width);
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );

  if (boxes.isEmpty) {
    return tester.getRect(finder);
  }

  var left = boxes.first.left;
  var top = boxes.first.top;
  var right = boxes.first.right;
  var bottom = boxes.first.bottom;
  for (final box in boxes.skip(1)) {
    if (box.left < left) left = box.left;
    if (box.top < top) top = box.top;
    if (box.right > right) right = box.right;
    if (box.bottom > bottom) bottom = box.bottom;
  }

  final widgetTopLeft = tester.getTopLeft(finder);
  return Rect.fromLTRB(
    widgetTopLeft.dx + left,
    widgetTopLeft.dy + top,
    widgetTopLeft.dx + right,
    widgetTopLeft.dy + bottom,
  );
}

StoryVm _story(
  String id, {
  required String authorUserId,
  bool seenByViewer = false,
  String? nickname,
  DateTime? createdAt,
  DateTime? expiresAt,
  int views = 1,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1);
  return StoryVm(
    id: id,
    slug: id,
    title: id,
    excerpt: 'Story $id',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const ['travel'],
    stats: StoryStatsVm(views: views, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: authorUserId,
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: nickname ?? authorUserId,
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    expiresAt: expiresAt ?? DateTime.utc(2027),
    shareUrl: 'https://inflap.test/stories/$id',
    createdAt: now,
    updatedAt: now,
  );
}
