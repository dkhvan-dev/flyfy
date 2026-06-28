import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/ui/app_list_search_field.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/reference/app_location_label_resolver.dart';
import '../../../shared/widgets/app_city_filter_section.dart';
import '../data/feed_api.dart';
import '../models/feed_block_vm.dart';
import 'community_display_helpers.dart';

class CommunityDiscoverySheet extends StatefulWidget {
  const CommunityDiscoverySheet({
    super.key,
    required this.feedApi,
    required this.onCommunityOpen,
    required this.onCommunityUpdated,
    this.initialCountryCode,
    this.initialCityId,
    this.initialCityName,
    this.locationLabelResolver,
  });

  final FeedApi feedApi;
  final ValueChanged<FeedCommunityVm> onCommunityOpen;
  final ValueChanged<FeedCommunityVm> onCommunityUpdated;
  final String? initialCountryCode;
  final String? initialCityId;
  final String? initialCityName;
  final AppLocationLabelResolver? locationLabelResolver;

  @override
  State<CommunityDiscoverySheet> createState() =>
      _CommunityDiscoverySheetState();
}

class _CommunityDiscoverySheetState extends State<CommunityDiscoverySheet> {
  static const _pageLimit = 30;
  static const _topics = feedCommunityTopicFilterValues;

  final TextEditingController _searchController = TextEditingController();
  late final AppLocationLabelResolver _locationLabelResolver;
  Timer? _searchDebounce;

  List<FeedCommunityVm> _communities = const [];
  Map<String, String> _communityLocationLabels = const {};
  Set<String> _updatingCommunityIds = const {};
  Object? _error;
  bool _isLoading = true;
  String _selectedTopic = '';
  String _search = '';
  String? _selectedCountryCode;
  String? _selectedCityId;
  String? _selectedCityName;
  int _requestGeneration = 0;

  AppCityFilterValue? get _selectedCityFilter => AppCityFilterValue.fromParts(
    countryCode: _selectedCountryCode,
    cityId: _selectedCityId,
    cityName: _selectedCityName,
  );

  String? get _selectedCityQueryId => _selectedCityFilter?.queryCityId;

  @override
  void initState() {
    super.initState();
    _locationLabelResolver =
        widget.locationLabelResolver ?? AppLocationLabelResolver();
    _selectedCountryCode = _trimmedOrNull(widget.initialCountryCode);
    _selectedCityId = _trimmedOrNull(widget.initialCityId);
    _selectedCityName = _trimmedOrNull(widget.initialCityName);
    _searchController.addListener(_onSearchChanged);
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      final next = _searchController.text.trim();
      if (next == _search || !mounted) {
        return;
      }
      setState(() => _search = next);
      _loadCommunities();
    });
  }

  Future<void> _loadCommunities() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await widget.feedApi.listCommunities(
        topic: _selectedTopic.isEmpty ? null : _selectedTopic,
        countryCode: _selectedCountryCode,
        cityId: _selectedCityQueryId,
        search: _search.isEmpty ? null : _search,
        excludeFollowed: true,
        limit: _pageLimit,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      final communities = [
        for (final community in page.items)
          if (!community.followedByViewer) community,
      ];
      final locationLabels = await _resolveLocationLabels(communities);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _communities = communities;
        _communityLocationLabels = locationLabels;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
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
          ? await widget.feedApi.unfollowCommunity(communityId)
          : await widget.feedApi.followCommunity(communityId);
      final mergedCommunity = _mergeCommunityForDiscovery(
        community,
        updatedCommunity,
      );
      if (!community.followedByViewer) {
        _trackCommunitySubscribe(mergedCommunity);
      }
      if (!mounted) {
        return;
      }
      widget.onCommunityUpdated(mergedCommunity);
      setState(() {
        _communities = [
          for (final item in _communities)
            item.id == updatedCommunity.id
                ? _mergeCommunityForDiscovery(item, updatedCommunity)
                : item,
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
      widget.feedApi.trackFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: FeedEventTypes.subscribe,
          surface: 'content',
          tab: 'for_you',
          blockId: 'communities:discovery_sheet',
          blockType: 'suggested_communities',
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

  int get _activeFilterCount =>
      (_selectedCountryCode == null ? 0 : 1) +
      (_selectedCityQueryId == null ? 0 : 1) +
      (_selectedTopic.isEmpty ? 0 : 1);

  Future<int> _loadPreviewCount(_CommunityDiscoveryFilters filters) async {
    if (!filters.hasRequiredLocation) {
      return 0;
    }

    final page = await widget.feedApi.listCommunities(
      topic: filters.topic.isEmpty ? null : filters.topic,
      countryCode: filters.country?.countryCode,
      cityId: filters.city?.queryCityId,
      search: _search.isEmpty ? null : _search,
      excludeFollowed: true,
      limit: _pageLimit,
    );
    return page.items.where((community) => !community.followedByViewer).length;
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_CommunityDiscoveryFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.transparent,
      barrierColor: AppPalette.black.withValues(alpha: 0.58),
      builder: (context) {
        return _CommunityDiscoveryFiltersSheet(
          l10n: l10n,
          topics: _topics,
          previewCount: _communities.length,
          previewCountLoader: _loadPreviewCount,
          initialFilters: _CommunityDiscoveryFilters(
            country: AppCountryFilterValue.fromParts(
              countryCode: _selectedCountryCode,
            ),
            city: AppCityFilterValue.fromParts(
              countryCode: _selectedCountryCode,
              cityId: _selectedCityId,
              cityName: _selectedCityName,
            ),
            topic: _selectedTopic,
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _selectedCountryCode = result.country?.countryCode;
      _selectedCityId = result.city?.queryCityId;
      _selectedCityName = result.city?.cityName;
      _selectedTopic = result.topic;
    });
    await _loadCommunities();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: AppEdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: AppBoxDecoration(
                color: AppPalette.outlineOverlay,
                borderRadius: AppBorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                l10n.communityDiscoveryTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppListSearchField(
              textFieldKey: const ValueKey('community-discovery-sheet-search'),
              controller: _searchController,
              hintText: l10n.communityDiscoverySearchHint,
              filterTooltip: l10n.communityDiscoveryFiltersTitle,
              activeFilterCount: _activeFilterCount,
              showClearButton: true,
              onClear: () {
                _searchController.clear();
                if (_search.isEmpty) {
                  return;
                }
                setState(() => _search = '');
                _loadCommunities();
              },
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onFilterTap: _openFilters,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.primary),
      );
    }

    if (_error != null) {
      return _CommunityDiscoverySheetMessage(
        icon: Icons.wifi_off_rounded,
        title: l10n.communityDiscoveryLoadFailedTitle,
        message: l10n.communityDiscoveryLoadFailedMessage,
        action: FilledButton(
          onPressed: _loadCommunities,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primary,
            foregroundColor: AppPalette.backgroundWarm,
          ),
          child: Text(l10n.feedRetryAction),
        ),
      );
    }

    if (_communities.isEmpty) {
      return _CommunityDiscoverySheetMessage(
        icon: Icons.groups_2_outlined,
        title: l10n.communityDiscoveryEmptyTitle,
        message: l10n.communityDiscoveryEmptyMessage,
      );
    }

    return ListView.separated(
      padding: const AppEdgeInsets.only(bottom: 8),
      itemCount: _communities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final community = _communities[index];
        return _CommunityDiscoveryCard(
          community: community,
          locationText: _communityLocationText(community),
          isUpdating: _updatingCommunityIds.contains(community.id),
          onToggle: _toggleCommunityFollow,
          onOpen: widget.onCommunityOpen,
        );
      },
    );
  }

  String _communityLocationText(FeedCommunityVm community) {
    final cached = _trimmedOrNull(_communityLocationLabels[community.id]);
    if (cached != null) {
      return cached;
    }
    return _communityLocationFallbackText(community);
  }

  String _communityLocationFallbackText(FeedCommunityVm community) {
    final cityName = _trimmedOrNull(community.cityName);
    if (cityName != null) {
      return cityName;
    }
    final cityId = _trimmedOrNull(community.cityId);
    if (cityId != null) {
      return _humanizeLocationCode(cityId);
    }
    final countryCode = _trimmedOrNull(community.countryCode);
    return countryCode ?? '';
  }

  Future<Map<String, String>> _resolveLocationLabels(
    List<FeedCommunityVm> communities,
  ) async {
    if (communities.isEmpty) {
      return const {};
    }
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final nextLabels = <String, String>{};
    for (final community in communities) {
      if (_trimmedOrNull(community.cityId) == null &&
          _trimmedOrNull(community.countryCode) == null &&
          _trimmedOrNull(community.cityName) == null) {
        continue;
      }
      try {
        final label = await _locationLabelResolver.resolve(
          countryCode: community.countryCode,
          cityId: community.cityId,
          cityName: community.cityName,
          localeName: localeName,
        );
        final normalized = _trimmedOrNull(label);
        if (normalized != null) {
          nextLabels[community.id] = normalized;
        }
      } catch (_) {
        final fallback = _communityLocationFallbackText(community);
        if (fallback.isNotEmpty) {
          nextLabels[community.id] = fallback;
        }
      }
    }
    return nextLabels;
  }
}

class _CommunityDiscoveryFilters {
  const _CommunityDiscoveryFilters({
    required this.country,
    required this.city,
    required this.topic,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final String topic;

  bool get hasRequiredLocation =>
      country?.countryCode != null && city?.queryCityId != null;
}

typedef _CommunityDiscoveryPreviewCountLoader =
    Future<int> Function(_CommunityDiscoveryFilters filters);

class _CommunityDiscoveryFiltersSheet extends StatefulWidget {
  const _CommunityDiscoveryFiltersSheet({
    required this.l10n,
    required this.topics,
    required this.initialFilters,
    required this.previewCount,
    required this.previewCountLoader,
  });

  final AppLocalizations l10n;
  final List<String> topics;
  final _CommunityDiscoveryFilters initialFilters;
  final int previewCount;
  final _CommunityDiscoveryPreviewCountLoader previewCountLoader;

  @override
  State<_CommunityDiscoveryFiltersSheet> createState() =>
      _CommunityDiscoveryFiltersSheetState();
}

class _CommunityDiscoveryFiltersSheetState
    extends State<_CommunityDiscoveryFiltersSheet> {
  late AppCountryFilterValue? _selectedCountry;
  late AppCityFilterValue? _selectedCity;
  late String _selectedTopic;
  late int _previewCount;
  bool _isPreviewLoading = false;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialFilters.country;
    _selectedCity = widget.initialFilters.city;
    _selectedTopic = widget.initialFilters.topic;
    _previewCount = widget.previewCount;
    _loadPreviewCount();
  }

  void _setCountry(AppCountryFilterValue? country) {
    setState(() {
      _selectedCountry = country;
      final selectedCountryCode = country?.countryCode;
      final selectedCityCountryCode = _selectedCity?.countryCode;
      if (selectedCountryCode == null ||
          (selectedCityCountryCode != null &&
              selectedCountryCode != selectedCityCountryCode)) {
        _selectedCity = null;
      }
    });
    _loadPreviewCount();
  }

  void _setCity(AppCityFilterValue? city) {
    setState(() => _selectedCity = city);
    _loadPreviewCount();
  }

  void _setTopic(String topic) {
    setState(() => _selectedTopic = topic);
    _loadPreviewCount();
  }

  void _resetFilters() {
    setState(() {
      _selectedCountry = widget.initialFilters.country;
      _selectedCity = widget.initialFilters.city;
      _selectedTopic = '';
    });
    _loadPreviewCount();
  }

  void _applyFilters() {
    final filters = _CommunityDiscoveryFilters(
      country: _selectedCountry,
      city: _selectedCity,
      topic: _selectedTopic,
    );
    if (!filters.hasRequiredLocation) {
      return;
    }
    Navigator.of(context).pop(filters);
  }

  Future<void> _loadPreviewCount() async {
    final requestId = ++_previewRequestId;
    final filters = _CommunityDiscoveryFilters(
      country: _selectedCountry,
      city: _selectedCity,
      topic: _selectedTopic,
    );
    setState(() => _isPreviewLoading = true);
    try {
      final count = await widget.previewCountLoader(filters);
      if (!mounted || requestId != _previewRequestId) {
        return;
      }
      setState(() {
        _previewCount = count;
        _isPreviewLoading = false;
      });
    } catch (_) {
      if (mounted && requestId == _previewRequestId) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final canApply =
        _selectedCountry?.countryCode != null &&
        _selectedCity?.hasValue == true;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: ClipRRect(
          borderRadius: const AppBorderRadius.vertical(
            top: AppRadiusValue.circular(28),
          ),
          child: DecoratedBox(
            decoration: const AppBoxDecoration(color: AppPalette.warmInk66),
            child: Column(
              children: [
                AppFilterSheetHeader(
                  title: widget.l10n.communityDiscoveryFiltersTitle,
                  clearLabel: widget.l10n.storyResetFiltersAction,
                  onClear: _resetFilters,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const AppEdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCountryFilterSection(
                          title: widget.l10n.activitiesFilterCountrySection,
                          allCountriesLabel:
                              widget.l10n.activitiesFilterCountryAll,
                          searchHint:
                              widget.l10n.activitiesFilterCountrySearchHint,
                          noResultsText:
                              widget.l10n.activitiesFilterCountryNoResults,
                          selectedCountry: _selectedCountry,
                          onChanged: _setCountry,
                        ),
                        const _CommunityFilterDivider(),
                        AppCityFilterSection(
                          title: widget.l10n.locationFilterCitySection,
                          allCitiesLabel: widget.l10n.locationFilterAllCities,
                          searchHint: widget.l10n.locationFilterCitySearchHint,
                          noResultsText:
                              widget.l10n.locationFilterCityNoResults,
                          selectedCity: _selectedCity,
                          countryCode: _selectedCountry?.countryCode,
                          onChanged: _setCity,
                        ),
                        const _CommunityFilterDivider(),
                        _CommunityTopicFilterSection(
                          l10n: widget.l10n,
                          topics: widget.topics,
                          selectedTopic: _selectedTopic,
                          onChanged: _setTopic,
                        ),
                        if (!canApply) ...[
                          const SizedBox(height: 18),
                          DecoratedBox(
                            decoration: AppBoxDecoration(
                              color: AppPalette.primary.withValues(alpha: 0.12),
                              borderRadius: AppBorderRadius.circular(16),
                              border: Border.all(
                                color: AppPalette.primary.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const AppEdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    color: AppPalette.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget
                                          .l10n
                                          .communityDiscoveryRequiredLocationMessage,
                                      style: const AppTextStyle(
                                        color: AppPalette.amberLight11,
                                        fontSize: 13,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canApply && !_isPreviewLoading
                          ? _applyFilters
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        disabledBackgroundColor: AppPalette.warmSurface61,
                        foregroundColor: AppPalette.textPrimary,
                        disabledForegroundColor: AppPalette.warmMuted05,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(18),
                        ),
                      ),
                      child: _isPreviewLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPalette.textPrimary,
                              ),
                            )
                          : Text(
                              widget.l10n.communityDiscoveryShowResultsCount(
                                _previewCount,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const AppTextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                    ),
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

class _CommunityTopicFilterSection extends StatelessWidget {
  const _CommunityTopicFilterSection({
    required this.l10n,
    required this.topics,
    required this.selectedTopic,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final List<String> topics;
  final String selectedTopic;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CommunityFilterSection(
      icon: Icons.category_rounded,
      title: l10n.communityDiscoveryTopicSection,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final topic in topics)
            ChoiceChip(
              label: Text(feedCommunityTopicLabel(topic, l10n)),
              selected: selectedTopic == topic,
              onSelected: (_) => onChanged(topic),
              selectedColor: AppPalette.primary.withValues(alpha: 0.2),
              backgroundColor: AppPalette.warmInk27,
              labelStyle: AppTextStyle(
                color: selectedTopic == topic
                    ? AppPalette.primary
                    : AppPalette.textSecondary,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: selectedTopic == topic
                    ? AppPalette.primary
                    : AppPalette.white.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityFilterSection extends StatelessWidget {
  const _CommunityFilterSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppPalette.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const AppTextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _CommunityFilterDivider extends StatelessWidget {
  const _CommunityFilterDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppEdgeInsets.symmetric(vertical: 22),
      child: Divider(height: 1, color: AppPalette.warmSurface66),
    );
  }
}

class _CommunityDiscoveryCard extends StatelessWidget {
  const _CommunityDiscoveryCard({
    required this.community,
    required this.locationText,
    required this.isUpdating,
    required this.onToggle,
    required this.onOpen,
  });

  final FeedCommunityVm community;
  final String locationText;
  final bool isUpdating;
  final ValueChanged<FeedCommunityVm> onToggle;
  final ValueChanged<FeedCommunityVm> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = feedCommunityDisplayTitle(community, l10n);
    final location = locationText.trim();
    final membersText = feedCommunityMembersLabel(community, l10n);
    return Material(
      color: AppPalette.white.withValues(alpha: 0.08),
      borderRadius: AppBorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('community-discovery-sheet-open-${community.id}'),
        borderRadius: AppBorderRadius.circular(8),
        onTap: () => onOpen(community),
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppPalette.primary.withValues(alpha: 0.18),
                child: Text(
                  _communityInitial(title),
                  style: const AppTextStyle(
                    color: AppPalette.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppPalette.textCoolSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppPalette.textCoolSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      membersText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.textCoolSecondary.withValues(
                          alpha: 0.88,
                        ),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                key: ValueKey(
                  'community-discovery-sheet-toggle-${community.id}',
                ),
                onPressed: isUpdating ? null : () => onToggle(community),
                style: IconButton.styleFrom(
                  backgroundColor: AppPalette.primary.withValues(alpha: 0.14),
                  foregroundColor: AppPalette.primary,
                  minimumSize: const Size.square(42),
                ),
                icon: isUpdating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppPalette.primary,
                        ),
                      )
                    : Icon(
                        community.followedByViewer
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityDiscoverySheetMessage extends StatelessWidget {
  const _CommunityDiscoverySheetMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppPalette.textCoolSecondary, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.textCoolSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

FeedCommunityVm _mergeCommunityForDiscovery(
  FeedCommunityVm current,
  FeedCommunityVm updated,
) {
  return current.copyWith(
    title: _trimmedOrNull(updated.title) ?? current.title,
    subtitle: _trimmedOrNull(updated.subtitle) ?? current.subtitle,
    description: _trimmedOrNull(updated.description) ?? current.description,
    topic: _trimmedOrNull(updated.topic) ?? current.topic,
    avatarFileId: _trimmedOrNull(updated.avatarFileId) ?? current.avatarFileId,
    coverFileId: _trimmedOrNull(updated.coverFileId) ?? current.coverFileId,
    countryCode: _trimmedOrNull(updated.countryCode) ?? current.countryCode,
    cityId: _trimmedOrNull(updated.cityId) ?? current.cityId,
    cityName: _trimmedOrNull(updated.cityName) ?? current.cityName,
    visibility: updated.visibility,
    postingPolicy: updated.postingPolicy,
    status: updated.status,
    languageCode: _trimmedOrNull(updated.languageCode) ?? current.languageCode,
    membersCount: updated.membersCount,
    postCount: updated.postCount,
    followedByViewer: updated.followedByViewer,
    viewerRole: _trimmedOrNull(updated.viewerRole) ?? current.viewerRole,
    viewerCanModerate: updated.viewerCanModerate,
    viewerTrustStatus: updated.viewerTrustStatus,
    viewerRestrictionId:
        _trimmedOrNull(updated.viewerRestrictionId) ??
        current.viewerRestrictionId,
    mutedByViewer: updated.mutedByViewer,
    rules: updated.rules.isEmpty ? current.rules : updated.rules,
  );
}

String _humanizeLocationCode(String code) {
  final words = code
      .trim()
      .split(RegExp(r'[-_]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return code;
  }
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _communityInitial(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    return 'C';
  }
  return trimmed.substring(0, 1).toUpperCase();
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
