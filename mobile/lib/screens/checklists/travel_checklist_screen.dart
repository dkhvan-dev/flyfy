import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/checklist_api.dart';
import '../../core/network/reference_api.dart';
import '../../features/checklists/data/checklist_offline_cache.dart';
import '../../features/checklists/models/trip_checklist_vm.dart';
import '../../features/checklists/models/travel_checklist_route_args.dart';
import '../../features/routing/models/routing_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/routing_provider.dart';
import '../../shared/reference/app_country_names.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

final class _ChecklistAmber {
  const _ChecklistAmber._(this.colors);

  final AppColors colors;

  static _ChecklistAmber of(BuildContext context) {
    return _ChecklistAmber._(AppDesignSystem.colorsFor(context));
  }

  Color get backgroundTop => colors.backgroundDeep;
  Color get backgroundBottom => colors.background;
  Color get backgroundWarm => colors.backgroundWarm;
  List<Color> get screenGradientColors => colors.screenGradientColors;
  Color get surface => colors.surface;
  Color get surfaceElevated => colors.surfaceRaised;
  Color get surfacePressed => colors.surfaceHigh;
  Color get itemSurface => colors.surfaceRaised;
  Color get border => colors.border;
  Color get amber => colors.primary;
  Color get amberSoft => colors.primarySoft;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get danger => colors.danger;
  Color get success => colors.success;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
}

enum _ChecklistListFilter { all, upcoming, manual, activities, excursions }

enum _ChecklistSource { manual, activity, excursion }

class TravelChecklistListScreen extends StatefulWidget {
  const TravelChecklistListScreen({
    super.key,
    this.checklistApi,
    this.checklistCache,
  });

  final ChecklistApi? checklistApi;
  final ChecklistOfflineCache? checklistCache;

  @override
  State<TravelChecklistListScreen> createState() =>
      _TravelChecklistListScreenState();
}

class _TravelChecklistListScreenState extends State<TravelChecklistListScreen> {
  late final ChecklistApi _checklistApi;
  late final ChecklistOfflineCache _checklistCache;
  late Future<List<CachedTravelChecklistEntry>> _entriesFuture;
  String _localeName = 'ru';
  bool _didLoadEntries = false;
  _ChecklistListFilter _selectedFilter = _ChecklistListFilter.all;

  @override
  void initState() {
    super.initState();
    _checklistApi = widget.checklistApi ?? ChecklistApi();
    _checklistCache = widget.checklistCache ?? ChecklistOfflineCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeName = AppLocalizations.of(context)?.localeName ?? 'ru';
    if (_didLoadEntries && _localeName == localeName) return;
    _localeName = localeName;
    _entriesFuture = _loadEntries(localeName: _localeName);
    _didLoadEntries = true;
  }

  void _reload() {
    setState(() {
      _entriesFuture = _loadEntries(localeName: _localeName);
    });
  }

  Future<void> _openChecklist(TravelChecklistRouteArgs routeArgs) async {
    await context.push('/travel-checklist', extra: routeArgs);
    if (!mounted) return;
    _reload();
  }

  Future<void> _createPreparation() async {
    await context.push('/travel-checklist');
    if (!mounted) return;
    _reload();
  }

  Future<List<CachedTravelChecklistEntry>> _loadEntries({
    required String localeName,
  }) async {
    final localEntries = await _checklistCache.listTripChecklistEntries();
    try {
      final summaries = await _checklistApi.listTripChecklists(
        locale: localeName,
        limit: 50,
      );
      final entries = summaries
          .map(_cachedEntryFromSummary)
          .where((entry) => entry.routeArgs.normalizedTripId.trim().isNotEmpty)
          .toList(growable: false);
      if (entries.isNotEmpty || localEntries.isEmpty) {
        await _checklistCache.replaceTripChecklistEntries(entries);
        return entries;
      }
      return localEntries;
    } catch (_) {
      return localEntries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _ChecklistAmber.of(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: palette.backgroundBottom,
        floatingActionButton: FloatingActionButton(
          key: const ValueKey('travel-checklist-list-create'),
          onPressed: _createPreparation,
          tooltip: l10n.travelChecklistQuickPrepSubmit,
          backgroundColor: palette.amber,
          foregroundColor: palette.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(16),
          ),
          child: Icon(Icons.add_rounded),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 340
                    ? 10.0
                    : constraints.maxWidth < 390
                    ? 14.0
                    : 18.0;

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: AppEdgeInsets.fromLTRB(
                        horizontalPadding,
                        constraints.maxWidth < 390 ? 18 : 24,
                        horizontalPadding,
                        32,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Header(
                                  title: l10n.travelChecklistRecentTitle,
                                  subtitle: l10n.travelChecklistRecentMessage,
                                ),
                                const SizedBox(height: 18),
                                FutureBuilder<List<CachedTravelChecklistEntry>>(
                                  future: _entriesFuture,
                                  builder: (context, snapshot) {
                                    final entries =
                                        snapshot.data ??
                                        const <CachedTravelChecklistEntry>[];
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        snapshot.connectionState ==
                                            ConnectionState.active) {
                                      return const _ChecklistListLoadingPanel();
                                    }
                                    if (snapshot.hasError) {
                                      return _ChecklistErrorView(
                                        message: l10n.travelChecklistLoadFailed,
                                        retryLabel: l10n.travelChecklistRetry,
                                        onRetry: _reload,
                                      );
                                    }
                                    if (entries.isEmpty) {
                                      return _ChecklistListEmptyPanel(
                                        onCreate: _createPreparation,
                                      );
                                    }
                                    return _SavedChecklistsPanel(
                                      entries: entries,
                                      selectedFilter: _selectedFilter,
                                      onFilterChanged: (filter) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      onOpen: _openChecklist,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

CachedTravelChecklistEntry _cachedEntryFromSummary(
  TripChecklistSummaryVm summary,
) {
  final savedAt = (summary.updatedAt ?? summary.generatedAt ?? DateTime.now())
      .toUtc();
  return CachedTravelChecklistEntry(
    routeArgs: TravelChecklistRouteArgs(
      tripId: summary.tripId,
      destination: summary.destination,
      destinationCountryName: summary.destinationCountryName,
      startAt: summary.startAt,
      endAt: summary.endAt,
      transportModes: summary.transportModes,
      activitySlugs: summary.activitySlugs,
      hasChildren: summary.hasChildren,
    ),
    savedAt: savedAt,
    readinessScore: summary.readinessScore,
    readinessStatus: summary.readinessStatus,
    itemCount: summary.itemCount,
  );
}

class TravelChecklistScreen extends StatefulWidget {
  const TravelChecklistScreen({
    super.key,
    this.checklistApi,
    this.checklistCache,
    this.referenceApi,
    this.routeArgs,
  });

  final ChecklistApi? checklistApi;
  final ChecklistOfflineCache? checklistCache;
  final ReferenceApi? referenceApi;
  final TravelChecklistRouteArgs? routeArgs;

  @override
  State<TravelChecklistScreen> createState() => _TravelChecklistScreenState();
}

class _TravelChecklistScreenState extends State<TravelChecklistScreen> {
  late final ChecklistApi _checklistApi;
  late final ChecklistOfflineCache _checklistCache;
  late final ReferenceApi _referenceApi;
  TravelChecklistRouteArgs? _routeArgs;
  late final TextEditingController _carrySearchController;
  late final TextEditingController _checklistItemSearchController;
  late final ScrollController _scrollController;
  late Future<_ChecklistLoadResult> _checklistFuture;
  bool _didCreateChecklistFuture = false;

  bool _isSearchingCarryItem = false;
  final Set<String> _updatingChecklistItemIds = <String>{};
  final Set<String> _submittingFeedbackItemIds = <String>{};
  final Set<String> _updatingCustomItemIds = <String>{};
  final Set<String> _deletingCustomItemIds = <String>{};
  final Map<String, ChecklistItemFeedbackType> _selectedFeedbackByItemId =
      <String, ChecklistItemFeedbackType>{};
  bool _isSavingCustomItem = false;
  bool _isOptimizingDayRoute = false;
  ItineraryOptimizationResponseVm? _optimizedItinerary;
  String? _optimizedItineraryError;
  List<CarryItemPolicyVm> _carryResults = const [];
  String? _carrySearchError;
  String _checklistItemSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _checklistApi = widget.checklistApi ?? ChecklistApi();
    _checklistCache = widget.checklistCache ?? ChecklistOfflineCache();
    _referenceApi = widget.referenceApi ?? ReferenceApi();
    _routeArgs = widget.routeArgs;
    _carrySearchController = TextEditingController();
    _checklistItemSearchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant TravelChecklistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeArgs == null || identical(widget.routeArgs, _routeArgs)) {
      return;
    }

    _routeArgs = widget.routeArgs;
    _didCreateChecklistFuture = true;
    _checklistFuture = _loadChecklist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCreateChecklistFuture) return;
    if (_routeArgs == null) return;
    _didCreateChecklistFuture = true;
    _checklistFuture = _loadChecklist();
  }

  @override
  void dispose() {
    _carrySearchController.dispose();
    _checklistItemSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_ChecklistLoadResult> _loadChecklist() async {
    final routeArgs = _requireRouteArgs();
    if (routeArgs.isPreview) {
      final checklist = await _checklistApi.previewTripChecklist(
        routeArgs.toRequest(
          preferredLanguage: _localeCode,
          citizenshipCountryCode: _profileCitizenshipCountryCode,
        ),
      );
      return _ChecklistLoadResult(checklist: checklist);
    }

    try {
      final checklist = await _checklistApi.getOrCreateTripChecklist(
        routeArgs.toRequest(
          preferredLanguage: _localeCode,
          citizenshipCountryCode: _profileCitizenshipCountryCode,
        ),
      );
      await _checklistCache.saveTripChecklist(
        routeArgs.normalizedTripId,
        checklist,
        routeArgs: routeArgs,
      );
      return _ChecklistLoadResult(checklist: checklist);
    } catch (_) {
      final cached = await _checklistCache.readTripChecklist(
        routeArgs.normalizedTripId,
      );
      if (cached != null) {
        return _ChecklistLoadResult(checklist: cached, isOffline: true);
      }
      rethrow;
    }
  }

  String get _localeCode {
    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode ?? 'ru';
  }

  String get _profileCitizenshipCountryCode {
    try {
      final session = context.read<SessionProvider>();
      return session.profile?.countryCode?.trim().toUpperCase() ?? '';
    } on ProviderNotFoundException {
      return '';
    }
  }

  void _reloadChecklist() {
    if (_routeArgs == null) return;
    setState(() {
      _checklistFuture = _loadChecklist();
    });
  }

  Future<void> _startQuickPreparation(
    TravelChecklistRouteArgs routeArgs,
  ) async {
    final existingEntry = await _findExistingManualChecklist(routeArgs);
    if (!mounted) return;

    final effectiveRouteArgs = existingEntry?.routeArgs ?? routeArgs;
    if (existingEntry != null) {
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistQuickPrepDuplicateOpened,
      );
    }

    setState(() {
      _routeArgs = effectiveRouteArgs;
      _didCreateChecklistFuture = true;
      _carryResults = const [];
      _carrySearchError = null;
      _checklistFuture = _loadChecklist();
    });
  }

  Future<CachedTravelChecklistEntry?> _findExistingManualChecklist(
    TravelChecklistRouteArgs routeArgs,
  ) async {
    if (_checklistSourceFor(routeArgs) != _ChecklistSource.manual) {
      return null;
    }

    try {
      final entries = await _checklistCache.listTripChecklistEntries();
      return _matchingManualChecklistEntry(entries, routeArgs);
    } catch (_) {
      return null;
    }
  }

  TravelChecklistRouteArgs _requireRouteArgs() {
    final routeArgs = _routeArgs;
    if (routeArgs == null) {
      throw StateError('Travel checklist requires route args.');
    }
    return routeArgs;
  }

  void _setLoadedChecklist(TripChecklistVm checklist) {
    setState(() {
      _checklistFuture = Future<_ChecklistLoadResult>.value(
        _ChecklistLoadResult(checklist: checklist),
      );
    });
  }

  Future<void> _toggleChecklistItem(ChecklistItemVm item) async {
    if (_requireRouteArgs().isPreview) return;
    if (_updatingChecklistItemIds.contains(item.id)) return;

    final nextStatus = item.isDone ? 'open' : 'done';
    final shouldAssignToMe =
        nextStatus == 'done' && item.assignedUserId.trim().isEmpty;
    setState(() {
      _updatingChecklistItemIds.add(item.id);
    });

    try {
      var updated = await _checklistApi.updateChecklistItemStatus(
        tripId: _requireRouteArgs().normalizedTripId,
        itemId: item.id,
        status: nextStatus,
        locale: _localeCode,
      );
      if (shouldAssignToMe) {
        updated = await _checklistApi.setChecklistItemAssignment(
          tripId: _requireRouteArgs().normalizedTripId,
          itemId: item.id,
          assignToMe: true,
          locale: _localeCode,
        );
      }
      if (!mounted) return;
      await _checklistCache.saveTripChecklist(
        _requireRouteArgs().normalizedTripId,
        updated,
        routeArgs: _requireRouteArgs(),
      );
      if (!mounted) return;
      setState(() {
        _checklistFuture = Future<_ChecklistLoadResult>.value(
          _ChecklistLoadResult(checklist: updated),
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistLoadFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _updatingChecklistItemIds.remove(item.id);
    });
  }

  Future<void> _submitChecklistItemFeedback(
    ChecklistItemVm item,
    ChecklistItemFeedbackType type,
  ) async {
    if (_requireRouteArgs().isPreview) return;
    if (_submittingFeedbackItemIds.contains(item.id)) return;
    if (_selectedFeedbackByItemId[item.id] == type) return;

    setState(() {
      _submittingFeedbackItemIds.add(item.id);
    });

    try {
      await _checklistApi.submitChecklistItemFeedback(
        tripId: _requireRouteArgs().normalizedTripId,
        itemId: item.id,
        type: type,
        locale: _localeCode,
      );
      if (!mounted) return;
      setState(() {
        _selectedFeedbackByItemId[item.id] = type;
      });
      _showChecklistSnackBar(
        _feedbackSnackBarMessage(type, AppLocalizations.of(context)!),
      );
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistFeedbackFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _submittingFeedbackItemIds.remove(item.id);
    });
  }

  Future<void> _createCustomChecklistItem(
    _CustomChecklistItemDraft draft,
  ) async {
    if (_requireRouteArgs().isPreview) return;
    if (_isSavingCustomItem) return;

    setState(() {
      _isSavingCustomItem = true;
    });

    try {
      final updated = await _checklistApi.createCustomChecklistItem(
        tripId: _requireRouteArgs().normalizedTripId,
        request: draft.toRequest(),
        locale: _localeCode,
      );
      if (!mounted) return;
      await _checklistCache.saveTripChecklist(
        _requireRouteArgs().normalizedTripId,
        updated,
        routeArgs: _requireRouteArgs(),
      );
      if (!mounted) return;
      _setLoadedChecklist(updated);
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemCreated,
      );
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSavingCustomItem = false;
    });
  }

  Future<void> _updateCustomChecklistItem(
    CustomChecklistItemVm item,
    _CustomChecklistItemDraft draft,
  ) async {
    if (_requireRouteArgs().isPreview) return;
    if (_updatingCustomItemIds.contains(item.id)) return;

    setState(() {
      _updatingCustomItemIds.add(item.id);
    });

    try {
      final updated = await _checklistApi.updateCustomChecklistItem(
        tripId: _requireRouteArgs().normalizedTripId,
        itemId: item.id,
        request: draft.toRequest(),
        locale: _localeCode,
      );
      if (!mounted) return;
      await _checklistCache.saveTripChecklist(
        _requireRouteArgs().normalizedTripId,
        updated,
        routeArgs: _requireRouteArgs(),
      );
      if (!mounted) return;
      _setLoadedChecklist(updated);
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemUpdated,
      );
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _updatingCustomItemIds.remove(item.id);
    });
  }

  Future<void> _toggleCustomChecklistItem(CustomChecklistItemVm item) async {
    if (_requireRouteArgs().isPreview) return;
    if (_updatingCustomItemIds.contains(item.id)) return;

    final nextStatus = item.isDone ? 'open' : 'done';
    setState(() {
      _updatingCustomItemIds.add(item.id);
    });

    try {
      final updated = await _checklistApi.updateCustomChecklistItemStatus(
        tripId: _requireRouteArgs().normalizedTripId,
        itemId: item.id,
        status: nextStatus,
        locale: _localeCode,
      );
      if (!mounted) return;
      await _checklistCache.saveTripChecklist(
        _requireRouteArgs().normalizedTripId,
        updated,
        routeArgs: _requireRouteArgs(),
      );
      if (!mounted) return;
      _setLoadedChecklist(updated);
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _updatingCustomItemIds.remove(item.id);
    });
  }

  Future<void> _deleteCustomChecklistItem(CustomChecklistItemVm item) async {
    if (_requireRouteArgs().isPreview) return;
    if (_deletingCustomItemIds.contains(item.id)) return;

    setState(() {
      _deletingCustomItemIds.add(item.id);
    });

    try {
      final updated = await _checklistApi.deleteCustomChecklistItem(
        tripId: _requireRouteArgs().normalizedTripId,
        itemId: item.id,
        locale: _localeCode,
      );
      if (!mounted) return;
      await _checklistCache.saveTripChecklist(
        _requireRouteArgs().normalizedTripId,
        updated,
        routeArgs: _requireRouteArgs(),
      );
      if (!mounted) return;
      _setLoadedChecklist(updated);
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemDeleted,
      );
    } catch (_) {
      if (!mounted) return;
      _showChecklistSnackBar(
        AppLocalizations.of(context)!.travelChecklistCustomItemFailed,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _deletingCustomItemIds.remove(item.id);
    });
  }

  Future<void> _openCreateCustomItemSheet() async {
    if (_requireRouteArgs().isPreview) return;
    final draft = await showAppModalBottomSheet<_CustomChecklistItemDraft>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: _ChecklistAmber.of(context).transparent,
      builder: (context) => const _CustomChecklistItemSheet(),
    );
    if (draft == null || !mounted) return;
    await _createCustomChecklistItem(draft);
  }

  Future<void> _openEditCustomItemSheet(CustomChecklistItemVm item) async {
    if (_requireRouteArgs().isPreview) return;
    final draft = await showAppModalBottomSheet<_CustomChecklistItemDraft>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: _ChecklistAmber.of(context).transparent,
      builder: (context) => _CustomChecklistItemSheet(item: item),
    );
    if (draft == null || !mounted) return;
    await _updateCustomChecklistItem(item, draft);
  }

  Future<void> _searchCarryItem() async {
    final query = _carrySearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _carryResults = const [];
        _carrySearchError = null;
      });
      return;
    }

    setState(() {
      _isSearchingCarryItem = true;
      _carrySearchError = null;
    });

    try {
      final result = await _checklistApi.searchCarryItems(
        query: query,
        transportMode: _requireRouteArgs().primaryTransportMode,
        locale: _localeCode,
      );
      if (!mounted) return;
      setState(() {
        _carryResults = result.items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carrySearchError = AppLocalizations.of(
          context,
        )!.travelChecklistLoadFailed;
      });
    }

    if (!mounted) return;
    setState(() {
      _isSearchingCarryItem = false;
    });
  }

  Future<void> _optimizeDayRoute() async {
    if (_isOptimizingDayRoute) return;
    final routeArgs = _requireRouteArgs();
    if (routeArgs.routeStops.length < 2) return;

    setState(() {
      _isOptimizingDayRoute = true;
      _optimizedItineraryError = null;
    });

    final routingProvider = context.read<RoutingProvider>();
    try {
      final result = await routingProvider.optimizeItinerary(
        ItineraryOptimizationRequestVm(
          profile: RouteProfile.dayPlan,
          stops: [
            for (final stop in routeArgs.routeStops)
              RoutePointVm(
                latitude: stop.latitude,
                longitude: stop.longitude,
                name: stop.name,
              ),
          ],
        ),
      );
      if (!mounted) return;

      setState(() {
        _optimizedItinerary = result;
        _optimizedItineraryError = result == null
            ? routingProvider.errorMessage ??
                  AppLocalizations.of(context)!.travelChecklistOptimizeFailed
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _optimizedItinerary = null;
        _optimizedItineraryError = AppLocalizations.of(
          context,
        )!.travelChecklistOptimizeFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _isOptimizingDayRoute = false);
      }
    }
  }

  void _setChecklistItemSearchQuery(String query) {
    final normalizedQuery = query.trim();
    if (_checklistItemSearchQuery == normalizedQuery) return;

    setState(() {
      _checklistItemSearchQuery = normalizedQuery;
    });
  }

  void _showChecklistSnackBar(String message, {bool isError = false}) {
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_rounded;
    final accentColor = isError
        ? _ChecklistAmber.of(context).danger
        : _ChecklistAmber.of(context).amberSoft;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ChecklistAmber.of(context).surfaceElevated,
          elevation: 12,
          margin: const AppEdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.circular(8),
            side: BorderSide(
              color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.42),
            ),
          ),
          content: Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routeArgs = _routeArgs;
    final palette = _ChecklistAmber.of(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: palette.backgroundBottom,
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
            child: routeArgs == null
                ? _MissingChecklistContextView(
                    referenceApi: _referenceApi,
                    onCreatePreparation: _startQuickPreparation,
                  )
                : FutureBuilder<_ChecklistLoadResult>(
                    future: _checklistFuture,
                    builder: (context, snapshot) {
                      final result = snapshot.data;
                      final content = result != null
                          ? _ChecklistContent(
                              scrollController: _scrollController,
                              routeArgs: routeArgs,
                              checklist: result.checklist,
                              isOffline: result.isOffline,
                              isReadOnly: routeArgs.isPreview,
                              carrySearchController: _carrySearchController,
                              checklistItemSearchController:
                                  _checklistItemSearchController,
                              checklistItemSearchQuery:
                                  _checklistItemSearchQuery,
                              carryResults: _carryResults,
                              carrySearchError: _carrySearchError,
                              isSearchingCarryItem: _isSearchingCarryItem,
                              isOptimizingDayRoute: _isOptimizingDayRoute,
                              optimizedItinerary: _optimizedItinerary,
                              optimizedItineraryError: _optimizedItineraryError,
                              updatingChecklistItemIds:
                                  _updatingChecklistItemIds,
                              submittingFeedbackItemIds:
                                  _submittingFeedbackItemIds,
                              updatingCustomItemIds: _updatingCustomItemIds,
                              deletingCustomItemIds: _deletingCustomItemIds,
                              selectedFeedbackByItemId:
                                  _selectedFeedbackByItemId,
                              isSavingCustomItem: _isSavingCustomItem,
                              onSearchCarryItem: _searchCarryItem,
                              onOptimizeDayRoute: _optimizeDayRoute,
                              onChecklistItemSearchChanged:
                                  _setChecklistItemSearchQuery,
                              onToggleChecklistItem: _toggleChecklistItem,
                              onSubmitItemFeedback:
                                  _submitChecklistItemFeedback,
                              onAddCustomItem: _openCreateCustomItemSheet,
                              onToggleCustomItem: _toggleCustomChecklistItem,
                              onEditCustomItem: _openEditCustomItemSheet,
                              onDeleteCustomItem: _deleteCustomChecklistItem,
                            )
                          : switch (snapshot.connectionState) {
                              ConnectionState.waiting ||
                              ConnectionState.active =>
                                const _ChecklistLoadingView(),
                              _ when snapshot.hasError => _ChecklistErrorView(
                                message: l10n.travelChecklistLoadFailed,
                                retryLabel: l10n.travelChecklistRetry,
                                onRetry: _reloadChecklist,
                              ),
                              _ => const _ChecklistLoadingView(),
                            };

                      return content;
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistLoadResult {
  const _ChecklistLoadResult({required this.checklist, this.isOffline = false});

  final TripChecklistVm checklist;
  final bool isOffline;
}

class _ChecklistContent extends StatelessWidget {
  const _ChecklistContent({
    required this.scrollController,
    required this.routeArgs,
    required this.checklist,
    required this.isOffline,
    required this.isReadOnly,
    required this.carrySearchController,
    required this.checklistItemSearchController,
    required this.checklistItemSearchQuery,
    required this.carryResults,
    required this.carrySearchError,
    required this.isSearchingCarryItem,
    required this.isOptimizingDayRoute,
    required this.optimizedItinerary,
    required this.optimizedItineraryError,
    required this.updatingChecklistItemIds,
    required this.submittingFeedbackItemIds,
    required this.updatingCustomItemIds,
    required this.deletingCustomItemIds,
    required this.selectedFeedbackByItemId,
    required this.isSavingCustomItem,
    required this.onSearchCarryItem,
    required this.onOptimizeDayRoute,
    required this.onChecklistItemSearchChanged,
    required this.onToggleChecklistItem,
    required this.onSubmitItemFeedback,
    required this.onAddCustomItem,
    required this.onToggleCustomItem,
    required this.onEditCustomItem,
    required this.onDeleteCustomItem,
  });

  final ScrollController scrollController;
  final TravelChecklistRouteArgs routeArgs;
  final TripChecklistVm checklist;
  final bool isOffline;
  final bool isReadOnly;
  final TextEditingController carrySearchController;
  final TextEditingController checklistItemSearchController;
  final String checklistItemSearchQuery;
  final List<CarryItemPolicyVm> carryResults;
  final String? carrySearchError;
  final bool isSearchingCarryItem;
  final bool isOptimizingDayRoute;
  final ItineraryOptimizationResponseVm? optimizedItinerary;
  final String? optimizedItineraryError;
  final Set<String> updatingChecklistItemIds;
  final Set<String> submittingFeedbackItemIds;
  final Set<String> updatingCustomItemIds;
  final Set<String> deletingCustomItemIds;
  final Map<String, ChecklistItemFeedbackType> selectedFeedbackByItemId;
  final bool isSavingCustomItem;
  final VoidCallback onSearchCarryItem;
  final VoidCallback onOptimizeDayRoute;
  final ValueChanged<String> onChecklistItemSearchChanged;
  final ValueChanged<ChecklistItemVm> onToggleChecklistItem;
  final void Function(ChecklistItemVm item, ChecklistItemFeedbackType type)
  onSubmitItemFeedback;
  final VoidCallback onAddCustomItem;
  final ValueChanged<CustomChecklistItemVm> onToggleCustomItem;
  final ValueChanged<CustomChecklistItemVm> onEditCustomItem;
  final ValueChanged<CustomChecklistItemVm> onDeleteCustomItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 390;
        final horizontalPadding = constraints.maxWidth < 340
            ? 10.0
            : isCompact
            ? 14.0
            : 18.0;

        return CustomScrollView(
          key: const PageStorageKey<String>('travel-checklist-content-scroll'),
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: AppEdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 18 : 24,
                horizontalPadding,
                32,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          title: l10n.travelChecklistTitle,
                          subtitle: l10n.travelChecklistSubtitle,
                        ),
                        const SizedBox(height: 18),
                        _TripContextPanel(routeArgs: routeArgs),
                        if (routeArgs.routeStops.length >= 2) ...[
                          const SizedBox(height: 12),
                          _OptimizedItineraryCard(
                            routeArgs: routeArgs,
                            result: optimizedItinerary,
                            errorMessage: optimizedItineraryError,
                            isLoading: isOptimizingDayRoute,
                            onOptimizeTap: onOptimizeDayRoute,
                          ),
                        ],
                        if (isOffline) ...[
                          const SizedBox(height: 12),
                          _OfflineChecklistNotice(
                            title: l10n.travelChecklistOfflineTitle,
                            message: l10n.travelChecklistOfflineMessage,
                          ),
                        ],
                        if (isReadOnly) ...[
                          const SizedBox(height: 12),
                          _ChecklistNotice(
                            icon: Icons.visibility_rounded,
                            title: l10n.travelChecklistPreviewAction,
                            message: l10n.travelChecklistPreviewMessage,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _ReadinessPanel(checklist: checklist),
                        const SizedBox(height: 12),
                        _TrustNoticePanel(notice: checklist.trustNotice),
                        if (checklist.seasonalProfile != null) ...[
                          const SizedBox(height: 12),
                          _SeasonalPanel(profile: checklist.seasonalProfile!),
                        ],
                        const SizedBox(height: 12),
                        _CarrySearchPanel(
                          controller: carrySearchController,
                          results: carryResults,
                          error: carrySearchError,
                          isSearching: isSearchingCarryItem,
                          onSearch: onSearchCarryItem,
                        ),
                        const SizedBox(height: 12),
                        _ChecklistItemsPanel(
                          items: checklist.items,
                          customItems: checklist.customItems,
                          searchController: checklistItemSearchController,
                          searchQuery: checklistItemSearchQuery,
                          updatingItemIds: updatingChecklistItemIds,
                          submittingFeedbackItemIds: submittingFeedbackItemIds,
                          updatingCustomItemIds: updatingCustomItemIds,
                          deletingCustomItemIds: deletingCustomItemIds,
                          selectedFeedbackByItemId: selectedFeedbackByItemId,
                          isSavingCustomItem: isSavingCustomItem,
                          isReadOnly: isReadOnly,
                          onAddCustomItem: onAddCustomItem,
                          onSearchChanged: onChecklistItemSearchChanged,
                          onToggleItem: onToggleChecklistItem,
                          onSubmitFeedback: onSubmitItemFeedback,
                          onToggleCustomItem: onToggleCustomItem,
                          onEditCustomItem: onEditCustomItem,
                          onDeleteCustomItem: onDeleteCustomItem,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canPop) ...[
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                color: _ChecklistAmber.of(context).textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textSecondary,
              fontSize: 14,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class _MissingChecklistContextView extends StatefulWidget {
  const _MissingChecklistContextView({
    required this.referenceApi,
    required this.onCreatePreparation,
  });

  final ReferenceApi referenceApi;
  final ValueChanged<TravelChecklistRouteArgs> onCreatePreparation;

  @override
  State<_MissingChecklistContextView> createState() =>
      _MissingChecklistContextViewState();
}

class _MissingChecklistContextViewState
    extends State<_MissingChecklistContextView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final FocusNode _countryFocusNode;
  late final FocusNode _cityFocusNode;
  late DateTime _startDate;
  late DateTime _endDate;
  _QuickPrepCountryOption? _selectedCountry;
  _QuickPrepCityOption? _selectedCity;
  final Map<String, List<_QuickPrepCountryOption>> _countryOptionsCache = {};
  final Map<String, List<_QuickPrepCityOption>> _cityOptionsCache = {};
  String _transportMode = 'flight';
  final Set<String> _activitySlugs = <String>{};
  bool _hasChildren = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toUtc();
    _startDate = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 30));
    _endDate = _startDate.add(const Duration(days: 7));
    _countryController = TextEditingController();
    _cityController = TextEditingController();
    _countryFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _countryFocusNode.addListener(_clearUnselectedCountryOnBlur);
    _cityFocusNode.addListener(_clearUnselectedCityOnBlur);
  }

  @override
  void dispose() {
    _countryFocusNode.removeListener(_clearUnselectedCountryOnBlur);
    _cityFocusNode.removeListener(_clearUnselectedCityOnBlur);
    _countryController.dispose();
    _cityController.dispose();
    _countryFocusNode.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate
        ? DateTime.now().toUtc()
        : _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().toUtc().add(const Duration(days: 730)),
      helpText: isStartDate
          ? AppLocalizations.of(context)!.travelChecklistQuickPrepStartDate
          : AppLocalizations.of(context)!.travelChecklistQuickPrepEndDate,
      builder: (context, child) {
        return Theme(
          key: const ValueKey('quick-prep-date-picker-amber-theme'),
          data: _quickPrepDatePickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;

    setState(() {
      final normalizedPicked = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
      );
      if (isStartDate) {
        _startDate = normalizedPicked;
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = normalizedPicked.isAfter(_startDate)
            ? normalizedPicked
            : _startDate.add(const Duration(days: 1));
      }
    });
  }

  void _submit() {
    _clearInvalidDestinationInputs();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final localeCode = Localizations.maybeLocaleOf(context)?.languageCode;
    final selectedCountry = _selectedCountry;
    final selectedCity = _selectedCity;
    final countryCode = selectedCountry?.countryCode ?? '';
    final cityName =
        selectedCity?.displayName(localeCode) ?? _cityController.text.trim();
    final startAt = DateTime.utc(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      9,
    );
    final endAt = DateTime.utc(_endDate.year, _endDate.month, _endDate.day, 18);

    widget.onCreatePreparation(
      TravelChecklistRouteArgs(
        tripId: _quickPreparationTripId(
          countryCode: countryCode,
          cityName: cityName,
          startAt: startAt,
          endAt: endAt,
          transportModes: [_transportMode],
          activitySlugs: _activitySlugs,
          hasChildren: _hasChildren,
        ),
        destination: TripChecklistDestinationRequest(
          countryCode: countryCode,
          cityName: cityName,
          cityId: selectedCity?.cityId,
        ),
        destinationCountryName: selectedCountry?.displayName(localeCode),
        startAt: startAt,
        endAt: endAt,
        transportModes: [_transportMode],
        activitySlugs: _activitySlugs.toList(growable: false)..sort(),
        hasChildren: _hasChildren,
      ),
    );
  }

  void _handleCountryInputChanged(String value) {
    final selectedCountry = _selectedCountry;
    if (selectedCountry == null) return;
    if (_isCountrySelectionTextValid(selectedCountry)) return;

    setState(() {
      _selectedCountry = null;
      _selectedCity = null;
      _cityController.clear();
    });
  }

  void _handleCityInputChanged(String value) {
    final selectedCity = _selectedCity;
    if (selectedCity == null) return;
    if (_isCitySelectionTextValid(selectedCity)) return;

    setState(() {
      _selectedCity = null;
    });
  }

  void _clearUnselectedCountryOnBlur() {
    if (_countryFocusNode.hasFocus || _selectedCountry != null) return;
    if (_countryController.text.trim().isEmpty) return;

    setState(() {
      _countryController.clear();
      _selectedCity = null;
      _cityController.clear();
    });
  }

  void _clearUnselectedCityOnBlur() {
    if (_cityFocusNode.hasFocus || _selectedCity != null) return;
    if (_cityController.text.trim().isEmpty) return;

    setState(() {
      _cityController.clear();
    });
  }

  void _clearInvalidDestinationInputs() {
    final selectedCountry = _selectedCountry;
    final selectedCity = _selectedCity;
    final shouldClearCountry =
        _countryController.text.trim().isNotEmpty &&
        (selectedCountry == null ||
            !_isCountrySelectionTextValid(selectedCountry));
    final shouldClearCity =
        _cityController.text.trim().isNotEmpty &&
        (selectedCity == null || !_isCitySelectionTextValid(selectedCity));

    if (!shouldClearCountry && !shouldClearCity) return;

    setState(() {
      if (shouldClearCountry) {
        _countryController.clear();
        _selectedCountry = null;
        _selectedCity = null;
        _cityController.clear();
      } else if (shouldClearCity) {
        _cityController.clear();
        _selectedCity = null;
      }
    });
  }

  bool _isCountrySelectionTextValid(_QuickPrepCountryOption country) {
    return _normalizeQuickPrepSearch(_countryController.text) ==
        _normalizeQuickPrepSearch(country.displayName(_localeLanguageCode));
  }

  bool _isCitySelectionTextValid(_QuickPrepCityOption city) {
    return _normalizeQuickPrepSearch(_cityController.text) ==
        _normalizeQuickPrepSearch(city.displayName(_localeLanguageCode));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 340
            ? 10.0
            : constraints.maxWidth < 390
            ? 14.0
            : 18.0;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppEdgeInsets.fromLTRB(
                horizontalPadding,
                constraints.maxWidth < 390 ? 18 : 24,
                horizontalPadding,
                32,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          title: l10n.travelChecklistTitle,
                          subtitle: l10n.travelChecklistSubtitle,
                        ),
                        const SizedBox(height: 12),
                        _SurfacePanel(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  icon: Icons.route_rounded,
                                  title:
                                      l10n.travelChecklistMissingContextTitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.travelChecklistMissingContextMessage,
                                  style: AppTextStyle(
                                    color: _ChecklistAmber.of(
                                      context,
                                    ).textSecondary,
                                    fontSize: 14,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.travelChecklistQuickPrepTitle,
                                  style: AppTextStyle(
                                    color: _ChecklistAmber.of(
                                      context,
                                    ).textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.travelChecklistQuickPrepMessage,
                                  style: AppTextStyle(
                                    color: _ChecklistAmber.of(
                                      context,
                                    ).textSecondary,
                                    fontSize: 14,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _QuickPrepAutocompleteField<
                                  _QuickPrepCountryOption
                                >(
                                  key: const ValueKey(
                                    'quick-prep-country-code-field',
                                  ),
                                  controller: _countryController,
                                  focusNode: _countryFocusNode,
                                  label:
                                      l10n.travelChecklistQuickPrepCountryCode,
                                  hint: l10n
                                      .travelChecklistQuickPrepCountryCodeHint,
                                  textCapitalization: TextCapitalization.words,
                                  displayStringForOption: (country) =>
                                      country.displayName(_localeLanguageCode),
                                  optionsBuilder: (value) =>
                                      _filterQuickPrepCountries(value.text),
                                  onChanged: _handleCountryInputChanged,
                                  onSelected: (country) {
                                    setState(() {
                                      _selectedCountry = country;
                                      if (_selectedCity?.countryCode !=
                                          country.countryCode) {
                                        _selectedCity = null;
                                        _cityController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return l10n
                                          .travelChecklistQuickPrepCountryRequired;
                                    }
                                    if (_selectedCountry == null) {
                                      return l10n
                                          .travelChecklistQuickPrepCountryInvalid;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _QuickPrepAutocompleteField<
                                  _QuickPrepCityOption
                                >(
                                  key: const ValueKey('quick-prep-city-field'),
                                  controller: _cityController,
                                  focusNode: _cityFocusNode,
                                  label: l10n.travelChecklistQuickPrepCity,
                                  hint: l10n.travelChecklistQuickPrepCityHint,
                                  textCapitalization: TextCapitalization.words,
                                  displayStringForOption: (city) =>
                                      city.displayName(_localeLanguageCode),
                                  optionsBuilder: (value) =>
                                      _filterQuickPrepCities(value.text),
                                  onChanged: _handleCityInputChanged,
                                  onSelected: (city) {
                                    setState(() {
                                      _selectQuickPrepCity(city);
                                    });
                                  },
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return l10n
                                          .travelChecklistQuickPrepCityRequired;
                                    }
                                    if (_selectedCity == null) {
                                      return l10n
                                          .travelChecklistQuickPrepCityRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _QuickPrepDateRow(
                                  startDate: _startDate,
                                  endDate: _endDate,
                                  onPickStartDate: () =>
                                      _pickDate(isStartDate: true),
                                  onPickEndDate: () =>
                                      _pickDate(isStartDate: false),
                                ),
                                const SizedBox(height: 16),
                                _QuickPrepChoiceSection(
                                  icon: Icons.flight_takeoff_rounded,
                                  title: l10n
                                      .travelChecklistQuickPrepTransportTitle,
                                  children: [
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-flight',
                                      ),
                                      label:
                                          l10n.travelChecklistTransportFlight,
                                      selected: _transportMode == 'flight',
                                      onSelected: () => setState(() {
                                        _transportMode = 'flight';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-train',
                                      ),
                                      label: l10n.travelChecklistTransportTrain,
                                      selected: _transportMode == 'train',
                                      onSelected: () => setState(() {
                                        _transportMode = 'train';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-car',
                                      ),
                                      label: l10n.travelChecklistTransportCar,
                                      selected: _transportMode == 'car',
                                      onSelected: () => setState(() {
                                        _transportMode = 'car';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-motorcycle',
                                      ),
                                      label: l10n
                                          .travelChecklistTransportMotorcycle,
                                      selected: _transportMode == 'motorcycle',
                                      onSelected: () => setState(() {
                                        _transportMode = 'motorcycle';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-bus',
                                      ),
                                      label: l10n.travelChecklistTransportBus,
                                      selected: _transportMode == 'bus',
                                      onSelected: () => setState(() {
                                        _transportMode = 'bus';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-ferry',
                                      ),
                                      label: l10n.travelChecklistTransportFerry,
                                      selected: _transportMode == 'ferry',
                                      onSelected: () => setState(() {
                                        _transportMode = 'ferry';
                                      }),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-transport-other',
                                      ),
                                      label: l10n.travelChecklistTransportOther,
                                      selected: _transportMode == 'other',
                                      onSelected: () => setState(() {
                                        _transportMode = 'other';
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _QuickPrepChoiceSection(
                                  icon: Icons.local_activity_rounded,
                                  title: l10n
                                      .travelChecklistQuickPrepActivitiesTitle,
                                  children: [
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-culture',
                                      ),
                                      label:
                                          l10n.travelChecklistActivityCulture,
                                      selected: _activitySlugs.contains(
                                        'culture',
                                      ),
                                      onSelected: () =>
                                          _toggleActivity('culture'),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-walking',
                                      ),
                                      label:
                                          l10n.travelChecklistActivityWalking,
                                      selected: _activitySlugs.contains(
                                        'walking',
                                      ),
                                      onSelected: () =>
                                          _toggleActivity('walking'),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-hiking',
                                      ),
                                      label: l10n.travelChecklistActivityHiking,
                                      selected: _activitySlugs.contains(
                                        'hiking',
                                      ),
                                      onSelected: () =>
                                          _toggleActivity('hiking'),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-beach',
                                      ),
                                      label: l10n.travelChecklistActivityBeach,
                                      selected: _activitySlugs.contains(
                                        'beach',
                                      ),
                                      onSelected: () =>
                                          _toggleActivity('beach'),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-food',
                                      ),
                                      label: l10n.travelChecklistActivityFood,
                                      selected: _activitySlugs.contains('food'),
                                      onSelected: () => _toggleActivity('food'),
                                    ),
                                    _QuickPrepChoiceChip(
                                      key: const ValueKey(
                                        'quick-prep-activity-shopping',
                                      ),
                                      label:
                                          l10n.travelChecklistActivityShopping,
                                      selected: _activitySlugs.contains(
                                        'shopping',
                                      ),
                                      onSelected: () =>
                                          _toggleActivity('shopping'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SwitchListTile.adaptive(
                                  key: const ValueKey(
                                    'quick-prep-has-children',
                                  ),
                                  contentPadding: AppEdgeInsets.zero,
                                  value: _hasChildren,
                                  onChanged: (value) => setState(() {
                                    _hasChildren = value;
                                  }),
                                  activeThumbColor: _ChecklistAmber.of(
                                    context,
                                  ).amber,
                                  title: Text(
                                    l10n.travelChecklistQuickPrepWithChildren,
                                    style: AppTextStyle(
                                      color: _ChecklistAmber.of(
                                        context,
                                      ).textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  key: const ValueKey('quick-prep-submit'),
                                  onPressed: _submit,
                                  icon: Icon(Icons.checklist_rtl_rounded),
                                  label: Text(
                                    l10n.travelChecklistQuickPrepSubmit,
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _ChecklistAmber.of(
                                      context,
                                    ).amber,
                                    foregroundColor: _ChecklistAmber.of(
                                      context,
                                    ).textPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppBorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  l10n.travelChecklistQuickPrepAlternativeTitle,
                                  style: AppTextStyle(
                                    color: _ChecklistAmber.of(
                                      context,
                                    ).textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _MissingContextAlternativeActions(l10n: l10n),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleActivity(String slug) {
    setState(() {
      if (_activitySlugs.contains(slug)) {
        _activitySlugs.remove(slug);
      } else {
        _activitySlugs.add(slug);
      }
    });
  }

  String get _localeLanguageCode {
    return Localizations.maybeLocaleOf(context)?.languageCode ?? 'ru';
  }

  void _selectQuickPrepCity(_QuickPrepCityOption city) {
    _selectedCity = city;
    if (_selectedCountry?.countryCode == city.countryCode) return;

    _selectedCountry =
        _firstWhereOrNull(
          _countryOptionsCache.values.expand((countries) => countries),
          (country) => country.countryCode == city.countryCode,
        ) ??
        _firstWhereOrNull(
          _quickPrepCountries,
          (country) => country.countryCode == city.countryCode,
        ) ??
        _QuickPrepCountryOption.fromReference(
          ReferenceCountry(code: city.countryCode, name: city.countryCode),
        );
    _countryController.text = _selectedCountry!.displayName(
      _localeLanguageCode,
    );
  }

  Future<Iterable<_QuickPrepCountryOption>> _filterQuickPrepCountries(
    String query,
  ) async {
    final normalizedQuery = _normalizeQuickPrepSearch(query);
    final cacheKey = '$_localeLanguageCode|$normalizedQuery';
    final cached = _countryOptionsCache[cacheKey];
    if (cached != null) return cached;

    try {
      final countries = normalizedQuery.length < 2
          ? await widget.referenceApi.listCountries(lang: _localeLanguageCode)
          : await widget.referenceApi.searchCountries(
              query,
              lang: _localeLanguageCode,
              limit: 40,
            );
      final options = countries
          .where((country) => country.code.trim().isNotEmpty)
          .map(_QuickPrepCountryOption.fromReference)
          .where((country) => normalizedQuery.isEmpty || country.matches(query))
          .toList(growable: false);
      _countryOptionsCache[cacheKey] = options;
      return options;
    } catch (_) {
      final fallback = normalizedQuery.isEmpty
          ? _quickPrepCountries
          : _quickPrepCountries
                .where((country) => country.matches(normalizedQuery))
                .toList(growable: false);
      _countryOptionsCache[cacheKey] = fallback;
      return fallback;
    }
  }

  Future<Iterable<_QuickPrepCityOption>> _filterQuickPrepCities(
    String query,
  ) async {
    final normalizedQuery = _normalizeQuickPrepSearch(query);
    final countryCode = _selectedCountry?.countryCode;
    final cacheKey = [
      _localeLanguageCode,
      countryCode ?? '',
      normalizedQuery,
    ].join('|');
    final cached = _cityOptionsCache[cacheKey];
    if (cached != null) return cached;

    try {
      final cities = normalizedQuery.length >= 2
          ? await widget.referenceApi.searchCities(
              query,
              countryCode: countryCode,
              lang: _localeLanguageCode,
              limit: 40,
            )
          : countryCode == null
          ? const <ReferenceCity>[]
          : await widget.referenceApi.citiesByCountry(
              countryCode,
              lang: _localeLanguageCode,
            );
      final options = cities
          .where((city) => city.id.trim().isNotEmpty)
          .map(_QuickPrepCityOption.fromReference)
          .where((city) => normalizedQuery.isEmpty || city.matches(query))
          .toList(growable: false);
      _cityOptionsCache[cacheKey] = options;
      return options;
    } catch (_) {
      final fallbackCities = countryCode == null
          ? _quickPrepCities
          : _quickPrepCities.where((city) => city.countryCode == countryCode);
      final fallback = normalizedQuery.isEmpty
          ? fallbackCities.toList(growable: false)
          : fallbackCities
                .where((city) => city.matches(normalizedQuery))
                .toList(growable: false);
      _cityOptionsCache[cacheKey] = fallback;
      return fallback;
    }
  }
}

class _ChecklistListLoadingPanel extends StatelessWidget {
  const _ChecklistListLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      prominent: true,
      child: Padding(
        padding: AppEdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            color: _ChecklistAmber.of(context).amber,
          ),
        ),
      ),
    );
  }
}

class _ChecklistListEmptyPanel extends StatelessWidget {
  const _ChecklistListEmptyPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SurfacePanel(
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.checklist_rtl_rounded,
            title: l10n.travelChecklistRecentEmptyTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.travelChecklistRecentEmptyMessage,
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textSecondary,
              fontSize: 13,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: Icon(Icons.add_task_rounded),
            label: Text(
              l10n.travelChecklistQuickPrepSubmit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _ChecklistAmber.of(context).amber,
              foregroundColor: _ChecklistAmber.of(context).textPrimary,
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedChecklistsPanel extends StatelessWidget {
  const _SavedChecklistsPanel({
    required this.entries,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onOpen,
  });

  final List<CachedTravelChecklistEntry> entries;
  final _ChecklistListFilter selectedFilter;
  final ValueChanged<_ChecklistListFilter> onFilterChanged;
  final ValueChanged<TravelChecklistRouteArgs> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _checklistListSections(
      entries,
      filter: selectedFilter,
      l10n: l10n,
      now: DateTime.now().toUtc(),
    );

    return _SurfacePanel(
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.checklist_rtl_rounded,
            title: l10n.travelChecklistRecentTitle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.travelChecklistRecentMessage,
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textSecondary,
              fontSize: 13,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          _ChecklistFilterChips(
            selectedFilter: selectedFilter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 14),
          if (sections.isEmpty)
            const _ChecklistFilterEmptyPanel()
          else
            for (var index = 0; index < sections.length; index++) ...[
              if (index > 0) const SizedBox(height: 18),
              _ChecklistListSectionView(
                section: sections[index],
                onOpen: onOpen,
              ),
            ],
        ],
      ),
    );
  }
}

class _ChecklistListSection {
  const _ChecklistListSection({
    required this.title,
    required this.icon,
    required this.entries,
  });

  final String title;
  final IconData icon;
  final List<CachedTravelChecklistEntry> entries;
}

class _ChecklistListSectionView extends StatelessWidget {
  const _ChecklistListSectionView({
    required this.section,
    required this.onOpen,
  });

  final _ChecklistListSection section;
  final ValueChanged<TravelChecklistRouteArgs> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: section.icon, title: section.title),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = section.entries[index];
            return _RecentChecklistTile(entry: entry, onOpen: onOpen);
          },
        ),
      ],
    );
  }
}

class _ChecklistFilterChips extends StatelessWidget {
  const _ChecklistFilterChips({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _ChecklistListFilter selectedFilter;
  final ValueChanged<_ChecklistListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in _ChecklistListFilter.values)
          _ChecklistListFilterChip(
            label: _checklistListFilterLabel(filter, l10n),
            selected: filter == selectedFilter,
            onSelected: () => onChanged(filter),
          ),
      ],
    );
  }
}

class _ChecklistListFilterChip extends StatelessWidget {
  const _ChecklistListFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: selected
              ? _ChecklistAmber.of(context).textPrimary
              : _ChecklistAmber.of(context).textSecondary,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
          letterSpacing: 0,
        ),
      ),
      backgroundColor: _ChecklistAmber.of(context).surfacePressed,
      selectedColor: _ChecklistAmber.of(context).amberSoft,
      side: BorderSide(
        color: selected
            ? _ChecklistAmber.of(context).amberSoft
            : _ChecklistAmber.of(context).border.withValues(alpha: 0.48),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const AppEdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _ChecklistFilterEmptyPanel extends StatelessWidget {
  const _ChecklistFilterEmptyPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _ChecklistAmber.of(context).itemSurface.withValues(alpha: 0.56),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: _ChecklistAmber.of(context).border.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.travelChecklistFilterEmptyTitle,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.travelChecklistFilterEmptyMessage,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentChecklistTile extends StatelessWidget {
  const _RecentChecklistTile({required this.entry, required this.onOpen});

  final CachedTravelChecklistEntry entry;
  final ValueChanged<TravelChecklistRouteArgs> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routeArgs = entry.routeArgs;
    final destination = _destinationLabel(routeArgs, l10n);
    final dates = _dateRangeLabel(routeArgs.startAt, routeArgs.safeEndAt);
    final readiness = entry.readinessScore.clamp(0, 100);
    final source = _checklistSourceFor(routeArgs);
    final sourceLabel = _checklistSourceLabel(source, l10n);
    final statusLabel = _cachedReadinessStatusLabel(
      entry.readinessStatus,
      l10n,
    );

    return Material(
      color: _ChecklistAmber.of(context).itemSurface.withValues(alpha: 0.72),
      borderRadius: AppBorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('travel-checklist-recent-${routeArgs.normalizedTripId}'),
        borderRadius: AppBorderRadius.circular(8),
        onTap: () => onOpen(routeArgs),
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: AppBoxDecoration(
                  color: _ChecklistAmber.of(
                    context,
                  ).amber.withValues(alpha: 0.18),
                  borderRadius: AppBorderRadius.circular(8),
                ),
                child: Padding(
                  padding: AppEdgeInsets.all(9),
                  child: Icon(
                    Icons.luggage_rounded,
                    color: _ChecklistAmber.of(context).amberSoft,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: _ChecklistAmber.of(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ChipLabel(label: sourceLabel),
                        _ChipLabel(label: statusLabel),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$dates · ${l10n.travelChecklistReadiness} $readiness%',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: _ChecklistAmber.of(context).textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.travelChecklistOpen,
                onPressed: () => onOpen(routeArgs),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: _ChecklistAmber.of(context).amberSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPrepAutocompleteField<T extends Object> extends StatelessWidget {
  const _QuickPrepAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.validator,
    required this.displayStringForOption,
    required this.optionsBuilder,
    required this.onChanged,
    required this.onSelected,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final FormFieldValidator<String> validator;
  final AutocompleteOptionToString<T> displayStringForOption;
  final AutocompleteOptionsBuilder<T> optionsBuilder;
  final ValueChanged<String> onChanged;
  final AutocompleteOnSelected<T> onSelected;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: displayStringForOption,
      optionsBuilder: optionsBuilder,
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, fieldFocusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: fieldFocusNode,
              validator: validator,
              onChanged: onChanged,
              textCapitalization: textCapitalization,
              autocorrect: false,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              decoration: AppInputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: AppTextStyle(
                  color: _ChecklistAmber.of(context).textSecondary,
                ),
                hintStyle: AppTextStyle(
                  color: _ChecklistAmber.of(
                    context,
                  ).textMuted.withValues(alpha: 0.8),
                ),
                filled: true,
                fillColor: _ChecklistAmber.of(
                  context,
                ).surfaceElevated.withValues(alpha: 0.72),
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _ChecklistAmber.of(context).amberSoft,
                ),
                errorMaxLines: 3,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _ChecklistAmber.of(
                      context,
                    ).border.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _ChecklistAmber.of(context).amberSoft,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _ChecklistAmber.of(context).danger,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _ChecklistAmber.of(context).danger,
                  ),
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: _ChecklistAmber.of(context).transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 240),
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  color: _ChecklistAmber.of(context).surfaceElevated,
                  borderRadius: AppBorderRadius.circular(8),
                  border: Border.all(
                    color: _ChecklistAmber.of(
                      context,
                    ).amber.withValues(alpha: 0.36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ChecklistAmber.of(
                        context,
                      ).black.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const AppEdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final isHighlighted =
                        AutocompleteHighlightedOption.of(context) == index;
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        color: isHighlighted
                            ? _ChecklistAmber.of(
                                context,
                              ).amber.withValues(alpha: 0.16)
                            : _ChecklistAmber.of(context).transparent,
                        padding: const AppEdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Text(
                          displayStringForOption(option),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: _ChecklistAmber.of(context).textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: 0,
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
      },
    );
  }
}

class _QuickPrepCountryOption {
  const _QuickPrepCountryOption({
    required this.countryCode,
    required this.ru,
    required this.en,
    required this.kk,
    this.aliases = const [],
  });

  final String countryCode;
  final String ru;
  final String en;
  final String kk;
  final List<String> aliases;

  factory _QuickPrepCountryOption.fromReference(ReferenceCountry country) {
    final name = country.name.trim().isNotEmpty
        ? country.name.trim()
        : country.code.trim().toUpperCase();
    return _QuickPrepCountryOption(
      countryCode: country.code.trim().toUpperCase(),
      ru: name,
      en: name,
      kk: name,
      aliases: [country.code],
    );
  }

  String displayName(String? localeCode) {
    return switch ((localeCode ?? '').trim().toLowerCase()) {
      'en' => en,
      'kk' => kk,
      _ => ru,
    };
  }

  bool matches(String query) {
    final normalizedQuery = _normalizeQuickPrepSearch(query);
    if (normalizedQuery.isEmpty) return true;
    return _searchTokens.any((token) => token.contains(normalizedQuery));
  }

  Iterable<String> get _searchTokens {
    return [countryCode, ru, en, kk, ...aliases].map(_normalizeQuickPrepSearch);
  }
}

class _QuickPrepCityOption {
  const _QuickPrepCityOption({
    required this.cityId,
    required this.countryCode,
    required this.ru,
    required this.en,
    required this.kk,
    this.aliases = const [],
  });

  final String cityId;
  final String countryCode;
  final String ru;
  final String en;
  final String kk;
  final List<String> aliases;

  factory _QuickPrepCityOption.fromReference(ReferenceCity city) {
    final name = city.name.trim().isNotEmpty
        ? city.name.trim()
        : city.id.trim();
    return _QuickPrepCityOption(
      cityId: city.id.trim(),
      countryCode: city.countryCode.trim().toUpperCase(),
      ru: name,
      en: name,
      kk: name,
      aliases: [city.id],
    );
  }

  String displayName(String? localeCode) {
    return switch ((localeCode ?? '').trim().toLowerCase()) {
      'en' => en,
      'kk' => kk,
      _ => ru,
    };
  }

  bool matches(String query) {
    final normalizedQuery = _normalizeQuickPrepSearch(query);
    if (normalizedQuery.isEmpty) return true;
    return _searchTokens.any((token) => token.contains(normalizedQuery));
  }

  Iterable<String> get _searchTokens {
    return [
      cityId,
      countryCode,
      ru,
      en,
      kk,
      ...aliases,
    ].map(_normalizeQuickPrepSearch);
  }
}

const _quickPrepCountries = [
  _QuickPrepCountryOption(
    countryCode: 'KZ',
    ru: 'Казахстан',
    en: 'Kazakhstan',
    kk: 'Қазақстан',
    aliases: ['казакстан', 'qazaqstan'],
  ),
  _QuickPrepCountryOption(
    countryCode: 'TR',
    ru: 'Турция',
    en: 'Turkey',
    kk: 'Түркия',
    aliases: ['turkiye', 'türkiye'],
  ),
  _QuickPrepCountryOption(
    countryCode: 'JP',
    ru: 'Япония',
    en: 'Japan',
    kk: 'Жапония',
  ),
  _QuickPrepCountryOption(
    countryCode: 'AE',
    ru: 'ОАЭ',
    en: 'United Arab Emirates',
    kk: 'БАӘ',
    aliases: ['uae', 'emirates', 'дубай'],
  ),
  _QuickPrepCountryOption(
    countryCode: 'GE',
    ru: 'Грузия',
    en: 'Georgia',
    kk: 'Грузия',
  ),
  _QuickPrepCountryOption(
    countryCode: 'TH',
    ru: 'Таиланд',
    en: 'Thailand',
    kk: 'Таиланд',
  ),
  _QuickPrepCountryOption(
    countryCode: 'IT',
    ru: 'Италия',
    en: 'Italy',
    kk: 'Италия',
  ),
  _QuickPrepCountryOption(
    countryCode: 'FR',
    ru: 'Франция',
    en: 'France',
    kk: 'Франция',
  ),
  _QuickPrepCountryOption(
    countryCode: 'ES',
    ru: 'Испания',
    en: 'Spain',
    kk: 'Испания',
  ),
  _QuickPrepCountryOption(
    countryCode: 'US',
    ru: 'США',
    en: 'United States',
    kk: 'АҚШ',
    aliases: ['usa', 'america', 'америка'],
  ),
];

const _quickPrepCities = [
  _QuickPrepCityOption(
    cityId: 'almaty',
    countryCode: 'KZ',
    ru: 'Алматы',
    en: 'Almaty',
    kk: 'Алматы',
  ),
  _QuickPrepCityOption(
    cityId: 'astana',
    countryCode: 'KZ',
    ru: 'Астана',
    en: 'Astana',
    kk: 'Астана',
  ),
  _QuickPrepCityOption(
    cityId: 'istanbul',
    countryCode: 'TR',
    ru: 'Стамбул',
    en: 'Istanbul',
    kk: 'Ыстамбұл',
    aliases: ['истамбул'],
  ),
  _QuickPrepCityOption(
    cityId: 'antalya',
    countryCode: 'TR',
    ru: 'Анталья',
    en: 'Antalya',
    kk: 'Анталья',
  ),
  _QuickPrepCityOption(
    cityId: 'tokyo',
    countryCode: 'JP',
    ru: 'Токио',
    en: 'Tokyo',
    kk: 'Токио',
  ),
  _QuickPrepCityOption(
    cityId: 'kyoto',
    countryCode: 'JP',
    ru: 'Киото',
    en: 'Kyoto',
    kk: 'Киото',
  ),
  _QuickPrepCityOption(
    cityId: 'dubai',
    countryCode: 'AE',
    ru: 'Дубай',
    en: 'Dubai',
    kk: 'Дубай',
  ),
  _QuickPrepCityOption(
    cityId: 'tbilisi',
    countryCode: 'GE',
    ru: 'Тбилиси',
    en: 'Tbilisi',
    kk: 'Тбилиси',
  ),
  _QuickPrepCityOption(
    cityId: 'bangkok',
    countryCode: 'TH',
    ru: 'Бангкок',
    en: 'Bangkok',
    kk: 'Бангкок',
  ),
  _QuickPrepCityOption(
    cityId: 'rome',
    countryCode: 'IT',
    ru: 'Рим',
    en: 'Rome',
    kk: 'Рим',
  ),
  _QuickPrepCityOption(
    cityId: 'paris',
    countryCode: 'FR',
    ru: 'Париж',
    en: 'Paris',
    kk: 'Париж',
  ),
  _QuickPrepCityOption(
    cityId: 'barcelona',
    countryCode: 'ES',
    ru: 'Барселона',
    en: 'Barcelona',
    kk: 'Барселона',
  ),
  _QuickPrepCityOption(
    cityId: 'new-york',
    countryCode: 'US',
    ru: 'Нью-Йорк',
    en: 'New York',
    kk: 'Нью-Йорк',
    aliases: ['nyc'],
  ),
];

class _QuickPrepDateRow extends StatelessWidget {
  const _QuickPrepDateRow({
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickPrepDateButton(
          key: const ValueKey('quick-prep-start-date'),
          icon: Icons.flight_takeoff_rounded,
          label: l10n.travelChecklistQuickPrepStartDate,
          value: _shortDate(startDate),
          onPressed: onPickStartDate,
        ),
        _QuickPrepDateButton(
          key: const ValueKey('quick-prep-end-date'),
          icon: Icons.event_available_rounded,
          label: l10n.travelChecklistQuickPrepEndDate,
          value: _shortDate(endDate),
          onPressed: onPickEndDate,
        ),
      ],
    );
  }
}

class _QuickPrepDateButton extends StatelessWidget {
  const _QuickPrepDateButton({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _ChecklistAmber.of(context).amberSoft,
        minimumSize: const Size(136, 48),
        padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(
          color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.45),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _QuickPrepChoiceSection extends StatelessWidget {
  const _QuickPrepChoiceSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _QuickPrepChoiceChip extends StatelessWidget {
  const _QuickPrepChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: _ChecklistAmber.of(context).textPrimary,
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: selected
                    ? _ChecklistAmber.of(context).textPrimary
                    : _ChecklistAmber.of(context).textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _ChecklistAmber.of(context).surfacePressed,
      selectedColor: _ChecklistAmber.of(context).amberSoft,
      side: BorderSide(
        color: selected
            ? _ChecklistAmber.of(context).amberSoft
            : _ChecklistAmber.of(context).border.withValues(alpha: 0.48),
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MissingContextAlternativeActions extends StatelessWidget {
  const _MissingContextAlternativeActions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const ValueKey('travel-checklist-open-excursions'),
          onPressed: () => context.go('/excursions'),
          icon: Icon(Icons.travel_explore_rounded),
          label: Text(
            l10n.travelChecklistMissingContextPrimaryAction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _ChecklistAmber.of(context).surfaceElevated,
            foregroundColor: _ChecklistAmber.of(context).amberSoft,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('travel-checklist-open-activities'),
          onPressed: () => context.go('/activities'),
          icon: Icon(Icons.hiking_rounded),
          label: Text(
            l10n.travelChecklistMissingContextSecondaryAction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _ChecklistAmber.of(context).amberSoft,
            minimumSize: const Size(0, 44),
            side: BorderSide(
              color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripContextPanel extends StatelessWidget {
  const _TripContextPanel({required this.routeArgs});

  final TravelChecklistRouteArgs routeArgs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transports = TravelChecklistRouteArgs.normalizedTokens(
      routeArgs.transportModes,
    );
    final activities = TravelChecklistRouteArgs.normalizedTokens(
      routeArgs.activitySlugs,
    );
    final activityLabels = _activityLabels(activities, l10n);

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.route_rounded,
            title: l10n.travelChecklistContextTitle,
          ),
          const SizedBox(height: 12),
          _ContextTextLine(
            icon: Icons.place_rounded,
            label: l10n.travelChecklistContextDestination,
            value: _destinationLabel(routeArgs, l10n),
          ),
          const SizedBox(height: 10),
          _ContextTextLine(
            icon: Icons.event_rounded,
            label: l10n.travelChecklistContextDates,
            value: routeArgs.isPreview
                ? l10n.travelChecklistPreviewDate
                : _dateRangeLabel(routeArgs.startAt, routeArgs.safeEndAt),
          ),
          const SizedBox(height: 10),
          _ContextChipLine(
            icon: Icons.flight_takeoff_rounded,
            label: l10n.travelChecklistContextTransport,
            chips: transports.isEmpty
                ? [l10n.travelChecklistUnknown]
                : transports
                      .map((mode) => _transportModeLabel(mode, l10n))
                      .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _ContextChipLine(
            icon: Icons.local_activity_rounded,
            label: l10n.travelChecklistContextActivities,
            chips: activityLabels.isEmpty
                ? [l10n.travelChecklistContextNoActivities]
                : activityLabels,
          ),
          if (routeArgs.hasChildren) ...[
            const SizedBox(height: 10),
            _ContextChipLine(
              icon: Icons.family_restroom_rounded,
              label: l10n.travelChecklistContextTravelerProfile,
              chips: [l10n.travelChecklistContextWithChildren],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptimizedItineraryCard extends StatelessWidget {
  const _OptimizedItineraryCard({
    required this.routeArgs,
    required this.result,
    required this.errorMessage,
    required this.isLoading,
    required this.onOptimizeTap,
  });

  final TravelChecklistRouteArgs routeArgs;
  final ItineraryOptimizationResponseVm? result;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onOptimizeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final optimized = result;
    final error = errorMessage?.trim();

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final title = _SectionTitle(
                icon: Icons.alt_route_rounded,
                title: l10n.travelChecklistOptimizeRouteTitle,
              );
              final action = FilledButton.icon(
                onPressed: isLoading ? null : onOptimizeTap,
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ChecklistAmber.of(context).textPrimary,
                        ),
                      )
                    : Icon(Icons.auto_awesome_motion_rounded),
                label: Text(
                  optimized == null
                      ? l10n.travelChecklistOptimizeRouteButton
                      : l10n.travelChecklistOptimizeRouteRetry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _ChecklistAmber.of(context).amber,
                  foregroundColor: _ChecklistAmber.of(context).backgroundBottom,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.circular(8),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            l10n.travelChecklistOptimizeRouteSubtitle(
              routeArgs.routeStops.length,
            ),
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textSecondary,
              fontSize: 13,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).danger,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (optimized != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipLabel(
                  label: _routingDurationLabel(optimized.durationSeconds),
                ),
                _ChipLabel(
                  label: _routingDistanceLabel(optimized.distanceMeters),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (
                  var index = 0;
                  index < optimized.orderedStops.length;
                  index += 1
                )
                  _OptimizedStopRow(
                    index: index + 1,
                    label: _routePointLabel(optimized.orderedStops[index]),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptimizedStopRow extends StatelessWidget {
  const _OptimizedStopRow({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppEdgeInsets.only(top: index == 1 ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: AppBoxDecoration(
              color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.18),
              borderRadius: AppBorderRadius.circular(8),
              border: Border.all(
                color: _ChecklistAmber.of(
                  context,
                ).amber.withValues(alpha: 0.42),
              ),
            ),
            child: Text(
              '$index',
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).amberSoft,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextTextLine extends StatelessWidget {
  const _ContextTextLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _ContextLineShell(
      icon: icon,
      label: label,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: _ChecklistAmber.of(context).textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ContextChipLine extends StatelessWidget {
  const _ContextChipLine({
    required this.icon,
    required this.label,
    required this.chips,
  });

  final IconData icon;
  final String label;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return _ContextLineShell(
      icon: icon,
      label: label,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips.map((chip) => _ChipLabel(label: chip)).toList(),
      ),
    );
  }
}

class _ContextLineShell extends StatelessWidget {
  const _ContextLineShell({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const AppEdgeInsets.only(top: 2),
          child: Icon(
            icon,
            color: _ChecklistAmber.of(context).textMuted,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _OfflineChecklistNotice extends StatelessWidget {
  const _OfflineChecklistNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: _ChecklistAmber.of(context).amberSoft.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: _ChecklistAmber.of(context).amberSoft,
              size: 20,
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
                    style: AppTextStyle(
                      color: _ChecklistAmber.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: _ChecklistAmber.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                    ),
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

class _ChecklistNotice extends StatelessWidget {
  const _ChecklistNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: _ChecklistAmber.of(context).amberSoft.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _ChecklistAmber.of(context).amberSoft, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: _ChecklistAmber.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: _ChecklistAmber.of(context).textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                      letterSpacing: 0,
                    ),
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

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({required this.checklist});

  final TripChecklistVm checklist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = checklist.readiness.score.clamp(0, 100);
    final personalProgress = checklist.personalProgress;
    final personalPercent = personalProgress.percent.clamp(0, 100);

    return _SurfacePanel(
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.travelChecklistSystemReadiness,
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              _StatusPill(status: checklist.readiness.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score%',
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textPrimary,
                  fontSize: 42,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: score / 100,
                    backgroundColor: _ChecklistAmber.of(
                      context,
                    ).white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _ChecklistAmber.of(context).amber,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (personalProgress.total > 0) ...[
            const SizedBox(height: 14),
            Text(
              l10n.travelChecklistPersonalProgress(
                personalProgress.done,
                personalProgress.total,
              ),
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppBorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: personalPercent / 100,
                      backgroundColor: _ChecklistAmber.of(
                        context,
                      ).white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _ChecklistAmber.of(context).amberSoft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$personalPercent%',
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ChecklistReadinessStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.18),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(
          color: _ChecklistAmber.of(context).amberSoft.withValues(alpha: 0.44),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _readinessStatusLabel(status, l10n),
          style: AppTextStyle(
            color: _ChecklistAmber.of(context).amberSoft,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TrustNoticePanel extends StatelessWidget {
  const _TrustNoticePanel({required this.notice});

  final ChecklistTrustNoticeVm notice;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: _ChecklistAmber.of(context).amberSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.message,
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textSecondary,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalPanel extends StatelessWidget {
  const _SeasonalPanel({required this.profile});

  final SeasonalProfileVm profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.wb_sunny_rounded,
            title: l10n.travelChecklistSeasonalProfile,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(
                label: _seasonalTemperatureLabel(profile.temperatureBand, l10n),
              ),
              _ChipLabel(
                label: _seasonalPrecipitationLabel(
                  profile.precipitationBand,
                  l10n,
                ),
              ),
              _ChipLabel(label: _seasonalSkyLabel(profile.skyBand, l10n)),
              ...profile.riskTags.map(
                (tag) => _ChipLabel(label: _seasonalRiskLabel(tag, l10n)),
              ),
            ],
          ),
          if (profile.packingImplications.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...profile.packingImplications.map(
              (item) => _InlineBullet(text: item),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarrySearchPanel extends StatelessWidget {
  const _CarrySearchPanel({
    required this.controller,
    required this.results,
    required this.error,
    required this.isSearching,
    required this.onSearch,
  });

  final TextEditingController controller;
  final List<CarryItemPolicyVm> results;
  final String? error;
  final bool isSearching;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.luggage_rounded,
            title: l10n.travelChecklistCarrySearch,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('carry-search-field'),
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textPrimary,
                  ),
                  decoration: AppInputDecoration(
                    hintText: l10n.travelChecklistCarrySearchHint,
                    hintStyle: AppTextStyle(
                      color: _ChecklistAmber.of(context).textMuted,
                    ),
                    filled: true,
                    fillColor: _ChecklistAmber.of(
                      context,
                    ).surfacePressed.withValues(alpha: 0.82),
                    border: OutlineInputBorder(
                      borderRadius: AppBorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _ChecklistAmber.of(
                          context,
                        ).border.withValues(alpha: 0.42),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _ChecklistAmber.of(
                          context,
                        ).border.withValues(alpha: 0.42),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.all(
                        AppRadiusValue.circular(8),
                      ),
                      borderSide: BorderSide(
                        color: _ChecklistAmber.of(context).amber,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('carry-search-submit'),
                onPressed: isSearching ? null : onSearch,
                tooltip: l10n.travelChecklistSearch,
                icon: isSearching
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: _ChecklistAmber.of(context).textPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.search_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: _ChecklistAmber.of(context).amber,
                  foregroundColor: _ChecklistAmber.of(context).textPrimary,
                  disabledBackgroundColor: _ChecklistAmber.of(
                    context,
                  ).amber.withValues(alpha: 0.28),
                  disabledForegroundColor: _ChecklistAmber.of(
                    context,
                  ).textMuted,
                ),
              ),
            ],
          ),
          if ((error ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: AppTextStyle(color: _ChecklistAmber.of(context).danger),
            ),
          ],
          if (results.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...results.map((result) => _CarryResultTile(result: result)),
          ],
        ],
      ),
    );
  }
}

class _CarryResultTile extends StatelessWidget {
  const _CarryResultTile({required this.result});

  final CarryItemPolicyVm result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const AppEdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: _ChecklistAmber.of(context).itemSurface,
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(
            color: _ChecklistAmber.of(context).border.withValues(alpha: 0.36),
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _carryItemLabel(result.itemSlug, l10n),
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipLabel(
                    label:
                        '${l10n.travelChecklistCarryOn}: '
                        '${_carryPolicyLabel(result.carryOn, l10n)}',
                  ),
                  _ChipLabel(
                    label:
                        '${l10n.travelChecklistCheckedBaggage}: '
                        '${_carryPolicyLabel(result.checkedBaggage, l10n)}',
                  ),
                ],
              ),
              if (result.conditionSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result.conditionSummary,
                  style: AppTextStyle(
                    color: _ChecklistAmber.of(context).textSecondary,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
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

class _ChecklistItemsPanel extends StatelessWidget {
  const _ChecklistItemsPanel({
    required this.items,
    required this.customItems,
    required this.searchController,
    required this.searchQuery,
    required this.updatingItemIds,
    required this.submittingFeedbackItemIds,
    required this.updatingCustomItemIds,
    required this.deletingCustomItemIds,
    required this.selectedFeedbackByItemId,
    required this.isSavingCustomItem,
    required this.isReadOnly,
    required this.onAddCustomItem,
    required this.onSearchChanged,
    required this.onToggleItem,
    required this.onSubmitFeedback,
    required this.onToggleCustomItem,
    required this.onEditCustomItem,
    required this.onDeleteCustomItem,
  });

  final List<ChecklistItemVm> items;
  final List<CustomChecklistItemVm> customItems;
  final TextEditingController searchController;
  final String searchQuery;
  final Set<String> updatingItemIds;
  final Set<String> submittingFeedbackItemIds;
  final Set<String> updatingCustomItemIds;
  final Set<String> deletingCustomItemIds;
  final Map<String, ChecklistItemFeedbackType> selectedFeedbackByItemId;
  final bool isSavingCustomItem;
  final bool isReadOnly;
  final VoidCallback onAddCustomItem;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ChecklistItemVm> onToggleItem;
  final void Function(ChecklistItemVm item, ChecklistItemFeedbackType type)
  onSubmitFeedback;
  final ValueChanged<CustomChecklistItemVm> onToggleCustomItem;
  final ValueChanged<CustomChecklistItemVm> onEditCustomItem;
  final ValueChanged<CustomChecklistItemVm> onDeleteCustomItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredItems = items
        .where((item) => _matchesChecklistItemSearch(item, searchQuery))
        .toList(growable: false);
    final filteredCustomItems = customItems
        .where((item) => _matchesCustomChecklistItemSearch(item, searchQuery))
        .toList(growable: false);
    final hasVisibleItems =
        filteredItems.isNotEmpty || filteredCustomItems.isNotEmpty;

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.checklist_rounded,
            title: l10n.travelChecklistChecklist,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('travel-checklist-items-search-field'),
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            decoration: AppInputDecoration(
              hintText: l10n.travelChecklistItemsSearchHint,
              hintStyle: AppTextStyle(
                color: _ChecklistAmber.of(context).textMuted,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _ChecklistAmber.of(context).amberSoft,
              ),
              suffixIcon: searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: Icon(Icons.close_rounded),
                      color: _ChecklistAmber.of(context).textMuted,
                    ),
              filled: true,
              fillColor: _ChecklistAmber.of(
                context,
              ).surfacePressed.withValues(alpha: 0.82),
              contentPadding: const AppEdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: AppBorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _ChecklistAmber.of(
                    context,
                  ).border.withValues(alpha: 0.42),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _ChecklistAmber.of(
                    context,
                  ).border.withValues(alpha: 0.42),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.all(AppRadiusValue.circular(8)),
                borderSide: BorderSide(
                  color: _ChecklistAmber.of(context).amber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!isReadOnly) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('travel-checklist-add-custom-item'),
                onPressed: isSavingCustomItem ? null : onAddCustomItem,
                icon: isSavingCustomItem
                    ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          color: _ChecklistAmber.of(context).textPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.add_task_rounded),
                label: Text(
                  l10n.travelChecklistAddItem,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _ChecklistAmber.of(context).amber,
                  foregroundColor: _ChecklistAmber.of(context).textPrimary,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!hasVisibleItems)
            Padding(
              padding: const AppEdgeInsets.symmetric(vertical: 14),
              child: Text(
                l10n.travelChecklistItemsSearchEmpty,
                style: AppTextStyle(
                  color: _ChecklistAmber.of(context).textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ),
          ...filteredItems.map(
            (item) => _ChecklistItemTile(
              item: item,
              isUpdating: updatingItemIds.contains(item.id),
              isSubmittingFeedback: submittingFeedbackItemIds.contains(item.id),
              selectedFeedback: selectedFeedbackByItemId[item.id],
              isReadOnly: isReadOnly,
              onToggle: () => onToggleItem(item),
              onSubmitFeedback: (type) => onSubmitFeedback(item, type),
            ),
          ),
          if (filteredCustomItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...filteredCustomItems.map(
              (item) => _CustomChecklistItemTile(
                item: item,
                isUpdating: updatingCustomItemIds.contains(item.id),
                isDeleting: deletingCustomItemIds.contains(item.id),
                isReadOnly: isReadOnly,
                onToggle: () => onToggleCustomItem(item),
                onEdit: () => onEditCustomItem(item),
                onDelete: () => onDeleteCustomItem(item),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.isUpdating,
    required this.isSubmittingFeedback,
    required this.selectedFeedback,
    required this.isReadOnly,
    required this.onToggle,
    required this.onSubmitFeedback,
  });

  final ChecklistItemVm item;
  final bool isUpdating;
  final bool isSubmittingFeedback;
  final ChecklistItemFeedbackType? selectedFeedback;
  final bool isReadOnly;
  final VoidCallback onToggle;
  final ValueChanged<ChecklistItemFeedbackType> onSubmitFeedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: _ChecklistAmber.of(context).itemSurface,
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(
            color: _ChecklistAmber.of(context).border.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AbsorbPointer(
                      absorbing: isUpdating || isReadOnly,
                      child: Checkbox(
                        key: ValueKey('checklist-item-toggle-${item.id}'),
                        value: item.isDone,
                        onChanged: isReadOnly ? null : (_) => onToggle(),
                        activeColor: _ChecklistAmber.of(context).amber,
                        checkColor: _ChecklistAmber.of(context).textPrimary,
                        side: BorderSide(
                          color: item.isCritical
                              ? _ChecklistAmber.of(context).amber
                              : _ChecklistAmber.of(context).textMuted,
                          width: 1.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(5),
                        ),
                      ),
                    ),
                    if (isUpdating)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _ChecklistAmber.of(context).amberSoft,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: Text(
                                item.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: _ChecklistAmber.of(
                                    context,
                                  ).textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            _ChipLabel(
                              label: _priorityLabel(item.priority, l10n),
                            ),
                          ],
                        ),
                        if (item.reason.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            item.reason,
                            style: AppTextStyle(
                              color: _ChecklistAmber.of(context).textSecondary,
                              fontSize: 13,
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                        if (!isReadOnly) ...[
                          const SizedBox(height: 8),
                          _ChecklistFeedbackActions(
                            itemId: item.id,
                            isSubmitting: isSubmittingFeedback,
                            selectedFeedback: selectedFeedback,
                            onSubmit: onSubmitFeedback,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomChecklistItemTile extends StatelessWidget {
  const _CustomChecklistItemTile({
    required this.item,
    required this.isUpdating,
    required this.isDeleting,
    required this.isReadOnly,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomChecklistItemVm item;
  final bool isUpdating;
  final bool isDeleting;
  final bool isReadOnly;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: _ChecklistAmber.of(
            context,
          ).itemSurface.withValues(alpha: 0.92),
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(
            color: _ChecklistAmber.of(
              context,
            ).amberSoft.withValues(alpha: 0.30),
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AbsorbPointer(
                      absorbing: isUpdating || isDeleting || isReadOnly,
                      child: Checkbox(
                        key: ValueKey(
                          'custom-checklist-item-toggle-${item.id}',
                        ),
                        value: item.isDone,
                        onChanged: isReadOnly ? null : (_) => onToggle(),
                        activeColor: _ChecklistAmber.of(context).amber,
                        checkColor: _ChecklistAmber.of(context).textPrimary,
                        side: BorderSide(
                          color: _ChecklistAmber.of(context).amberSoft,
                          width: 1.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(5),
                        ),
                      ),
                    ),
                    if (isUpdating || isDeleting)
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: _ChecklistAmber.of(context).amberSoft,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: _ChecklistAmber.of(context).textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        _ChipLabel(label: l10n.travelChecklistCustomItemBadge),
                        _ChipLabel(label: _priorityLabel(item.priority, l10n)),
                      ],
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: _ChecklistAmber.of(context).textSecondary,
                          fontSize: 13,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                    if (!isReadOnly) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: ValueKey(
                              'custom-checklist-item-edit-${item.id}',
                            ),
                            onPressed: isUpdating || isDeleting ? null : onEdit,
                            icon: Icon(Icons.edit_rounded, size: 16),
                            label: Text(l10n.travelChecklistCustomItemEdit),
                            style: _smallAmberOutlinedButtonStyle(context),
                          ),
                          OutlinedButton.icon(
                            key: ValueKey(
                              'custom-checklist-item-delete-${item.id}',
                            ),
                            onPressed: isUpdating || isDeleting
                                ? null
                                : onDelete,
                            icon: Icon(Icons.delete_outline_rounded, size: 16),
                            label: Text(l10n.travelChecklistCustomItemDelete),
                            style: _smallAmberOutlinedButtonStyle(
                              context,
                              foregroundColor: _ChecklistAmber.of(
                                context,
                              ).danger,
                            ),
                          ),
                        ],
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

ButtonStyle _smallAmberOutlinedButtonStyle(
  BuildContext context, {
  Color? foregroundColor,
}) {
  final color = foregroundColor ?? _ChecklistAmber.of(context).amberSoft;
  return OutlinedButton.styleFrom(
    foregroundColor: color,
    minimumSize: const Size(0, 34),
    padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    side: BorderSide(color: color.withValues(alpha: 0.45)),
    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(8)),
    textStyle: AppTextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );
}

bool _matchesChecklistItemSearch(ChecklistItemVm item, String query) {
  return _matchesChecklistSearchValues([
    item.title,
    item.reason,
    item.category,
    item.priority,
  ], query);
}

bool _matchesCustomChecklistItemSearch(
  CustomChecklistItemVm item,
  String query,
) {
  return _matchesChecklistSearchValues([
    item.title,
    item.note,
    item.category,
    item.priority,
  ], query);
}

bool _matchesChecklistSearchValues(Iterable<String> values, String query) {
  final queryTokens = _checklistSearchTokens(query);
  if (queryTokens.isEmpty) return true;

  final valueTokens = values
      .expand(_checklistSearchTokens)
      .where((token) => token.isNotEmpty)
      .toList(growable: false);

  return queryTokens.every((queryToken) {
    final queryStem = _checklistSearchStem(queryToken);
    return valueTokens.any((valueToken) {
      final valueStem = _checklistSearchStem(valueToken);
      return valueToken.contains(queryToken) ||
          queryToken.contains(valueToken) ||
          valueStem.contains(queryStem) ||
          queryStem.contains(valueStem);
    });
  });
}

List<String> _checklistSearchTokens(String value) {
  return _normalizeChecklistItemSearch(
    value,
  ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
}

String _checklistSearchStem(String token) {
  var stem = token.trim();
  if (stem.length <= 4) return stem;

  const endings = [
    'ами',
    'ями',
    'ого',
    'ему',
    'ыми',
    'ими',
    'ой',
    'ей',
    'ые',
    'ие',
    'ый',
    'ий',
    'ая',
    'яя',
    'ое',
    'ее',
    'ов',
    'ев',
    'ам',
    'ям',
    'ах',
    'ях',
    'ом',
    'ем',
    'а',
    'я',
    'ы',
    'и',
    'у',
    'ю',
    'е',
    'ь',
  ];

  for (final ending in endings) {
    if (stem.length - ending.length >= 4 && stem.endsWith(ending)) {
      stem = stem.substring(0, stem.length - ending.length);
      break;
    }
  }

  return stem;
}

String _normalizeChecklistItemSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9а-яёәғқңөұүһі]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class _CustomItemPriorityChip extends StatelessWidget {
  const _CustomItemPriorityChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: selected
              ? _ChecklistAmber.of(context).textPrimary
              : _ChecklistAmber.of(context).textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      avatar: Icon(
        Icons.check_rounded,
        size: 16,
        color: selected
            ? _ChecklistAmber.of(context).textPrimary
            : _ChecklistAmber.of(context).transparent,
      ),
      backgroundColor: _ChecklistAmber.of(context).surfacePressed,
      selectedColor: _ChecklistAmber.of(context).amber,
      side: BorderSide(
        color: selected
            ? _ChecklistAmber.of(context).amber
            : _ChecklistAmber.of(context).amberSoft.withValues(alpha: 0.34),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CustomChecklistItemDraft {
  const _CustomChecklistItemDraft({
    required this.title,
    required this.note,
    required this.priority,
    required this.reuseInFuture,
  });

  final String title;
  final String note;
  final String priority;
  final bool reuseInFuture;

  CustomChecklistItemRequest toRequest() {
    return CustomChecklistItemRequest(
      title: title,
      note: note,
      category: 'custom',
      priority: priority,
      reuseInFuture: reuseInFuture,
    );
  }
}

class _CustomChecklistItemSheet extends StatefulWidget {
  const _CustomChecklistItemSheet({this.item});

  final CustomChecklistItemVm? item;

  @override
  State<_CustomChecklistItemSheet> createState() =>
      _CustomChecklistItemSheetState();
}

class _CustomChecklistItemSheetState extends State<_CustomChecklistItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late String _priority;
  late bool _reuseInFuture;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _noteController = TextEditingController(text: item?.note ?? '');
    _priority = item?.priority.isNotEmpty == true
        ? item!.priority
        : 'recommended';
    _reuseInFuture = item?.reuseInFuture ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    Navigator.of(context).pop(
      _CustomChecklistItemDraft(
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        priority: _priority,
        reuseInFuture: _reuseInFuture,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: AppEdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: _ChecklistAmber.of(context).surface,
          borderRadius: const AppBorderRadius.vertical(
            top: AppRadiusValue.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const AppEdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.add_task_rounded,
                    title: widget.item == null
                        ? l10n.travelChecklistAddItem
                        : l10n.travelChecklistCustomItemEdit,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('custom-checklist-item-title-field'),
                    controller: _titleController,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyle(
                      color: _ChecklistAmber.of(context).textPrimary,
                      letterSpacing: 0,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.travelChecklistCustomItemTitleRequired
                        : null,
                    decoration: _customItemInputDecoration(
                      context,
                      label: l10n.travelChecklistCustomItemTitle,
                      hint: l10n.travelChecklistCustomItemTitleHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: _ChecklistAmber.of(context).transparent,
                      splashColor: _ChecklistAmber.of(
                        context,
                      ).amber.withValues(alpha: 0.10),
                    ),
                    child: ExpansionTile(
                      key: const ValueKey(
                        'custom-checklist-item-additional-toggle',
                      ),
                      tilePadding: AppEdgeInsets.zero,
                      collapsedIconColor: _ChecklistAmber.of(context).amberSoft,
                      iconColor: _ChecklistAmber.of(context).amberSoft,
                      title: Text(
                        l10n.travelChecklistCustomItemAdditional,
                        style: AppTextStyle(
                          color: _ChecklistAmber.of(context).textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      children: [
                        TextFormField(
                          key: const ValueKey(
                            'custom-checklist-item-note-field',
                          ),
                          controller: _noteController,
                          minLines: 1,
                          maxLines: 3,
                          style: AppTextStyle(
                            color: _ChecklistAmber.of(context).textPrimary,
                            letterSpacing: 0,
                          ),
                          decoration: _customItemInputDecoration(
                            context,
                            label: l10n.travelChecklistCustomItemNote,
                            multiline: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final priority in const [
                              'important',
                              'recommended',
                              'optional',
                            ])
                              _CustomItemPriorityChip(
                                label: _priorityLabel(priority, l10n),
                                selected: _priority == priority,
                                onSelected: () {
                                  setState(() {
                                    _priority = priority;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          key: const ValueKey(
                            'custom-checklist-item-reuse-switch',
                          ),
                          value: _reuseInFuture,
                          onChanged: (value) {
                            setState(() {
                              _reuseInFuture = value;
                            });
                          },
                          activeThumbColor: _ChecklistAmber.of(context).amber,
                          contentPadding: AppEdgeInsets.zero,
                          title: Text(
                            l10n.travelChecklistCustomItemReuse,
                            style: AppTextStyle(
                              color: _ChecklistAmber.of(context).textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('custom-checklist-item-save'),
                      onPressed: _submit,
                      icon: Icon(Icons.check_rounded),
                      label: Text(l10n.travelChecklistCustomItemSave),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ChecklistAmber.of(context).amber,
                        foregroundColor: _ChecklistAmber.of(
                          context,
                        ).textPrimary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(8),
                        ),
                      ),
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

InputDecoration _customItemInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  bool multiline = false,
}) {
  return AppInputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: AppTextStyle(color: _ChecklistAmber.of(context).textSecondary),
    floatingLabelStyle: AppTextStyle(
      color: _ChecklistAmber.of(context).amberSoft,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    hintStyle: AppTextStyle(color: _ChecklistAmber.of(context).textMuted),
    floatingLabelBehavior: multiline
        ? FloatingLabelBehavior.always
        : FloatingLabelBehavior.auto,
    alignLabelWithHint: true,
    contentPadding: multiline
        ? const AppEdgeInsets.fromLTRB(14, 24, 14, 18)
        : const AppEdgeInsets.symmetric(horizontal: 14, vertical: 18),
    errorMaxLines: 3,
    filled: true,
    fillColor: _ChecklistAmber.of(
      context,
    ).surfacePressed.withValues(alpha: 0.82),
    border: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(8),
      borderSide: BorderSide(
        color: _ChecklistAmber.of(context).border.withValues(alpha: 0.42),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(8),
      borderSide: BorderSide(
        color: _ChecklistAmber.of(context).border.withValues(alpha: 0.42),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.all(AppRadiusValue.circular(8)),
      borderSide: BorderSide(color: _ChecklistAmber.of(context).amber),
    ),
  );
}

class _ChecklistFeedbackActions extends StatelessWidget {
  const _ChecklistFeedbackActions({
    required this.itemId,
    required this.isSubmitting,
    required this.selectedFeedback,
    required this.onSubmit,
  });

  final String itemId;
  final bool isSubmitting;
  final ChecklistItemFeedbackType? selectedFeedback;
  final ValueChanged<ChecklistItemFeedbackType> onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _FeedbackButton(
          key: ValueKey('checklist-item-feedback-helpful-$itemId'),
          icon: Icons.thumb_up_alt_outlined,
          label: l10n.travelChecklistFeedbackHelpful,
          tooltip: l10n.travelChecklistFeedbackHelpful,
          color: _ChecklistAmber.of(context).success,
          isSubmitting: isSubmitting,
          isSelected: selectedFeedback == ChecklistItemFeedbackType.helpful,
          onPressed: () => onSubmit(ChecklistItemFeedbackType.helpful),
        ),
        _FeedbackButton(
          key: ValueKey('checklist-item-feedback-not-helpful-$itemId'),
          icon: Icons.thumb_down_alt_outlined,
          label: l10n.travelChecklistFeedbackNotHelpful,
          tooltip: l10n.travelChecklistFeedbackNotHelpful,
          color: _ChecklistAmber.of(context).danger,
          isSubmitting: isSubmitting,
          isSelected: selectedFeedback == ChecklistItemFeedbackType.notHelpful,
          onPressed: () => onSubmit(ChecklistItemFeedbackType.notHelpful),
        ),
        _FeedbackButton(
          key: ValueKey('checklist-item-feedback-add-next-time-$itemId'),
          icon: Icons.playlist_add_check_rounded,
          label: l10n.travelChecklistFeedbackAddNextTime,
          tooltip: l10n.travelChecklistFeedbackAddNextTime,
          color: _ChecklistAmber.of(context).amberSoft,
          isSubmitting: isSubmitting,
          isSelected: selectedFeedback == ChecklistItemFeedbackType.addNextTime,
          onPressed: () => onSubmit(ChecklistItemFeedbackType.addNextTime),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.isSubmitting,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final bool isSubmitting;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          onPressed: isSubmitting || isSelected ? null : onPressed,
          icon: isSubmitting
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _ChecklistAmber.of(context).textPrimary,
                  ),
                )
              : Icon(isSelected ? Icons.check_circle_rounded : icon, size: 16),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: isSelected
                ? color
                : _ChecklistAmber.of(context).textMuted,
            backgroundColor: isSelected
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: 0.08),
            disabledBackgroundColor: isSelected
                ? color.withValues(alpha: 0.18)
                : _ChecklistAmber.of(context).surfacePressed,
            side: BorderSide(
              color: color.withValues(alpha: isSelected ? 0.78 : 0.45),
              width: isSelected ? 1.4 : 1,
            ),
            minimumSize: const Size(0, 34),
            padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
            textStyle: AppTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.16),
            borderRadius: AppBorderRadius.circular(8),
            border: Border.all(
              color: _ChecklistAmber.of(
                context,
              ).amberSoft.withValues(alpha: 0.24),
            ),
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(7),
            child: Icon(
              icon,
              color: _ChecklistAmber.of(context).amberSoft,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyle(
              color: _ChecklistAmber.of(context).textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineBullet extends StatelessWidget {
  const _InlineBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const AppEdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppEdgeInsets.only(top: 7),
            child: SizedBox.square(
              dimension: 5,
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  color: _ChecklistAmber.of(context).amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textSecondary,
                fontSize: 13,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _ChecklistAmber.of(context).amber.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: _ChecklistAmber.of(context).amberSoft.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            color: _ChecklistAmber.of(context).textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child, this.prominent = false});

  final Widget child;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: prominent
              ? [
                  _ChecklistAmber.of(context).surfaceElevated,
                  _ChecklistAmber.of(context).surface,
                ]
              : [
                  _ChecklistAmber.of(context).surface,
                  _ChecklistAmber.of(context).surfacePressed,
                ],
        ),
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(
          color: _ChecklistAmber.of(
            context,
          ).border.withValues(alpha: prominent ? 0.62 : 0.42),
        ),
      ),
      child: Padding(
        padding: AppEdgeInsets.all(
          MediaQuery.sizeOf(context).width < 340 ? 12 : 14,
        ),
        child: child,
      ),
    );
  }
}

class _ChecklistLoadingView extends StatelessWidget {
  const _ChecklistLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}

class _ChecklistErrorView extends StatelessWidget {
  const _ChecklistErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: _ChecklistAmber.of(context).danger,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: _ChecklistAmber.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

ThemeData _quickPrepDatePickerTheme(BuildContext context) {
  final base = Theme.of(context);
  final colorScheme = ColorScheme.dark(
    primary: _ChecklistAmber.of(context).amber,
    onPrimary: _ChecklistAmber.of(context).textPrimary,
    surface: _ChecklistAmber.of(context).surface,
    onSurface: _ChecklistAmber.of(context).textPrimary,
    secondary: _ChecklistAmber.of(context).amberSoft,
    onSecondary: _ChecklistAmber.of(context).textPrimary,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    dialogTheme: DialogThemeData(
      backgroundColor: _ChecklistAmber.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(12)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: _ChecklistAmber.of(context).surface,
      headerBackgroundColor: _ChecklistAmber.of(context).amber,
      headerForegroundColor: _ChecklistAmber.of(context).textPrimary,
      dividerColor: _ChecklistAmber.of(context).border.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(12)),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _ChecklistAmber.of(context).textPrimary;
        }
        if (states.contains(WidgetState.disabled)) {
          return _ChecklistAmber.of(context).textMuted.withValues(alpha: 0.52);
        }
        return _ChecklistAmber.of(context).textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _ChecklistAmber.of(context).amber;
        }
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.all(
        _ChecklistAmber.of(context).amberSoft,
      ),
      todayBorder: BorderSide(color: _ChecklistAmber.of(context).amberSoft),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _ChecklistAmber.of(context).textPrimary;
        }
        return _ChecklistAmber.of(context).textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _ChecklistAmber.of(context).amber;
        }
        return null;
      }),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _ChecklistAmber.of(context).amberSoft,
        textStyle: AppTextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
      ),
    ),
  );
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}

String _normalizeQuickPrepSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll('ү', 'у')
      .replaceAll('ұ', 'у')
      .replaceAll('қ', 'к')
      .replaceAll('ғ', 'г')
      .replaceAll('ң', 'н')
      .replaceAll('ә', 'а')
      .replaceAll('ө', 'о')
      .replaceAll('һ', 'х')
      .replaceAll('і', 'и')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _shortDate(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _quickPreparationTripId({
  required String countryCode,
  required String cityName,
  required DateTime startAt,
  required DateTime endAt,
  required Iterable<String> transportModes,
  required Iterable<String> activitySlugs,
  required bool hasChildren,
}) {
  final countryToken = countryCode.trim().toLowerCase();
  final cityToken = cityName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9а-яёәғқңөұүһі]+', unicode: true), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final destinationToken = [
    countryToken,
    if (cityToken.isNotEmpty) cityToken,
  ].join(':');
  final transportToken = _checklistTokenListKey(transportModes);
  final activityToken = _checklistTokenListKey(activitySlugs);
  final familyToken = hasChildren ? 'children' : 'adults';
  return [
    'quick-prep',
    destinationToken,
    _utcDateKey(startAt),
    _utcDateKey(endAt),
    if (transportToken.isNotEmpty) transportToken,
    if (activityToken.isNotEmpty) activityToken,
    familyToken,
  ].join(':');
}

CachedTravelChecklistEntry? _matchingManualChecklistEntry(
  List<CachedTravelChecklistEntry> entries,
  TravelChecklistRouteArgs candidate,
) {
  return _firstWhereOrNull(
    entries,
    (entry) =>
        _checklistSourceFor(entry.routeArgs) == _ChecklistSource.manual &&
        _sameManualChecklistIdentity(entry.routeArgs, candidate),
  );
}

bool _sameManualChecklistIdentity(
  TravelChecklistRouteArgs a,
  TravelChecklistRouteArgs b,
) {
  return _manualDestinationIdentityKey(a) == _manualDestinationIdentityKey(b) &&
      _utcDateKey(a.startAt) == _utcDateKey(b.startAt) &&
      _utcDateKey(a.safeEndAt) == _utcDateKey(b.safeEndAt) &&
      _checklistTokenListKey(a.transportModes) ==
          _checklistTokenListKey(b.transportModes) &&
      _checklistTokenListKey(a.activitySlugs) ==
          _checklistTokenListKey(b.activitySlugs) &&
      a.hasChildren == b.hasChildren;
}

String _manualDestinationIdentityKey(TravelChecklistRouteArgs routeArgs) {
  final destination = routeArgs.destination;
  final country = destination.countryCode.trim().toLowerCase();
  final city = (destination.cityId ?? '').trim().isNotEmpty
      ? destination.cityId!.trim().toLowerCase()
      : _normalizeQuickPrepSearch(destination.cityName);
  return '$country:$city';
}

String _checklistTokenListKey(Iterable<String> values) {
  final tokens = TravelChecklistRouteArgs.normalizedTokens(values).toList()
    ..sort();
  return tokens.join('+');
}

String _utcDateKey(DateTime date) {
  final utc = date.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$day';
}

List<_ChecklistListSection> _checklistListSections(
  List<CachedTravelChecklistEntry> entries, {
  required _ChecklistListFilter filter,
  required AppLocalizations l10n,
  required DateTime now,
}) {
  final nowUtc = now.toUtc();

  List<CachedTravelChecklistEntry> matching(
    bool Function(CachedTravelChecklistEntry entry) test,
  ) {
    return entries.where(test).toList(growable: false);
  }

  final sections = <_ChecklistListSection>[];

  void addSection({
    required String title,
    required IconData icon,
    required List<CachedTravelChecklistEntry> items,
  }) {
    if (items.isEmpty) return;
    sections.add(
      _ChecklistListSection(title: title, icon: icon, entries: items),
    );
  }

  switch (filter) {
    case _ChecklistListFilter.all:
      addSection(
        title: l10n.travelChecklistSectionUpcoming,
        icon: Icons.event_available_rounded,
        items: matching(
          (entry) =>
              !_isPastChecklistEntry(entry, nowUtc) &&
              _checklistSourceFor(entry.routeArgs) != _ChecklistSource.manual,
        )..sort(_compareUpcomingChecklistEntries),
      );
      addSection(
        title: l10n.travelChecklistSectionManual,
        icon: Icons.edit_note_rounded,
        items: matching(
          (entry) =>
              !_isPastChecklistEntry(entry, nowUtc) &&
              _checklistSourceFor(entry.routeArgs) == _ChecklistSource.manual,
        )..sort(_compareUpcomingChecklistEntries),
      );
      addSection(
        title: l10n.travelChecklistSectionPast,
        icon: Icons.history_rounded,
        items: matching((entry) => _isPastChecklistEntry(entry, nowUtc))
          ..sort(_comparePastChecklistEntries),
      );
    case _ChecklistListFilter.upcoming:
      addSection(
        title: l10n.travelChecklistSectionUpcoming,
        icon: Icons.event_available_rounded,
        items: matching((entry) => !_isPastChecklistEntry(entry, nowUtc))
          ..sort(_compareUpcomingChecklistEntries),
      );
    case _ChecklistListFilter.manual:
      addSection(
        title: l10n.travelChecklistSectionManual,
        icon: Icons.edit_note_rounded,
        items: matching(
          (entry) =>
              _checklistSourceFor(entry.routeArgs) == _ChecklistSource.manual,
        )..sort((a, b) => _compareChecklistEntriesWithPastLast(a, b, nowUtc)),
      );
    case _ChecklistListFilter.activities:
      _addSourceChecklistSections(
        sections,
        entries: entries,
        source: _ChecklistSource.activity,
        l10n: l10n,
        now: nowUtc,
      );
    case _ChecklistListFilter.excursions:
      _addSourceChecklistSections(
        sections,
        entries: entries,
        source: _ChecklistSource.excursion,
        l10n: l10n,
        now: nowUtc,
      );
  }

  return List<_ChecklistListSection>.unmodifiable(sections);
}

void _addSourceChecklistSections(
  List<_ChecklistListSection> sections, {
  required List<CachedTravelChecklistEntry> entries,
  required _ChecklistSource source,
  required AppLocalizations l10n,
  required DateTime now,
}) {
  final upcoming =
      entries
          .where(
            (entry) =>
                _checklistSourceFor(entry.routeArgs) == source &&
                !_isPastChecklistEntry(entry, now),
          )
          .toList(growable: false)
        ..sort(_compareUpcomingChecklistEntries);
  if (upcoming.isNotEmpty) {
    sections.add(
      _ChecklistListSection(
        title: l10n.travelChecklistSectionUpcoming,
        icon: Icons.event_available_rounded,
        entries: upcoming,
      ),
    );
  }

  final past =
      entries
          .where(
            (entry) =>
                _checklistSourceFor(entry.routeArgs) == source &&
                _isPastChecklistEntry(entry, now),
          )
          .toList(growable: false)
        ..sort(_comparePastChecklistEntries);
  if (past.isNotEmpty) {
    sections.add(
      _ChecklistListSection(
        title: l10n.travelChecklistSectionPast,
        icon: Icons.history_rounded,
        entries: past,
      ),
    );
  }
}

bool _isPastChecklistEntry(CachedTravelChecklistEntry entry, DateTime now) {
  return entry.routeArgs.safeEndAt.toUtc().isBefore(now.toUtc());
}

int _compareUpcomingChecklistEntries(
  CachedTravelChecklistEntry a,
  CachedTravelChecklistEntry b,
) {
  final startCompare = a.routeArgs.startAt.toUtc().compareTo(
    b.routeArgs.startAt.toUtc(),
  );
  if (startCompare != 0) return startCompare;
  return b.savedAt.toUtc().compareTo(a.savedAt.toUtc());
}

int _comparePastChecklistEntries(
  CachedTravelChecklistEntry a,
  CachedTravelChecklistEntry b,
) {
  final endCompare = b.routeArgs.safeEndAt.toUtc().compareTo(
    a.routeArgs.safeEndAt.toUtc(),
  );
  if (endCompare != 0) return endCompare;
  return b.savedAt.toUtc().compareTo(a.savedAt.toUtc());
}

int _compareChecklistEntriesWithPastLast(
  CachedTravelChecklistEntry a,
  CachedTravelChecklistEntry b,
  DateTime now,
) {
  final aPast = _isPastChecklistEntry(a, now);
  final bPast = _isPastChecklistEntry(b, now);
  if (aPast != bPast) return aPast ? 1 : -1;
  return aPast
      ? _comparePastChecklistEntries(a, b)
      : _compareUpcomingChecklistEntries(a, b);
}

_ChecklistSource _checklistSourceFor(TravelChecklistRouteArgs routeArgs) {
  final tripId = routeArgs.normalizedTripId.trim().toLowerCase();
  if (tripId.startsWith('activity:')) {
    return _ChecklistSource.activity;
  }
  if (tripId.startsWith('excursion:') ||
      tripId.startsWith('excursion_booking:')) {
    return _ChecklistSource.excursion;
  }
  return _ChecklistSource.manual;
}

String _checklistListFilterLabel(
  _ChecklistListFilter filter,
  AppLocalizations l10n,
) {
  return switch (filter) {
    _ChecklistListFilter.all => l10n.travelChecklistFilterAll,
    _ChecklistListFilter.upcoming => l10n.travelChecklistFilterUpcoming,
    _ChecklistListFilter.manual => l10n.travelChecklistFilterManual,
    _ChecklistListFilter.activities => l10n.travelChecklistFilterActivities,
    _ChecklistListFilter.excursions => l10n.travelChecklistFilterExcursions,
  };
}

String _checklistSourceLabel(_ChecklistSource source, AppLocalizations l10n) {
  return switch (source) {
    _ChecklistSource.manual => l10n.travelChecklistSourceManual,
    _ChecklistSource.activity => l10n.travelChecklistSourceActivity,
    _ChecklistSource.excursion => l10n.travelChecklistSourceExcursion,
  };
}

String _dateRangeLabel(DateTime startAt, DateTime endAt) {
  final start = _shortDate(startAt);
  final end = _shortDate(endAt);
  if (start == end) {
    final startTime = _shortTime(startAt);
    final endTime = _shortTime(endAt);
    if (startTime != endTime) return '$start, $startTime - $endTime';
    return start;
  }
  return '$start - $end';
}

String _shortTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _destinationLabel(
  TravelChecklistRouteArgs routeArgs,
  AppLocalizations l10n,
) {
  final destination = routeArgs.destination;
  final cityName = _cityNameForDisplay(
    destination: destination,
    localeCode: l10n.localeName,
  );
  final countryCode = destination.countryCode.trim().toUpperCase();
  final countryName = _countryNameForDisplay(
    countryCode: countryCode,
    preferredName: routeArgs.destinationCountryName,
    localeCode: l10n.localeName,
  );

  if (cityName.isNotEmpty && countryName.isNotEmpty) {
    return '$cityName, $countryName';
  }
  if (cityName.isNotEmpty) return cityName;
  if (countryName.isNotEmpty) return countryName;
  if (countryCode.isNotEmpty) return countryCode;
  return l10n.travelChecklistUnknown;
}

String _cityNameForDisplay({
  required TripChecklistDestinationRequest destination,
  required String localeCode,
}) {
  final originalCityName = destination.cityName.trim();
  final normalizedCountryCode = destination.countryCode.trim().toUpperCase();
  final normalizedCityId = destination.cityId?.trim().toLowerCase();

  if (normalizedCityId != null && normalizedCityId.isNotEmpty) {
    for (final city in _quickPrepCities) {
      if (city.countryCode != normalizedCountryCode) continue;
      if (city.cityId.trim().toLowerCase() == normalizedCityId) {
        return city.displayName(localeCode);
      }
    }
  }

  final normalizedCityName = _normalizeQuickPrepSearch(originalCityName);
  if (normalizedCityName.isNotEmpty) {
    for (final city in _quickPrepCities) {
      if (city.countryCode != normalizedCountryCode) continue;
      final hasExactToken = city._searchTokens.any(
        (token) => token == normalizedCityName,
      );
      if (hasExactToken) {
        return city.displayName(localeCode);
      }
    }
  }

  return originalCityName;
}

String _countryNameForDisplay({
  required String countryCode,
  required String? preferredName,
  required String localeCode,
}) {
  final normalizedPreferredName = (preferredName ?? '').trim();
  if (normalizedPreferredName.isNotEmpty) return normalizedPreferredName;

  final normalizedCountryCode = countryCode.trim().toUpperCase();
  if (normalizedCountryCode.isEmpty) return '';

  for (final country in _quickPrepCountries) {
    if (country.countryCode == normalizedCountryCode) {
      return country.displayName(localeCode);
    }
  }

  return appCountryNameForCode(normalizedCountryCode, localeName: localeCode) ??
      '';
}

String _transportModeLabel(String mode, AppLocalizations l10n) {
  switch (mode) {
    case 'flight':
      return l10n.travelChecklistTransportFlight;
    case 'train':
      return l10n.travelChecklistTransportTrain;
    case 'bus':
      return l10n.travelChecklistTransportBus;
    case 'car':
      return l10n.travelChecklistTransportCar;
    case 'motorcycle':
      return l10n.travelChecklistTransportMotorcycle;
    case 'ferry':
      return l10n.travelChecklistTransportFerry;
    case 'other':
      return l10n.travelChecklistTransportOther;
    default:
      return _humanizeCode(mode);
  }
}

List<String> _activityLabels(
  Iterable<String> activities,
  AppLocalizations l10n,
) {
  final labels = <String>[];
  final seen = <String>{};

  for (final activity in activities) {
    final label = _activityLabel(activity, l10n)?.trim();
    if (label == null || label.isEmpty) continue;

    final key = label.toLowerCase();
    if (!seen.add(key)) continue;
    labels.add(label);
  }

  return List.unmodifiable(labels);
}

String? _activityLabel(String activity, AppLocalizations l10n) {
  final slug = _normalizeActivityContextSlug(activity);
  if (slug.isEmpty || _hiddenActivityContextSlugs.contains(slug)) return null;

  switch (slug) {
    case 'walking':
    case 'city-walk':
    case 'city-walks':
    case 'photo-walk':
      return l10n.travelChecklistActivityWalking;
    case 'hiking':
    case 'nature-outdoor':
    case 'adventure':
    case 'adventure-sports':
      return l10n.travelChecklistActivityHiking;
    case 'culture':
    case 'cultural':
    case 'culture-art':
    case 'local-culture':
      return l10n.travelChecklistActivityCulture;
    case 'food':
    case 'food-drinks':
    case 'culinary':
    case 'gourmet':
      return l10n.travelChecklistActivityFood;
    case 'beach':
      return l10n.travelChecklistActivityBeach;
    case 'museum':
    case 'museum-gallery':
      return l10n.travelChecklistActivityMuseum;
    case 'shopping':
    case 'market':
      return l10n.travelChecklistActivityShopping;
    case 'nightlife':
    case 'social-nightlife':
    case 'party-night':
      return l10n.travelChecklistActivityNightlife;
    case 'offline':
      return l10n.activityFormatOffline;
    case 'online':
      return l10n.activityFormatOnline;
    case 'hybrid':
      return l10n.activityFormatHybrid;
    default:
      return _localizedActivityContextFallbacks[slug]?.label(l10n.localeName);
  }
}

String _normalizeActivityContextSlug(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '-');
}

const Set<String> _hiddenActivityContextSlugs = {
  'activity-flow',
  'qa',
  'single-place',
  'combined-route',
  'single-place-route',
  'combined-route-route',
  'route',
  'route-flow',
  'walking-route',
};

const Map<String, _LocalizedChecklistLabel> _localizedActivityContextFallbacks =
    {
      'coffee-meetup': _LocalizedChecklistLabel(
        en: 'Coffee meetup',
        ru: 'Кофе-встреча',
        kk: 'Кофе кездесуі',
      ),
      'food-tasting': _LocalizedChecklistLabel(
        en: 'Food tasting',
        ru: 'Дегустация',
        kk: 'Дәм тату',
      ),
      'dinner-club': _LocalizedChecklistLabel(
        en: 'Dinner club',
        ru: 'Ужин-клуб',
        kk: 'Кешкі ас клубы',
      ),
      'bar-hop': _LocalizedChecklistLabel(
        en: 'Bar hop',
        ru: 'Бар-хоппинг',
        kk: 'Барларға бару',
      ),
      'social-meetup': _LocalizedChecklistLabel(
        en: 'Social meetup',
        ru: 'Встреча для общения',
        kk: 'Қарым-қатынас кездесуі',
      ),
      'speed-friending': _LocalizedChecklistLabel(
        en: 'Speed friending',
        ru: 'Быстрые знакомства',
        kk: 'Жылдам танысу',
      ),
      'networking': _LocalizedChecklistLabel(
        en: 'Networking',
        ru: 'Нетворкинг',
        kk: 'Нетворкинг',
      ),
      'live-music': _LocalizedChecklistLabel(
        en: 'Live music',
        ru: 'Живая музыка',
        kk: 'Жанды музыка',
      ),
      'theatre-cinema': _LocalizedChecklistLabel(
        en: 'Theatre or cinema',
        ru: 'Театр или кино',
        kk: 'Театр немесе кино',
      ),
      'architecture': _LocalizedChecklistLabel(
        en: 'Architecture',
        ru: 'Архитектура',
        kk: 'Сәулет',
      ),
      'hidden-gems': _LocalizedChecklistLabel(
        en: 'Hidden gems',
        ru: 'Неочевидные места',
        kk: 'Жасырын орындар',
      ),
      'park-picnic': _LocalizedChecklistLabel(
        en: 'Park or picnic',
        ru: 'Парк или пикник',
        kk: 'Саябақ немесе пикник',
      ),
      'camping': _LocalizedChecklistLabel(
        en: 'Camping',
        ru: 'Кемпинг',
        kk: 'Кемпинг',
      ),
      'day-trip': _LocalizedChecklistLabel(
        en: 'Day trip',
        ru: 'Поездка на день',
        kk: 'Бір күндік сапар',
      ),
      'sports-wellness': _LocalizedChecklistLabel(
        en: 'Sports & wellness',
        ru: 'Спорт и здоровье',
        kk: 'Спорт және денсаулық',
      ),
      'health-wellness': _LocalizedChecklistLabel(
        en: 'Sports & wellness',
        ru: 'Спорт и здоровье',
        kk: 'Спорт және денсаулық',
      ),
      'yoga-meditation': _LocalizedChecklistLabel(
        en: 'Yoga or meditation',
        ru: 'Йога или медитация',
        kk: 'Йога немесе медитация',
      ),
      'running': _LocalizedChecklistLabel(
        en: 'Running',
        ru: 'Бег',
        kk: 'Жүгіру',
      ),
      'fitness': _LocalizedChecklistLabel(
        en: 'Fitness',
        ru: 'Фитнес',
        kk: 'Фитнес',
      ),
      'dance': _LocalizedChecklistLabel(en: 'Dance', ru: 'Танцы', kk: 'Би'),
      'workshops-learning': _LocalizedChecklistLabel(
        en: 'Workshops & learning',
        ru: 'Мастер-классы и обучение',
        kk: 'Шеберлік сабақтары және оқу',
      ),
      'creative-workshop': _LocalizedChecklistLabel(
        en: 'Creative workshop',
        ru: 'Творческий мастер-класс',
        kk: 'Шығармашылық шеберхана',
      ),
      'language-practice': _LocalizedChecklistLabel(
        en: 'Language practice',
        ru: 'Языковая практика',
        kk: 'Тіл тәжірибесі',
      ),
      'lecture-talk': _LocalizedChecklistLabel(
        en: 'Lecture or talk',
        ru: 'Лекция или встреча',
        kk: 'Дәріс немесе кездесу',
      ),
      'cooking-class': _LocalizedChecklistLabel(
        en: 'Cooking class',
        ru: 'Кулинарный мастер-класс',
        kk: 'Аспаздық сабақ',
      ),
      'games-entertainment': _LocalizedChecklistLabel(
        en: 'Games & entertainment',
        ru: 'Игры и развлечения',
        kk: 'Ойындар және ойын-сауық',
      ),
      'quiz-trivia': _LocalizedChecklistLabel(
        en: 'Quiz or trivia',
        ru: 'Квиз',
        kk: 'Квиз',
      ),
      'board-games': _LocalizedChecklistLabel(
        en: 'Board games',
        ru: 'Настольные игры',
        kk: 'Үстел ойындары',
      ),
      'karaoke': _LocalizedChecklistLabel(
        en: 'Karaoke',
        ru: 'Караоке',
        kk: 'Караоке',
      ),
      'escape-room': _LocalizedChecklistLabel(
        en: 'Escape room',
        ru: 'Квест',
        kk: 'Квест',
      ),
      'family-kids': _LocalizedChecklistLabel(
        en: 'Family & kids',
        ru: 'Семья и дети',
        kk: 'Отбасы және балалар',
      ),
      'family-walk': _LocalizedChecklistLabel(
        en: 'Family walk',
        ru: 'Семейная прогулка',
        kk: 'Отбасылық серуен',
      ),
      'kids-workshop': _LocalizedChecklistLabel(
        en: 'Kids workshop',
        ru: 'Детский мастер-класс',
        kk: 'Балалар шеберханасы',
      ),
      'kids-education': _LocalizedChecklistLabel(
        en: 'Kids education',
        ru: 'Детское обучение',
        kk: 'Балаларға білім',
      ),
      'family-show': _LocalizedChecklistLabel(
        en: 'Family show',
        ru: 'Семейное шоу',
        kk: 'Отбасылық шоу',
      ),
      'community-event': _LocalizedChecklistLabel(
        en: 'Community event',
        ru: 'Событие сообщества',
        kk: 'Қауымдастық іс-шарасы',
      ),
      'special-event': _LocalizedChecklistLabel(
        en: 'Special event',
        ru: 'Особое событие',
        kk: 'Арнайы іс-шара',
      ),
      'wellness': _LocalizedChecklistLabel(
        en: 'Wellness',
        ru: 'Здоровье и отдых',
        kk: 'Сауықтыру және демалыс',
      ),
    };

class _LocalizedChecklistLabel {
  const _LocalizedChecklistLabel({
    required this.en,
    required this.ru,
    required this.kk,
  });

  final String en;
  final String ru;
  final String kk;

  String label(String localeName) {
    final languageCode = localeName
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    return switch (languageCode) {
      'en' => en,
      'kk' => kk,
      _ => ru,
    };
  }
}

String _feedbackSnackBarMessage(
  ChecklistItemFeedbackType type,
  AppLocalizations l10n,
) {
  switch (type) {
    case ChecklistItemFeedbackType.helpful:
      return l10n.travelChecklistFeedbackHelpfulSaved;
    case ChecklistItemFeedbackType.notHelpful:
      return l10n.travelChecklistFeedbackNotHelpfulSaved;
    case ChecklistItemFeedbackType.addNextTime:
      return l10n.travelChecklistFeedbackAddNextTimeSaved;
    case ChecklistItemFeedbackType.unknown:
      return l10n.travelChecklistFeedbackSent;
  }
}

String _readinessStatusLabel(
  ChecklistReadinessStatus status,
  AppLocalizations l10n,
) {
  switch (status) {
    case ChecklistReadinessStatus.notReady:
      return l10n.travelChecklistReadinessNotReady;
    case ChecklistReadinessStatus.atRisk:
      return l10n.travelChecklistReadinessAtRisk;
    case ChecklistReadinessStatus.onTrack:
      return l10n.travelChecklistReadinessOnTrack;
    case ChecklistReadinessStatus.almostReady:
      return l10n.travelChecklistReadinessAlmostReady;
    case ChecklistReadinessStatus.ready:
      return l10n.travelChecklistReadinessReady;
    case ChecklistReadinessStatus.readyWithWarnings:
      return l10n.travelChecklistReadinessReadyWithWarnings;
    case ChecklistReadinessStatus.unknown:
      return l10n.travelChecklistUnknown;
  }
}

String _cachedReadinessStatusLabel(String status, AppLocalizations l10n) {
  switch (status.trim().toLowerCase()) {
    case 'not_ready':
      return l10n.travelChecklistReadinessNotReady;
    case 'at_risk':
      return l10n.travelChecklistReadinessAtRisk;
    case 'on_track':
      return l10n.travelChecklistReadinessOnTrack;
    case 'almost_ready':
      return l10n.travelChecklistReadinessAlmostReady;
    case 'ready':
      return l10n.travelChecklistReadinessReady;
    case 'ready_with_warnings':
      return l10n.travelChecklistReadinessReadyWithWarnings;
    default:
      return l10n.travelChecklistUnknown;
  }
}

String _priorityLabel(String priority, AppLocalizations l10n) {
  switch (priority) {
    case 'critical':
      return l10n.travelChecklistPriorityCritical;
    case 'essential':
      return l10n.travelChecklistPriorityEssential;
    case 'important':
      return l10n.travelChecklistPriorityImportant;
    case 'recommended':
      return l10n.travelChecklistPriorityRecommended;
    case 'optional':
      return l10n.travelChecklistPriorityOptional;
    default:
      return _humanizeCode(priority);
  }
}

String _seasonalTemperatureLabel(String band, AppLocalizations l10n) {
  switch (band) {
    case 'cold':
      return l10n.travelChecklistTemperatureCold;
    case 'mild':
      return l10n.travelChecklistTemperatureMild;
    case 'warm':
      return l10n.travelChecklistTemperatureWarm;
    case 'hot':
      return l10n.travelChecklistTemperatureHot;
    case 'very_hot':
      return l10n.travelChecklistTemperatureVeryHot;
    default:
      return _humanizeCode(band);
  }
}

String _seasonalPrecipitationLabel(String band, AppLocalizations l10n) {
  switch (band) {
    case 'dry':
      return l10n.travelChecklistPrecipitationDry;
    case 'occasional_rain':
      return l10n.travelChecklistPrecipitationOccasionalRain;
    case 'rainy':
      return l10n.travelChecklistPrecipitationRainy;
    case 'monsoon':
      return l10n.travelChecklistPrecipitationMonsoon;
    case 'snow':
      return l10n.travelChecklistPrecipitationSnow;
    default:
      return _humanizeCode(band);
  }
}

String _seasonalSkyLabel(String band, AppLocalizations l10n) {
  switch (band) {
    case 'sunny':
      return l10n.travelChecklistSkySunny;
    case 'mixed':
      return l10n.travelChecklistSkyMixed;
    case 'cloudy':
      return l10n.travelChecklistSkyCloudy;
    default:
      return _humanizeCode(band);
  }
}

String _seasonalRiskLabel(String risk, AppLocalizations l10n) {
  switch (risk) {
    case 'cold':
      return l10n.travelChecklistRiskCold;
    case 'dry':
      return l10n.travelChecklistRiskDry;
    case 'heat':
      return l10n.travelChecklistRiskHeat;
    case 'high_uv':
      return l10n.travelChecklistRiskHighUv;
    case 'humid':
      return l10n.travelChecklistRiskHumid;
    case 'icy':
      return l10n.travelChecklistRiskIcy;
    case 'mixed_weather':
      return l10n.travelChecklistRiskMixedWeather;
    case 'rain':
      return l10n.travelChecklistRiskRain;
    case 'windy':
      return l10n.travelChecklistRiskWindy;
    default:
      return _humanizeCode(risk);
  }
}

String _carryItemLabel(String itemSlug, AppLocalizations l10n) {
  switch (itemSlug) {
    case 'power_bank':
      return l10n.travelChecklistCarryItemPowerBank;
    case 'travel_visa':
      return l10n.travelChecklistCarryItemTravelVisa;
    case 'liquids':
      return l10n.travelChecklistCarryItemLiquids;
    case 'sharp_items':
      return l10n.travelChecklistCarryItemSharpItems;
    default:
      return _humanizeCode(itemSlug);
  }
}

String _carryPolicyLabel(CarryPolicy policy, AppLocalizations l10n) {
  switch (policy) {
    case CarryPolicy.allowed:
      return l10n.travelChecklistCarryAllowed;
    case CarryPolicy.allowedWithConditions:
      return l10n.travelChecklistCarryAllowedWithConditions;
    case CarryPolicy.prohibited:
      return l10n.travelChecklistCarryProhibited;
    case CarryPolicy.checkAuthority:
      return l10n.travelChecklistCarryCheckAuthority;
    case CarryPolicy.unknown:
      return l10n.travelChecklistUnknown;
  }
}

String _humanizeCode(String value) {
  final text = value.trim().replaceAll('_', ' ');
  if (text.isEmpty) {
    return '-';
  }
  return text[0].toUpperCase() + text.substring(1);
}

String _routePointLabel(RoutePointVm point) {
  final name = point.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
}

String _routingDurationLabel(int durationSeconds) {
  final minutes = (durationSeconds / 60).round().clamp(1, 10080);
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
}

String _routingDistanceLabel(double distanceMeters) {
  if (distanceMeters <= 0) return '0 m';
  if (distanceMeters < 1000) return '${distanceMeters.round()} m';
  final kilometers = distanceMeters / 1000;
  return '${kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1)} km';
}
