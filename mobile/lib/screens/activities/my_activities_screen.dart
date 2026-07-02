import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/activity_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../core/time/app_time.dart';
import '../../core/utils/pagination.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/activity_participant_vm.dart';
import '../../features/activities/models/activity_review_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import '../../shared/widgets/app_localized_location_text.dart';
import 'widgets/activity_review_sheet.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum _MyActivitiesTab { hosted, attended }

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  static const int _pageSize = 8;

  static const List<String> _hostedFilterOrder = <String>[
    'PUBLISHED',
    'COMPLETED',
    'CANCELLED',
  ];

  static const List<String> _attendedFilterOrder = <String>[
    'PUBLISHED',
    'COMPLETED',
    'CANCELLED',
  ];

  static const Set<String> _publishedStatuses = <String>{
    'PUBLISHED',
    'ENROLLMENT_OPEN',
  };

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ActivityApi _activityApi = ActivityApi();
  final Set<String> _reviewedActivityIds = {};
  final Set<String> _reviewStateLoadedActivityIds = {};
  final Set<String> _reviewEligibleActivityIds = {};
  final Set<String> _reviewEligibilityLoadedActivityIds = {};
  final Map<String, ActivityReviewVm> _activityReviewCache = {};
  final Map<String, ActivityOrganizerReviewVm> _organizerReviewCache = {};
  String? _lastReviewStateSyncKey;
  _MyActivitiesTab _activeTab = _MyActivitiesTab.hosted;
  _MyActivitiesFilters _filters = const _MyActivitiesFilters();
  String _searchQuery = '';
  int _hostedPage = 1;
  int _attendedPage = 1;
  bool _hasAppliedDefaultLocationFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDefaultLocationFilter());
      final provider = context.read<ActivityProvider>();
      provider.loadActivityCategories();
      provider.loadMyActivities();
      provider.loadJoinedActivities();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openCreateActivity() async {
    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    final provider = context.read<ActivityProvider>();
    await context.push('/activities/create');
    if (!mounted) return;
    provider.loadMyActivities();
    provider.loadJoinedActivities();
  }

  Future<void> _openEdit(ActivityListItemVm item) async {
    final provider = context.read<ActivityProvider>();
    await context.push('/activities/${item.id}/edit', extra: item);
    if (!mounted) return;
    provider.loadMyActivities();
    provider.loadJoinedActivities();
  }

  Future<void> _openRepeat(ActivityListItemVm item) async {
    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    final provider = context.read<ActivityProvider>();
    await context.push('/activities/create', extra: item);
    if (!mounted) return;
    provider.loadMyActivities();
    provider.loadJoinedActivities();
  }

  void _openDetails(ActivityListItemVm item) {
    context.push('/activities/${item.id}');
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  void _goHome() {
    context.go('/');
  }

  void _goActivities() {
    context.go('/activities');
  }

  void _openQrStub() {
    context.push('/qr');
  }

  void _openChatsStub() {
    context.push('/chats');
  }

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  bool _canReviewActivity(ActivityListItemVm item) {
    return item.status.trim().toUpperCase() == 'COMPLETED';
  }

  bool _canShowReviewAction(ActivityListItemVm item) {
    final activityId = item.id.trim();
    if (activityId.isEmpty) return false;
    return _canReviewActivity(item) &&
        _reviewEligibleActivityIds.contains(activityId);
  }

  ActivityReviewVm? _myActivityReview(
    List<ActivityReviewVm> reviews,
    String currentUserId,
  ) {
    final normalizedCurrentUserId = currentUserId.trim();
    if (normalizedCurrentUserId.isEmpty) return null;

    for (final review in reviews) {
      if (review.author.userId.trim() == normalizedCurrentUserId ||
          review.authorUserId.trim() == normalizedCurrentUserId) {
        return review;
      }
    }
    return null;
  }

  ActivityOrganizerReviewVm? _myOrganizerReview(
    List<ActivityOrganizerReviewVm> reviews,
    String currentUserId,
  ) {
    final normalizedCurrentUserId = currentUserId.trim();
    if (normalizedCurrentUserId.isEmpty) return null;

    for (final review in reviews) {
      if (review.author.userId.trim() == normalizedCurrentUserId ||
          review.authorUserId.trim() == normalizedCurrentUserId) {
        return review;
      }
    }
    return null;
  }

  ActivityParticipantVm? _currentReviewParticipant(
    List<ActivityParticipantVm> participants,
    String currentUserId,
  ) {
    final normalizedCurrentUserId = currentUserId.trim();
    if (normalizedCurrentUserId.isEmpty) return null;

    for (final participant in participants) {
      if (participant.userId.trim() == normalizedCurrentUserId) {
        return participant;
      }
    }
    return null;
  }

  bool _isActivityReviewConflict(Object error) {
    return error is DioException && error.response?.statusCode == 409;
  }

  bool _isReviewableParticipant(ActivityParticipantVm? participant) {
    switch (participant?.normalizedStatus) {
      case 'CHECKED_IN':
        return true;
      default:
        return false;
    }
  }

  void _storeReviewEligibility(String activityId, {required bool canReview}) {
    final normalizedActivityId = activityId.trim();
    if (normalizedActivityId.isEmpty) return;

    _reviewEligibilityLoadedActivityIds.add(normalizedActivityId);
    if (canReview) {
      _reviewEligibleActivityIds.add(normalizedActivityId);
    } else {
      _reviewEligibleActivityIds.remove(normalizedActivityId);
    }
  }

  void _setReviewEligibility(String activityId, {required bool canReview}) {
    if (!mounted) return;

    setState(() {
      _storeReviewEligibility(activityId, canReview: canReview);
    });
  }

  void _storeActivityReviewState(
    String activityId, {
    ActivityReviewVm? activityReview,
    ActivityOrganizerReviewVm? organizerReview,
  }) {
    _reviewStateLoadedActivityIds.add(activityId);
    if (activityReview != null || organizerReview != null) {
      _reviewedActivityIds.add(activityId);
    } else {
      _reviewedActivityIds.remove(activityId);
    }

    if (activityReview != null) {
      _activityReviewCache[activityId] = activityReview;
    } else {
      _activityReviewCache.remove(activityId);
    }

    if (organizerReview != null) {
      _organizerReviewCache[activityId] = organizerReview;
    } else {
      _organizerReviewCache.remove(activityId);
    }
  }

  void _setActivityReviewState(
    String activityId, {
    ActivityReviewVm? activityReview,
    ActivityOrganizerReviewVm? organizerReview,
  }) {
    if (!mounted) return;

    setState(() {
      _storeActivityReviewState(
        activityId,
        activityReview: activityReview,
        organizerReview: organizerReview,
      );
    });
  }

  void _scheduleReviewStateSyncForPage(
    List<ActivityListItemVm> items,
    String currentUserId,
  ) {
    if (_activeTab != _MyActivitiesTab.attended ||
        currentUserId.trim().isEmpty) {
      return;
    }

    final activityIds = items
        .where(_canReviewActivity)
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (activityIds.isEmpty) return;

    final syncKey = '$currentUserId:${activityIds.join(',')}';
    if (_lastReviewStateSyncKey == syncKey) return;
    _lastReviewStateSyncKey = syncKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncReviewStateForItems(activityIds, currentUserId, syncKey));
    });
  }

  Future<void> _syncReviewStateForItems(
    List<String> activityIds,
    String currentUserId,
    String syncKey,
  ) async {
    final pendingActivityIds = activityIds
        .where(
          (id) =>
              !_reviewStateLoadedActivityIds.contains(id) ||
              !_reviewEligibilityLoadedActivityIds.contains(id),
        )
        .toList(growable: false);
    if (pendingActivityIds.isEmpty) return;

    final updates = <String, _CachedActivityReviewState>{};
    var hasFailures = false;

    await Future.wait(
      pendingActivityIds.map((activityId) async {
        try {
          final results = await Future.wait<Object>([
            _activityApi.getActivityReviews(
              activityId: activityId,
              limit: 1000,
            ),
            _activityApi.getActivityOrganizerReviews(
              activityId: activityId,
              limit: 1000,
            ),
            _activityApi.getActivityParticipants(activityId, limit: 1000),
          ]);
          final activityReviewsPage = results[0] as ActivityReviewsPage;
          final organizerReviewsPage =
              results[1] as ActivityOrganizerReviewsPage;
          final participants = results[2] as List<ActivityParticipantVm>;
          final currentParticipant = _currentReviewParticipant(
            participants,
            currentUserId,
          );
          updates[activityId] = _CachedActivityReviewState(
            canReview: _isReviewableParticipant(currentParticipant),
            activityReview: _myActivityReview(
              activityReviewsPage.items,
              currentUserId,
            ),
            organizerReview: _myOrganizerReview(
              organizerReviewsPage.items,
              currentUserId,
            ),
          );
        } catch (_) {
          hasFailures = true;
        }
      }),
    );

    if (!mounted) return;
    if (updates.isEmpty) {
      if (hasFailures && _lastReviewStateSyncKey == syncKey) {
        _lastReviewStateSyncKey = null;
      }
      return;
    }

    setState(() {
      for (final entry in updates.entries) {
        _storeActivityReviewState(
          entry.key,
          activityReview: entry.value.activityReview,
          organizerReview: entry.value.organizerReview,
        );
        _storeReviewEligibility(entry.key, canReview: entry.value.canReview);
      }
      if (hasFailures && _lastReviewStateSyncKey == syncKey) {
        _lastReviewStateSyncKey = null;
      }
    });
  }

  Future<void> _openReviewSheet(ActivityListItemVm item) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId =
        context.read<SessionProvider>().profile?.userId.trim() ?? '';
    if (currentUserId.isEmpty) {
      context.push(
        Uri(
          path: '/login',
          queryParameters: {'from': '/me/activities'},
        ).toString(),
      );
      return;
    }

    if (!_canReviewActivity(item)) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewUnavailable,
      );
      return;
    }

    late final List<ActivityParticipantVm> participants;
    try {
      participants = await _activityApi.getActivityParticipants(
        item.id,
        limit: 1000,
      );
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewsLoadFailed,
      );
      return;
    }

    if (!mounted) return;
    final currentParticipant = _currentReviewParticipant(
      participants,
      currentUserId,
    );
    final canReview = _isReviewableParticipant(currentParticipant);
    _setReviewEligibility(item.id, canReview: canReview);
    if (!canReview) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewUnavailable,
      );
      return;
    }

    if (_reviewedActivityIds.contains(item.id) &&
        _reviewStateLoadedActivityIds.contains(item.id)) {
      await _showReviewEditor(
        item: item,
        currentUserId: currentUserId,
        existingActivityReview: _activityReviewCache[item.id],
        existingOrganizerReview: _organizerReviewCache[item.id],
        l10n: l10n,
      );
      return;
    }

    late final ActivityReviewsPage activityReviewsPage;
    late final ActivityOrganizerReviewsPage organizerReviewsPage;
    try {
      final results = await Future.wait<Object>([
        _activityApi.getActivityReviews(activityId: item.id, limit: 1000),
        _activityApi.getActivityOrganizerReviews(
          activityId: item.id,
          limit: 1000,
        ),
      ]);
      activityReviewsPage = results[0] as ActivityReviewsPage;
      organizerReviewsPage = results[1] as ActivityOrganizerReviewsPage;
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewsLoadFailed,
      );
      return;
    }

    if (!mounted) return;
    final existingActivityReview = _myActivityReview(
      activityReviewsPage.items,
      currentUserId,
    );
    final existingOrganizerReview = _myOrganizerReview(
      organizerReviewsPage.items,
      currentUserId,
    );
    final hadExistingReview =
        existingActivityReview != null || existingOrganizerReview != null;
    if (_reviewedActivityIds.contains(item.id) != hadExistingReview ||
        _activityReviewCache[item.id] != existingActivityReview ||
        _organizerReviewCache[item.id] != existingOrganizerReview) {
      _setActivityReviewState(
        item.id,
        activityReview: existingActivityReview,
        organizerReview: existingOrganizerReview,
      );
    }

    await _showReviewEditor(
      item: item,
      currentUserId: currentUserId,
      existingActivityReview: existingActivityReview,
      existingOrganizerReview: existingOrganizerReview,
      l10n: l10n,
    );
  }

  Future<void> _showReviewEditor({
    required ActivityListItemVm item,
    required String currentUserId,
    required ActivityReviewVm? existingActivityReview,
    required ActivityOrganizerReviewVm? existingOrganizerReview,
    required AppLocalizations l10n,
  }) async {
    final request = await showActivityReviewSheet(
      context,
      activityReview: existingActivityReview,
      organizerReview: existingOrganizerReview,
      allowOrganizerReview: item.hostUserId.trim() != currentUserId,
    );
    if (request == null || !mounted) return;

    try {
      final result = await _activityApi.saveActivityReviews(item.id, request);
      if (!mounted) return;
      _setActivityReviewState(
        item.id,
        activityReview: result.activityReview,
        organizerReview: result.organizerReview,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.activityReviewSaved)));
    } catch (error) {
      if (!mounted) return;
      if (_isActivityReviewConflict(error)) {
        await showErrorDialog(
          context,
          title: l10n.error,
          message: l10n.activityReviewUnavailable,
        );
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.activityReviewSaveFailed,
      );
    }
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (_searchQuery == nextQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextQuery;
      _hostedPage = 1;
      _attendedPage = 1;
    });
  }

  Future<void> _refreshActive(ActivityProvider provider) {
    if (_activeTab == _MyActivitiesTab.hosted) {
      return provider.refreshMyActivities();
    }
    return provider.refreshJoinedActivities();
  }

  Future<void> _initializeDefaultLocationFilter() async {
    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      await provider.load(
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    if (!mounted) return;
    _applyDefaultLocationFilter(provider);
  }

  void _applyDefaultLocationFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultLocationFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultLocationFilter = true;
      return;
    }

    final defaults = HomeLocationFilterDefaults.fromPreference(
      provider.effectiveLocation,
    );
    if (!defaults.hasValue) return;

    _hasAppliedDefaultLocationFilter = true;

    setState(
      () => _filters = _filters.copyWith(
        country: defaults.country,
        city: defaults.city,
      ),
    );
  }

  ActivitiesState _activeState(ActivityProvider provider) {
    return _activeTab == _MyActivitiesTab.hosted
        ? provider.myState
        : provider.joinedState;
  }

  String? _activeError(ActivityProvider provider) {
    return _activeTab == _MyActivitiesTab.hosted
        ? provider.myErrorMessage
        : provider.joinedErrorMessage;
  }

  List<ActivityListItemVm> _activeItems(
    ActivityProvider provider, {
    required String currentUserId,
  }) {
    if (_activeTab == _MyActivitiesTab.hosted) {
      return provider.myItems;
    }

    final normalizedCurrentUserId = currentUserId.trim();
    final hostedActivityIds = provider.myItems
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    return provider.joinedItems
        .where((item) {
          final itemId = item.id.trim();
          if (itemId.isNotEmpty && hostedActivityIds.contains(itemId)) {
            return false;
          }

          return normalizedCurrentUserId.isEmpty ||
              item.hostUserId.trim() != normalizedCurrentUserId;
        })
        .toList(growable: false);
  }

  int get _activePage {
    return _activeTab == _MyActivitiesTab.hosted ? _hostedPage : _attendedPage;
  }

  Future<void> _setActivePage(int page) async {
    if (page == _activePage) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      if (_activeTab == _MyActivitiesTab.hosted) {
        _hostedPage = page;
      } else {
        _attendedPage = page;
      }
    });
    if (!_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _resetActivePage() {
    if (_activeTab == _MyActivitiesTab.hosted) {
      _hostedPage = 1;
    } else {
      _attendedPage = 1;
    }
  }

  List<String> _statusOrderForTab(_MyActivitiesTab tab) {
    return tab == _MyActivitiesTab.hosted
        ? _hostedFilterOrder
        : _attendedFilterOrder;
  }

  _MyActivitiesFilters _filtersForTab(_MyActivitiesTab tab) {
    return _filters.onlyAllowedStatuses(_statusOrderForTab(tab).toSet());
  }

  List<ActivityListItemVm> _filterItems(
    List<ActivityListItemVm> items, {
    _MyActivitiesFilters? filters,
  }) {
    final activeFilters = (filters ?? _filtersForTab(_activeTab))
        .onlyAllowedStatuses(_statusOrderForTab(_activeTab).toSet());
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return items.where((item) {
      if (!_matchesLocationFilter(item, activeFilters)) {
        return false;
      }

      if (activeFilters.statuses.isNotEmpty &&
          !activeFilters.statuses.any(
            (status) => _matchesStatus(item, status),
          )) {
        return false;
      }

      if (activeFilters.startDate != null) {
        final startBoundary = DateTime(
          activeFilters.startDate!.year,
          activeFilters.startDate!.month,
          activeFilters.startDate!.day,
        );
        if (item.startAt.isBefore(startBoundary)) {
          return false;
        }
      }

      if (activeFilters.endDate != null) {
        final endBoundary = DateTime(
          activeFilters.endDate!.year,
          activeFilters.endDate!.month,
          activeFilters.endDate!.day,
          23,
          59,
          59,
          999,
        );
        if (item.startAt.isAfter(endBoundary)) {
          return false;
        }
      }

      if (normalizedQuery.isNotEmpty) {
        final haystack = [
          item.title,
          item.description,
          item.shortLocation,
          item.tags.join(' '),
        ].join(' ').toLowerCase();

        if (!haystack.contains(normalizedQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _matchesLocationFilter(
    ActivityListItemVm item,
    _MyActivitiesFilters filters,
  ) {
    if (filters.country != null &&
        !filters.country!.matches(countryCode: item.countryCode)) {
      return false;
    }

    final selectedCity = filters.city;
    if (selectedCity == null) return true;
    return selectedCity.matches(
      cityId: item.cityId,
      cityName: item.cityName,
      countryCode: item.countryCode,
    );
  }

  String _myActivitiesEmptyMessage(AppLocalizations l10n) {
    final base = _activeTab == _MyActivitiesTab.hosted
        ? l10n.myActivitiesEmptyHint
        : l10n.myActivitiesAttendedEmptyHint;
    final filters = _filtersForTab(_activeTab);
    if (filters.city == null && filters.country == null) return base;
    return '$base\n\n${l10n.cityFilterEmptyHint}';
  }

  bool _matchesStatus(ActivityListItemVm item, String filterKey) {
    final status = item.status.toUpperCase();
    if (filterKey == 'PUBLISHED') {
      return _publishedStatuses.contains(status);
    }
    return status == filterKey;
  }

  List<_FilterStatusOption> _buildStatusOptions(
    AppLocalizations l10n,
    List<ActivityListItemVm> items,
  ) {
    final statusOrder = _statusOrderForTab(_activeTab);
    final counts = <String, int>{for (final key in statusOrder) key: 0};

    for (final item in items) {
      for (final key in statusOrder) {
        if (_matchesStatus(item, key)) {
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    return statusOrder
        .map(
          (key) => _FilterStatusOption(
            key: key,
            label: _statusLabel(key, l10n),
            count: counts[key] ?? 0,
          ),
        )
        .toList();
  }

  String _statusLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'PUBLISHED':
        return l10n.activityStatusPublished;
      case 'COMPLETED':
        return l10n.activityStatusCompleted;
      case 'CANCELLED':
        return l10n.activityStatusCancelled;
      default:
        return key;
    }
  }

  String _activityCategoryLabel(
    ActivityListItemVm item,
    List<ActivityCategoryVm> categories,
    String languageCode,
  ) {
    return localizedActivityCategoryLabel(
      categories: categories,
      slug: item.categorySlug,
      languageCode: languageCode,
    );
  }

  Future<void> _openFilters(
    AppLocalizations l10n,
    List<ActivityListItemVm> items,
  ) async {
    final availableStatuses = _statusOrderForTab(_activeTab).toSet();
    final result = await showAppModalBottomSheet<_MyActivitiesFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _MyActivitiesPalette.of(context).transparent,
      builder: (context) {
        return _MyActivitiesFilterSheet(
          l10n: l10n,
          initialFilters: _filters.onlyAllowedStatuses(availableStatuses),
          statusOptions: _buildStatusOptions(l10n, items),
          previewCountBuilder: (filters) =>
              _filterItems(items, filters: filters).length,
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _filters = _MyActivitiesFilters(
        country: result.country,
        city: result.city,
        statuses: <String>{
          ..._filters.statuses.where(
            (status) => !availableStatuses.contains(status),
          ),
          ...result.statuses,
        },
        startDate: result.startDate,
        endDate: result.endDate,
      );
      _resetActivePage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layout = _MyActivitiesAdaptiveLayout.of(context);
    final palette = _MyActivitiesPalette.of(context);
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final currentUserId = context.select<SessionProvider, String>(
      (session) => session.profile?.userId.trim() ?? '',
    );

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: palette.background,
        bottomNavigationBar: CreateActionBottomNavigationBar(
          backgroundStyle: AppBottomNavCreateBackgroundStyle.flat,
          onHomeTap: _goHome,
          onQrTap: _openQrStub,
          onCreateTap: _openCreateActivity,
          onServicesTap: _goActivities,
          onChatsTap: _openChatsStub,
        ),
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.screenGradientColors,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Consumer<ActivityProvider>(
              builder: (context, provider, _) {
                final items = _activeItems(
                  provider,
                  currentUserId: currentUserId,
                );
                final state = _activeState(provider);
                final locale = Localizations.localeOf(context);
                final localeName = locale.toString();
                final filteredItems = _filterItems(items);
                final paginatedItems = paginateItems(
                  filteredItems,
                  currentPage: _activePage,
                  pageSize: _pageSize,
                );
                _scheduleReviewStateSyncForPage(
                  paginatedItems.items,
                  currentUserId,
                );
                final errorMessage = _activeError(provider);
                final isInitialLoading =
                    state == ActivitiesState.loading && items.isEmpty;
                final isInitialError =
                    state == ActivitiesState.error && items.isEmpty;

                return RefreshIndicator(
                  color: palette.accent,
                  backgroundColor: palette.card,
                  onRefresh: () => _refreshActive(provider),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AppEdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          layout.topPadding,
                          layout.horizontalPadding,
                          layout.listBottomPadding + safeBottomInset,
                        ),
                        children: [
                          AppListScreenHeader(
                            title: l10n.myActivitiesTitle,
                            notificationsTooltip:
                                l10n.profileNotificationsRowTitle,
                            onBackTap: _goBack,
                            onNotificationsTap: () =>
                                context.push('/notifications'),
                            horizontalPadding: 0,
                          ),
                          SizedBox(height: layout.topSectionSpacing),
                          _MyActivitiesSearchField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            hintText: l10n.activitiesSearchHint,
                            filterActiveCount: _filtersForTab(
                              _activeTab,
                            ).activeCount,
                            onFilterTap: () => _openFilters(l10n, items),
                          ),
                          SizedBox(height: layout.topSectionSpacing),
                          _MyActivitiesTabSwitcher(
                            activeTab: _activeTab,
                            hostedLabel: l10n.myActivitiesTitle,
                            attendedLabel: l10n.myActivitiesAttendedTab,
                            onChanged: (tab) =>
                                setState(() => _activeTab = tab),
                          ),
                          SizedBox(height: layout.cardSpacing),
                          if (isInitialLoading) ...[
                            const _MyActivitiesSkeletonCard(),
                            SizedBox(height: layout.cardSpacing),
                            const _MyActivitiesSkeletonCard(),
                            SizedBox(height: layout.cardSpacing),
                            const _MyActivitiesSkeletonCard(),
                          ] else if (isInitialError) ...[
                            _MyActivitiesInfoCard(
                              icon: Icons.wifi_off_rounded,
                              title: _activeTab == _MyActivitiesTab.hosted
                                  ? l10n.myActivitiesLoadFailed
                                  : l10n.myActivitiesAttendedLoadFailed,
                              message:
                                  errorMessage ??
                                  (_activeTab == _MyActivitiesTab.hosted
                                      ? l10n.myActivitiesLoadFailed
                                      : l10n.myActivitiesAttendedLoadFailed),
                              actionLabel: l10n.myActivitiesRetryButton,
                              onActionTap: () => _refreshActive(provider),
                            ),
                          ] else if (filteredItems.isEmpty) ...[
                            _MyActivitiesInfoCard(
                              icon: _activeTab == _MyActivitiesTab.hosted
                                  ? Icons.event_note_rounded
                                  : Icons.check_circle_outline_rounded,
                              title: _activeTab == _MyActivitiesTab.hosted
                                  ? l10n.myActivitiesEmpty
                                  : l10n.myActivitiesAttendedEmpty,
                              message: _myActivitiesEmptyMessage(l10n),
                            ),
                          ] else ...[
                            for (
                              var i = 0;
                              i < paginatedItems.items.length;
                              i++
                            ) ...[
                              Builder(
                                builder: (context) {
                                  final item = paginatedItems.items[i];
                                  return _MyActivitiesCard(
                                    item: item,
                                    tab: _activeTab,
                                    localeName: localeName,
                                    categoryLabel: _activityCategoryLabel(
                                      item,
                                      provider.categoryItems,
                                      locale.languageCode,
                                    ),
                                    onPrimaryTap: () {
                                      if (_activeTab ==
                                          _MyActivitiesTab.attended) {
                                        _openDetails(item);
                                        return;
                                      }

                                      final status = item.status.toUpperCase();
                                      if (status == 'COMPLETED' ||
                                          status == 'CANCELLED' ||
                                          status == 'ARCHIVED') {
                                        _openDetails(item);
                                        return;
                                      }
                                      _openEdit(item);
                                    },
                                    onSecondaryTap:
                                        _activeTab == _MyActivitiesTab.hosted
                                        ? () {
                                            if (item.status.toUpperCase() ==
                                                'CANCELLED') {
                                              _openRepeat(item);
                                              return;
                                            }
                                            _showComingSoon();
                                          }
                                        : null,
                                    onReviewTap:
                                        _activeTab ==
                                                _MyActivitiesTab.attended &&
                                            _canShowReviewAction(item)
                                        ? () => _openReviewSheet(item)
                                        : null,
                                    hasReview: _reviewedActivityIds.contains(
                                      item.id,
                                    ),
                                    onCardTap: () => _openDetails(item),
                                  );
                                },
                              ),
                              if (i != paginatedItems.items.length - 1)
                                SizedBox(height: layout.cardSpacing),
                            ],
                            if (paginatedItems.hasMultiplePages) ...[
                              SizedBox(height: layout.sectionSpacing),
                              InflapPaginationBar(
                                currentPage: paginatedItems.currentPage,
                                totalPages: paginatedItems.totalPages,
                                onPageChanged: _setActivePage,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MyActivitiesFilters {
  const _MyActivitiesFilters({
    this.country,
    this.city,
    this.statuses = const <String>{},
    this.startDate,
    this.endDate,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final Set<String> statuses;
  final DateTime? startDate;
  final DateTime? endDate;

  int get activeCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      statuses.length +
      (startDate == null ? 0 : 1) +
      (endDate == null ? 0 : 1);

  _MyActivitiesFilters copyWith({
    Object? country = _unset,
    Object? city = _unset,
    Set<String>? statuses,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return _MyActivitiesFilters(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      statuses: statuses ?? this.statuses,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }

  _MyActivitiesFilters onlyAllowedStatuses(Set<String> allowedStatuses) {
    return _MyActivitiesFilters(
      country: country,
      city: city,
      statuses: statuses.where(allowedStatuses.contains).toSet(),
      startDate: startDate,
      endDate: endDate,
    );
  }

  static const Object _unset = Object();
}

class _FilterStatusOption {
  const _FilterStatusOption({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class _CachedActivityReviewState {
  const _CachedActivityReviewState({
    required this.canReview,
    required this.activityReview,
    required this.organizerReview,
  });

  final bool canReview;
  final ActivityReviewVm? activityReview;
  final ActivityOrganizerReviewVm? organizerReview;
}

class _MyActivityMetaData {
  const _MyActivityMetaData({
    required this.icon,
    this.label = '',
    this.labelBuilder,
  });

  final IconData icon;
  final String label;
  final Widget Function(TextStyle style)? labelBuilder;
}

IconData _activityFormatIcon(String format) {
  switch (format.toUpperCase()) {
    case 'ONLINE':
      return Icons.videocam_outlined;
    case 'HYBRID':
      return Icons.devices_outlined;
    default:
      return Icons.location_on_outlined;
  }
}

IconData _activityCategoryIcon(ActivityListItemVm item) {
  switch (item.format.toUpperCase()) {
    case 'ONLINE':
      return Icons.videocam_rounded;
    case 'HYBRID':
      return Icons.devices_rounded;
    default:
      return Icons.travel_explore_rounded;
  }
}

final class _MyActivitiesPalette {
  const _MyActivitiesPalette._(this.colors);

  final AppColors colors;

  static _MyActivitiesPalette of(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return _MyActivitiesPalette._(colors);
  }

  Color get backgroundTop => colors.backgroundDeep;
  Color get background => colors.background;
  Color get backgroundBottom => colors.backgroundWarm;
  List<Color> get screenGradientColors => colors.screenGradientColors;
  Color get surface => colors.surface;
  Color get surfaceSoft => colors.surfaceRaised;
  Color get surfaceHigh => colors.surfaceHigh;
  Color get surfaceWarm => colors.surfaceWarm;
  Color get card => colors.surfaceRaised;
  Color get accent => colors.primary;
  Color get primary => colors.primary;
  Color get primarySoft => colors.primarySoft;
  Color get primaryContainer => colors.primaryContainer;
  Color get secondary => colors.secondary;
  Color get text => colors.textPrimary;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get badgeCompleted => colors.success;
  Color get badgeCancelled => colors.danger;
  Color get success => colors.success;
  Color get danger => colors.danger;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
}

class _MyActivitiesAdaptiveLayout {
  const _MyActivitiesAdaptiveLayout._({
    required this.screenWidth,
    required this.textScale,
  });

  factory _MyActivitiesAdaptiveLayout.of(BuildContext context) {
    return _MyActivitiesAdaptiveLayout._(
      screenWidth: MediaQuery.sizeOf(context).width,
      textScale: MediaQuery.textScalerOf(context).scale(1),
    );
  }

  final double screenWidth;
  final double textScale;

  bool get isCompact => screenWidth < 360 || textScale > 1.1;
  bool get isLargePhone => screenWidth >= 430;
  bool get isWideMobile => screenWidth >= 600;

  double get horizontalPadding => isCompact
      ? 16
      : isLargePhone
      ? 24
      : 20;
  double get topPadding => isCompact ? 12 : 14;
  double get topSectionSpacing => isCompact ? 12 : 14;
  double get sectionSpacing => isCompact ? 14 : 16;
  double get cardSpacing => isCompact ? 14 : 16;
  double get listBottomPadding => isCompact ? 118 : 130;
  double get maxContentWidth => isWideMobile ? 460 : double.infinity;
  double get topBarTitleSize => isCompact ? 18 : 20;
  double get segmentHeight => isCompact ? 40 : 42;
  double get segmentFontSize => isCompact ? 13 : 15;
  double get navLabelSize => isCompact ? 10.5 : 12;
  double get navIconSize => isCompact ? 20 : 22;
  double get navVerticalPadding => isCompact ? 4 : 6;
  double get navHorizontalPadding => isCompact ? 6 : 10;
}

class _MyActivitiesSearchField extends StatelessWidget {
  const _MyActivitiesSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.filterActiveCount,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int filterActiveCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final filterActive = filterActiveCount > 0;

    return Container(
      decoration: AppBoxDecoration(
        borderRadius: AppBorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            _MyActivitiesPalette.of(context).white.withValues(alpha: 0.035),
            _MyActivitiesPalette.of(context).white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(
          color: _MyActivitiesPalette.of(
            context,
          ).primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: _MyActivitiesPalette.of(
              context,
            ).black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: AppTextStyle(
          color: _MyActivitiesPalette.of(context).textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: _MyActivitiesPalette.of(context).primary,
        decoration: AppInputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: AppTextStyle(
            color: _MyActivitiesPalette.of(context).textMuted,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const AppEdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          prefixIcon: Padding(
            padding: AppEdgeInsets.only(left: 12, right: 10),
            child: Icon(
              Icons.search_rounded,
              color: _MyActivitiesPalette.of(context).primary,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  onPressed: controller.clear,
                  splashRadius: 20,
                  icon: Icon(
                    Icons.close_rounded,
                    color: _MyActivitiesPalette.of(context).primary,
                  ),
                ),
              Padding(
                padding: const AppEdgeInsets.only(right: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: AppLocalizations.of(
                        context,
                      )!.myActivitiesFilterTitle,
                      onPressed: onFilterTap,
                      splashRadius: 20,
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _MyActivitiesPalette.of(context).primary,
                        size: 20,
                      ),
                    ),
                    if (filterActive)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const AppEdgeInsets.symmetric(horizontal: 4),
                          decoration: AppBoxDecoration(
                            color: _MyActivitiesPalette.of(context).accent,
                            borderRadius: AppBorderRadius.circular(999),
                            border: Border.all(width: 1.4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$filterActiveCount',
                            style: AppTextStyle(
                              color: _MyActivitiesPalette.of(
                                context,
                              ).textPrimary,
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
        ),
      ),
    );
  }
}

class _MyActivitiesTabSwitcher extends StatelessWidget {
  const _MyActivitiesTabSwitcher({
    required this.activeTab,
    required this.hostedLabel,
    required this.attendedLabel,
    required this.onChanged,
  });

  final _MyActivitiesTab activeTab;
  final String hostedLabel;
  final String attendedLabel;
  final ValueChanged<_MyActivitiesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return Container(
      padding: AppEdgeInsets.all(layout.isCompact ? 5 : 6),
      decoration: AppBoxDecoration(
        color: _MyActivitiesPalette.of(context).surfaceSoft,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(
          color: _MyActivitiesPalette.of(context).white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: hostedLabel,
              isActive: activeTab == _MyActivitiesTab.hosted,
              onTap: () => onChanged(_MyActivitiesTab.hosted),
            ),
          ),
          SizedBox(width: layout.isCompact ? 6 : 8),
          Expanded(
            child: _SegmentButton(
              label: attendedLabel,
              isActive: activeTab == _MyActivitiesTab.attended,
              onTap: () => onChanged(_MyActivitiesTab.attended),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return Material(
      color: _MyActivitiesPalette.of(context).transparent,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: layout.segmentHeight,
          decoration: AppBoxDecoration(
            color: isActive
                ? _MyActivitiesPalette.of(context).accent
                : _MyActivitiesPalette.of(context).transparent,
            borderRadius: AppBorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _MyActivitiesPalette.of(
                        context,
                      ).accent.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const AppEdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyle(
                    color: isActive
                        ? _MyActivitiesPalette.of(context).textPrimary
                        : _MyActivitiesPalette.of(context).textSecondary,
                    fontSize: layout.segmentFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyActivitiesCard extends StatelessWidget {
  const _MyActivitiesCard({
    required this.item,
    required this.tab,
    required this.localeName,
    required this.categoryLabel,
    required this.onPrimaryTap,
    required this.onCardTap,
    this.hasReview = false,
    this.onSecondaryTap,
    this.onReviewTap,
  });

  final ActivityListItemVm item;
  final _MyActivitiesTab tab;
  final String localeName;
  final String categoryLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onCardTap;
  final bool hasReview;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onReviewTap;

  bool get _isHostedReadOnly =>
      tab == _MyActivitiesTab.hosted &&
      const {
        'COMPLETED',
        'CANCELLED',
        'ARCHIVED',
      }.contains(item.status.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateText = formatEventDateTime(
      item.startAt,
      timezoneId: item.timezone,
      localeName: localeName,
    );
    final locationFallbackText = activityLocationFallbackText(item, l10n);
    final normalizedCategoryLabel = categoryLabel.trim();
    final metaItems = <_MyActivityMetaData>[
      _MyActivityMetaData(
        icon: Icons.place_outlined,
        label: locationFallbackText,
        labelBuilder: (style) => AppLocalizedLocationText(
          countryCode: item.countryCode,
          cityId: item.cityId,
          cityName: item.cityName,
          fallbackText: locationFallbackText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
      _MyActivityMetaData(
        icon: _activityFormatIcon(item.format),
        label: formatActivityFormat(item.format, l10n),
      ),
      _MyActivityMetaData(icon: Icons.schedule_outlined, label: dateText),
      _MyActivityMetaData(
        icon: Icons.groups_2_outlined,
        label: item.maxParticipants == null
            ? l10n.activityUnlimitedSpots
            : l10n.activityPeopleMax(item.maxParticipants!),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactCard = constraints.maxWidth < 340 || textScale > 1.1;
        final stackPrimaryActions =
            constraints.maxWidth < 330 || textScale > 1.18;
        final radius = compactCard ? 22.0 : 26.0;
        final contentPadding = compactCard ? 12.0 : 14.0;

        return Material(
          color: _MyActivitiesPalette.of(context).transparent,
          child: InkWell(
            borderRadius: AppBorderRadius.circular(radius),
            onTap: onCardTap,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _MyActivitiesPalette.of(context).card,
                    _MyActivitiesPalette.of(context).surface,
                  ],
                ),
                borderRadius: AppBorderRadius.circular(radius),
                border: Border.all(
                  color: _MyActivitiesPalette.of(
                    context,
                  ).accent.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _MyActivitiesPalette.of(
                      context,
                    ).black.withValues(alpha: 0.38),
                    blurRadius: compactCard ? 28 : 40,
                    offset: Offset(0, compactCard ? 12 : 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActivityCover(item: item),
                  Padding(
                    padding: AppEdgeInsets.fromLTRB(
                      contentPadding,
                      compactCard ? 12 : 14,
                      contentPadding,
                      compactCard ? 12 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (normalizedCategoryLabel.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: compactCard ? 32 : 34,
                                height: compactCard ? 32 : 34,
                                decoration: AppBoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _MyActivitiesPalette.of(
                                    context,
                                  ).accent.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: _MyActivitiesPalette.of(
                                      context,
                                    ).white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Icon(
                                  _activityCategoryIcon(item),
                                  color: _MyActivitiesPalette.of(
                                    context,
                                  ).accent,
                                  size: compactCard ? 16 : 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  normalizedCategoryLabel.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: _MyActivitiesPalette.of(
                                      context,
                                    ).primary,
                                    fontSize: compactCard ? 10 : 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compactCard ? 10 : 12),
                        ],
                        if (compactCard) ...[
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: _MyActivitiesPalette.of(context).text,
                              fontSize: 17,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ] else
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: _MyActivitiesPalette.of(context).text,
                              fontSize: 19,
                              height: 1.08,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        SizedBox(height: compactCard ? 6 : 7),
                        LayoutBuilder(
                          builder: (context, metaConstraints) {
                            final gap = compactCard ? 8.0 : 10.0;
                            final columns = metaConstraints.maxWidth < 320
                                ? 1
                                : 2;
                            final itemWidth =
                                (metaConstraints.maxWidth -
                                    gap * (columns - 1)) /
                                columns;

                            return Wrap(
                              spacing: gap,
                              runSpacing: compactCard ? 8 : 10,
                              children: [
                                for (final meta in metaItems)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _MetaItem(
                                      icon: meta.icon,
                                      label: meta.label,
                                      labelBuilder: meta.labelBuilder,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: compactCard ? 10 : 12),
                        _buildActions(
                          context,
                          l10n,
                          stackPrimaryActions: stackPrimaryActions,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppLocalizations l10n, {
    required bool stackPrimaryActions,
  }) {
    if (tab == _MyActivitiesTab.attended) {
      if (onReviewTap != null) {
        return SizedBox(
          width: double.infinity,
          child: _CardActionButton(
            label: hasReview
                ? l10n.activityReviewEditButton
                : l10n.activityReviewWriteButton,
            icon: Icons.star_rounded,
            onTap: onReviewTap,
            variant: _CardActionVariant.primary,
          ),
        );
      }

      return const SizedBox.shrink();
    }

    if (_isHostedReadOnly) {
      if (onSecondaryTap == null) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        width: double.infinity,
        child: _CardActionButton(
          label: l10n.myActivitiesRecreateButton,
          icon: Icons.copy_rounded,
          onTap: onSecondaryTap,
          variant: _CardActionVariant.secondary,
        ),
      );
    }

    if (stackPrimaryActions) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _CardActionButton(
              label: l10n.editActivityButton,
              icon: Icons.edit_outlined,
              onTap: onPrimaryTap,
              variant: _CardActionVariant.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _CardActionButton(
              label: l10n.myActivitiesRecreateButton,
              icon: Icons.copy_rounded,
              onTap: onSecondaryTap,
              variant: _CardActionVariant.secondary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _CardActionButton(
            label: l10n.editActivityButton,
            icon: Icons.edit_outlined,
            onTap: onPrimaryTap,
            variant: _CardActionVariant.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CardActionButton(
            label: l10n.myActivitiesRecreateButton,
            icon: Icons.copy_rounded,
            onTap: onSecondaryTap,
            variant: _CardActionVariant.secondary,
          ),
        ),
      ],
    );
  }
}

class _ActivityCover extends StatelessWidget {
  const _ActivityCover({required this.item});

  final ActivityListItemVm item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final status = item.status.toUpperCase();
    final badge = _statusBadgeStyle(context, status);
    final statusText = formatActivityDisplayStatus(item, l10n);
    final priceText = item.isFree
        ? l10n.createPriceFree
        : item.formattedPriceLabel(localeName);
    final imageUrl = resolveActivityCoverUrl(item)?.trim() ?? '';
    final badgeMaxWidth = MediaQuery.sizeOf(context).width * 0.42;

    return AspectRatio(
      aspectRatio: 1.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ActivityCoverFallback(item: item),
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _MyActivitiesPalette.of(
                    context,
                  ).black.withValues(alpha: 0.02),
                  _MyActivitiesPalette.of(
                    context,
                  ).black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              constraints: BoxConstraints(maxWidth: badgeMaxWidth),
              padding: const AppEdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: AppBoxDecoration(
                color: badge.background,
                borderRadius: AppBorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: badge.foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              constraints: BoxConstraints(maxWidth: badgeMaxWidth),
              padding: const AppEdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: AppBoxDecoration(
                color: _MyActivitiesPalette.of(
                  context,
                ).black.withValues(alpha: 0.48),
                borderRadius: AppBorderRadius.circular(999),
              ),
              child: Text(
                priceText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: item.isFree
                      ? _MyActivitiesPalette.of(context).success
                      : _MyActivitiesPalette.of(context).accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusBadgeStyle _statusBadgeStyle(BuildContext context, String status) {
    switch (status) {
      case 'COMPLETED':
        return _StatusBadgeStyle(
          background: _MyActivitiesPalette.of(context).badgeCompleted,
          foreground: _MyActivitiesPalette.of(context).textPrimary,
        );
      case 'CANCELLED':
        return _StatusBadgeStyle(
          background: _MyActivitiesPalette.of(context).badgeCancelled,
          foreground: _MyActivitiesPalette.of(context).textPrimary,
        );
      case 'ARCHIVED':
        return _StatusBadgeStyle(
          background: _MyActivitiesPalette.of(context).surfaceHigh,
          foreground: _MyActivitiesPalette.of(context).textPrimary,
        );
      default:
        return _StatusBadgeStyle(
          background: _MyActivitiesPalette.of(context).accent,
          foreground: _MyActivitiesPalette.of(context).textPrimary,
        );
    }
  }
}

class _ActivityCoverFallback extends StatelessWidget {
  const _ActivityCoverFallback({required this.item});

  final ActivityListItemVm item;

  @override
  Widget build(BuildContext context) {
    final cover = _coverPalette(context, item);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cover,
            ),
          ),
        ),
        Center(
          child: Icon(
            _coverIcon(item),
            size: 54,
            color: _MyActivitiesPalette.of(
              context,
            ).white.withValues(alpha: 0.22),
          ),
        ),
      ],
    );
  }

  List<Color> _coverPalette(BuildContext context, ActivityListItemVm item) {
    switch (item.categorySlug) {
      case 'adventure-sports':
        return [
          _MyActivitiesPalette.of(context).surfaceWarm,
          _MyActivitiesPalette.of(context).primaryContainer,
        ];
      case 'social-nightlife':
        return [
          _MyActivitiesPalette.of(context).surfaceWarm,
          _MyActivitiesPalette.of(context).danger,
        ];
      case 'health-wellness':
        return [
          _MyActivitiesPalette.of(context).surfaceHigh,
          _MyActivitiesPalette.of(context).secondary,
        ];
      case 'workshops-learning':
        return [
          _MyActivitiesPalette.of(context).surfaceHigh,
          _MyActivitiesPalette.of(context).secondary,
        ];
      default:
        return item.format.toUpperCase() == 'ONLINE'
            ? [
                _MyActivitiesPalette.of(context).surfaceHigh,
                _MyActivitiesPalette.of(context).secondary,
              ]
            : [
                _MyActivitiesPalette.of(context).surfaceWarm,
                _MyActivitiesPalette.of(context).primarySoft,
              ];
    }
  }

  IconData _coverIcon(ActivityListItemVm item) {
    switch (item.format.toUpperCase()) {
      case 'ONLINE':
        return Icons.videocam_rounded;
      case 'HYBRID':
        return Icons.devices_rounded;
      default:
        return Icons.landscape_rounded;
    }
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.labelBuilder});

  final IconData icon;
  final String label;
  final Widget Function(TextStyle style)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Row(
      children: [
        Icon(icon, size: 16, color: _MyActivitiesPalette.of(context).textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Builder(
            builder: (context) {
              final style = AppTextStyle(
                color: _MyActivitiesPalette.of(context).textMuted,
                fontSize: compact ? 12 : 13,
                height: 1.25,
              );
              return labelBuilder?.call(style) ??
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  );
            },
          ),
        ),
      ],
    );
  }
}

enum _CardActionVariant { primary, secondary, disabled }

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final _CardActionVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final backgroundColor = switch (variant) {
      _CardActionVariant.primary => _MyActivitiesPalette.of(context).accent,
      _CardActionVariant.secondary => _MyActivitiesPalette.of(
        context,
      ).accent.withValues(alpha: 0.08),
      _CardActionVariant.disabled => _MyActivitiesPalette.of(
        context,
      ).accent.withValues(alpha: 0.05),
    };

    final foregroundColor = switch (variant) {
      _CardActionVariant.primary => _MyActivitiesPalette.of(
        context,
      ).textPrimary,
      _CardActionVariant.secondary => _MyActivitiesPalette.of(context).primary,
      _CardActionVariant.disabled => _MyActivitiesPalette.of(context).textMuted,
    };

    final buttonHeight = compact ? 42.0 : 46.0;

    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(999),
          ),
          elevation: 0,
          padding: AppEdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          textStyle: AppTextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, size: compact ? 14 : 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyActivitiesInfoCard extends StatelessWidget {
  const _MyActivitiesInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: AppEdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 22 : 26,
        compact ? 18 : 22,
        compact ? 20 : 24,
      ),
      decoration: AppBoxDecoration(
        color: _MyActivitiesPalette.of(context).surfaceSoft,
        borderRadius: AppBorderRadius.circular(30),
        border: Border.all(
          color: _MyActivitiesPalette.of(
            context,
          ).accent.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 52 : 58,
            height: compact ? 52 : 58,
            decoration: AppBoxDecoration(
              color: _MyActivitiesPalette.of(
                context,
              ).accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _MyActivitiesPalette.of(context).accent,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            title,
            style: AppTextStyle(
              color: _MyActivitiesPalette.of(context).text,
              fontSize: compact ? 22 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            message,
            style: AppTextStyle(
              color: _MyActivitiesPalette.of(context).textMuted,
              fontSize: compact ? 14 : 15,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            SizedBox(height: compact ? 14 : 18),
            SizedBox(
              width: double.infinity,
              child: _CardActionButton(
                label: actionLabel!,
                icon: Icons.refresh_rounded,
                onTap: onActionTap,
                variant: _CardActionVariant.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyActivitiesSkeletonCard extends StatelessWidget {
  const _MyActivitiesSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      decoration: AppBoxDecoration(
        color: _MyActivitiesPalette.of(context).surfaceSoft,
        borderRadius: AppBorderRadius.circular(34),
        border: Border.all(
          color: _MyActivitiesPalette.of(context).white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.55,
            child: Container(
              decoration: AppBoxDecoration(
                color: _MyActivitiesPalette.of(
                  context,
                ).white.withValues(alpha: 0.05),
                borderRadius: const AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(34),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppEdgeInsets.all(compact ? 16 : 20),
            child: Column(
              children: [
                _SkeletonLine(width: double.infinity, height: 22),
                const SizedBox(height: 12),
                const FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.58,
                  child: _SkeletonLine(width: double.infinity, height: 16),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: _SkeletonLine(width: 0, height: 18)),
                    SizedBox(width: 12),
                    Expanded(child: _SkeletonLine(width: 0, height: 18)),
                  ],
                ),
                const SizedBox(height: 18),
                const _SkeletonLine(width: double.infinity, height: 58),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        final double? lineWidth;
        if (availableWidth == null) {
          lineWidth = width == 0 || width == double.infinity ? null : width;
        } else if (width == 0 || width == double.infinity) {
          lineWidth = availableWidth;
        } else {
          lineWidth = width.clamp(0, availableWidth).toDouble();
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: lineWidth,
            height: height,
            decoration: AppBoxDecoration(
              color: _MyActivitiesPalette.of(
                context,
              ).white.withValues(alpha: 0.07),
              borderRadius: AppBorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }
}

class _MyActivitiesFilterSheet extends StatefulWidget {
  const _MyActivitiesFilterSheet({
    required this.l10n,
    required this.initialFilters,
    required this.statusOptions,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final _MyActivitiesFilters initialFilters;
  final List<_FilterStatusOption> statusOptions;
  final int Function(_MyActivitiesFilters filters) previewCountBuilder;

  @override
  State<_MyActivitiesFilterSheet> createState() =>
      _MyActivitiesFilterSheetState();
}

class _MyActivitiesFilterSheetState extends State<_MyActivitiesFilterSheet> {
  late AppCountryFilterValue? _country;
  late AppCityFilterValue? _city;
  late Set<String> _selectedStatuses;
  late final ScrollController _sheetScrollController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final FocusNode _startDateFocusNode;
  late final FocusNode _endDateFocusNode;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startDateError;
  String? _endDateError;

  @override
  void initState() {
    super.initState();
    _country = widget.initialFilters.country;
    _city = widget.initialFilters.city;
    _selectedStatuses = Set<String>.from(widget.initialFilters.statuses);
    _sheetScrollController = ScrollController();
    _startDate = widget.initialFilters.startDate;
    _endDate = widget.initialFilters.endDate;
    _startDateController = TextEditingController(
      text: _startDate == null ? '' : _formatDate(_startDate!),
    );
    _endDateController = TextEditingController(
      text: _endDate == null ? '' : _formatDate(_endDate!),
    );
    _startDateFocusNode = FocusNode();
    _endDateFocusNode = FocusNode();
    _startDateFocusNode.addListener(_handleFocusChange);
    _endDateFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _sheetScrollController.dispose();
    _startDateFocusNode.removeListener(_handleFocusChange);
    _endDateFocusNode.removeListener(_handleFocusChange);
    _startDateController.dispose();
    _endDateController.dispose();
    _startDateFocusNode.dispose();
    _endDateFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  void _handleFocusChange() {
    if (_startDateFocusNode.hasFocus || _endDateFocusNode.hasFocus) {
      return;
    }
    _validateDateInputs(showIncompleteErrors: true);
  }

  DateTime? _parseDateInput(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length != 10) {
      return null;
    }

    final parts = normalized.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  String? _dateErrorFor(
    String value,
    DateTime? parsed, {
    required bool showIncompleteErrors,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length < 10) {
      return showIncompleteErrors
          ? widget.l10n.myActivitiesFilterInvalidDate
          : null;
    }
    if (parsed == null) {
      return widget.l10n.myActivitiesFilterInvalidDate;
    }
    return null;
  }

  bool _validateDateInputs({required bool showIncompleteErrors}) {
    final startParsed = _parseDateInput(_startDateController.text);
    final endParsed = _parseDateInput(_endDateController.text);

    var startError = _dateErrorFor(
      _startDateController.text,
      startParsed,
      showIncompleteErrors: showIncompleteErrors,
    );
    var endError = _dateErrorFor(
      _endDateController.text,
      endParsed,
      showIncompleteErrors: showIncompleteErrors,
    );

    if (startError == null &&
        endError == null &&
        startParsed != null &&
        endParsed != null &&
        endParsed.isBefore(startParsed)) {
      endError = widget.l10n.myActivitiesFilterInvalidRange;
    }

    setState(() {
      _startDate = startParsed;
      _endDate = endParsed;
      _startDateError = startError;
      _endDateError = endError;
    });

    return startError == null && endError == null;
  }

  void _handleDateChanged() {
    _validateDateInputs(showIncompleteErrors: false);
  }

  void _clearDate({required bool isStart}) {
    if (isStart) {
      _startDateController.clear();
    } else {
      _endDateController.clear();
    }
    _handleDateChanged();
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    if (!_validateDateInputs(showIncompleteErrors: true)) {
      return;
    }

    Navigator.of(context).pop(
      _MyActivitiesFilters(
        country: _country,
        city: _city,
        statuses: Set<String>.from(_selectedStatuses),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  void _clearDraftFilters() {
    setState(() {
      _country = null;
      _city = null;
      _selectedStatuses.clear();
      _startDateController.clear();
      _endDateController.clear();
      _startDate = null;
      _endDate = null;
      _startDateError = null;
      _endDateError = null;
    });
  }

  _MyActivitiesFilters _draftFilters() {
    return _MyActivitiesFilters(
      country: _country,
      city: _city,
      statuses: Set<String>.from(_selectedStatuses),
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _setCountry(AppCountryFilterValue? country) {
    setState(() {
      _country = country;
      _city = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final horizontalPadding = layout.isCompact ? 16.0 : 20.0;
    final previewCount = widget.previewCountBuilder(_draftFilters());

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: keyboardInset),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: _MyActivitiesPalette.of(context).transparent,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _MyActivitiesPalette.of(
                    context,
                  ).surface.withValues(alpha: 0.99),
                  _MyActivitiesPalette.of(context).background,
                ],
              ),
              borderRadius: AppBorderRadius.vertical(
                top: AppRadiusValue.circular(layout.isCompact ? 24 : 28),
              ),
              border: Border.all(
                color: _MyActivitiesPalette.of(
                  context,
                ).white.withValues(alpha: 0.04),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MyActivitiesFilterSheetHeader(
                    title: widget.l10n.myActivitiesFilterTitle,
                    clearLabel: widget.l10n.myActivitiesFilterClear,
                    onClear: _clearDraftFilters,
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _sheetScrollController,
                      child: SingleChildScrollView(
                        controller: _sheetScrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          layout.isCompact ? 14 : 18,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCountryFilterSection(
                              title: widget.l10n.activitiesFilterCountrySection,
                              allCountriesLabel:
                                  widget.l10n.activitiesFilterCountryAll,
                              searchHint:
                                  widget.l10n.activitiesFilterCountrySearchHint,
                              noResultsText:
                                  widget.l10n.activitiesFilterCountryNoResults,
                              selectedCountry: _country,
                              onChanged: _setCountry,
                            ),
                            if (_country != null) ...[
                              const SizedBox(height: 18),
                              AppCityFilterSection(
                                title: widget.l10n.locationFilterCitySection,
                                allCitiesLabel:
                                    widget.l10n.locationFilterAllCities,
                                searchHint:
                                    widget.l10n.locationFilterCitySearchHint,
                                noResultsText:
                                    widget.l10n.locationFilterCityNoResults,
                                selectedCity: _city,
                                onChanged: (city) {
                                  setState(() => _city = city);
                                },
                                countryCode: _country?.countryCode,
                              ),
                            ],
                            const SizedBox(height: 18),
                            _FilterSheetSectionTitle(
                              icon: Icons.calendar_month_outlined,
                              label: widget.l10n.myActivitiesFilterDateRange,
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final useColumn = constraints.maxWidth < 390;
                                final children = [
                                  _FilterDateField(
                                    label:
                                        widget.l10n.myActivitiesFilterStartDate,
                                    controller: _startDateController,
                                    focusNode: _startDateFocusNode,
                                    hintText: widget
                                        .l10n
                                        .activitiesFilterStartDatePlaceholder,
                                    errorText: _startDateError,
                                    onChanged: (_) => _handleDateChanged(),
                                    onSubmitted: (_) =>
                                        _endDateFocusNode.requestFocus(),
                                    onClear: _startDateController.text.isEmpty
                                        ? null
                                        : () => _clearDate(isStart: true),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  _FilterDateField(
                                    label:
                                        widget.l10n.myActivitiesFilterEndDate,
                                    controller: _endDateController,
                                    focusNode: _endDateFocusNode,
                                    hintText: widget
                                        .l10n
                                        .activitiesFilterEndDatePlaceholder,
                                    errorText: _endDateError,
                                    onChanged: (_) => _handleDateChanged(),
                                    onSubmitted: (_) => _applyFilters(),
                                    onClear: _endDateController.text.isEmpty
                                        ? null
                                        : () => _clearDate(isStart: false),
                                    textInputAction: TextInputAction.done,
                                  ),
                                ];

                                if (useColumn) {
                                  return Column(
                                    children: [
                                      children[0],
                                      const SizedBox(height: 10),
                                      children[1],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: children[0]),
                                    const SizedBox(width: 10),
                                    Expanded(child: children[1]),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            _FilterSheetSectionTitle(
                              icon: Icons.fact_check_outlined,
                              label: widget.l10n.myActivitiesFilterStatus,
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final useSingleColumn =
                                    constraints.maxWidth < 370 ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.08;
                                final spacing = layout.isCompact ? 8.0 : 10.0;
                                final columns = useSingleColumn ? 1 : 2;
                                final itemWidth =
                                    (constraints.maxWidth -
                                        spacing * (columns - 1)) /
                                    columns;

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    for (final option in widget.statusOptions)
                                      SizedBox(
                                        width: itemWidth,
                                        child: _FilterStatusChip(
                                          label: option.label,
                                          count: option.count,
                                          selected: _selectedStatuses.contains(
                                            option.key,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (_selectedStatuses.contains(
                                                option.key,
                                              )) {
                                                _selectedStatuses.remove(
                                                  option.key,
                                                );
                                              } else {
                                                _selectedStatuses.add(
                                                  option.key,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: AppEdgeInsets.only(top: layout.isCompact ? 10 : 12),
                    padding: AppEdgeInsets.fromLTRB(
                      horizontalPadding,
                      layout.isCompact ? 10 : 12,
                      horizontalPadding,
                      14 + safeBottomInset,
                    ),
                    decoration: AppBoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: _MyActivitiesPalette.of(
                            context,
                          ).accent.withValues(alpha: 0.09),
                        ),
                      ),
                      color: _MyActivitiesPalette.of(
                        context,
                      ).black.withValues(alpha: 0.06),
                    ),
                    child: _MyActivitiesFilterPrimaryButton(
                      label: widget.l10n.activitiesShowResults(previewCount),
                      onTap: _applyFilters,
                      minHeight: layout.isCompact ? 50 : 56,
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
}

class _MyActivitiesFilterSheetHeader extends StatelessWidget {
  const _MyActivitiesFilterSheetHeader({
    required this.title,
    required this.clearLabel,
    required this.onClear,
  });

  final String title;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return AppFilterSheetHeader(
      title: title,
      clearLabel: clearLabel,
      onClear: onClear,
      height: layout.isCompact ? 44 : 46,
      horizontalPadding: layout.isCompact ? 16 : 18,
      titleFontSize: layout.isCompact ? 14 : 16,
      clearFontSize: layout.isCompact ? 11 : 12,
    );
  }
}

class _MyActivitiesFilterPrimaryButton extends StatelessWidget {
  const _MyActivitiesFilterPrimaryButton({
    required this.label,
    required this.onTap,
    required this.minHeight,
  });

  final String label;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return AppFilterApplyButton(
      label: label,
      onTap: onTap,
      minHeight: minHeight,
      fontSize: layout.isCompact ? 15 : 17,
    );
  }
}

class _FilterSheetSectionTitle extends StatelessWidget {
  const _FilterSheetSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: AppBoxDecoration(
            shape: BoxShape.circle,
            color: _MyActivitiesPalette.of(
              context,
            ).accent.withValues(alpha: 0.10),
            border: Border.all(
              color: _MyActivitiesPalette.of(
                context,
              ).accent.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: _MyActivitiesPalette.of(context).accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: _MyActivitiesPalette.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterDateField extends StatelessWidget {
  const _FilterDateField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.onClear,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String? errorText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final hasValue = controller.text.isNotEmpty;
    final borderColor = errorText == null
        ? _MyActivitiesPalette.of(context).accent.withValues(alpha: 0.28)
        : _MyActivitiesPalette.of(context).danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(
            color: _MyActivitiesPalette.of(context).text,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          inputFormatters: const [_DateTextInputFormatter()],
          style: AppTextStyle(
            color: _MyActivitiesPalette.of(context).text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: AppInputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyle(
              color: _MyActivitiesPalette.of(context).textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: _MyActivitiesPalette.of(
              context,
            ).white.withValues(alpha: 0.02),
            contentPadding: const AppEdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            suffixIcon: hasValue
                ? IconButton(
                    onPressed: onClear,
                    splashRadius: 20,
                    icon: Icon(
                      Icons.close_rounded,
                      color: _MyActivitiesPalette.of(context).textMuted,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            border: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(999),
              borderSide: BorderSide(
                color: _MyActivitiesPalette.of(context).accent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(999),
              borderSide: BorderSide(
                color: _MyActivitiesPalette.of(context).danger,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(999),
              borderSide: BorderSide(
                color: _MyActivitiesPalette.of(context).danger,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clampedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < clampedDigits.length; i++) {
      buffer.write(clampedDigits[i]);
      if ((i == 1 || i == 3) && i != clampedDigits.length - 1) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    final digitsBeforeSelection = newValue.selection.end <= 0
        ? 0
        : newValue.text
              .substring(0, newValue.selection.end)
              .replaceAll(RegExp(r'[^0-9]'), '')
              .length;

    var selectionOffset = 0;
    var seenDigits = 0;
    while (selectionOffset < formatted.length &&
        seenDigits < digitsBeforeSelection) {
      if (RegExp(r'[0-9]').hasMatch(formatted[selectionOffset])) {
        seenDigits++;
      }
      selectionOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

class _FilterStatusChip extends StatelessWidget {
  const _FilterStatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final foreground = selected
        ? _MyActivitiesPalette.of(context).textPrimary
        : _MyActivitiesPalette.of(context).text;

    return Material(
      color: _MyActivitiesPalette.of(context).transparent,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: compact ? 54 : 58,
          padding: const AppEdgeInsets.symmetric(horizontal: 12),
          decoration: AppBoxDecoration(
            color: selected
                ? _MyActivitiesPalette.of(
                    context,
                  ).accent.withValues(alpha: 0.18)
                : _MyActivitiesPalette.of(
                    context,
                  ).white.withValues(alpha: 0.025),
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? _MyActivitiesPalette.of(context).accent
                  : _MyActivitiesPalette.of(
                      context,
                    ).accent.withValues(alpha: 0.14),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _MyActivitiesPalette.of(context).accent
                      : _MyActivitiesPalette.of(context).transparent,
                  border: Border.all(
                    color: _MyActivitiesPalette.of(
                      context,
                    ).accent.withValues(alpha: 0.56),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: _MyActivitiesPalette.of(context).white,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: foreground,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: AppBoxDecoration(
                  color: _MyActivitiesPalette.of(
                    context,
                  ).accent.withValues(alpha: 0.14),
                  borderRadius: AppBorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: AppTextStyle(
                    color: _MyActivitiesPalette.of(context).accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _StatusBadgeStyle {
  const _StatusBadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
