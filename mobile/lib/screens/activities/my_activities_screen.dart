import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import 'widgets/activities_bottom_bar.dart';

enum _MyActivitiesTab { hosted, attended }

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  static const List<String> _hostedFilterOrder = <String>[
    'DRAFT',
    'PUBLISHED',
    'REVIEW_REQUIRED',
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

  _MyActivitiesTab _activeTab = _MyActivitiesTab.hosted;
  _MyActivitiesFilters _filters = const _MyActivitiesFilters();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      provider.loadMyActivities();
      provider.loadJoinedActivities();
    });
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

  Future<void> _refreshActive(ActivityProvider provider) {
    if (_activeTab == _MyActivitiesTab.hosted) {
      return provider.refreshMyActivities();
    }
    return provider.refreshJoinedActivities();
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

  List<ActivityListItemVm> _activeItems(ActivityProvider provider) {
    return _activeTab == _MyActivitiesTab.hosted
        ? provider.myItems
        : provider.joinedItems;
  }

  List<String> _statusOrderForTab(_MyActivitiesTab tab) {
    return tab == _MyActivitiesTab.hosted
        ? _hostedFilterOrder
        : _attendedFilterOrder;
  }

  _MyActivitiesFilters _filtersForTab(_MyActivitiesTab tab) {
    return _filters.onlyAllowedStatuses(_statusOrderForTab(tab).toSet());
  }

  List<ActivityListItemVm> _filterItems(List<ActivityListItemVm> items) {
    final activeFilters = _filtersForTab(_activeTab);

    return items.where((item) {
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

      return true;
    }).toList();
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
      case 'DRAFT':
        return l10n.activityStatusDraft;
      case 'PUBLISHED':
        return l10n.activityStatusPublished;
      case 'REVIEW_REQUIRED':
        return l10n.activityStatusReviewRequired;
      case 'COMPLETED':
        return l10n.activityStatusCompleted;
      case 'CANCELLED':
        return l10n.activityStatusCancelled;
      default:
        return key;
    }
  }

  Future<void> _openFilters(
    AppLocalizations l10n,
    List<ActivityListItemVm> items,
  ) async {
    final availableStatuses = _statusOrderForTab(_activeTab).toSet();
    final result = await showModalBottomSheet<_MyActivitiesFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MyActivitiesFilterSheet(
          l10n: l10n,
          initialFilters: _filters.onlyAllowedStatuses(availableStatuses),
          statusOptions: _buildStatusOptions(l10n, items),
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _filters = _MyActivitiesFilters(
        statuses: <String>{
          ..._filters.statuses.where(
            (status) => !availableStatuses.contains(status),
          ),
          ...result.statuses,
        },
        startDate: result.startDate,
        endDate: result.endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layout = _MyActivitiesAdaptiveLayout.of(context);
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _MyActivitiesPalette.background,
      bottomNavigationBar: ActivitiesBottomBar(
        backgroundStyle: ActivitiesBottomBarBackgroundStyle.home,
        onHomeTap: _goHome,
        onQrTap: _openQrStub,
        onCreateTap: _openCreateActivity,
        onServicesTap: _goActivities,
        onChatsTap: _openChatsStub,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _MyActivitiesPalette.backgroundTop,
              _MyActivitiesPalette.background,
              _MyActivitiesPalette.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<ActivityProvider>(
            builder: (context, provider, _) {
              final items = _activeItems(provider);
              final state = _activeState(provider);
              final filteredItems = _filterItems(items);
              final errorMessage = _activeError(provider);
              final isInitialLoading =
                  state == ActivitiesState.loading && items.isEmpty;
              final isInitialError =
                  state == ActivitiesState.error && items.isEmpty;

              return RefreshIndicator(
                color: _MyActivitiesPalette.accent,
                backgroundColor: _MyActivitiesPalette.card,
                onRefresh: () => _refreshActive(provider),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.maxContentWidth,
                    ),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.listBottomPadding + safeBottomInset,
                      ),
                      children: [
                        _MyActivitiesTopBar(
                          title: l10n.myActivitiesTitle,
                          onBackTap: _goBack,
                          onSearchTap: _showComingSoon,
                        ),
                        SizedBox(height: layout.topSectionSpacing),
                        _MyActivitiesTabSwitcher(
                          activeTab: _activeTab,
                          hostedLabel: l10n.myActivitiesTitle,
                          attendedLabel: l10n.myActivitiesAttendedTab,
                          onChanged: (tab) => setState(() => _activeTab = tab),
                        ),
                        SizedBox(height: layout.sectionSpacing),
                        _MyActivitiesFilterButton(
                          label: l10n.myActivitiesFilterButton,
                          activeCount: _filtersForTab(_activeTab).activeCount,
                          onTap: () => _openFilters(l10n, items),
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
                            message: _activeTab == _MyActivitiesTab.hosted
                                ? l10n.myActivitiesEmptyHint
                                : l10n.myActivitiesAttendedEmptyHint,
                          ),
                        ] else ...[
                          for (var i = 0; i < filteredItems.length; i++) ...[
                            _MyActivitiesCard(
                              item: filteredItems[i],
                              tab: _activeTab,
                              localeName: Localizations.localeOf(
                                context,
                              ).toString(),
                              onPrimaryTap: () {
                                if (_activeTab == _MyActivitiesTab.attended) {
                                  _openDetails(filteredItems[i]);
                                  return;
                                }

                                final status = filteredItems[i].status
                                    .toUpperCase();
                                if (status == 'DRAFT') {
                                  _openEdit(filteredItems[i]);
                                  return;
                                }
                                if (status == 'REVIEW_REQUIRED') {
                                  return;
                                }
                                _openEdit(filteredItems[i]);
                              },
                              onSecondaryTap:
                                  _activeTab == _MyActivitiesTab.hosted
                                  ? () => _showComingSoon()
                                  : null,
                              onTertiaryTap:
                                  _activeTab == _MyActivitiesTab.hosted &&
                                      filteredItems[i].status.toUpperCase() ==
                                          'DRAFT'
                                  ? _showComingSoon
                                  : null,
                              onCardTap: () {
                                if (_activeTab == _MyActivitiesTab.hosted &&
                                    filteredItems[i].status.toUpperCase() ==
                                        'DRAFT') {
                                  _openEdit(filteredItems[i]);
                                  return;
                                }
                                _openDetails(filteredItems[i]);
                              },
                            ),
                            if (i != filteredItems.length - 1)
                              SizedBox(height: layout.cardSpacing),
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
    );
  }
}

class _MyActivitiesFilters {
  const _MyActivitiesFilters({
    this.statuses = const <String>{},
    this.startDate,
    this.endDate,
  });

  final Set<String> statuses;
  final DateTime? startDate;
  final DateTime? endDate;

  int get activeCount =>
      statuses.length + (startDate == null ? 0 : 1) + (endDate == null ? 0 : 1);

  _MyActivitiesFilters onlyAllowedStatuses(Set<String> allowedStatuses) {
    return _MyActivitiesFilters(
      statuses: statuses.where(allowedStatuses.contains).toSet(),
      startDate: startDate,
      endDate: endDate,
    );
  }
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

abstract final class _MyActivitiesPalette {
  static const Color backgroundTop = Color(0xFF170D08);
  static const Color background = Color(0xFF120A05);
  static const Color backgroundBottom = Color(0xFF0F0905);
  static const Color surface = Color(0xFF1A1009);
  static const Color surfaceSoft = Color(0xFF241405);
  static const Color card = Color(0xFF21150D);
  static const Color accent = Color(0xFFFF9800);
  static const Color text = Color(0xFFFFF4E5);
  static const Color textMuted = Color(0xFFB9A88F);
  static const Color badgeDraft = Color(0xFF3B4D67);
  static const Color badgeReview = Color(0x33BCA35A);
  static const Color badgeCompleted = Color(0xFF245C3D);
  static const Color badgeCancelled = Color(0xFF5B2C26);
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
  bool get stretchFilterButton => screenWidth < 380;
  bool get stackSheetActions => screenWidth < 360 || textScale > 1.15;

  double get horizontalPadding => isCompact
      ? 16
      : isLargePhone
      ? 24
      : 20;
  double get topPadding => isCompact ? 12 : 14;
  double get topSectionSpacing => isCompact ? 14 : 16;
  double get sectionSpacing => isCompact ? 16 : 18;
  double get cardSpacing => isCompact ? 18 : 22;
  double get listBottomPadding => isCompact ? 136 : 148;
  double get maxContentWidth => isWideMobile ? 620 : double.infinity;
  double get topBarTitleSize => isCompact ? 18 : 20;
  double get segmentHeight => isCompact ? 44 : 46;
  double get segmentFontSize => isCompact ? 13 : 15;
  double get navLabelSize => isCompact ? 10.5 : 12;
  double get navIconSize => isCompact ? 20 : 22;
  double get navVerticalPadding => isCompact ? 4 : 6;
  double get navHorizontalPadding => isCompact ? 6 : 10;
}

class _MyActivitiesTopBar extends StatelessWidget {
  const _MyActivitiesTopBar({
    required this.title,
    required this.onBackTap,
    required this.onSearchTap,
  });

  final String title;
  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackTap,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _MyActivitiesPalette.text,
              fontSize: layout.topBarTitleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        _CircleIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
      ],
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
      padding: EdgeInsets.all(layout.isCompact ? 5 : 6),
      decoration: BoxDecoration(
        color: _MyActivitiesPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: layout.segmentHeight,
          decoration: BoxDecoration(
            color: isActive ? _MyActivitiesPalette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _MyActivitiesPalette.accent.withValues(
                        alpha: 0.25,
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFFFAF2)
                        : const Color(0xFF9D947F),
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

class _MyActivitiesFilterButton extends StatelessWidget {
  const _MyActivitiesFilterButton({
    required this.label,
    required this.activeCount,
    required this.onTap,
  });

  final String label;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: layout.stretchFilterButton ? double.infinity : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: layout.isCompact ? 18 : 22,
                vertical: layout.isCompact ? 14 : 15,
              ),
              decoration: BoxDecoration(
                color: _MyActivitiesPalette.accent.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _MyActivitiesPalette.accent.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: layout.stretchFilterButton
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _MyActivitiesPalette.accent,
                  ),
                  const SizedBox(width: 10),
                  if (layout.stretchFilterButton)
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _MyActivitiesPalette.accent,
                          fontSize: layout.isCompact ? 15 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Text(
                      label,
                      style: TextStyle(
                        color: _MyActivitiesPalette.accent,
                        fontSize: layout.isCompact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _MyActivitiesPalette.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF231100),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
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
    required this.onPrimaryTap,
    required this.onCardTap,
    this.onSecondaryTap,
    this.onTertiaryTap,
  });

  final ActivityListItemVm item;
  final _MyActivitiesTab tab;
  final String localeName;
  final VoidCallback onPrimaryTap;
  final VoidCallback onCardTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onTertiaryTap;

  bool get _isDraft => item.status.toUpperCase() == 'DRAFT';
  bool get _isReviewRequired => item.status.toUpperCase() == 'REVIEW_REQUIRED';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = l10n.myActivitiesLastUpdated(
      DateFormat('dd MMM yyyy', localeName).format(item.startAt),
    );
    final formattedDate = DateFormat('dd MMM', localeName).format(item.startAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactCard = constraints.maxWidth < 380;
        final stackPrimaryActions = constraints.maxWidth < 430;
        final radius = compactCard ? 28.0 : 34.0;
        final contentPadding = compactCard ? 16.0 : 20.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onCardTap,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _MyActivitiesPalette.card,
                    _MyActivitiesPalette.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _MyActivitiesPalette.accent.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
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
                    padding: EdgeInsets.fromLTRB(
                      contentPadding,
                      compactCard ? 16 : 18,
                      contentPadding,
                      compactCard ? 16 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (compactCard) ...[
                          Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _MyActivitiesPalette.text,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PriceBlock(
                            value: item.isFree
                                ? l10n.freeLabel
                                : item.priceLabel,
                            note: item.isFree
                                ? l10n.myActivitiesPriceNoteFree
                                : l10n.createPricePerPersonHint,
                            alignStart: true,
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _MyActivitiesPalette.text,
                                    fontSize: 22,
                                    height: 1.08,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _PriceBlock(
                                value: item.isFree
                                    ? l10n.freeLabel
                                    : item.priceLabel,
                                note: item.isFree
                                    ? l10n.myActivitiesPriceNoteFree
                                    : l10n.createPricePerPersonHint,
                              ),
                            ],
                          ),
                        SizedBox(height: compactCard ? 8 : 10),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: _MyActivitiesPalette.textMuted,
                            fontSize: compactCard ? 14 : 15,
                          ),
                        ),
                        SizedBox(height: compactCard ? 14 : 16),
                        Wrap(
                          spacing: compactCard ? 16 : 20,
                          runSpacing: 10,
                          children: [
                            _MetaItem(
                              icon: Icons.calendar_today_rounded,
                              label: formattedDate,
                            ),
                            _MetaItem(
                              icon: Icons.place_rounded,
                              label: item.shortLocation.isNotEmpty
                                  ? item.shortLocation
                                  : formatActivityFormat(item.format, l10n),
                            ),
                          ],
                        ),
                        SizedBox(height: compactCard ? 16 : 18),
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
      return SizedBox(
        width: double.infinity,
        child: _CardActionButton(
          label: l10n.myActivitiesOpenButton,
          icon: Icons.open_in_new_rounded,
          onTap: onPrimaryTap,
          variant: _CardActionVariant.primary,
        ),
      );
    }

    if (_isReviewRequired) {
      return SizedBox(
        width: double.infinity,
        child: _CardActionButton(
          label: l10n.myActivitiesRestrictedButton,
          icon: Icons.lock_outline_rounded,
          onTap: null,
          variant: _CardActionVariant.disabled,
        ),
      );
    }

    if (_isDraft) {
      return Row(
        children: [
          Expanded(
            child: _CardActionButton(
              label: l10n.myActivitiesContinueButton,
              icon: Icons.edit_outlined,
              onTap: onPrimaryTap,
              variant: _CardActionVariant.primary,
            ),
          ),
          const SizedBox(width: 12),
          _IconOnlyActionButton(
            icon: Icons.delete_outline_rounded,
            onTap: onTertiaryTap,
          ),
        ],
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
          const SizedBox(height: 12),
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
        const SizedBox(width: 12),
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
    final status = item.status.toUpperCase();
    final badge = _statusBadgeStyle(status);
    final cover = _coverPalette(item);

    return AspectRatio(
      aspectRatio: 1.38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cover,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              _coverIcon(item),
              size: 62,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: badge.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                formatActivityStatus(
                  item.status,
                  AppLocalizations.of(context)!,
                ),
                style: TextStyle(
                  color: badge.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _coverPalette(ActivityListItemVm item) {
    switch (item.categorySlug) {
      case 'adventure-sports':
        return const [Color(0xFF81562A), Color(0xFFE39A47)];
      case 'social-nightlife':
        return const [Color(0xFF5A2348), Color(0xFFCB6BA6)];
      case 'health-wellness':
        return const [Color(0xFF1F5248), Color(0xFF59B596)];
      case 'workshops-learning':
        return const [Color(0xFF3E346A), Color(0xFF8E7CDB)];
      default:
        return item.format.toUpperCase() == 'ONLINE'
            ? const [Color(0xFF25405A), Color(0xFF4E86C7)]
            : const [Color(0xFF4A2B1A), Color(0xFF9D6437)];
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

  _StatusBadgeStyle _statusBadgeStyle(String status) {
    switch (status) {
      case 'DRAFT':
        return const _StatusBadgeStyle(
          background: _MyActivitiesPalette.badgeDraft,
          foreground: Color(0xFFF2F6FF),
        );
      case 'REVIEW_REQUIRED':
        return const _StatusBadgeStyle(
          background: _MyActivitiesPalette.badgeReview,
          foreground: Color(0xFFE9CE83),
        );
      case 'COMPLETED':
        return const _StatusBadgeStyle(
          background: _MyActivitiesPalette.badgeCompleted,
          foreground: Color(0xFFDAFFE7),
        );
      case 'CANCELLED':
        return const _StatusBadgeStyle(
          background: _MyActivitiesPalette.badgeCancelled,
          foreground: Color(0xFFF8D1CB),
        );
      default:
        return const _StatusBadgeStyle(
          background: _MyActivitiesPalette.accent,
          foreground: Color(0xFF261300),
        );
    }
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.value,
    required this.note,
    this.alignStart = false,
  });

  final String value;
  final String note;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: alignStart ? 220 : 112),
      child: Column(
        crossAxisAlignment: alignStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            value,
            textAlign: alignStart ? TextAlign.left : TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MyActivitiesPalette.accent,
              fontSize: compact ? 17 : 18,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            textAlign: alignStart ? TextAlign.left : TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MyActivitiesPalette.textMuted,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: _MyActivitiesPalette.textMuted),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 170 : 210),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MyActivitiesPalette.textMuted,
              fontSize: compact ? 14 : 15,
            ),
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
      _CardActionVariant.primary => _MyActivitiesPalette.accent,
      _CardActionVariant.secondary => _MyActivitiesPalette.accent.withValues(
        alpha: 0.08,
      ),
      _CardActionVariant.disabled => _MyActivitiesPalette.accent.withValues(
        alpha: 0.05,
      ),
    };

    final foregroundColor = switch (variant) {
      _CardActionVariant.primary => const Color(0xFF201000),
      _CardActionVariant.secondary => const Color(0xFFF0DFC8),
      _CardActionVariant.disabled => const Color(0xFF9A856F),
    };

    return SizedBox(
      height: compact ? 54 : 58,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: compact ? 17 : 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          textStyle: TextStyle(
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _IconOnlyActionButton extends StatelessWidget {
  const _IconOnlyActionButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return SizedBox(
      width: compact ? 52 : 56,
      height: compact ? 54 : 58,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _MyActivitiesPalette.accent.withValues(alpha: 0.08),
          foregroundColor: const Color(0xFFF0DFC8),
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Icon(icon, size: compact ? 20 : 22),
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
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 22 : 26,
        compact ? 18 : 22,
        compact ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: _MyActivitiesPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _MyActivitiesPalette.accent.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 52 : 58,
            height: compact ? 52 : 58,
            decoration: BoxDecoration(
              color: _MyActivitiesPalette.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _MyActivitiesPalette.accent,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            title,
            style: TextStyle(
              color: _MyActivitiesPalette.text,
              fontSize: compact ? 22 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            message,
            style: TextStyle(
              color: _MyActivitiesPalette.textMuted,
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
      decoration: BoxDecoration(
        color: _MyActivitiesPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            height: compact ? 188 : 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              children: [
                _SkeletonLine(width: double.infinity, height: 22),
                const SizedBox(height: 12),
                const _SkeletonLine(width: 180, height: 16),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width == 0 ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: compact ? 38 : 40,
          height: compact ? 38 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
            color: _MyActivitiesPalette.text,
          ),
        ),
      ),
    );
  }
}

class _MyActivitiesFilterSheet extends StatefulWidget {
  const _MyActivitiesFilterSheet({
    required this.l10n,
    required this.initialFilters,
    required this.statusOptions,
  });

  final AppLocalizations l10n;
  final _MyActivitiesFilters initialFilters;
  final List<_FilterStatusOption> statusOptions;

  @override
  State<_MyActivitiesFilterSheet> createState() =>
      _MyActivitiesFilterSheetState();
}

class _MyActivitiesFilterSheetState extends State<_MyActivitiesFilterSheet> {
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
        statuses: Set<String>.from(_selectedStatuses),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _MyActivitiesAdaptiveLayout.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: EdgeInsets.only(
            left: layout.isCompact ? 18 : 22,
            right: layout.isCompact ? 18 : 22,
            top: layout.isCompact ? 14 : 16,
            bottom: 18 + safeBottomInset,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _MyActivitiesPalette.surfaceSoft,
                _MyActivitiesPalette.surface,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            border: Border.all(
              color: _MyActivitiesPalette.accent.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _MyActivitiesPalette.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.l10n.myActivitiesFilterTitle,
                style: TextStyle(
                  color: _MyActivitiesPalette.text,
                  fontSize: layout.isCompact ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: layout.isCompact ? 16 : 20),
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.l10n.myActivitiesFilterDateRange,
                          style: const TextStyle(
                            color: _MyActivitiesPalette.accent,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useColumn = constraints.maxWidth < 520;
                            final children = [
                              _FilterDateField(
                                label: widget.l10n.myActivitiesFilterStartDate,
                                controller: _startDateController,
                                focusNode: _startDateFocusNode,
                                hintText: widget
                                    .l10n
                                    .myActivitiesFilterDatePlaceholder,
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
                                label: widget.l10n.myActivitiesFilterEndDate,
                                controller: _endDateController,
                                focusNode: _endDateFocusNode,
                                hintText: widget
                                    .l10n
                                    .myActivitiesFilterDatePlaceholder,
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
                                  const SizedBox(height: 16),
                                  children[1],
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: children[0]),
                                const SizedBox(width: 16),
                                Expanded(child: children[1]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.l10n.myActivitiesFilterDateHint,
                          style: const TextStyle(
                            color: _MyActivitiesPalette.textMuted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          widget.l10n.myActivitiesFilterStatus,
                          style: const TextStyle(
                            color: _MyActivitiesPalette.accent,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final option in widget.statusOptions) ...[
                          _FilterStatusRow(
                            label: option.label,
                            count: option.count,
                            selected: _selectedStatuses.contains(option.key),
                            onTap: () {
                              setState(() {
                                if (_selectedStatuses.contains(option.key)) {
                                  _selectedStatuses.remove(option.key);
                                } else {
                                  _selectedStatuses.add(option.key);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: layout.isCompact ? 10 : 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (layout.stackSheetActions) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _SheetActionButton(
                            label: widget.l10n.myActivitiesFilterApply,
                            variant: _CardActionVariant.primary,
                            onTap: _applyFilters,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _SheetActionButton(
                            label: widget.l10n.myActivitiesFilterClear,
                            variant: _CardActionVariant.secondary,
                            onTap: () => Navigator.of(
                              context,
                            ).pop(const _MyActivitiesFilters()),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _SheetActionButton(
                          label: widget.l10n.myActivitiesFilterClear,
                          variant: _CardActionVariant.secondary,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(const _MyActivitiesFilters()),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: _SheetActionButton(
                          label: widget.l10n.myActivitiesFilterApply,
                          variant: _CardActionVariant.primary,
                          onTap: _applyFilters,
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
        ? _MyActivitiesPalette.accent.withValues(alpha: 0.28)
        : const Color(0xFFE28A7E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _MyActivitiesPalette.text,
            fontSize: compact ? 15 : 16,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          inputFormatters: const [_DateTextInputFormatter()],
          style: const TextStyle(
            color: _MyActivitiesPalette.text,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB8B0AA),
              fontSize: 19,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 22,
            ),
            suffixIcon: hasValue
                ? IconButton(
                    onPressed: onClear,
                    splashRadius: 20,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFB8B0AA),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: _MyActivitiesPalette.accent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFFE28A7E),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFFE28A7E),
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

class _FilterStatusRow extends StatelessWidget {
  const _FilterStatusRow({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _MyActivitiesPalette.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _MyActivitiesPalette.accent
                      : Colors.transparent,
                  border: Border.all(
                    color: _MyActivitiesPalette.accent.withValues(alpha: 0.56),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _MyActivitiesPalette.text,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _MyActivitiesPalette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _MyActivitiesPalette.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.variant,
    required this.onTap,
  });

  final String label;
  final _CardActionVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: _CardActionButton(
        label: label,
        icon: variant == _CardActionVariant.primary
            ? Icons.done_rounded
            : Icons.clear_rounded,
        onTap: onTap,
        variant: variant,
      ),
    );
  }
}

class _StatusBadgeStyle {
  const _StatusBadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
