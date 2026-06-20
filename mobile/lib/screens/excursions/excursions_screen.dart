import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/models/place_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../features/feed/widgets/contextual_story_tray.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../shared/formatters/app_money_formatter.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';

class ExcursionsRouteArgs {
  const ExcursionsRouteArgs({
    this.showNoPlaceExcursionsNotice = false,
    this.placeId,
    this.placeTitle,
  });

  const ExcursionsRouteArgs.noPlaceExcursions({
    required String placeId,
    String? placeTitle,
  }) : this(
         showNoPlaceExcursionsNotice: true,
         placeId: placeId,
         placeTitle: placeTitle,
       );

  final bool showNoPlaceExcursionsNotice;
  final String? placeId;
  final String? placeTitle;
}

class ExcursionsScreen extends StatefulWidget {
  const ExcursionsScreen({super.key, this.routeArgs});

  final ExcursionsRouteArgs? routeArgs;

  @override
  State<ExcursionsScreen> createState() => _ExcursionsScreenState();
}

enum _ExcursionsSortMode { createdAt, rating, price, duration }

enum _ExcursionsSortDirection { asc, desc }

enum _ExcursionsDurationFilter { short, halfDay, fullDay, multiDay }

extension _ExcursionsSortModeLabel on _ExcursionsSortMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _ExcursionsSortMode.createdAt => l10n.excursionsSortCreatedAt,
      _ExcursionsSortMode.rating => l10n.excursionsSortRating,
      _ExcursionsSortMode.price => l10n.excursionsSortPrice,
      _ExcursionsSortMode.duration => l10n.excursionsSortDuration,
    };
  }

  _ExcursionsSortDirection get defaultDirection {
    return switch (this) {
      _ExcursionsSortMode.createdAt => _ExcursionsSortDirection.desc,
      _ExcursionsSortMode.rating => _ExcursionsSortDirection.desc,
      _ExcursionsSortMode.price => _ExcursionsSortDirection.asc,
      _ExcursionsSortMode.duration => _ExcursionsSortDirection.asc,
    };
  }
}

class _CategoryFilterOption {
  const _CategoryFilterOption({required this.slug, required this.icon});

  final String slug;
  final IconData icon;
}

const _categoryFilterOptions = [
  _CategoryFilterOption(slug: 'adventure', icon: Icons.terrain_rounded),
  _CategoryFilterOption(slug: 'cultural', icon: Icons.account_balance_rounded),
  _CategoryFilterOption(slug: 'culinary', icon: Icons.restaurant_rounded),
  _CategoryFilterOption(slug: 'wellness', icon: Icons.spa_rounded),
];

const _languageFilterCodes = ['en', 'ru', 'kk', 'fr', 'ja', 'de', 'es', 'tr'];

String _normalizeExcursionSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[@_.,;:\/\\|()\[\]{}<>+\-=]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<List<String>> _excursionSearchNeedleGroups(String value) {
  final tokens = _normalizeExcursionSearchText(value)
      .split(' ')
      .where((token) => token.trim().isNotEmpty)
      .take(6)
      .toList(growable: false);
  return [
    for (final token in tokens) _excursionSearchNeedleVariants(token),
  ].where((variants) => variants.isNotEmpty).toList(growable: false);
}

List<String> _excursionSearchNeedleVariants(String token) {
  final variants = <String>[];
  final seen = <String>{};
  void add(String value) {
    final normalized = _normalizeExcursionSearchText(value);
    if (normalized.isEmpty || !seen.add(normalized)) return;
    variants.add(normalized);
  }

  add(token);
  if (RegExp(r'[a-z]').hasMatch(token)) {
    add(_latinToCyrillicExcursionSearchText(token));
  }
  if (RegExp(r'[а-яәғқңөұүһі]').hasMatch(token)) {
    add(_cyrillicToLatinExcursionSearchText(token));
  }
  _addExcursionLanguageSearchVariants(add, token);
  return variants;
}

String _latinToCyrillicExcursionSearchText(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return '';

  final buffer = StringBuffer();
  var index = 0;
  while (index < normalized.length) {
    final rest = normalized.substring(index);
    if (rest.startsWith('shch')) {
      buffer.write('щ');
      index += 4;
    } else if (rest.startsWith('sch')) {
      buffer.write('щ');
      index += 3;
    } else if (rest.startsWith('nyo') || rest.startsWith('nio')) {
      buffer.write('ньо');
      index += 3;
    } else if (rest.startsWith('ch')) {
      buffer.write('ч');
      index += 2;
    } else if (rest.startsWith('sh')) {
      buffer.write('ш');
      index += 2;
    } else if (rest.startsWith('zh')) {
      buffer.write('ж');
      index += 2;
    } else if (rest.startsWith('kh')) {
      buffer.write('х');
      index += 2;
    } else if (rest.startsWith('gh')) {
      buffer.write('ғ');
      index += 2;
    } else if (rest.startsWith('ng')) {
      buffer.write('ң');
      index += 2;
    } else if (rest.startsWith('ya') || rest.startsWith('ia')) {
      buffer.write('я');
      index += 2;
    } else if (rest.startsWith('yu') || rest.startsWith('iu')) {
      buffer.write('ю');
      index += 2;
    } else if (rest.startsWith('yo') || rest.startsWith('io')) {
      buffer.write('е');
      index += 2;
    } else if (rest.startsWith('ye')) {
      buffer.write('е');
      index += 2;
    } else {
      buffer.write(_latinCharToCyrillic(normalized[index]));
      index++;
    }
  }
  return buffer.toString();
}

String _latinCharToCyrillic(String char) {
  return switch (char) {
    'a' => 'а',
    'b' => 'б',
    'c' || 'k' => 'к',
    'd' => 'д',
    'e' => 'е',
    'f' => 'ф',
    'g' => 'г',
    'h' => 'х',
    'i' => 'и',
    'j' => 'ж',
    'l' => 'л',
    'm' => 'м',
    'n' => 'н',
    'o' => 'о',
    'p' => 'п',
    'q' => 'қ',
    'r' => 'р',
    's' => 'с',
    't' => 'т',
    'u' || 'w' => 'у',
    'v' => 'в',
    'x' => 'кс',
    'y' => 'ы',
    'z' => 'з',
    _ => char,
  };
}

String _cyrillicToLatinExcursionSearchText(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(switch (char) {
      'а' || 'ә' => 'a',
      'б' => 'b',
      'в' => 'v',
      'г' || 'ғ' => 'g',
      'д' => 'd',
      'е' || 'э' => 'e',
      'ё' => 'yo',
      'ж' => 'zh',
      'з' => 'z',
      'и' || 'і' => 'i',
      'й' => 'y',
      'к' || 'қ' => 'k',
      'л' => 'l',
      'м' => 'm',
      'н' || 'ң' => 'n',
      'о' || 'ө' => 'o',
      'п' => 'p',
      'р' => 'r',
      'с' => 's',
      'т' => 't',
      'у' || 'ұ' || 'ү' => 'u',
      'ф' => 'f',
      'х' || 'һ' => 'h',
      'ц' => 'ts',
      'ч' => 'ch',
      'ш' => 'sh',
      'щ' => 'shch',
      'ы' || 'ь' => 'y',
      'ъ' => '',
      'ю' => 'yu',
      'я' => 'ya',
      _ => char,
    });
  }
  return buffer.toString();
}

void _addExcursionLanguageSearchVariants(
  void Function(String value) add,
  String token,
) {
  switch (_normalizeExcursionSearchText(token)) {
    case 'en':
    case 'eng':
    case 'english':
    case 'анг':
    case 'английский':
    case 'ағылшын':
      add('en');
      add('english');
      add('английский');
      add('ағылшын');
      return;
    case 'ru':
    case 'rus':
    case 'russian':
    case 'рус':
    case 'русский':
    case 'орыс':
      add('ru');
      add('russian');
      add('русский');
      add('орыс');
      return;
    case 'kk':
    case 'kz':
    case 'kaz':
    case 'kazakh':
    case 'қазақ':
    case 'казахский':
      add('kk');
      add('kz');
      add('kazakh');
      add('қазақ');
      add('казахский');
      return;
    case 'fr':
    case 'fre':
    case 'french':
    case 'француз':
    case 'французский':
      add('fr');
      add('french');
      add('французский');
      return;
    case 'ja':
    case 'jp':
    case 'japanese':
    case 'япон':
    case 'японский':
    case 'жапон':
      add('ja');
      add('jp');
      add('japanese');
      add('японский');
      add('жапон');
      return;
    case 'de':
    case 'ger':
    case 'german':
    case 'немецкий':
    case 'неміс':
      add('de');
      add('german');
      add('немецкий');
      add('неміс');
      return;
    case 'es':
    case 'spa':
    case 'spanish':
    case 'испанский':
    case 'испан':
      add('es');
      add('spanish');
      add('испанский');
      return;
    case 'tr':
    case 'tur':
    case 'turkish':
    case 'турецкий':
    case 'түрік':
      add('tr');
      add('turkish');
      add('турецкий');
      add('түрік');
      return;
  }
}

String _formatExcursionPriceInput(double? value) {
  if (value == null || value <= 0) return '';
  return value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

double? _parseExcursionPriceInput(String value) {
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

class _ExcursionsScreenState extends State<ExcursionsScreen> {
  final PlaceApi _placeApi = PlaceApi();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, PlaceVm> _localizedLandmarks = const {};
  final Set<String> _loadingLocalizedLandmarkIds = <String>{};
  String? _localizedLandmarksLocale;
  bool _hasAppliedDefaultCityFilter = false;
  _ExcursionsSortMode _sortMode = _ExcursionsSortMode.createdAt;
  _ExcursionsSortDirection _sortDirection = _ExcursionsSortDirection.desc;
  _ExcursionsFilters _filters = const _ExcursionsFilters();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeDefaultCityFilter();
      if (!mounted) return;
      unawaited(_loadExcursionsForCurrentFilters());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final lang = Localizations.localeOf(context).languageCode;
    if (_localizedLandmarksLocale == lang) return;
    _localizedLandmarksLocale = lang;
    _localizedLandmarks = const {};
    _loadingLocalizedLandmarkIds.clear();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeDefaultCityFilter() async {
    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      await provider.load(
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    if (!mounted) return;
    final location = await provider.resolveCityReference(
      provider.effectiveLocation,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    _applyDefaultCityFilter(location);
  }

  void _applyDefaultCityFilter(HomeLocationPreference location) {
    if (_hasAppliedDefaultCityFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }

    final defaults = HomeLocationFilterDefaults.fromPreference(location);
    if (!defaults.hasValue) return;

    _hasAppliedDefaultCityFilter = true;

    setState(
      () => _filters = _filters.copyWith(
        country: defaults.country,
        city: defaults.city,
      ),
    );
  }

  void _scheduleApplyDefaultCityFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultCityFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final location = await provider.resolveCityReference(
        provider.effectiveLocation,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      _applyDefaultCityFilter(location);
    });
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) return;

    setState(() {
      _searchQuery = nextQuery;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_loadExcursionsForCurrentFilters());
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Future<void> _handleRefresh() {
    return _loadExcursionsForCurrentFilters();
  }

  Future<void> _loadExcursionsForCurrentFilters() {
    final city = _filters.city;
    return context.read<ExcursionProvider>().refreshExcursions(
      query: _searchQuery,
      countryCode: _filters.countryCode,
      cityName: city?.cityName,
      departureCityId: city?.cityId,
    );
  }

  void _scheduleResolveLocalizedLandmarks(List<ExcursionVm> excursions) {
    if (!mounted) return;

    final lang = Localizations.localeOf(context).languageCode;
    final ids = <String>[];
    for (final excursion in excursions) {
      final landmarkId = excursion.landmarkId?.trim();
      if (landmarkId == null ||
          landmarkId.isEmpty ||
          _localizedLandmarks.containsKey(landmarkId) ||
          _loadingLocalizedLandmarkIds.contains(landmarkId)) {
        continue;
      }
      ids.add(landmarkId);
    }
    if (ids.isEmpty) return;

    for (final landmarkId in ids.take(16)) {
      _loadingLocalizedLandmarkIds.add(landmarkId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadLocalizedLandmark(landmarkId, lang));
      });
    }
  }

  Future<void> _loadLocalizedLandmark(String landmarkId, String lang) async {
    try {
      final place = await _placeApi.getPlace(landmarkId, locale: lang);
      if (!mounted || _localizedLandmarksLocale != lang) return;

      setState(() {
        _localizedLandmarks = {..._localizedLandmarks, landmarkId: place};
        _loadingLocalizedLandmarkIds.remove(landmarkId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocalizedLandmarkIds.remove(landmarkId));
    }
  }

  PlaceVm? _localizedLandmarkFor(ExcursionVm excursion) {
    final landmarkId = excursion.landmarkId?.trim();
    if (landmarkId == null || landmarkId.isEmpty) return null;
    return _localizedLandmarks[landmarkId];
  }

  Future<void> _onCreateExcursionTap() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/excursions/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    await context.push('/excursions/create');
    if (!mounted) return;

    final lastCreatedExcursion = context
        .read<ExcursionProvider>()
        .lastCreatedExcursion;
    if (lastCreatedExcursion != null && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openExcursionDetails(ExcursionVm excursion) {
    if (excursion.id.trim().isEmpty) return;

    context.push(
      '/excursions/${Uri.encodeComponent(excursion.id)}',
      extra: excursion,
    );
  }

  void _onSortTap(_ExcursionsSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortDirection = _sortDirection == _ExcursionsSortDirection.asc
            ? _ExcursionsSortDirection.desc
            : _ExcursionsSortDirection.asc;
        return;
      }

      _sortMode = mode;
      _sortDirection = mode.defaultDirection;
    });
  }

  Future<void> _showFilters() async {
    final excursionsSnapshot = context.read<ExcursionProvider>().excursions;
    final selectedFilters = await showModalBottomSheet<_ExcursionsFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExcursionsFiltersSheet(
        initialFilters: _filters,
        initialResultCount: _visibleExcursions(
          excursionsSnapshot,
          filtersOverride: _filters,
        ).length,
        resultCountLoader: _loadPreviewResultCount,
      ),
    );

    if (selectedFilters == null || !mounted) return;
    setState(() => _filters = selectedFilters);
    unawaited(_loadExcursionsForCurrentFilters());
  }

  Future<int> _loadPreviewResultCount(_ExcursionsFilters filters) async {
    final city = filters.city;
    final previewExcursions = await context
        .read<ExcursionProvider>()
        .previewExcursions(
          query: _searchQuery,
          countryCode: filters.countryCode,
          cityName: city?.cityName,
          departureCityId: city?.cityId,
        );
    if (!mounted) return 0;
    return _visibleExcursions(
      previewExcursions,
      filtersOverride: filters,
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<SessionProvider>().profile;
    final locationProvider = context.watch<HomeLocationProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final canCreateExcursion = profile?.isGuide == true;

    _scheduleApplyDefaultCityFilter(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF21170D),
      bottomNavigationBar: ExcursionsBottomNavigation(
        canCreateExcursion: canCreateExcursion,
        onCreateExcursionTap: _onCreateExcursionTap,
        onMapTap: () => context.push('/map'),
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppListScreenHeader(
              title: l10n.excursionsDiscoverTitle,
              notificationsTooltip: l10n.placeNotificationsTooltip,
              onBackTap: _goBack,
              onNotificationsTap: () => context.push('/notifications'),
            ),
            Expanded(
              child: Consumer<ExcursionProvider>(
                builder: (context, provider, _) {
                  _scheduleResolveLocalizedLandmarks(provider.excursions);
                  final visibleExcursions = _visibleExcursions(
                    provider.excursions,
                  );
                  final isInitialLoading =
                      provider.listState == ExcursionListState.loading &&
                      provider.excursions.isEmpty;
                  final hasInitialError =
                      provider.listState == ExcursionListState.error &&
                      provider.excursions.isEmpty;

                  if (hasInitialError) {
                    return ErrorView(
                      message:
                          provider.listErrorMessage ??
                          l10n.excursionsLoadFailed,
                      onRetry: () => context
                          .read<ExcursionProvider>()
                          .loadExcursions(query: _searchQuery),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: const Color(0xFF2B1F14),
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPadding(context),
                            14,
                            _horizontalPadding(context),
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ExcursionsSearchField(
                                  controller: _searchController,
                                  hintText: l10n.excursionsSearchHint,
                                  onFilterTap: _showFilters,
                                  activeFilterCount: _filters.activeCount,
                                ),
                                const SizedBox(height: 18),
                                if (isLoggedIn) ...[
                                  SurfaceStoryTray(
                                    surface: 'excursions',
                                    viewerAvatarFileId: profile?.avatarFileId,
                                    viewerInitials: profile?.initials ?? 'F',
                                    viewerUserId: profile?.userId,
                                  ),
                                  const SizedBox(height: 22),
                                ],
                                const Divider(
                                  height: 1,
                                  color: Color(0x1AFFFFFF),
                                ),
                                const SizedBox(height: 9),
                                _ExcursionsSortBar(
                                  l10n: l10n,
                                  selected: _sortMode,
                                  direction: _sortDirection,
                                  onChanged: _onSortTap,
                                ),
                                if (widget
                                        .routeArgs
                                        ?.showNoPlaceExcursionsNotice ==
                                    true) ...[
                                  const SizedBox(height: 14),
                                  _buildNoPlaceExcursionsNotice(l10n),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isInitialLoading)
                          _ExcursionsLoadingGrid(
                            horizontalPadding: _horizontalPadding(context),
                          )
                        else if (visibleExcursions.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ExcursionsEmptyState(
                              title: l10n.excursionsEmptyTitle,
                              subtitle: _searchQuery.isEmpty
                                  ? l10n.excursionsEmptySubtitle
                                  : l10n.excursionsEmptySearchSubtitle,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              _horizontalPadding(context),
                              26,
                              _horizontalPadding(context),
                              28,
                            ),
                            sliver: SliverGrid.builder(
                              itemCount: visibleExcursions.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 220,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 18,
                                    childAspectRatio: _gridAspectRatio(context),
                                  ),
                              itemBuilder: (context, index) {
                                return ExcursionListCard(
                                  excursion: visibleExcursions[index],
                                  languageCode: Localizations.localeOf(
                                    context,
                                  ).languageCode,
                                  localizedLandmark: _localizedLandmarkFor(
                                    visibleExcursions[index],
                                  ),
                                  seed: index,
                                  onTap: () => _openExcursionDetails(
                                    visibleExcursions[index],
                                  ),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ExcursionVm> _visibleExcursions(
    List<ExcursionVm> excursions, {
    _ExcursionsFilters? filtersOverride,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final searchGroups = _excursionSearchNeedleGroups(_searchQuery);
    final filters = filtersOverride ?? _filters;
    final filtered = excursions
        .where((excursion) {
          if (!filters.matches(excursion)) return false;
          if (searchGroups.isEmpty) return true;

          final haystack = _excursionSearchHaystack(l10n, excursion, lang);
          return searchGroups.every(
            (variants) => variants.any(haystack.contains),
          );
        })
        .toList(growable: false);

    final sorted = [...filtered];
    sorted.sort((a, b) {
      final comparison = switch (_sortMode) {
        _ExcursionsSortMode.createdAt => _excursionCreatedAtFor(
          a,
        ).compareTo(_excursionCreatedAtFor(b)),
        _ExcursionsSortMode.rating => _excursionRatingFor(
          a,
        ).compareTo(_excursionRatingFor(b)),
        _ExcursionsSortMode.price => _excursionCardPriceFor(
          a,
        ).amount.compareTo(_excursionCardPriceFor(b).amount),
        _ExcursionsSortMode.duration => a.durationMinutes.compareTo(
          b.durationMinutes,
        ),
      };

      final directedComparison = _sortDirection == _ExcursionsSortDirection.asc
          ? comparison
          : -comparison;
      if (directedComparison != 0) return directedComparison;
      final aTitle = localizedExcursionTitle(
        languageCode: lang,
        excursion: a,
        place: _localizedLandmarkFor(a),
      );
      final bTitle = localizedExcursionTitle(
        languageCode: lang,
        excursion: b,
        place: _localizedLandmarkFor(b),
      );
      return aTitle.compareTo(bTitle);
    });

    return sorted;
  }

  Widget _buildNoPlaceExcursionsNotice(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.excursionsNoPlaceExcursionsTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.excursionsNoPlaceExcursionsSubtitle,
                    style: const TextStyle(
                      color: Color(0xFFD6C5B8),
                      fontSize: 13,
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

  String _excursionSearchHaystack(
    AppLocalizations l10n,
    ExcursionVm excursion,
    String lang,
  ) {
    final landmark = _localizedLandmarkFor(excursion);
    final values = <String>[
      excursion.id,
      localizedExcursionTitle(
        languageCode: lang,
        excursion: excursion,
        place: landmark,
      ),
      localizedExcursionSummary(
        languageCode: lang,
        excursion: excursion,
        place: landmark,
      ),
      localizedExcursionDescription(
        languageCode: lang,
        excursion: excursion,
        place: landmark,
      ),
      localizedExcursionLandmarkName(
        languageCode: lang,
        excursion: excursion,
        place: landmark,
      ),
      excursion.title,
      excursion.summary,
      excursion.description,
      excursion.cityName ?? '',
      excursion.countryCode ?? '',
      excursion.landmarkId ?? '',
      excursion.landmarkName ?? '',
      excursion.categorySlug ?? '',
      localizedExcursionCategoryLabel(l10n, excursion.categorySlug),
      excursion.meetingPoint,
      excursion.mapUrl ?? '',
      excursion.status,
      excursion.visibility,
      excursion.currency,
      excursion.priceAmount.toString(),
      excursion.durationMinutes.toString(),
      excursion.maxGroupSize.toString(),
      ...excursion.tags,
      for (final code in excursion.languageCodes) ...[
        code,
        localizedExcursionLanguageLabel(l10n, code),
      ],
      ...excursion.includedItems,
      ...excursion.localizedIncludedItems(lang),
      for (final values in excursion.includedItemTranslations.values) ...values,
      for (final item in excursion.itinerary) ...[
        item.title,
        item.description,
        item.localizedTitle(lang),
        item.localizedDescription(lang),
        for (final copy in item.translations.values) ...[
          copy.title,
          copy.description,
        ],
        item.durationMinutes?.toString() ?? '',
        item.startOffsetMinutes.toString(),
      ],
      for (final offer in excursion.offers) ...[
        offer.title,
        offer.summary,
        offer.description,
        offer.meetingPoint,
        offer.currency,
        offer.priceAmount.toString(),
        offer.durationMinutes.toString(),
        offer.maxGroupSize.toString(),
        offer.guideUserId,
        offer.guideProfileId,
        ...offer.includedItems,
        ...offer.localizedIncludedItems(lang),
        for (final values in offer.includedItemTranslations.values) ...values,
        for (final item in offer.itinerary) ...[
          item.title,
          item.description,
          item.localizedTitle(lang),
          item.localizedDescription(lang),
          for (final copy in item.translations.values) ...[
            copy.title,
            copy.description,
          ],
        ],
        for (final code in offer.languageCodes) ...[
          code,
          localizedExcursionLanguageLabel(l10n, code),
        ],
      ],
    ];

    return _normalizeExcursionSearchText(values.join(' '));
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 18;
    if (width >= 600) return 28;
    return 24;
  }
}

double _gridAspectRatio(BuildContext context) {
  return _excursionGridAspectRatioForWidth(MediaQuery.sizeOf(context).width);
}

double _excursionGridAspectRatioForWidth(double width) {
  final normalizedWidth = ((width - 360) / 480).clamp(0.0, 1.0).toDouble();
  return 0.70 + normalizedWidth * 0.12;
}

double _excursionFilterHeaderHeight(BuildContext context) {
  final scaledTitleHeight = MediaQuery.textScalerOf(context).scale(18);
  return (scaledTitleHeight + 52).clamp(66.0, 82.0).toDouble();
}

double _excursionLanguageGridMaxHeight(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return (height * 0.26).clamp(176.0, 248.0).toDouble();
}

double _excursionSegmentMainAxisExtent(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  return (width * 0.115 + 4 * textScale).clamp(46.0, 56.0).toDouble();
}

DateTime _excursionCreatedAtFor(ExcursionVm excursion) {
  return excursion.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

double _excursionRatingFor(ExcursionVm excursion) {
  if (excursion.offers.isEmpty) return 0;
  return excursion.offers
      .map((offer) => offer.guideRatingAvg)
      .fold<double>(0, math.max);
}

class ExcursionsBottomNavigation extends StatelessWidget {
  const ExcursionsBottomNavigation({
    super.key,
    required this.canCreateExcursion,
    required this.onCreateExcursionTap,
    required this.onMapTap,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onServicesTap,
    required this.onChatsTap,
  });

  final bool canCreateExcursion;
  final VoidCallback onCreateExcursionTap;
  final VoidCallback onMapTap;
  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (canCreateExcursion) {
      return CreateActionBottomNavigationBar(
        createSemanticsLabel: l10n.excursionsCreateFab,
        onHomeTap: onHomeTap,
        onQrTap: onQrTap,
        onCreateTap: onCreateExcursionTap,
        onServicesTap: onServicesTap,
        onChatsTap: onChatsTap,
        backgroundStyle: AppBottomNavCreateBackgroundStyle.flat,
      );
    }

    return CommonBottomNavigationBar(
      onHomeTap: onHomeTap,
      onQrTap: () => context.push('/qr'),
      onMapTap: onMapTap,
      onServicesTap: onServicesTap,
      onChatsTap: onChatsTap,
    );
  }
}

class _ExcursionsSearchField extends StatelessWidget {
  const _ExcursionsSearchField({
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return AppListSearchField(
      controller: controller,
      hintText: hintText,
      filterTooltip: AppLocalizations.of(context)!.myActivitiesFilterButton,
      activeFilterCount: activeFilterCount,
      onFilterTap: onFilterTap,
    );
  }
}

class _ExcursionsFilters {
  const _ExcursionsFilters({
    this.country,
    this.city,
    this.categorySlugs = const <String>{},
    this.languageCodes = const <String>{},
    this.duration,
    this.priceMin,
    this.priceMax,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final Set<String> categorySlugs;
  final Set<String> languageCodes;
  final _ExcursionsDurationFilter? duration;
  final double? priceMin;
  final double? priceMax;

  int get activeCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      categorySlugs.length +
      languageCodes.length +
      (duration == null ? 0 : 1) +
      (priceMin == null ? 0 : 1) +
      (priceMax == null ? 0 : 1);

  String? get countryCode => country?.countryCode ?? city?.countryCode;

  _ExcursionsFilters copyWith({
    Object? country = _unset,
    Object? city = _unset,
    Set<String>? categorySlugs,
    Set<String>? languageCodes,
    _ExcursionsDurationFilter? duration,
    bool clearDuration = false,
    double? priceMin,
    bool clearPriceMin = false,
    double? priceMax,
    bool clearPriceMax = false,
  }) {
    return _ExcursionsFilters(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      categorySlugs: categorySlugs ?? this.categorySlugs,
      languageCodes: languageCodes ?? this.languageCodes,
      duration: clearDuration ? null : duration ?? this.duration,
      priceMin: clearPriceMin ? null : priceMin ?? this.priceMin,
      priceMax: clearPriceMax ? null : priceMax ?? this.priceMax,
    );
  }

  static const Object _unset = Object();

  bool matches(ExcursionVm excursion) {
    final selectedCountry = country;
    if (selectedCountry != null &&
        !selectedCountry.matches(countryCode: excursion.countryCode)) {
      return false;
    }

    final selectedCity = city;
    if (selectedCity != null) {
      if (!selectedCity.matches(
        cityId: excursion.departureCityId,
        cityName: excursion.cityName,
        countryCode: excursion.countryCode,
      )) {
        return false;
      }
    }

    if (categorySlugs.isNotEmpty) {
      final category = excursion.categorySlug?.trim().toLowerCase();
      if (category == null || !categorySlugs.contains(category)) return false;
    }

    if (languageCodes.isNotEmpty) {
      final excursionLanguages = excursion.languageCodes
          .map((code) => code.trim().toLowerCase())
          .where((code) => code.isNotEmpty)
          .toSet();
      if (!languageCodes.any(excursionLanguages.contains)) return false;
    }

    final durationFilter = duration;
    if (durationFilter != null &&
        !_matchesDuration(durationFilter, excursion.durationMinutes)) {
      return false;
    }

    final priceKzt = _priceApproxKzt(excursion);
    final min = priceMin;
    if (min != null && priceKzt < min) return false;
    final max = priceMax;
    if (max != null && priceKzt > max) return false;

    return true;
  }

  static bool _matchesDuration(_ExcursionsDurationFilter filter, int minutes) {
    return switch (filter) {
      _ExcursionsDurationFilter.short => minutes > 0 && minutes < 180,
      _ExcursionsDurationFilter.halfDay => minutes >= 180 && minutes <= 360,
      _ExcursionsDurationFilter.fullDay => minutes > 360 && minutes <= 720,
      _ExcursionsDurationFilter.multiDay => minutes > 720,
    };
  }

  static double _priceApproxKzt(ExcursionVm excursion) {
    final price = _excursionCardPriceFor(excursion);
    final amount = price.amount;
    switch (price.currency.trim().toUpperCase()) {
      case 'USD':
        return amount * 450;
      case 'EUR':
        return amount * 500;
      case 'RUB':
        return amount * 5;
      case 'GBP':
        return amount * 580;
      case 'KZT':
      default:
        return amount;
    }
  }
}

class _ExcursionsFiltersSheet extends StatefulWidget {
  const _ExcursionsFiltersSheet({
    required this.initialFilters,
    required this.initialResultCount,
    required this.resultCountLoader,
  });

  final _ExcursionsFilters initialFilters;
  final int initialResultCount;
  final Future<int> Function(_ExcursionsFilters filters) resultCountLoader;

  @override
  State<_ExcursionsFiltersSheet> createState() =>
      _ExcursionsFiltersSheetState();
}

class _ExcursionsFiltersSheetState extends State<_ExcursionsFiltersSheet> {
  static const _resultCountDebounceDuration = Duration(milliseconds: 250);

  late _ExcursionsFilters _filters;
  late final TextEditingController _languageSearchController;
  late final TextEditingController _priceFromController;
  late final TextEditingController _priceToController;
  Timer? _resultCountDebounce;
  late int _resultCount;
  bool _isResultCountLoading = false;
  int _resultCountRequestId = 0;
  String _languageSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _resultCount = widget.initialResultCount;
    _languageSearchController = TextEditingController()
      ..addListener(_handleLanguageSearchChanged);
    _priceFromController = TextEditingController(
      text: _formatExcursionPriceInput(widget.initialFilters.priceMin),
    )..addListener(_handlePriceRangeChanged);
    _priceToController = TextEditingController(
      text: _formatExcursionPriceInput(widget.initialFilters.priceMax),
    )..addListener(_handlePriceRangeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleResultCountLoad(immediate: true);
    });
  }

  @override
  void dispose() {
    _resultCountDebounce?.cancel();
    _languageSearchController
      ..removeListener(_handleLanguageSearchChanged)
      ..dispose();
    _priceFromController
      ..removeListener(_handlePriceRangeChanged)
      ..dispose();
    _priceToController
      ..removeListener(_handlePriceRangeChanged)
      ..dispose();
    super.dispose();
  }

  void _handleLanguageSearchChanged() {
    final nextQuery = _languageSearchController.text.trim();
    if (nextQuery == _languageSearchQuery) return;

    setState(() => _languageSearchQuery = nextQuery);
  }

  void _scheduleResultCountLoad({bool immediate = false}) {
    _resultCountDebounce?.cancel();
    _resultCountRequestId++;

    if (immediate) {
      unawaited(_loadResultCount());
      return;
    }

    _resultCountDebounce = Timer(_resultCountDebounceDuration, () {
      unawaited(_loadResultCount());
    });
  }

  Future<void> _loadResultCount() async {
    final requestId = _resultCountRequestId;
    final filters = _filters;
    setState(() => _isResultCountLoading = true);

    try {
      final resultCount = await widget.resultCountLoader(filters);
      if (!mounted || requestId != _resultCountRequestId) return;
      setState(() {
        _resultCount = resultCount;
        _isResultCountLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _resultCountRequestId) return;
      setState(() => _isResultCountLoading = false);
    }
  }

  void _clear() {
    _languageSearchController.clear();
    _priceFromController.clear();
    _priceToController.clear();
    setState(() {
      _filters = const _ExcursionsFilters();
      _languageSearchQuery = '';
    });
    _scheduleResultCountLoad();
  }

  void _toggleCategory(String slug) {
    final next = Set<String>.of(_filters.categorySlugs);
    if (!next.remove(slug)) next.add(slug);

    setState(() {
      _filters = _filters.copyWith(categorySlugs: next);
    });
    _scheduleResultCountLoad();
  }

  void _selectLanguage(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final isSelected = _filters.languageCodes.contains(normalized);

    setState(() {
      _filters = _filters.copyWith(
        languageCodes: isSelected ? const <String>{} : {normalized},
      );
      _languageSearchController.clear();
      _languageSearchQuery = '';
    });
    _scheduleResultCountLoad();
  }

  void _setDuration(_ExcursionsDurationFilter duration) {
    setState(() {
      _filters = _filters.copyWith(
        duration: _filters.duration == duration ? null : duration,
        clearDuration: _filters.duration == duration,
      );
    });
    _scheduleResultCountLoad();
  }

  void _setCountry(AppCountryFilterValue? country) {
    setState(() {
      _filters = _filters.copyWith(country: country, city: null);
    });
    _scheduleResultCountLoad();
  }

  void _setCity(AppCityFilterValue? city) {
    setState(() {
      _filters = _filters.copyWith(city: city);
    });
    _scheduleResultCountLoad();
  }

  void _handlePriceRangeChanged() {
    final priceMin = _parseExcursionPriceInput(_priceFromController.text);
    final priceMax = _parseExcursionPriceInput(_priceToController.text);
    setState(() {
      _filters = _filters.copyWith(
        priceMin: priceMin,
        clearPriceMin: priceMin == null,
        priceMax: priceMax,
        clearPriceMax: priceMax == null,
      );
    });
    _scheduleResultCountLoad();
  }

  String? _selectedLanguage(AppLocalizations l10n) {
    if (_filters.languageCodes.isEmpty) return null;
    return localizedExcursionLanguageLabel(l10n, _filters.languageCodes.first);
  }

  List<String> _visibleLanguages(AppLocalizations l10n) {
    final query = _normalizeExcursionSearchText(_languageSearchQuery);
    if (query.isEmpty) return const [];

    final tokens = query
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);

    return _languageFilterCodes
        .where((code) {
          final haystack = _languageSearchHaystack(l10n, code);
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);
  }

  String _languageSearchHaystack(AppLocalizations l10n, String code) {
    final aliases = switch (code.trim().toLowerCase()) {
      'en' => 'eng english английский анг ағылшын',
      'ru' => 'rus russian русский рус орыс',
      'kk' => 'kz kaz kazakh казахский қазақ қазақша',
      'fr' => 'fre french французский француз',
      'ja' => 'jp japanese японский япон жапон',
      'de' => 'ger german немецкий неміс',
      'es' => 'spa spanish испанский испан',
      'tr' => 'tur turkish турецкий түрік',
      _ => '',
    };

    return _normalizeExcursionSearchText(
      '$code ${localizedExcursionLanguageLabel(l10n, code)} $aliases',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selectedLanguage = _selectedLanguage(l10n);
    final visibleLanguages = _visibleLanguages(l10n);

    return AppDismissibleModalSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF21170D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x293A270F))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.excursionsFiltersTitle,
                clearLabel: l10n.excursionsFiltersClear,
                onClear: _clear,
                height: _excursionFilterHeaderHeight(context),
                horizontalPadding: 22,
                titleFontSize: 18,
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCountryFilterSection(
                        title: l10n.placeFilterCountrySection,
                        allCountriesLabel: l10n.placeFilterCountryAll,
                        searchHint: l10n.placeFilterCountrySearchHint,
                        noResultsText: l10n.placeFilterCountryNoResults,
                        selectedCountry: _filters.country,
                        onChanged: _setCountry,
                      ),
                      if (_filters.country != null) ...[
                        const SizedBox(height: 30),
                        AppCityFilterSection(
                          title: l10n.locationFilterCitySection,
                          allCitiesLabel: l10n.locationFilterAllCities,
                          searchHint: l10n.locationFilterCitySearchHint,
                          noResultsText: l10n.locationFilterCityNoResults,
                          selectedCity: _filters.city,
                          onChanged: _setCity,
                          countryCode: _filters.country?.countryCode,
                        ),
                      ],
                      const SizedBox(height: 30),
                      _ExcursionsFilterSection(
                        title: l10n.excursionsFilterCategories,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final option in _categoryFilterOptions)
                              _ExcursionsFilterChip(
                                label: localizedExcursionCategoryLabel(
                                  l10n,
                                  option.slug,
                                ),
                                icon: option.icon,
                                selected: _filters.categorySlugs.contains(
                                  option.slug,
                                ),
                                onTap: () => _toggleCategory(option.slug),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ExcursionsFilterSection(
                        title: l10n.excursionsFilterPriceRange,
                        child: _ExcursionsPriceRangeFields(
                          fromController: _priceFromController,
                          toController: _priceToController,
                          fromLabel: l10n.excursionsFilterPriceFrom,
                          toLabel: l10n.excursionsFilterPriceTo,
                          currencyLabel: 'KZT',
                        ),
                      ),
                      const SizedBox(height: 30),
                      _ExcursionsFilterSection(
                        title: l10n.excursionsFilterDuration,
                        child:
                            _ExcursionsSegmentGrid<_ExcursionsDurationFilter>(
                              items: [
                                _ExcursionsSegmentItem(
                                  value: _ExcursionsDurationFilter.short,
                                  label: l10n.excursionsFilterShortDuration,
                                ),
                                _ExcursionsSegmentItem(
                                  value: _ExcursionsDurationFilter.halfDay,
                                  label: l10n.excursionsFilterHalfDayDuration,
                                ),
                                _ExcursionsSegmentItem(
                                  value: _ExcursionsDurationFilter.fullDay,
                                  label: l10n.excursionsFilterFullDayDuration,
                                ),
                                _ExcursionsSegmentItem(
                                  value: _ExcursionsDurationFilter.multiDay,
                                  label: l10n.excursionsFilterMultiDayDuration,
                                ),
                              ],
                              selectedValue: _filters.duration,
                              onSelected: _setDuration,
                            ),
                      ),
                      const SizedBox(height: 30),
                      _ExcursionsFilterSection(
                        title: l10n.excursionsFilterLanguage,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2118),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.translate_rounded,
                                      color: AppColors.accent,
                                      size: 21,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedLanguage ??
                                            l10n.excursionsFilterLanguageAll,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (selectedLanguage != null)
                                      IconButton(
                                        tooltip: l10n.excursionsFiltersClear,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => setState(() {
                                          _filters = _filters.copyWith(
                                            languageCodes: const <String>{},
                                          );
                                        }),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFFBDAA98),
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _languageSearchController,
                              cursorColor: AppColors.accent,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    l10n.excursionsFilterLanguageSearchHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9D8877),
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.accent,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF171009),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.accent,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            if (_languageSearchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              if (visibleLanguages.isEmpty)
                                Text(
                                  l10n.excursionsFilterLanguageNoResults,
                                  style: const TextStyle(
                                    color: Color(0xFFBDAA98),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: _excursionLanguageGridMaxHeight(
                                      context,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: visibleLanguages.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final code = visibleLanguages[index];
                                      return _ExcursionsLanguageOptionRow(
                                        label: localizedExcursionLanguageLabel(
                                          l10n,
                                          code,
                                        ),
                                        code: code.toUpperCase(),
                                        selected: _filters.languageCodes
                                            .contains(code),
                                        onTap: () => _selectLanguage(code),
                                      );
                                    },
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
              Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 18),
                child: AppFilterApplyButton(
                  label: l10n.excursionsFiltersShowResults(_resultCount),
                  onTap: () => Navigator.of(context).pop(_filters),
                  isLoading: _isResultCountLoading,
                  borderRadius: 14,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionsFilterSection extends StatelessWidget {
  const _ExcursionsFilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ExcursionsPriceRangeFields extends StatelessWidget {
  const _ExcursionsPriceRangeFields({
    required this.fromController,
    required this.toController,
    required this.fromLabel,
    required this.toLabel,
    required this.currencyLabel,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final String fromLabel;
  final String toLabel;
  final String currencyLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final fields = [
          _ExcursionsPriceInputField(
            controller: fromController,
            label: fromLabel,
            suffix: currencyLabel,
          ),
          _ExcursionsPriceInputField(
            controller: toController,
            label: toLabel,
            suffix: currencyLabel,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [fields[0], const SizedBox(height: 12), fields[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 12),
            Expanded(child: fields[1]),
          ],
        );
      },
    );
  }
}

class _ExcursionsPriceInputField extends StatelessWidget {
  const _ExcursionsPriceInputField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cursorColor: AppColors.accent,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFFBDAA98),
          fontWeight: FontWeight.w700,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: Color(0xFFBDAA98),
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: const Color(0xFF171009),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
      ),
    );
  }
}

class _ExcursionsLanguageOptionRow extends StatelessWidget {
  const _ExcursionsLanguageOptionRow({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : const Color(0xFF2C2118),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFFBDAA98),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionsFilterChip extends StatelessWidget {
  const _ExcursionsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF534638),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFFD8C7B7),
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD8C7B7),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionsSegmentItem<T> {
  const _ExcursionsSegmentItem({required this.value, required this.label});

  final T value;
  final String label;
}

class _ExcursionsSegmentGrid<T> extends StatelessWidget {
  const _ExcursionsSegmentGrid({
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_ExcursionsSegmentItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 330;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useSingleColumn ? 1 : 2,
            mainAxisExtent: _excursionSegmentMainAxisExtent(context),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.value == selectedValue;
            return _ExcursionsSegmentButton(
              label: item.label,
              selected: selected,
              onTap: () => onSelected(item.value),
            );
          },
        );
      },
    );
  }
}

class _ExcursionsSegmentButton extends StatelessWidget {
  const _ExcursionsSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF4A3D31),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFD8C7B7),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcursionsSortBar extends StatelessWidget {
  const _ExcursionsSortBar({
    required this.l10n,
    required this.selected,
    required this.direction,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final _ExcursionsSortMode selected;
  final _ExcursionsSortDirection direction;
  final ValueChanged<_ExcursionsSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppInlineSortRow<_ExcursionsSortMode>(
      label: l10n.excursionsSortLabel,
      options: [
        for (final mode in _ExcursionsSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction == _ExcursionsSortDirection.asc,
      onSelected: onChanged,
    );
  }
}

class ExcursionListCard extends StatelessWidget {
  const ExcursionListCard({
    super.key,
    required this.excursion,
    required this.languageCode,
    required this.seed,
    this.localizedLandmark,
    this.onTap,
  });

  final ExcursionVm excursion;
  final String languageCode;
  final int seed;
  final PlaceVm? localizedLandmark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = _formatDuration(context, excursion.durationMinutes);
    final meta = _formatMeta(context, excursion, duration);
    final price = _formatPrice(context, excursion);
    final category = _categoryLabel(l10n, excursion.categorySlug);
    final displayTitle = localizedExcursionTitle(
      languageCode: languageCode,
      excursion: excursion,
      place: localizedLandmark,
      fallback: category,
    );
    final location = _primaryLocation(excursion, displayTitle, category);
    final semanticLabel = [
      displayTitle,
      if (location.isNotEmpty) location,
      price,
      if (meta.isNotEmpty) meta,
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFF251A10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ExcursionCoverArt(
                        seed: seed,
                        categorySlug: excursion.categorySlug,
                        imageUrl: resolveExcursionCoverUrl(excursion),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (location.isNotEmpty) ...[
                              Text(
                                location.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 7),
                            ],
                            Text(
                              displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFEADCD0),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                height: 1.16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              meta.isEmpty ? category : meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFB5A394),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
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
      ),
    );
  }

  String _primaryLocation(
    ExcursionVm excursion,
    String displayTitle,
    String fallbackLabel,
  ) {
    final city = excursion.cityName?.trim();
    if (city != null && city.isNotEmpty && !_isSameLabel(city, displayTitle)) {
      return city;
    }

    final landmark = localizedExcursionLandmarkName(
      languageCode: languageCode,
      excursion: excursion,
      place: localizedLandmark,
    ).trim();
    if (landmark.isNotEmpty && !_isSameLabel(landmark, displayTitle)) {
      return landmark;
    }

    if (fallbackLabel.trim().isNotEmpty &&
        !_isSameLabel(fallbackLabel, displayTitle)) {
      return fallbackLabel.trim();
    }

    return 'Inflap';
  }

  bool _isSameLabel(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes <= 0) return '';

    final l10n = AppLocalizations.of(context)!;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours > 0 && remainder > 0) {
      return '$hours ${l10n.excursionsDurationHourShort} '
          '$remainder ${l10n.excursionsDurationMinuteShort}';
    }
    if (hours > 0) {
      return '$hours ${l10n.excursionsDurationHourShort}';
    }
    return '$minutes ${l10n.excursionsDurationMinuteShort}';
  }

  String _formatMeta(
    BuildContext context,
    ExcursionVm excursion,
    String duration,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[
      if (duration.trim().isNotEmpty) duration.trim(),
      if (excursion.publishedOffersCount > 0)
        l10n.excursionsOffersCount(excursion.publishedOffersCount),
    ];
    return parts.join(' • ');
  }

  String _formatPrice(BuildContext context, ExcursionVm excursion) {
    final l10n = AppLocalizations.of(context)!;
    final price = _displayPriceFor(excursion);
    if (price.amount <= 0) return l10n.excursionsFreePrice;

    final formatted = formatAppMoney(
      amount: price.amount,
      currency: price.currency,
      localeName: Localizations.localeOf(context).toString(),
      useListCurrencyFormat: true,
    );
    return l10n.excursionsPriceFrom(formatted);
  }

  _ExcursionCardPrice _displayPriceFor(ExcursionVm excursion) {
    return _excursionCardPriceFor(excursion);
  }

  String _categoryLabel(AppLocalizations l10n, String? categorySlug) {
    return localizedExcursionCategoryLabel(l10n, categorySlug);
  }
}

_ExcursionCardPrice _excursionCardPriceFor(ExcursionVm excursion) {
  final offers = excursion.offers;
  if (offers.isEmpty) {
    return _ExcursionCardPrice(
      amount: excursion.priceAmount,
      currency: excursion.currency,
    );
  }

  var selected = _ExcursionCardPrice(
    amount: offers.first.priceAmount,
    currency: offers.first.currency,
  );
  for (final offer in offers.skip(1)) {
    if (offer.priceAmount < selected.amount) {
      selected = _ExcursionCardPrice(
        amount: offer.priceAmount,
        currency: offer.currency,
      );
    }
  }
  return selected;
}

class _ExcursionCardPrice {
  const _ExcursionCardPrice({required this.amount, required this.currency});

  final double amount;
  final String currency;
}

class _ExcursionCoverArt extends StatelessWidget {
  const _ExcursionCoverArt({
    required this.seed,
    required this.categorySlug,
    this.imageUrl,
  });

  final int seed;
  final String? categorySlug;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(categorySlug, seed);
    final resolvedImageUrl = imageUrl?.trim() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (resolvedImageUrl.isNotEmpty)
          Image.network(
            resolvedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _GeneratedExcursionCover(palette: palette, seed: seed),
          )
        else
          _GeneratedExcursionCover(palette: palette, seed: seed),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 3),
                  Text(
                    '4.9',
                    style: TextStyle(
                      color: Color(0xFFF4EEE8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _ExcursionCoverPalette _paletteFor(String? categorySlug, int seed) {
    switch (categorySlug?.toLowerCase()) {
      case 'cultural':
        return const _ExcursionCoverPalette(
          sky: Color(0xFF52B8D9),
          haze: Color(0xFFE1C071),
          ground: Color(0xFF8A5A2B),
          ridge: Color(0xFFB67A33),
          ridgeDark: Color(0xFF5A3419),
        );
      case 'culinary':
        return const _ExcursionCoverPalette(
          sky: Color(0xFFFFB13B),
          haze: Color(0xFF8C4022),
          ground: Color(0xFF30160C),
          ridge: Color(0xFFE07A22),
          ridgeDark: Color(0xFF6D2812),
        );
      case 'wellness':
        return const _ExcursionCoverPalette(
          sky: Color(0xFF7DD2C7),
          haze: Color(0xFF4F8E65),
          ground: Color(0xFF143B29),
          ridge: Color(0xFF2E7D4C),
          ridgeDark: Color(0xFF10291E),
        );
      default:
        final variants = [
          const _ExcursionCoverPalette(
            sky: Color(0xFF43A9DF),
            haze: Color(0xFFBFE6F3),
            ground: Color(0xFF143E23),
            ridge: Color(0xFF2D8437),
            ridgeDark: Color(0xFF102E19),
          ),
          const _ExcursionCoverPalette(
            sky: Color(0xFFF7A541),
            haze: Color(0xFFD17618),
            ground: Color(0xFF7D3508),
            ridge: Color(0xFF9B4C08),
            ridgeDark: Color(0xFF4C2206),
          ),
        ];
        return variants[seed % variants.length];
    }
  }
}

class _GeneratedExcursionCover extends StatelessWidget {
  const _GeneratedExcursionCover({required this.palette, required this.seed});

  final _ExcursionCoverPalette palette;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.sky, palette.haze, palette.ground],
            ),
          ),
        ),
        CustomPaint(painter: _ExcursionCoverPainter(palette, seed)),
      ],
    );
  }
}

class _ExcursionCoverPainter extends CustomPainter {
  const _ExcursionCoverPainter(this.palette, this.seed);

  final _ExcursionCoverPalette palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final ridgePaint = Paint()..color = palette.ridge;
    final ridgeDarkPaint = Paint()..color = palette.ridgeDark;
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.86);

    final offset = (seed % 4) * size.width * 0.05;
    final firstRidge = Path()
      ..moveTo(-size.width * 0.1, size.height)
      ..lineTo(size.width * 0.32 + offset, size.height * 0.42)
      ..lineTo(size.width * 0.78 + offset, size.height)
      ..close();

    final secondRidge = Path()
      ..moveTo(size.width * 0.22 - offset, size.height)
      ..lineTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 1.12, size.height)
      ..close();

    final snowCap = Path()
      ..moveTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 0.63 - offset, size.height * 0.48)
      ..lineTo(size.width * 0.78 - offset, size.height * 0.44)
      ..close();

    canvas
      ..drawPath(firstRidge, ridgeDarkPaint)
      ..drawPath(secondRidge, ridgePaint)
      ..drawPath(snowCap, snowPaint);

    final sunPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.54, size.height * 0.28),
              radius: math.min(size.width, size.height) * 0.2,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.28),
      math.min(size.width, size.height) * 0.2,
      sunPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExcursionCoverPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.seed != seed;
  }
}

class _ExcursionCoverPalette {
  const _ExcursionCoverPalette({
    required this.sky,
    required this.haze,
    required this.ground,
    required this.ridge,
    required this.ridgeDark,
  });

  final Color sky;
  final Color haze;
  final Color ground;
  final Color ridge;
  final Color ridgeDark;
}

class _ExcursionsLoadingGrid extends StatelessWidget {
  const _ExcursionsLoadingGrid({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        26,
        horizontalPadding,
        28,
      ),
      sliver: SliverGrid.builder(
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: _gridAspectRatio(context),
        ),
        itemBuilder: (context, index) {
          return const _ExcursionsSkeletonCard();
        },
      ),
    );
  }
}

class _ExcursionsSkeletonCard extends StatelessWidget {
  const _ExcursionsSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF251A10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SkeletonBlock()),
            SizedBox(height: 14),
            _SkeletonLine(width: 84, height: 10),
            SizedBox(height: 10),
            _SkeletonLine(width: double.infinity, height: 18),
            SizedBox(height: 8),
            _SkeletonLine(width: 92, height: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ExcursionsEmptyState extends StatelessWidget {
  const _ExcursionsEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA99586),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
