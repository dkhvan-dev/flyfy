import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/network/file_api.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../core/ui/app_inline_sort_row.dart';
import '../../../core/ui/app_list_search_field.dart';
import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/reference/app_location_label_resolver.dart';
import '../data/feed_api.dart';
import '../models/feed_block_vm.dart';
import 'community_display_helpers.dart';
import 'community_location_text.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class MySubscriptionsBlock extends StatelessWidget {
  const MySubscriptionsBlock({
    super.key,
    required this.subscriptions,
    this.onCommunityOpen,
    this.onPersonOpen,
    this.onOpenAll,
    this.locationLabelResolver,
  });

  final FeedSubscriptionsVm subscriptions;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedPersonVm>? onPersonOpen;
  final VoidCallback? onOpenAll;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final communities = subscriptions.communities.take(8).toList();
    final people = subscriptions.people.take(8).toList();

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: DecoratedBox(
        key: const ValueKey('my-subscriptions-block'),
        decoration: AppBoxDecoration(
          color: colors.surface,
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(color: colors.borderPrimary),
          boxShadow: _v2DarkShadow(context, colors),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.feedMySubscriptionsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.feedMySubscriptionsSummary(
                            subscriptions.communities.length,
                            subscriptions.people.length,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('open-my-subscriptions'),
                    tooltip: l10n.feedMySubscriptionsViewAll,
                    onPressed: onOpenAll,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.18),
                      foregroundColor: colors.primary,
                      minimumSize: const Size.square(40),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth * 0.78).clamp(
                    220.0,
                    300.0,
                  );
                  return SingleChildScrollView(
                    key: const ValueKey('my-subscriptions-rail'),
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (communities.isNotEmpty)
                          _SubscriptionsRow(
                            key: const ValueKey('my-subscriptions-row-0'),
                            itemWidth: itemWidth,
                            items: [
                              for (final community in communities)
                                _SubscriptionTileData.community(community),
                            ],
                            onCommunityOpen: onCommunityOpen,
                            onPersonOpen: onPersonOpen,
                            locationLabelResolver: locationLabelResolver,
                          ),
                        if (communities.isNotEmpty && people.isNotEmpty)
                          const SizedBox(height: 10),
                        if (people.isNotEmpty)
                          _SubscriptionsRow(
                            key: const ValueKey('my-subscriptions-row-1'),
                            itemWidth: itemWidth,
                            items: [
                              for (final person in people)
                                _SubscriptionTileData.person(person),
                            ],
                            onCommunityOpen: onCommunityOpen,
                            onPersonOpen: onPersonOpen,
                            locationLabelResolver: locationLabelResolver,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MySubscriptionsSheet extends StatefulWidget {
  const MySubscriptionsSheet({
    super.key,
    required this.subscriptions,
    this.onCommunityOpen,
    this.onPersonOpen,
    this.feedApi,
    this.locationLabelResolver,
    this.currentCountryCode,
    this.currentCityId,
    this.currentCityName,
  });

  final FeedSubscriptionsVm subscriptions;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedPersonVm>? onPersonOpen;
  final FeedApi? feedApi;
  final AppLocationLabelResolver? locationLabelResolver;
  final String? currentCountryCode;
  final String? currentCityId;
  final String? currentCityName;

  @override
  State<MySubscriptionsSheet> createState() => _MySubscriptionsSheetState();
}

class _MySubscriptionsSheetState extends State<MySubscriptionsSheet> {
  final _searchController = TextEditingController();
  final FeedApi _defaultFeedApi = FeedApi();
  var _tabIndex = 0;
  var _communityFilter = _CommunityFilter.all;
  var _communityTopic = '';
  var _communitySort = _CommunitySort.relevant;
  var _peopleFilter = _PeopleFilter.all;
  var _peopleSort = _PeopleSort.relevant;
  late List<FeedCommunityVm> _communities;
  late List<FeedPersonVm> _people;
  Set<String> _updatingCommunityIds = const {};

  FeedApi get _feedApi => widget.feedApi ?? _defaultFeedApi;

  @override
  void initState() {
    super.initState();
    _communities = widget.subscriptions.communities.toList(growable: true);
    _people = widget.subscriptions.people.toList(growable: false);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant MySubscriptionsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subscriptions != widget.subscriptions) {
      _communities = widget.subscriptions.communities.toList(growable: true);
      _people = widget.subscriptions.people.toList(growable: false);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _activeFilterCount {
    if (_tabIndex == 0) {
      return [
        _communityFilter != _CommunityFilter.all,
        _communityTopic.trim().isNotEmpty,
      ].where((active) => active).length;
    }
    return _peopleFilter == _PeopleFilter.all ? 0 : 1;
  }

  int get _visibleResultCount {
    final query = _searchController.text.trim().toLowerCase();
    return _tabIndex == 0
        ? _filteredCommunities(query).length
        : _filteredPeople(query).length;
  }

  Future<void> _openFilters() async {
    final query = _searchController.text.trim().toLowerCase();
    final colors = AppDesignSystem.colorsFor(context);
    final result = await showAppModalBottomSheet<_MySubscriptionsFiltersResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.transparent,
      barrierColor: colors.scrim,
      builder: (context) {
        return Theme(
          data: AppDesignSystem.themeFor(context),
          child: _MySubscriptionsFiltersSheet(
            tabIndex: _tabIndex,
            communityFilter: _communityFilter,
            communityTopic: _communityTopic,
            peopleFilter: _peopleFilter,
            communityTopicOptions: _communityTopicOptions(query),
            communityResultCount: (filter, topic) =>
                _communityResultCountFor(query, filter: filter, topic: topic),
            peopleResultCount: (filter) =>
                _peopleResultCountFor(query, filter: filter),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _communityFilter = result.communityFilter;
      _communityTopic = result.communityTopic;
      _peopleFilter = result.peopleFilter;
    });
  }

  Future<void> _toggleCommunityFollow(FeedCommunityVm community) async {
    final communityId = community.id.trim();
    if (communityId.isEmpty || _updatingCommunityIds.contains(communityId)) {
      return;
    }
    setState(() {
      _updatingCommunityIds = {..._updatingCommunityIds, communityId};
    });

    try {
      final updatedCommunity = community.followedByViewer
          ? await _feedApi.unfollowCommunity(communityId)
          : await _feedApi.followCommunity(communityId);
      final mergedCommunity = _mergeCommunityForSubscriptions(
        community,
        updatedCommunity,
      );
      if (!community.followedByViewer) {
        _trackCommunitySubscribe(mergedCommunity);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _communities = [
          for (final current in _communities)
            if (current.id == communityId)
              _mergeCommunityForSubscriptions(current, updatedCommunity)
            else
              current,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.feedCommunityActionFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCommunityIds = {
            for (final id in _updatingCommunityIds)
              if (id != communityId) id,
          };
        });
      }
    }
  }

  void _trackCommunitySubscribe(FeedCommunityVm community) {
    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }
    final rank = _communities.indexWhere((item) => item.id == community.id);
    unawaited(
      _feedApi.trackFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: FeedEventTypes.subscribe,
          surface: 'content',
          tab: 'following',
          blockId: 'subscriptions:mine',
          blockType: 'my_subscriptions',
          communityId: communityId,
          rank: rank < 0 ? 0 : rank,
          occurredAt: DateTime.now().toUtc(),
          metadata: {
            'action': FeedEventTypes.subscribe,
            'entityType': 'community',
            'entityId': communityId,
            if ((community.topic ?? '').trim().isNotEmpty)
              'topic': community.topic!.trim(),
            if ((community.countryCode ?? '').trim().isNotEmpty)
              'countryCode': community.countryCode!.trim(),
            if ((community.cityId ?? '').trim().isNotEmpty)
              'cityId': community.cityId!.trim(),
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final query = _searchController.text.trim().toLowerCase();
    final communities = _filteredCommunities(query);
    final people = _filteredPeople(query);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: DefaultTabController(
        length: 2,
        initialIndex: _tabIndex,
        child: SafeArea(
          child: DecoratedBox(
            key: const ValueKey('my-subscriptions-sheet'),
            decoration: AppBoxDecoration(color: colors.background),
            child: Padding(
              padding: AppEdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: AppBoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.36),
                      borderRadius: AppBorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MySubscriptionsSheetSummaryCard(
                    communitiesCount: _communities.length,
                    peopleCount: _people.length,
                  ),
                  const SizedBox(height: 12),
                  _MySubscriptionsSegmentedTabs(
                    selectedIndex: _tabIndex,
                    visibleResultCount: _visibleResultCount,
                    onSelected: (index) => setState(() => _tabIndex = index),
                  ),
                  const SizedBox(height: 12),
                  AppListSearchField(
                    textFieldKey: const ValueKey('my-subscriptions-search'),
                    controller: _searchController,
                    hintText: l10n.feedMySubscriptionsSearchHint,
                    filterTooltip: l10n.communityDiscoveryFiltersTitle,
                    activeFilterCount: _activeFilterCount,
                    showClearButton: true,
                    onClear: _searchController.clear,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onFilterTap: _openFilters,
                  ),
                  const SizedBox(height: 8),
                  KeyedSubtree(
                    key: const ValueKey('my-subscriptions-inline-sort'),
                    child: _MySubscriptionsInlineSortRow(
                      tabIndex: _tabIndex,
                      communitySort: _communitySort,
                      peopleSort: _peopleSort,
                      onCommunitySortSelected: (sort) =>
                          setState(() => _communitySort = sort),
                      onPeopleSortSelected: (sort) =>
                          setState(() => _peopleSort = sort),
                    ),
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(height: 10),
                    _ActiveSubscriptionFilterPill(
                      label: _activeFilterLabel(l10n),
                      count: _visibleResultCount,
                      onClear: () {
                        setState(() {
                          if (_tabIndex == 0) {
                            _communityFilter = _CommunityFilter.all;
                            _communityTopic = '';
                          } else {
                            _peopleFilter = _PeopleFilter.all;
                          }
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tabIndex == 0
                        ? _CommunitySubscriptionList(
                            communities: communities,
                            onCommunityOpen: widget.onCommunityOpen,
                            onCommunityToggle: _toggleCommunityFollow,
                            updatingCommunityIds: _updatingCommunityIds,
                            locationLabelResolver: widget.locationLabelResolver,
                          )
                        : _PeopleSubscriptionList(
                            people: people,
                            onPersonOpen: widget.onPersonOpen,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FeedCommunityVm> _filteredCommunities(String query) {
    final communities = [
      for (final community in _communities)
        if (_matchesCommunityFilter(community) &&
            _matchesCommunityTopic(community, _communityTopic) &&
            _matchesCommunityQuery(community, query))
          community,
    ];
    return _sortCommunities(communities);
  }

  List<FeedPersonVm> _filteredPeople(String query) {
    final people = [
      for (final person in _people)
        if (_matchesPeopleFilter(person) && _matchesPersonQuery(person, query))
          person,
    ];
    return _sortPeople(people);
  }

  bool _matchesCommunityFilter(FeedCommunityVm community) {
    return _matchesCommunityFilterValue(community, _communityFilter);
  }

  bool _matchesCommunityFilterValue(
    FeedCommunityVm community,
    _CommunityFilter filter,
  ) {
    return switch (filter) {
      _CommunityFilter.all => true,
      _CommunityFilter.currentCity => _matchesCurrentCity(community),
      _CommunityFilter.active => community.postCount > 0,
      _CommunityFilter.popular => community.membersCount > 0,
    };
  }

  bool _matchesPeopleFilter(FeedPersonVm person) {
    return _matchesPeopleFilterValue(person, _peopleFilter);
  }

  bool _matchesPeopleFilterValue(FeedPersonVm person, _PeopleFilter filter) {
    return switch (filter) {
      _PeopleFilter.all => true,
      _PeopleFilter.friends =>
        person.relationship == FeedPersonRelationship.friend,
      _PeopleFilter.following =>
        person.relationship == FeedPersonRelationship.following,
    };
  }

  bool _matchesCommunityTopic(FeedCommunityVm community, String topic) {
    final normalizedTopic = _canonicalCommunityTopic(topic);
    if (normalizedTopic.isEmpty) {
      return true;
    }
    return _canonicalCommunityTopic(community.topic) == normalizedTopic;
  }

  bool _matchesCurrentCity(FeedCommunityVm community) {
    final currentCityId = _normalizeLocationKey(widget.currentCityId);
    final currentCityName = _normalizeLocationKey(widget.currentCityName);
    final currentCountryCode = _normalizeLocationKey(widget.currentCountryCode);
    final communityCityId = _normalizeLocationKey(community.cityId);
    final communityCityName = _normalizeLocationKey(community.cityName);
    final communityCountryCode = _normalizeLocationKey(community.countryCode);

    final cityMatches =
        (currentCityId != null &&
            communityCityId != null &&
            currentCityId == communityCityId) ||
        (currentCityName != null &&
            communityCityName != null &&
            currentCityName == communityCityName);
    if (!cityMatches) {
      return false;
    }
    if (currentCountryCode == null || communityCountryCode == null) {
      return true;
    }
    return currentCountryCode == communityCountryCode;
  }

  int _communityResultCountFor(
    String query, {
    required _CommunityFilter filter,
    required String topic,
  }) {
    return _communities
        .where(
          (community) =>
              _matchesCommunityFilterValue(community, filter) &&
              _matchesCommunityTopic(community, topic) &&
              _matchesCommunityQuery(community, query),
        )
        .length;
  }

  int _peopleResultCountFor(String query, {required _PeopleFilter filter}) {
    return _people
        .where(
          (person) =>
              _matchesPeopleFilterValue(person, filter) &&
              _matchesPersonQuery(person, query),
        )
        .length;
  }

  List<String> _communityTopicOptions(String query) {
    final discovered = <String>{''};
    for (final community in _communities) {
      if (!_matchesCommunityQuery(community, query)) {
        continue;
      }
      final topic = _canonicalCommunityTopic(community.topic);
      if (topic.isNotEmpty) {
        discovered.add(topic);
      }
    }
    final ordered = <String>[
      for (final topic in feedCommunityTopicFilterValues)
        if (discovered.contains(_canonicalCommunityTopic(topic)))
          _canonicalCommunityTopic(topic),
    ];
    final customTopics =
        discovered.where((topic) => !ordered.contains(topic)).toList()..sort();
    return [...ordered, ...customTopics];
  }

  List<FeedCommunityVm> _sortCommunities(List<FeedCommunityVm> communities) {
    if (_communitySort == _CommunitySort.relevant) {
      return communities;
    }
    final sorted = communities.toList(growable: false);
    sorted.sort((left, right) {
      return switch (_communitySort) {
        _CommunitySort.relevant => 0,
        _CommunitySort.active =>
          _compareDesc(left.postCount, right.postCount) ??
              _compareDesc(left.membersCount, right.membersCount) ??
              _compareCommunityTitle(left, right),
        _CommunitySort.popular =>
          _compareDesc(left.membersCount, right.membersCount) ??
              _compareDesc(left.postCount, right.postCount) ??
              _compareCommunityTitle(left, right),
        _CommunitySort.name => _compareCommunityTitle(left, right),
      };
    });
    return sorted;
  }

  List<FeedPersonVm> _sortPeople(List<FeedPersonVm> people) {
    if (_peopleSort == _PeopleSort.relevant) {
      return people;
    }
    final sorted = people.toList(growable: false);
    sorted.sort((left, right) {
      return switch (_peopleSort) {
        _PeopleSort.relevant => 0,
        _PeopleSort.online =>
          _compareDesc(left.isOnline ? 1 : 0, right.isOnline ? 1 : 0) ??
              _comparePersonName(left, right),
        _PeopleSort.name => _comparePersonName(left, right),
      };
    });
    return sorted;
  }

  String _activeFilterLabel(AppLocalizations l10n) {
    final labels = <String>[];
    if (_tabIndex == 0) {
      if (_communityFilter != _CommunityFilter.all) {
        labels.add(_communityFilterLabel(_communityFilter, l10n));
      }
      if (_communityTopic.trim().isNotEmpty) {
        labels.add(feedCommunityTopicLabel(_communityTopic, l10n));
      }
      return labels.join(' · ');
    }
    if (_peopleFilter != _PeopleFilter.all) {
      labels.add(_peopleFilterLabel(_peopleFilter, l10n));
    }
    return labels.join(' · ');
  }
}

class _MySubscriptionsSheetSummaryCard extends StatelessWidget {
  const _MySubscriptionsSheetSummaryCard({
    required this.communitiesCount,
    required this.peopleCount,
  });

  final int communitiesCount;
  final int peopleCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      key: const ValueKey('my-subscriptions-sheet-summary'),
      decoration: AppBoxDecoration(
        borderRadius: AppBorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary.withValues(alpha: 0.22), colors.surface],
        ),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: _v2DarkShadow(
          context,
          colors,
          alpha: 0.18,
          blurRadius: 24,
          dy: 14,
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(Icons.bookmarks_rounded, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedMySubscriptionsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.feedMySubscriptionsSheetSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryBadge(
                        icon: Icons.groups_rounded,
                        label: l10n.feedMySubscriptionsCommunitiesTab,
                        value: communitiesCount,
                      ),
                      _SummaryBadge(
                        icon: Icons.person_rounded,
                        label: l10n.feedMySubscriptionsPeopleTab,
                        value: peopleCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.primary),
            const SizedBox(width: 5),
            Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MySubscriptionsSegmentedTabs extends StatelessWidget {
  const _MySubscriptionsSegmentedTabs({
    required this.selectedIndex,
    required this.visibleResultCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int visibleResultCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _SegmentedTabButton(
                key: const ValueKey('my-subscriptions-tab-communities'),
                label: l10n.feedMySubscriptionsCommunitiesTab,
                icon: Icons.groups_rounded,
                count: selectedIndex == 0 ? visibleResultCount : null,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _SegmentedTabButton(
                key: const ValueKey('my-subscriptions-tab-people'),
                label: l10n.feedMySubscriptionsPeopleTab,
                icon: Icons.person_rounded,
                count: selectedIndex == 1 ? visibleResultCount : null,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabButton extends StatelessWidget {
  const _SegmentedTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Material(
      color: selected ? colors.primary : colors.transparent,
      borderRadius: AppBorderRadius.circular(14),
      child: InkWell(
        borderRadius: AppBorderRadius.circular(14),
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  count == null ? label : '$label · $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSubscriptionFilterPill extends StatelessWidget {
  const _ActiveSubscriptionFilterPill({
    required this.label,
    required this.count,
    required this.onClear,
  });

  final String label;
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: colors.primary.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.circular(999),
        child: InkWell(
          borderRadius: AppBorderRadius.circular(999),
          onTap: onClear,
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(10, 7, 8, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  '$label · $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.close_rounded, size: 16, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MySubscriptionsInlineSortRow extends StatelessWidget {
  const _MySubscriptionsInlineSortRow({
    required this.tabIndex,
    required this.communitySort,
    required this.peopleSort,
    required this.onCommunitySortSelected,
    required this.onPeopleSortSelected,
  });

  final int tabIndex;
  final _CommunitySort communitySort;
  final _PeopleSort peopleSort;
  final ValueChanged<_CommunitySort> onCommunitySortSelected;
  final ValueChanged<_PeopleSort> onPeopleSortSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (tabIndex == 1) {
      return AppInlineSortRow<_PeopleSort>(
        label: l10n.activitiesSortLabel,
        options: [
          for (final sort in _PeopleSort.values)
            AppInlineSortOption(
              value: sort,
              label: _peopleSortLabel(sort, l10n),
            ),
        ],
        selectedValue: peopleSort,
        isAscending: peopleSort == _PeopleSort.name,
        onSelected: onPeopleSortSelected,
        letterSpacing: 0,
        fontSize: 12,
        iconSize: 14,
        labelToOptionsGap: 12,
        optionGap: 16,
        verticalPadding: 6,
        minItemHeight: 36,
      );
    }

    return AppInlineSortRow<_CommunitySort>(
      label: l10n.activitiesSortLabel,
      options: [
        for (final sort in _CommunitySort.values)
          AppInlineSortOption(
            value: sort,
            label: _communitySortLabel(sort, l10n),
          ),
      ],
      selectedValue: communitySort,
      isAscending: communitySort == _CommunitySort.name,
      onSelected: onCommunitySortSelected,
      letterSpacing: 0,
      fontSize: 12,
      iconSize: 14,
      labelToOptionsGap: 12,
      optionGap: 16,
      verticalPadding: 6,
      minItemHeight: 36,
    );
  }
}

class _SubscriptionsRow extends StatelessWidget {
  const _SubscriptionsRow({
    super.key,
    required this.itemWidth,
    required this.items,
    this.onCommunityOpen,
    this.onPersonOpen,
    this.locationLabelResolver,
  });

  final double itemWidth;
  final List<_SubscriptionTileData> items;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedPersonVm>? onPersonOpen;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          SizedBox(
            width: itemWidth,
            child: _SubscriptionPill(
              data: items[index],
              onCommunityOpen: onCommunityOpen,
              onPersonOpen: onPersonOpen,
              locationLabelResolver: locationLabelResolver,
            ),
          ),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _SubscriptionPill extends StatelessWidget {
  const _SubscriptionPill({
    required this.data,
    this.onCommunityOpen,
    this.onPersonOpen,
    this.locationLabelResolver,
  });

  final _SubscriptionTileData data;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedPersonVm>? onPersonOpen;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    final title = data.title(context);
    final subtitle = data.subtitle(context);
    final avatarUrl = data.avatarUrl;
    final community = data.community;
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return Material(
      color: colors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.circular(8),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.42),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: data.openKey,
        borderRadius: AppBorderRadius.circular(8),
        onTap: () {
          final community = data.community;
          if (community != null) {
            onCommunityOpen?.call(community);
            return;
          }
          final person = data.person;
          if (person != null) {
            onPersonOpen?.call(person);
          }
        },
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _SubscriptionAvatar(
                title: title,
                imageUrl: avatarUrl,
                icon: data.community == null
                    ? Icons.person_rounded
                    : Icons.groups_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (community != null) ...[
                      const SizedBox(height: 2),
                      FeedCommunityLocationText(
                        community: community,
                        resolver: locationLabelResolver,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l10n.feedCommunityMembersLabel(
                          _formatCount(community.membersCount),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          height: 1.14,
                        ),
                      ),
                    ] else if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunitySubscriptionList extends StatelessWidget {
  const _CommunitySubscriptionList({
    required this.communities,
    this.onCommunityOpen,
    required this.onCommunityToggle,
    required this.updatingCommunityIds,
    this.locationLabelResolver,
  });

  final List<FeedCommunityVm> communities;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm> onCommunityToggle;
  final Set<String> updatingCommunityIds;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    if (communities.isEmpty) {
      return _SheetEmptyState(message: l10n.feedMySubscriptionsEmptyMessage);
    }

    return ListView.separated(
      itemCount: communities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final community = communities[index];
        return _SheetListTile(
          key: ValueKey('my-subscriptions-sheet-community-${community.id}'),
          title: feedCommunityDisplayTitle(community, l10n),
          subtitle: '',
          imageUrl: _avatarUrl(community.avatarFileId),
          icon: Icons.groups_rounded,
          locationWidget: FeedCommunityLocationText(
            community: community,
            includeCountry: true,
            resolver: locationLabelResolver,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.secondary,
              height: 1.14,
            ),
          ),
          metaText: community.membersCount > 0
              ? l10n.feedCommunityMembersLabel(
                  _formatCount(community.membersCount),
                )
              : '',
          trailing: _CommunitySubscriptionToggleButton(
            community: community,
            isUpdating: updatingCommunityIds.contains(community.id),
            onPressed: () => onCommunityToggle(community),
          ),
          onTap: () => onCommunityOpen?.call(community),
        );
      },
    );
  }
}

class _PeopleSubscriptionList extends StatelessWidget {
  const _PeopleSubscriptionList({required this.people, this.onPersonOpen});

  final List<FeedPersonVm> people;
  final ValueChanged<FeedPersonVm>? onPersonOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (people.isEmpty) {
      return _SheetEmptyState(message: l10n.feedMySubscriptionsEmptyMessage);
    }

    return ListView.separated(
      itemCount: people.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final person = people[index];
        return _SheetListTile(
          key: ValueKey('my-subscriptions-sheet-person-${person.userId}'),
          title: person.displayName(l10n.feedMySubscriptionsUnknownPerson),
          subtitle: _personSubtitle(context, person),
          imageUrl: _avatarUrl(person.avatarFileId),
          icon: Icons.person_rounded,
          onTap: () => onPersonOpen?.call(person),
        );
      },
    );
  }
}

class _SheetListTile extends StatelessWidget {
  const _SheetListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl,
    this.locationWidget,
    this.metaText,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
  final Widget? locationWidget;
  final String? metaText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Material(
      color: colors.surfaceHigh,
      borderRadius: AppBorderRadius.circular(8),
      child: InkWell(
        borderRadius: AppBorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: Row(
            children: [
              _SubscriptionAvatar(title: title, imageUrl: imageUrl, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (locationWidget != null) ...[
                      const SizedBox(height: 4),
                      locationWidget!,
                    ] else if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if ((metaText ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaText!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          height: 1.14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunitySubscriptionToggleButton extends StatelessWidget {
  const _CommunitySubscriptionToggleButton({
    required this.community,
    required this.isUpdating,
    required this.onPressed,
  });

  final FeedCommunityVm community;
  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return IconButton.filledTonal(
      key: ValueKey('my-subscriptions-sheet-toggle-${community.id}'),
      onPressed: isUpdating ? null : onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.primary.withValues(alpha: 0.14),
        foregroundColor: colors.primary,
        minimumSize: const Size.square(42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: isUpdating
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textPrimary,
              ),
            )
          : Icon(
              community.followedByViewer
                  ? Icons.remove_rounded
                  : Icons.add_rounded,
            ),
    );
  }
}

class _SubscriptionAvatar extends StatelessWidget {
  const _SubscriptionAvatar({
    required this.title,
    required this.icon,
    this.imageUrl,
  });

  final String title;
  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? 'F' : title.trim()[0].toUpperCase();
    final url = imageUrl?.trim();
    final colors = AppDesignSystem.colorsFor(context);

    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.primary.withValues(alpha: 0.18),
      foregroundColor: colors.primary,
      backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: url == null || url.isEmpty
          ? icon == Icons.person_rounded
                ? Icon(icon)
                : Text(
                    initial,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const AppTextStyle(fontWeight: FontWeight.w900),
                  )
          : null,
    );
  }
}

class _CommunityFilters extends StatelessWidget {
  const _CommunityFilters({
    required this.selectedFilter,
    required this.selectedTopic,
    required this.topicOptions,
    required this.resultCountFor,
    required this.onFilterSelected,
    required this.onTopicSelected,
  });

  final _CommunityFilter selectedFilter;
  final String selectedTopic;
  final List<String> topicOptions;
  final int Function(_CommunityFilter filter, String topic) resultCountFor;
  final ValueChanged<_CommunityFilter> onFilterSelected;
  final ValueChanged<String> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionTitle(
          title: l10n.feedMySubscriptionsFilterCommunityActivitySection,
        ),
        const SizedBox(height: 10),
        _FilterWrap(
          children: [
            for (final filter in const [
              _CommunityFilter.all,
              _CommunityFilter.currentCity,
              _CommunityFilter.active,
              _CommunityFilter.popular,
            ])
              _FilterChipData(
                key: _communityFilterKey(filter),
                label: _communityFilterLabel(filter, l10n),
                icon: _communityFilterIcon(filter),
                count: resultCountFor(filter, selectedTopic),
                selected: selectedFilter == filter,
                onSelected: () => onFilterSelected(filter),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _FilterSectionTitle(
          title: l10n.feedMySubscriptionsFilterCommunityTopicSection,
        ),
        const SizedBox(height: 10),
        _FilterWrap(
          children: [
            for (final topic in topicOptions)
              _FilterChipData(
                key: _communityTopicKey(topic),
                label: feedCommunityTopicLabel(topic, l10n),
                icon: topic.isEmpty
                    ? Icons.all_inclusive_rounded
                    : Icons.local_offer_rounded,
                count: resultCountFor(selectedFilter, topic),
                selected:
                    _canonicalCommunityTopic(selectedTopic) ==
                    _canonicalCommunityTopic(topic),
                onSelected: () => onTopicSelected(topic),
              ),
          ],
        ),
      ],
    );
  }
}

class _PeopleFilters extends StatelessWidget {
  const _PeopleFilters({
    required this.selectedFilter,
    required this.resultCountFor,
    required this.onFilterSelected,
  });

  final _PeopleFilter selectedFilter;
  final int Function(_PeopleFilter filter) resultCountFor;
  final ValueChanged<_PeopleFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionTitle(
          title: l10n.feedMySubscriptionsFilterPeopleConnectionSection,
        ),
        const SizedBox(height: 10),
        _FilterWrap(
          children: [
            for (final filter in const [
              _PeopleFilter.all,
              _PeopleFilter.friends,
              _PeopleFilter.following,
            ])
              _FilterChipData(
                key: _peopleFilterKey(filter),
                label: _peopleFilterLabel(filter, l10n),
                icon: _peopleFilterIcon(filter),
                count: resultCountFor(filter),
                selected: selectedFilter == filter,
                onSelected: () => onFilterSelected(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _MySubscriptionsFiltersResult {
  const _MySubscriptionsFiltersResult({
    required this.communityFilter,
    required this.communityTopic,
    required this.peopleFilter,
  });

  final _CommunityFilter communityFilter;
  final String communityTopic;
  final _PeopleFilter peopleFilter;
}

class _MySubscriptionsFiltersSheet extends StatefulWidget {
  const _MySubscriptionsFiltersSheet({
    required this.tabIndex,
    required this.communityFilter,
    required this.communityTopic,
    required this.peopleFilter,
    required this.communityTopicOptions,
    required this.communityResultCount,
    required this.peopleResultCount,
  });

  final int tabIndex;
  final _CommunityFilter communityFilter;
  final String communityTopic;
  final _PeopleFilter peopleFilter;
  final List<String> communityTopicOptions;
  final int Function(_CommunityFilter filter, String topic)
  communityResultCount;
  final int Function(_PeopleFilter filter) peopleResultCount;

  @override
  State<_MySubscriptionsFiltersSheet> createState() =>
      _MySubscriptionsFiltersSheetState();
}

class _MySubscriptionsFiltersSheetState
    extends State<_MySubscriptionsFiltersSheet> {
  late _CommunityFilter _communityFilter;
  late String _communityTopic;
  late _PeopleFilter _peopleFilter;

  bool get _isPeopleTab => widget.tabIndex == 1;

  @override
  void initState() {
    super.initState();
    _communityFilter = widget.communityFilter;
    _communityTopic = widget.communityTopic;
    _peopleFilter = widget.peopleFilter;
  }

  void _clearCurrentTab() {
    setState(() {
      if (_isPeopleTab) {
        _peopleFilter = _PeopleFilter.all;
      } else {
        _communityFilter = _CommunityFilter.all;
        _communityTopic = '';
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _MySubscriptionsFiltersResult(
        communityFilter: _communityFilter,
        communityTopic: _communityTopic,
        peopleFilter: _peopleFilter,
      ),
    );
  }

  int get _selectedResultCount {
    if (_isPeopleTab) {
      return widget.peopleResultCount(_peopleFilter);
    }
    return widget.communityResultCount(_communityFilter, _communityTopic);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final applyLabel = _isPeopleTab
        ? l10n.feedMySubscriptionsShowPeopleCount(_selectedResultCount)
        : l10n.feedMySubscriptionsShowCommunitiesCount(_selectedResultCount);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: ClipRRect(
          borderRadius: const AppBorderRadius.vertical(
            top: AppRadiusValue.circular(28),
          ),
          child: DecoratedBox(
            decoration: AppBoxDecoration(color: colors.background),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFilterSheetHeader(
                  title: l10n.communityDiscoveryFiltersTitle,
                  clearLabel: l10n.storyResetFiltersAction,
                  onClear: _clearCurrentTab,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const AppEdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FilterSheetIntro(
                          title: _isPeopleTab
                              ? l10n.feedMySubscriptionsPeopleTab
                              : l10n.feedMySubscriptionsCommunitiesTab,
                          resultCount: _selectedResultCount,
                        ),
                        const SizedBox(height: 16),
                        _isPeopleTab
                            ? _PeopleFilters(
                                selectedFilter: _peopleFilter,
                                resultCountFor: widget.peopleResultCount,
                                onFilterSelected: (value) =>
                                    setState(() => _peopleFilter = value),
                              )
                            : _CommunityFilters(
                                selectedFilter: _communityFilter,
                                selectedTopic: _communityTopic,
                                topicOptions: widget.communityTopicOptions,
                                resultCountFor: widget.communityResultCount,
                                onFilterSelected: (value) =>
                                    setState(() => _communityFilter = value),
                                onTopicSelected: (value) =>
                                    setState(() => _communityTopic = value),
                              ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: AppEdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    18 + safeBottomInset,
                  ),
                  child: AppFilterApplyButton(
                    key: const ValueKey('my-subscriptions-apply-filters'),
                    label: applyLabel,
                    onTap: _apply,
                    borderRadius: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterWrap extends StatelessWidget {
  const _FilterWrap({required this.children});

  final List<_FilterChipData> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          _FilterOptionTile(data: children[index]),
          if (index != children.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _FilterSheetIntro extends StatelessWidget {
  const _FilterSheetIntro({required this.title, required this.resultCount});

  final String title;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(22),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.16),
              ),
              child: Icon(Icons.tune_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: AppBoxDecoration(
                color: colors.primary.withValues(alpha: 0.18),
                borderRadius: AppBorderRadius.circular(999),
              ),
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  resultCount.toString(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      children: [
        Icon(Icons.filter_list_rounded, color: colors.primary, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({required this.data});

  final _FilterChipData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final foreground = data.selected
        ? colors.textPrimary
        : colors.textSecondary;

    return Material(
      key: ValueKey(data.key),
      color: data.selected
          ? colors.primary.withValues(alpha: 0.20)
          : colors.surfaceHigh,
      borderRadius: AppBorderRadius.circular(18),
      child: InkWell(
        borderRadius: AppBorderRadius.circular(18),
        onTap: data.onSelected,
        child: Container(
          padding: const AppEdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(
              color: data.selected ? colors.primary : colors.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: data.selected
                      ? colors.primary
                      : colors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  data.selected ? Icons.check_rounded : data.icon,
                  color: data.selected ? colors.textPrimary : colors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              if (data.count != null) ...[
                const SizedBox(width: 10),
                DecoratedBox(
                  decoration: AppBoxDecoration(
                    color: colors.black.withValues(alpha: 0.20),
                    borderRadius: AppBorderRadius.circular(999),
                    border: Border.all(color: colors.borderPrimary),
                  ),
                  child: Padding(
                    padding: const AppEdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      data.count.toString(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({
    required this.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  final String key;
  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;
}

class _SubscriptionTileData {
  const _SubscriptionTileData.community(this.community) : person = null;
  const _SubscriptionTileData.person(this.person) : community = null;

  final FeedCommunityVm? community;
  final FeedPersonVm? person;

  ValueKey<String> get openKey {
    final community = this.community;
    if (community != null) {
      return ValueKey('open-my-subscriptions-community-${community.id}');
    }
    return ValueKey('open-my-subscriptions-person-${person?.userId ?? ''}');
  }

  String title(BuildContext context) {
    final community = this.community;
    if (community != null) {
      return feedCommunityDisplayTitle(
        community,
        AppLocalizations.of(context)!,
      );
    }
    return person?.displayName(person?.userId ?? '') ?? '';
  }

  String? get avatarUrl {
    final community = this.community;
    if (community != null) {
      return _avatarUrl(community.avatarFileId);
    }
    return _avatarUrl(person?.avatarFileId);
  }

  String subtitle(BuildContext context) {
    final community = this.community;
    if (community != null) {
      return _communitySubtitle(context, community);
    }
    final person = this.person;
    if (person == null) {
      return '';
    }
    return _personSubtitle(context, person);
  }
}

enum _CommunityFilter { all, currentCity, active, popular }

enum _PeopleFilter { all, friends, following }

enum _CommunitySort { relevant, active, popular, name }

enum _PeopleSort { relevant, online, name }

String _communityFilterLabel(_CommunityFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    _CommunityFilter.all => l10n.feedMySubscriptionsFilterAll,
    _CommunityFilter.currentCity => l10n.feedMySubscriptionsFilterCurrentCity,
    _CommunityFilter.active => l10n.feedMySubscriptionsFilterActive,
    _CommunityFilter.popular => l10n.feedMySubscriptionsFilterPopular,
  };
}

String _peopleFilterLabel(_PeopleFilter filter, AppLocalizations l10n) {
  return switch (filter) {
    _PeopleFilter.all => l10n.feedMySubscriptionsFilterAll,
    _PeopleFilter.friends => l10n.feedMySubscriptionsFilterFriends,
    _PeopleFilter.following => l10n.feedMySubscriptionsFilterFollowing,
  };
}

String _communitySortLabel(_CommunitySort sort, AppLocalizations l10n) {
  return switch (sort) {
    _CommunitySort.relevant => l10n.feedMySubscriptionsSortRelevant,
    _CommunitySort.active => l10n.feedMySubscriptionsSortMostActive,
    _CommunitySort.popular => l10n.feedMySubscriptionsSortMostPopular,
    _CommunitySort.name => l10n.feedMySubscriptionsSortName,
  };
}

String _peopleSortLabel(_PeopleSort sort, AppLocalizations l10n) {
  return switch (sort) {
    _PeopleSort.relevant => l10n.feedMySubscriptionsSortRelevant,
    _PeopleSort.online => l10n.feedMySubscriptionsSortOnlineFirst,
    _PeopleSort.name => l10n.feedMySubscriptionsSortName,
  };
}

String _communityFilterKey(_CommunityFilter filter) {
  return switch (filter) {
    _CommunityFilter.all => 'my-subscriptions-filter-communities-all',
    _CommunityFilter.currentCity =>
      'my-subscriptions-filter-communities-current-city',
    _CommunityFilter.active => 'my-subscriptions-filter-communities-active',
    _CommunityFilter.popular => 'my-subscriptions-filter-communities-popular',
  };
}

String _communityTopicKey(String topic) {
  final normalized = _canonicalCommunityTopic(topic);
  return normalized.isEmpty
      ? 'my-subscriptions-topic-communities-all'
      : 'my-subscriptions-topic-communities-$normalized';
}

String _peopleFilterKey(_PeopleFilter filter) {
  return switch (filter) {
    _PeopleFilter.all => 'my-subscriptions-filter-all',
    _PeopleFilter.friends => 'my-subscriptions-filter-friends',
    _PeopleFilter.following => 'my-subscriptions-filter-following',
  };
}

IconData _communityFilterIcon(_CommunityFilter filter) {
  return switch (filter) {
    _CommunityFilter.all => Icons.all_inclusive_rounded,
    _CommunityFilter.currentCity => Icons.location_on_rounded,
    _CommunityFilter.active => Icons.forum_rounded,
    _CommunityFilter.popular => Icons.trending_up_rounded,
  };
}

IconData _peopleFilterIcon(_PeopleFilter filter) {
  return switch (filter) {
    _PeopleFilter.all => Icons.all_inclusive_rounded,
    _PeopleFilter.friends => Icons.diversity_1_rounded,
    _PeopleFilter.following => Icons.person_add_alt_1_rounded,
  };
}

bool _matchesCommunityQuery(FeedCommunityVm community, String query) {
  if (query.isEmpty) {
    return true;
  }
  return [
    community.title,
    ...community.titleI18n.values,
    community.subtitle,
    community.description,
    ...community.descriptionI18n.values,
    community.topic,
  ].whereType<String>().any((value) => value.toLowerCase().contains(query));
}

String _canonicalCommunityTopic(String? topic) {
  final normalized = (topic ?? '').trim().replaceAll('-', '_').toUpperCase();
  return switch (normalized) {
    '' => '',
    'LANGUAGE' || 'LANGUAGES' => 'LANGUAGES',
    'HOUSING' || 'REAL_ESTATE' || 'REAL_ESTATE_RENT' => 'HOUSING',
    'TRANSPORT' || 'TRANSPORTATION' => 'TRANSPORT',
    'SPORT' || 'SPORTS' => 'SPORTS',
    'OUTDOOR' || 'TRIPS' || 'HIKING' || 'TREKKING' => 'OUTDOOR',
    'HOBBIES' || 'ART' || 'POTTERY' || 'MASTER_CLASSES' => 'HOBBIES',
    'WELLNESS' || 'YOGA' || 'HEALTH_WELLNESS' => 'WELLNESS',
    'PETS' || 'PET_OWNERS' => 'PETS',
    'CITY_LIFE' || 'CITY' || 'EVENTS' || 'MARKETPLACE' => 'CITY_LIFE',
    'CONTENT' || 'NEWS' || 'TRAVEL_TIPS' || 'APP_NEWS' => 'CONTENT',
    'FAMILY' || 'FAMILIES' => 'FAMILY',
    'GENERAL' => 'GENERAL',
    _ => normalized,
  };
}

String? _normalizeLocationKey(String? value) {
  final normalized = (value ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'[_\s]+'),
    '-',
  );
  return normalized.isEmpty ? null : normalized;
}

int? _compareDesc(int left, int right) {
  final result = right.compareTo(left);
  return result == 0 ? null : result;
}

int _compareCommunityTitle(FeedCommunityVm left, FeedCommunityVm right) {
  return left.title.toLowerCase().compareTo(right.title.toLowerCase());
}

int _comparePersonName(FeedPersonVm left, FeedPersonVm right) {
  return left
      .displayName(left.userId)
      .toLowerCase()
      .compareTo(right.displayName(right.userId).toLowerCase());
}

bool _matchesPersonQuery(FeedPersonVm person, String query) {
  if (query.isEmpty) {
    return true;
  }
  return person.displayName(person.userId).toLowerCase().contains(query) ||
      person.userId.toLowerCase().contains(query);
}

String _communitySubtitle(BuildContext context, FeedCommunityVm community) {
  final l10n = AppLocalizations.of(context)!;
  final location = feedCommunityLocationLabel(community).trim();
  final members = community.membersCount > 0
      ? l10n.feedCommunityMembersLabel(_formatCount(community.membersCount))
      : '';
  if (location.isNotEmpty && members.isNotEmpty) {
    return '$location · $members';
  }
  if (location.isNotEmpty) {
    return location;
  }
  final subtitle = feedCommunityDisplayDescription(community, l10n);
  if (subtitle.isNotEmpty) {
    return subtitle;
  }
  if (community.membersCount > 0) {
    return members;
  }
  return '';
}

String _personSubtitle(BuildContext context, FeedPersonVm person) {
  final l10n = AppLocalizations.of(context)!;
  final parts = <String>[
    if (person.relationship == FeedPersonRelationship.friend)
      l10n.feedMySubscriptionsFriendBadge
    else
      l10n.feedMySubscriptionsFollowingBadge,
    if (person.isOnline) l10n.feedMySubscriptionsOnlineBadge,
  ];
  return parts.join(' · ');
}

String? _avatarUrl(String? fileId) {
  final trimmed = (fileId ?? '').trim();
  return trimmed.isEmpty ? null : resolvePublicFileContentUrl(trimmed);
}

FeedCommunityVm _mergeCommunityForSubscriptions(
  FeedCommunityVm current,
  FeedCommunityVm updated,
) {
  return current.copyWith(
    title: _trimmedStringOrNull(updated.title) ?? current.title,
    titleI18n: updated.titleI18n.isEmpty
        ? current.titleI18n
        : updated.titleI18n,
    subtitle: _trimmedStringOrNull(updated.subtitle) ?? current.subtitle,
    description:
        _trimmedStringOrNull(updated.description) ?? current.description,
    descriptionI18n: updated.descriptionI18n.isEmpty
        ? current.descriptionI18n
        : updated.descriptionI18n,
    topic: _trimmedStringOrNull(updated.topic) ?? current.topic,
    avatarFileId:
        _trimmedStringOrNull(updated.avatarFileId) ?? current.avatarFileId,
    coverFileId:
        _trimmedStringOrNull(updated.coverFileId) ?? current.coverFileId,
    visibility: updated.visibility,
    postingPolicy: updated.postingPolicy,
    status: updated.status,
    defaultPostProfileKey: updated.defaultPostProfileKey,
    allowedPostProfileKeys: updated.allowedPostProfileKeys.isEmpty
        ? current.allowedPostProfileKeys
        : updated.allowedPostProfileKeys,
    enabledTabs: updated.enabledTabs.isEmpty
        ? current.enabledTabs
        : updated.enabledTabs,
    languageCode:
        _trimmedStringOrNull(updated.languageCode) ?? current.languageCode,
    countryCode:
        _trimmedStringOrNull(updated.countryCode) ?? current.countryCode,
    cityId: _trimmedStringOrNull(updated.cityId) ?? current.cityId,
    cityName: _trimmedStringOrNull(updated.cityName) ?? current.cityName,
    membersCount: updated.membersCount,
    postCount: updated.postCount == 0 ? current.postCount : updated.postCount,
    followedByViewer: updated.followedByViewer,
    viewerRole: _trimmedStringOrNull(updated.viewerRole) ?? current.viewerRole,
    viewerCanModerate: updated.viewerCanModerate,
    viewerTrustStatus: updated.viewerTrustStatus,
    viewerRestrictionId:
        _trimmedStringOrNull(updated.viewerRestrictionId) ??
        current.viewerRestrictionId,
    mutedByViewer: updated.mutedByViewer,
    rules: updated.rules.isEmpty ? current.rules : updated.rules,
  );
}

String? _trimmedStringOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<BoxShadow> _v2DarkShadow(
  BuildContext context,
  AppColors colors, {
  double alpha = 0.16,
  double blurRadius = 18,
  double dy = 10,
}) {
  if (Theme.of(context).brightness != Brightness.dark) {
    return const [];
  }

  return [
    BoxShadow(
      color: colors.black.withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: Offset(0, dy),
    ),
  ];
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return value.toString();
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(hexByte).join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}
