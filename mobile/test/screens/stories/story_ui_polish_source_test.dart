import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story feed uses adaptive search hint and semantic sort buttons', () {
    final source = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();

    final searchStart = source.indexOf('class _StoriesSearchBar');
    final sortStart = source.indexOf('class _StoriesSortRow');
    final cardStart = source.indexOf('class _StoryListCard');
    expect(searchStart, isNonNegative);
    expect(sortStart, greaterThan(searchStart));
    expect(cardStart, greaterThan(sortStart));

    final searchSource = source.substring(searchStart, sortStart);
    final sortSource = source.substring(sortStart, cardStart);

    expect(searchSource, contains('LayoutBuilder('));
    expect(source, contains('storySearchCompactHint'));
    expect(sortSource, contains('Semantics('));
    expect(sortSource, contains('button: true'));
    expect(sortSource, contains(r'selected: selectedSort == item.$1'));
    expect(sortSource, contains('InkWell('));
    expect(sortSource, isNot(contains('GestureDetector(')));
  });

  test('story title typography avoids negative letter spacing', () {
    final storiesSource = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    expect(storiesSource, isNot(contains('letterSpacing: -')));
    expect(detailSource, isNot(contains('letterSpacing: -')));
  });

  test('story detail screen does not render bottom navigation bar', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final stateStart = detailSource.indexOf('class _StoryDetailsScreenState');
    final heroStart = detailSource.indexOf('class _StoryHero');
    expect(stateStart, isNonNegative);
    expect(heroStart, greaterThan(stateStart));
    final stateSource = detailSource.substring(stateStart, heroStart);

    expect(stateSource, isNot(contains('bottomNavigationBar:')));
    expect(stateSource, isNot(contains('StoriesBottomNavBar(')));
  });

  test('story detail leaves readable spacing after author card', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final buildStart = detailSource.indexOf(
      'Widget build(BuildContext context)',
    );
    final authorStart = detailSource.indexOf('_AuthorCard(', buildStart);
    final articleStart = detailSource.indexOf('_StoryArticle(', authorStart);
    expect(buildStart, isNonNegative);
    expect(authorStart, greaterThan(buildStart));
    expect(articleStart, greaterThan(authorStart));

    final authorToArticleSource = detailSource.substring(
      authorStart,
      articleStart,
    );

    expect(
      authorToArticleSource,
      contains('SizedBox(height: adaptive.scale(18))'),
    );
    expect(
      authorToArticleSource,
      isNot(contains('SizedBox(height: adaptive.scale(12))')),
    );
  });

  test('story fullscreen gallery avoids stateful paging gesture layers', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final viewerStart = detailSource.indexOf('class _StoryImageGalleryViewer');
    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    expect(viewerStart, isNonNegative);
    expect(relatedStart, greaterThan(viewerStart));
    final viewerSource = detailSource.substring(viewerStart, relatedStart);

    expect(viewerSource, isNot(contains('PageView.builder(')));
    expect(viewerSource, isNot(contains('PageController')));
    expect(viewerSource, isNot(contains('onHorizontalDragEnd')));
    expect(viewerSource, isNot(contains('KeyedSubtree(')));
    expect(viewerSource, contains('_showNextImage'));
    expect(viewerSource, contains('_showPreviousImage'));
  });

  test(
    'story fullscreen gallery keeps image content as the direct image surface',
    () {
      final detailSource = File(
        'lib/screens/stories/story_details_screen.dart',
      ).readAsStringSync();

      final viewerStart = detailSource.indexOf(
        'class _StoryImageGalleryViewer',
      );
      final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
      expect(viewerStart, isNonNegative);
      expect(relatedStart, greaterThan(viewerStart));
      final viewerSource = detailSource.substring(viewerStart, relatedStart);

      expect(viewerSource, contains('Positioned.fill('));
      expect(viewerSource, contains('_StoryImageViewerPage('));
      expect(viewerSource, isNot(contains('Dismissible(')));
      expect(viewerSource, isNot(contains('DismissDirection.down')));
    },
  );

  test('story fullscreen gallery uses a dialog-safe full-screen root', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final viewerStart = detailSource.indexOf('class _StoryImageGalleryViewer');
    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    expect(viewerStart, isNonNegative);
    expect(relatedStart, greaterThan(viewerStart));
    final viewerSource = detailSource.substring(viewerStart, relatedStart);

    expect(viewerSource, contains('SizedBox.expand('));
    expect(viewerSource, contains('ColoredBox('));
    expect(viewerSource, isNot(contains('Scaffold(')));
  });

  test('story fullscreen gallery disables inherited debug text decoration', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final viewerStart = detailSource.indexOf('class _StoryImageGalleryViewer');
    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    expect(viewerStart, isNonNegative);
    expect(relatedStart, greaterThan(viewerStart));
    final viewerSource = detailSource.substring(viewerStart, relatedStart);

    expect(viewerSource, contains('DefaultTextStyle.merge('));
    expect(viewerSource, contains('decoration: TextDecoration.none'));
  });

  test('story fullscreen gallery does not emit diagnostic viewer logs', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    expect(detailSource, isNot(contains('[STORY_VIEWER]')));
  });

  test('story fullscreen gallery animates image changes smoothly', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final viewerStart = detailSource.indexOf('class _StoryImageGalleryViewer');
    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    expect(viewerStart, isNonNegative);
    expect(relatedStart, greaterThan(viewerStart));
    final viewerSource = detailSource.substring(viewerStart, relatedStart);

    expect(viewerSource, contains('AnimatedSwitcher('));
    expect(detailSource, contains('_storyImageViewerTransitionDuration'));
    expect(
      detailSource,
      contains('_storyImageViewerReverseTransitionDuration'),
    );
    expect(detailSource, contains('milliseconds: 320'));
    expect(detailSource, contains('milliseconds: 260'));
    expect(
      detailSource,
      contains('const double _storyImageViewerTransitionSlideDistance = 0.16;'),
    );
    expect(viewerSource, contains('SlideTransition('));
    expect(viewerSource, contains('FadeTransition('));
    expect(viewerSource, isNot(contains('PageView.builder(')));
  });

  test('story draft delete action uses destructive color', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final heroStart = detailSource.indexOf('class _StoryHero');
    final metaStart = detailSource.indexOf('class _StoryArticle');
    expect(heroStart, isNonNegative);
    expect(metaStart, greaterThan(heroStart));
    final heroSource = detailSource.substring(heroStart, metaStart);

    expect(heroSource, contains('storyDeleteAction'));
    expect(heroSource, contains('TextButton.styleFrom('));
    expect(heroSource, contains('foregroundColor: AppColors.destructive'));
  });

  test('story list filter sheet uses summary chips and card-like options', () {
    final storiesSource = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();

    final filterStart = storiesSource.indexOf('class _StoryFiltersSheet');
    final filterEnd = storiesSource.indexOf('class _FilterSheet');
    expect(filterStart, isNonNegative);
    expect(filterEnd, greaterThan(filterStart));
    final filterSource = storiesSource.substring(filterStart, filterEnd);

    expect(filterSource, contains('_ActiveFiltersSummary('));
    expect(filterSource, contains('_FilterCategoryGrid('));
    expect(storiesSource, contains('class _FilterOptionCard'));
    expect(storiesSource, contains('Wrap('));
  });

  test('story list format tag uses primary text color on accent badge', () {
    final storiesSource = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();

    final tagStart = storiesSource.indexOf('class _FormatTag');
    final locationStart = storiesSource.indexOf('class _LocationTag');
    expect(tagStart, isNonNegative);
    expect(locationStart, greaterThan(tagStart));
    final tagSource = storiesSource.substring(tagStart, locationStart);

    expect(tagSource, contains('color: AppColors.accent'));
    expect(tagSource, contains('color: AppColors.textPrimary'));
    expect(tagSource, isNot(contains('Color(0xFF211306)')));
  });

  test('story related view all action uses accent color token', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final sectionStart = detailSource.indexOf('class _RelatedStoriesSection');
    final errorStart = detailSource.indexOf('class _StoryDetailErrorState');
    expect(sectionStart, isNonNegative);
    expect(errorStart, greaterThan(sectionStart));
    final sectionSource = detailSource.substring(sectionStart, errorStart);

    expect(sectionSource, contains('l10n.storyViewAll'));
    expect(sectionSource, contains('color: AppColors.accent'));
    expect(sectionSource, isNot(contains('Color(0xFFFFBD55)')));
  });

  test('legacy story entry points use shared state affordances', () {
    final storyUiSource = File(
      'lib/features/stories/story_ui.dart',
    ).readAsStringSync();
    final storiesSource = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final listCardStart = storiesSource.indexOf('class _StoryListCard');
    final metaChipStart = storiesSource.indexOf('class _StoryMetaChip');
    expect(listCardStart, isNonNegative);
    expect(metaChipStart, greaterThan(listCardStart));
    final listCardSource = storiesSource.substring(
      listCardStart,
      metaChipStart,
    );

    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    final errorStart = detailSource.indexOf('class _StoryDetailErrorState');
    expect(relatedStart, isNonNegative);
    expect(errorStart, greaterThan(relatedStart));
    final relatedSource = detailSource.substring(relatedStart, errorStart);

    expect(storyUiSource, contains('class StoryStateAffordance'));
    expect(storyUiSource, contains('StoryEntryState.seen'));
    expect(storyUiSource, contains('StoryEntryState.expired'));
    expect(storyUiSource, contains('StoryEntryState.pending'));
    expect(storyUiSource, contains('StoryEntryState.hidden'));
    expect(storyUiSource, contains('bool get disablesEntry'));
    expect(listCardSource, contains('StoryStateAffordance.fromPost('));
    expect(relatedSource, contains('StoryStateAffordance.fromPost('));
    expect(listCardSource, contains('enabled: !state.disablesEntry'));
    expect(
      listCardSource,
      contains('onTap: state.disablesEntry ? null : onTap'),
    );
    expect(relatedSource, contains('onTap: state.disablesEntry'));
    expect(relatedSource, contains(': () => onStoryTap(story)'));
  });

  test('story state affordance strings are localized', () {
    for (final locale in ['en', 'ru', 'kk']) {
      final arbSource = File('lib/l10n/app_$locale.arb').readAsStringSync();

      expect(arbSource, contains('storyStateSeenLabel'));
      expect(arbSource, contains('storyStateExpiredLabel'));
      expect(arbSource, contains('storyStatePendingLabel'));
      expect(arbSource, contains('storyStateHiddenLabel'));
    }
  });

  test('story fullscreen gallery uses place-style dialog route', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final openStart = detailSource.indexOf('Future<void> _openStoryImages');
    final startComment = detailSource.indexOf('void _startEditingComment');
    expect(openStart, isNonNegative);
    expect(startComment, greaterThan(openStart));
    final openSource = detailSource.substring(openStart, startComment);

    expect(openSource, contains('showGeneralDialog<int>('));
    expect(openSource, contains('barrierColor: Colors.black'));
    expect(openSource, contains('FadeTransition('));
    expect(openSource, isNot(contains('PageRouteBuilder<int>(')));
  });

  test('story fullscreen gallery uses place-style image sizing', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final pageStart = detailSource.indexOf('class _StoryImageViewerPage');
    final publicStart = detailSource.indexOf('class _StoryPublicImage');
    final privateStart = detailSource.indexOf('class _StoryPrivateImage');
    expect(pageStart, isNonNegative);
    expect(publicStart, greaterThan(pageStart));
    expect(privateStart, greaterThan(publicStart));
    final pageSource = detailSource.substring(pageStart, publicStart);
    final publicSource = detailSource.substring(publicStart, privateStart);

    expect(pageSource, contains('InteractiveViewer('));
    expect(pageSource, contains('Center('));
    expect(pageSource, isNot(contains('SizedBox(')));
    expect(pageSource, contains('minWidth: 900'));
    expect(pageSource, contains('maxWidth: 2200'));
    expect(publicSource, isNot(contains('width: width')));
    expect(publicSource, isNot(contains('height: height')));
  });

  test('story detail keeps draft initial stories off the public endpoint', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final loadStart = detailSource.indexOf('Future<void> _loadDetail');
    final authorStart = detailSource.indexOf('Future<void> _loadAuthorProfile');
    expect(loadStart, isNonNegative);
    expect(authorStart, greaterThan(loadStart));
    final loadSource = detailSource.substring(loadStart, authorStart);

    expect(loadSource, contains('!initialStory.isPublished'));
    expect(loadSource, contains('getPostById('));
    expect(
      loadSource.indexOf('getPostById('),
      lessThan(loadSource.indexOf('getPublicPostBySlug(')),
    );
  });

  test(
    'draft story details hide social sections and block comment submits',
    () {
      final detailSource = File(
        'lib/screens/stories/story_details_screen.dart',
      ).readAsStringSync();

      final buildStart = detailSource.indexOf(
        'Widget build(BuildContext context)',
      );
      final heroStart = detailSource.indexOf('class _StoryHero');
      expect(buildStart, isNonNegative);
      expect(heroStart, greaterThan(buildStart));
      final buildSource = detailSource.substring(buildStart, heroStart);

      expect(buildSource, contains('showSocialSections'));
      expect(buildSource, contains('if (showSocialSections) ...['));
      expect(
        buildSource.indexOf('if (showSocialSections) ...['),
        lessThan(buildSource.indexOf('_CommentComposer(')),
      );
      expect(
        buildSource.indexOf('if (showSocialSections) ...['),
        lessThan(buildSource.indexOf('_CommentsSection(')),
      );
      expect(
        buildSource.indexOf('if (showSocialSections) ...['),
        lessThan(buildSource.indexOf('_RelatedStoriesSection(')),
      );

      final submitStart = detailSource.indexOf('Future<void> _submitComment()');
      final likeStart = detailSource.indexOf(
        'Future<void> _toggleCommentLike',
        submitStart,
      );
      expect(submitStart, isNonNegative);
      expect(likeStart, greaterThan(submitStart));
      final submitSource = detailSource.substring(submitStart, likeStart);

      expect(submitSource, contains('!detail.post.isPublished'));
      expect(
        submitSource.indexOf('!detail.post.isPublished'),
        lessThan(submitSource.indexOf('createComment(')),
      );
      expect(
        submitSource.indexOf('!detail.post.isPublished'),
        lessThan(submitSource.indexOf('updateComment(')),
      );
    },
  );

  test('story fullscreen gallery uses render-safe draft image fallback', () {
    final detailSource = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final openStart = detailSource.indexOf('Future<void> _openStoryImages');
    final viewerStart = detailSource.indexOf('class _StoryImageGalleryViewer');
    final relatedStart = detailSource.indexOf('class _RelatedStoriesSection');
    expect(openStart, isNonNegative);
    expect(viewerStart, greaterThan(openStart));
    expect(relatedStart, greaterThan(viewerStart));
    final openSource = detailSource.substring(openStart, viewerStart);
    final viewerSource = detailSource.substring(viewerStart, relatedStart);

    expect(openSource, contains('!(_detail?.post.isPublished ?? true)'));
    expect(openSource, contains('preferPrivateContent:'));
    expect(viewerSource, contains('preferPrivateContent'));
    expect(viewerSource, contains('if (preferPrivateContent) {'));
    expect(
      viewerSource.indexOf('if (preferPrivateContent)'),
      lessThan(viewerSource.indexOf('if (url != null)')),
    );
    expect(viewerSource, contains('class _StoryDraftImage'));
    expect(viewerSource, contains('_showPrivateFallback'));
    expect(
      viewerSource.indexOf('Image.network('),
      lessThan(viewerSource.indexOf('_StoryPrivateImage(')),
    );
    expect(viewerSource, contains('downloadContent('));
    expect(viewerSource, contains('Image.memory('));
    expect(viewerSource, contains('publicUrl: url'));
  });

  test('my stories status tabs reuse my excursions button colors', () {
    final source = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();

    final tabsStart = source.indexOf('class _MyStoriesStatusTabs');
    final searchStart = source.indexOf('class _StoriesSearchBar');
    expect(tabsStart, isNonNegative);
    expect(searchStart, greaterThan(tabsStart));
    final tabsSource = source.substring(tabsStart, searchStart);

    expect(tabsSource, contains('selectedColor: AppColors.accent'));
    expect(tabsSource, contains('backgroundColor: const Color(0xFF2A1D13)'));
    expect(tabsSource, contains('showCheckmark: false'));
    expect(tabsSource, contains('SingleChildScrollView('));
    expect(tabsSource, contains('scrollDirection: Axis.horizontal'));
    expect(tabsSource, contains('Row('));
    expect(tabsSource, isNot(contains('Wrap(')));
    expect(tabsSource, contains('Colors.white'));
    expect(tabsSource, contains('const Color(0xFFCBB8A3)'));
    expect(tabsSource, isNot(contains('const Color(0xFF211306)')));
    expect(tabsSource, isNot(contains('StoryPalette.textSoft')));
  });

  test(
    'story images expose loading placeholders before network completion',
    () {
      final storyUiSource = File(
        'lib/features/stories/story_ui.dart',
      ).readAsStringSync();
      final rendererSource = File(
        'lib/features/stories/widgets/story_document_renderer.dart',
      ).readAsStringSync();

      expect(storyUiSource, contains('loadingBuilder:'));
      expect(storyUiSource, contains('_StoryImageLoadingPlaceholder'));
      expect(rendererSource, contains('loadingBuilder:'));
      expect(rendererSource, contains('_RenderedImageLoadingPlaceholder'));
    },
  );
}
