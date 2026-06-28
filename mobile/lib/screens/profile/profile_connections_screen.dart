import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/chat_api.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/chat/utils/chat_presence_status.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/profile_follower_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

RelativeRect? _connectionMenuPositionFor(BuildContext buttonContext) {
  final overlay = Overlay.of(buttonContext).context.findRenderObject();
  final buttonBox = buttonContext.findRenderObject();
  if (overlay is! RenderBox || buttonBox is! RenderBox) return null;

  final buttonTopRight = buttonBox.localToGlobal(
    Offset(buttonBox.size.width, 0),
    ancestor: overlay,
  );
  final buttonBottomRight = buttonBox.localToGlobal(
    buttonBox.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );
  return RelativeRect.fromLTRB(
    buttonTopRight.dx,
    buttonTopRight.dy,
    overlay.size.width - buttonBottomRight.dx,
    overlay.size.height - buttonBottomRight.dy,
  );
}

class ProfileConnectionsScreen extends StatefulWidget {
  const ProfileConnectionsScreen({super.key});

  @override
  State<ProfileConnectionsScreen> createState() =>
      _ProfileConnectionsScreenState();
}

class _ProfileConnectionsScreenState extends State<ProfileConnectionsScreen>
    with SingleTickerProviderStateMixin {
  static const _pageSize = 20;

  final ProfileApi _profileApi = ProfileApi();
  final ChatApi _chatApi = ChatApi();
  final TextEditingController _searchController = TextEditingController();
  final _friendsData = _ConnectionTabData();
  final _followingData = _ConnectionTabData();
  final _requestsPreviewData = _ConnectionTabData();

  late final TabController _tabController;
  Timer? _searchDebounce;
  _ConnectionSortMode _sortMode = _ConnectionSortMode.recent;
  _ConnectionSortDirection _sortDirection = _ConnectionSortDirection.desc;
  _ConnectionFilters _filters = const _ConnectionFilters();
  String? _actionUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_handleSearchChanged);
    _friendsData.scrollController.addListener(
      () => _handleScroll(_ConnectionTab.friends),
    );
    _followingData.scrollController.addListener(
      () => _handleScroll(_ConnectionTab.following),
    );
    unawaited(_reloadAll());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _tabController.dispose();
    _friendsData.dispose();
    _followingData.dispose();
    _requestsPreviewData.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => unawaited(_reloadAll()),
    );
  }

  void _handleScroll(_ConnectionTab tab) {
    final data = _dataFor(tab);
    if (!data.scrollController.hasClients || data.loading || data.loadingMore) {
      return;
    }

    final position = data.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      unawaited(_loadMore(tab));
    }
  }

  _ConnectionTabData _dataFor(_ConnectionTab tab) {
    return switch (tab) {
      _ConnectionTab.friends => _friendsData,
      _ConnectionTab.following => _followingData,
    };
  }

  Future<void> _reloadAll() async {
    await Future.wait([
      _reloadTab(_ConnectionTab.friends),
      _reloadTab(_ConnectionTab.following),
      _reloadFriendRequestPreview(),
    ]);
  }

  Future<void> _reloadFriendRequestPreview() async {
    final requestEpoch = ++_requestsPreviewData.requestEpoch;
    setState(() {
      _requestsPreviewData.loading = true;
      _requestsPreviewData.loadingMore = false;
      _requestsPreviewData.errorText = null;
      _requestsPreviewData.nextOffset = null;
      _requestsPreviewData.items = const [];
    });

    try {
      final page = await _profileApi.getMyIncomingFriendRequests(
        limit: 1,
        offset: 0,
      );
      if (!mounted || requestEpoch != _requestsPreviewData.requestEpoch) {
        return;
      }

      setState(() {
        _requestsPreviewData.items = page.items;
        _requestsPreviewData.nextOffset = page.nextOffset;
      });
    } catch (_) {
      if (!mounted || requestEpoch != _requestsPreviewData.requestEpoch) {
        return;
      }
      setState(() => _requestsPreviewData.errorText = '');
    } finally {
      if (mounted && requestEpoch == _requestsPreviewData.requestEpoch) {
        setState(() => _requestsPreviewData.loading = false);
      }
    }
  }

  Future<void> _reloadTab(_ConnectionTab tab) async {
    final data = _dataFor(tab);
    final requestEpoch = ++data.requestEpoch;
    setState(() {
      data.loading = true;
      data.loadingMore = false;
      data.errorText = null;
      data.nextOffset = null;
      data.items = const [];
    });

    try {
      final page = await _fetchPage(tab, offset: 0);
      if (!mounted || requestEpoch != data.requestEpoch) return;

      setState(() {
        data.items = page.items;
        data.nextOffset = page.nextOffset;
      });
    } catch (e) {
      if (!mounted || requestEpoch != data.requestEpoch) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        data.errorText = e is DioException
            ? DioErrorMapper.toMessage(e)
            : l10n.profileConnectionsLoadFailed;
      });
    } finally {
      if (mounted && requestEpoch == data.requestEpoch) {
        setState(() => data.loading = false);
      }
    }
  }

  Future<void> _loadMore(_ConnectionTab tab) async {
    final data = _dataFor(tab);
    final offset = data.nextOffset;
    if (offset == null) return;

    final requestEpoch = data.requestEpoch;
    setState(() => data.loadingMore = true);

    try {
      final page = await _fetchPage(tab, offset: offset);
      if (!mounted || requestEpoch != data.requestEpoch) return;

      final merged = <String, ProfileFollowerVm>{
        for (final item in data.items) item.userId: item,
      };
      for (final item in page.items) {
        merged[item.userId] = item;
      }

      setState(() {
        data.items = merged.values.toList(growable: false);
        data.nextOffset = page.nextOffset;
      });
    } catch (_) {
      if (!mounted || requestEpoch != data.requestEpoch) return;
    } finally {
      if (mounted && requestEpoch == data.requestEpoch) {
        setState(() => data.loadingMore = false);
      }
    }
  }

  Future<ProfileFollowersPageVm> _fetchPage(
    _ConnectionTab tab, {
    required int offset,
  }) {
    final sort = _sortMode.wireName;
    final sortDirection = _sortDirection.wireName;
    final query = _searchController.text;

    return switch (tab) {
      _ConnectionTab.friends => _profileApi.getMyFriends(
        limit: _pageSize,
        offset: offset,
        query: query,
        sort: sort,
        sortDirection: sortDirection,
        onlineOnly: _filters.onlineOnly,
      ),
      _ConnectionTab.following => _profileApi.getMyFollowing(
        limit: _pageSize,
        offset: offset,
        query: query,
        sort: sort,
        sortDirection: sortDirection,
        onlineOnly: _filters.onlineOnly,
      ),
    };
  }

  void _handleSortChanged(_ConnectionSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortDirection = _sortDirection.toggled;
      } else {
        _sortMode = mode;
        _sortDirection = mode.defaultDirection;
      }
    });
    unawaited(_reloadAll());
  }

  Future<void> _showFilters() async {
    final selectedFilters = await showAppModalBottomSheet<_ConnectionFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => _ConnectionFiltersSheet(initialFilters: _filters),
    );

    if (selectedFilters == null || !mounted) return;
    setState(() => _filters = selectedFilters);
    unawaited(_reloadAll());
  }

  void _openProfile(ProfileFollowerVm user) {
    final userId = user.userId.trim();
    if (userId.isEmpty) return;

    final currentUserId = context
        .read<SessionProvider>()
        .profile
        ?.userId
        .trim();
    if (currentUserId != null && currentUserId == userId) {
      context.push('/profile');
      return;
    }

    context.push('/users/${Uri.encodeComponent(userId)}/profile');
  }

  Future<void> _showUserActions(
    BuildContext buttonContext,
    ProfileFollowerVm user,
    _ConnectionTab tab,
  ) async {
    final position = _connectionMenuPositionFor(buttonContext);
    if (position == null) return;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final action = await showMenu<_ConnectionAction>(
      context: context,
      position: position,
      color: AppPalette.surfaceRaised,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(18)),
      items: [
        PopupMenuItem(
          value: tab == _ConnectionTab.friends
              ? _ConnectionAction.removeFriend
              : _ConnectionAction.unfollow,
          child: _ConnectionPopupActionRow(
            icon: tab == _ConnectionTab.friends
                ? Icons.person_remove_alt_1_rounded
                : Icons.person_off_rounded,
            label: tab == _ConnectionTab.friends
                ? l10n.profileRemoveFriendAction
                : l10n.profileUnfollowAction,
            destructive: true,
          ),
        ),
        PopupMenuItem(
          value: _ConnectionAction.message,
          child: _ConnectionPopupActionRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.profileMessageAction,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ConnectionAction.removeFriend:
        await _removeFriend(user);
      case _ConnectionAction.unfollow:
        await _unfollowUser(user);
      case _ConnectionAction.message:
        await _openDirectChat(user);
      case _ConnectionAction.acceptFriendRequest:
      case _ConnectionAction.declineFriendRequest:
        break;
    }
  }

  Future<void> _showFriendRequestActions(
    BuildContext buttonContext,
    ProfileFollowerVm user,
  ) async {
    final position = _connectionMenuPositionFor(buttonContext);
    if (position == null) return;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final action = await showMenu<_ConnectionAction>(
      context: context,
      position: position,
      color: AppPalette.surfaceRaised,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(18)),
      items: [
        PopupMenuItem(
          value: _ConnectionAction.acceptFriendRequest,
          child: _ConnectionPopupActionRow(
            icon: Icons.person_add_alt_1_rounded,
            label: l10n.profileFriendRequestAcceptAction,
          ),
        ),
        PopupMenuItem(
          value: _ConnectionAction.declineFriendRequest,
          child: _ConnectionPopupActionRow(
            icon: Icons.person_remove_alt_1_rounded,
            label: l10n.profileFriendRequestDeclineAction,
            destructive: true,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ConnectionAction.acceptFriendRequest:
        await _resolveFriendRequest(user, accept: true);
      case _ConnectionAction.declineFriendRequest:
        await _resolveFriendRequest(user, accept: false);
      case _ConnectionAction.removeFriend:
      case _ConnectionAction.unfollow:
      case _ConnectionAction.message:
        break;
    }
  }

  Future<void> _resolveFriendRequest(
    ProfileFollowerVm user, {
    required bool accept,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _actionUserId = user.userId);

    try {
      if (accept) {
        await _profileApi.acceptFriendRequest(user.userId);
      } else {
        await _profileApi.declineFriendRequest(user.userId);
      }
      if (!mounted) return;
      setState(() => _requestsPreviewData.remove(user.userId));
      if (accept) {
        unawaited(_reloadTab(_ConnectionTab.friends));
      }
      unawaited(_reloadFriendRequestPreview());
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileFriendshipUpdateFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) setState(() => _actionUserId = null);
    }
  }

  Future<void> _handleFriendRequestResolved({required bool accepted}) async {
    await _reloadFriendRequestPreview();
    if (accepted) {
      await _reloadTab(_ConnectionTab.friends);
    }
  }

  Future<void> _showFriendRequestsSheet() async {
    await showAppModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => _FriendRequestsSheet(
        profileApi: _profileApi,
        onOpenProfile: _openProfile,
        onRequestResolved: _handleFriendRequestResolved,
      ),
    );
  }

  Future<void> _removeFriend(ProfileFollowerVm user) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _actionUserId = user.userId);

    try {
      await _profileApi.removeFriend(user.userId);
      if (!mounted) return;
      setState(() => _friendsData.remove(user.userId));
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileFriendshipUpdateFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) setState(() => _actionUserId = null);
    }
  }

  Future<void> _unfollowUser(ProfileFollowerVm user) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _actionUserId = user.userId);

    try {
      await _profileApi.unfollowUser(user.userId);
      if (!mounted) return;
      setState(() => _followingData.remove(user.userId));
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileFollowUpdateFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) setState(() => _actionUserId = null);
    }
  }

  Future<void> _openDirectChat(ProfileFollowerVm user) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _actionUserId = user.userId);

    try {
      final conversationId = await _chatApi.createDirectConversation(
        user.userId,
      );
      if (!mounted) return;
      context.push('/chats/$conversationId');
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileMessageOpenFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) setState(() => _actionUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppPalette.backgroundWarm,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: _ConnectionHeader(title: l10n.profileConnectionsTitle),
                ),
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(18, 20, 18, 0),
                  child: AppListSearchField(
                    controller: _searchController,
                    hintText: l10n.profileConnectionsSearchHint,
                    filterTooltip: l10n.myActivitiesFilterButton,
                    activeFilterCount: _filters.activeCount,
                    showClearButton: true,
                    onFilterTap: _showFilters,
                  ),
                ),
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(18, 12, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppInlineSortRow<_ConnectionSortMode>(
                      label: l10n.excursionsSortLabel,
                      options: [
                        for (final mode in _ConnectionSortMode.values)
                          AppInlineSortOption(
                            value: mode,
                            label: mode.label(l10n),
                          ),
                      ],
                      selectedValue: _sortMode,
                      isAscending:
                          _sortDirection == _ConnectionSortDirection.asc,
                      onSelected: _handleSortChanged,
                    ),
                  ),
                ),
                _FriendRequestsPreviewSection(
                  data: _requestsPreviewData,
                  actionUserId: _actionUserId,
                  onViewAll: _showFriendRequestsSheet,
                  onTap: _openProfile,
                  onActionsTap: _showFriendRequestActions,
                ),
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _ConnectionTabBar(
                    controller: _tabController,
                    friendsLabel: l10n.profileConnectionsFriendsTab,
                    followingLabel: l10n.profileConnectionsFollowingTab,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ConnectionListView(
                        tab: _ConnectionTab.friends,
                        data: _friendsData,
                        actionUserId: _actionUserId,
                        onRefresh: () => _reloadTab(_ConnectionTab.friends),
                        onTap: _openProfile,
                        onActionsTap: _showUserActions,
                      ),
                      _ConnectionListView(
                        tab: _ConnectionTab.following,
                        data: _followingData,
                        actionUserId: _actionUserId,
                        onRefresh: () => _reloadTab(_ConnectionTab.following),
                        onTap: _openProfile,
                        onActionsTap: _showUserActions,
                      ),
                    ],
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

class _ConnectionTabData {
  final ScrollController scrollController = ScrollController();
  List<ProfileFollowerVm> items = const [];
  bool loading = true;
  bool loadingMore = false;
  String? errorText;
  int? nextOffset;
  int requestEpoch = 0;

  void remove(String userId) {
    items = items
        .where((item) => item.userId != userId)
        .toList(growable: false);
  }

  void dispose() {
    scrollController.dispose();
  }
}

enum _ConnectionTab { friends, following }

enum _ConnectionAction {
  removeFriend,
  unfollow,
  message,
  acceptFriendRequest,
  declineFriendRequest,
}

enum _ConnectionSortDirection {
  asc('asc'),
  desc('desc');

  const _ConnectionSortDirection(this.wireName);

  final String wireName;

  _ConnectionSortDirection get toggled => this == asc ? desc : asc;
}

enum _ConnectionSortMode {
  recent('recent', _ConnectionSortDirection.desc),
  name('name', _ConnectionSortDirection.asc);

  const _ConnectionSortMode(this.wireName, this.defaultDirection);

  final String wireName;
  final _ConnectionSortDirection defaultDirection;

  String label(AppLocalizations l10n) {
    return switch (this) {
      recent => l10n.profileConnectionsSortRecent,
      name => l10n.profileConnectionsSortName,
    };
  }
}

class _ConnectionFilters {
  const _ConnectionFilters({this.onlineOnly = false});

  final bool onlineOnly;

  int get activeCount => onlineOnly ? 1 : 0;

  _ConnectionFilters copyWith({bool? onlineOnly}) {
    return _ConnectionFilters(onlineOnly: onlineOnly ?? this.onlineOnly);
  }
}

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppPalette.surfaceRaised,
            foregroundColor: AppPalette.textPrimary,
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const AppTextStyle(
              color: AppPalette.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionTabBar extends StatelessWidget {
  const _ConnectionTabBar({
    required this.controller,
    required this.friendsLabel,
    required this.followingLabel,
  });

  final TabController controller;
  final String friendsLabel;
  final String followingLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppPalette.transparent,
        labelColor: AppPalette.textPrimary,
        unselectedLabelColor: AppPalette.orangeMuted04,
        labelStyle: const AppTextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
        unselectedLabelStyle: const AppTextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        indicator: AppBoxDecoration(
          color: AppPalette.primary,
          borderRadius: AppBorderRadius.circular(16),
          border: Border.all(color: AppPalette.primary),
        ),
        tabs: [
          Tab(text: friendsLabel),
          Tab(text: followingLabel),
        ],
      ),
    );
  }
}

class _ConnectionListView extends StatelessWidget {
  const _ConnectionListView({
    required this.tab,
    required this.data,
    required this.actionUserId,
    required this.onRefresh,
    required this.onTap,
    required this.onActionsTap,
  });

  final _ConnectionTab tab;
  final _ConnectionTabData data;
  final String? actionUserId;
  final RefreshCallback onRefresh;
  final ValueChanged<ProfileFollowerVm> onTap;
  final Future<void> Function(
    BuildContext buttonContext,
    ProfileFollowerVm user,
    _ConnectionTab tab,
  )
  onActionsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      color: AppPalette.primary,
      backgroundColor: AppPalette.surfaceRaised,
      onRefresh: onRefresh,
      child: Builder(
        builder: (context) {
          if (data.loading) {
            return ListView(
              controller: data.scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: const [
                SizedBox(height: 180),
                Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppPalette.primary,
                    ),
                  ),
                ),
              ],
            );
          }

          if (data.errorText != null && data.items.isEmpty) {
            return ListView(
              controller: data.scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const AppEdgeInsets.fromLTRB(24, 110, 24, 24),
              children: [
                _ConnectionStateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.profileConnectionsLoadFailed,
                  subtitle: data.errorText!,
                ),
              ],
            );
          }

          if (data.items.isEmpty) {
            return ListView(
              controller: data.scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const AppEdgeInsets.fromLTRB(24, 110, 24, 24),
              children: [
                _ConnectionStateMessage(
                  icon: Icons.people_outline_rounded,
                  title: tab == _ConnectionTab.friends
                      ? l10n.profileConnectionsFriendsEmptyTitle
                      : l10n.profileConnectionsFollowingEmptyTitle,
                  subtitle: tab == _ConnectionTab.friends
                      ? l10n.profileConnectionsFriendsEmptySubtitle
                      : l10n.profileConnectionsFollowingEmptySubtitle,
                ),
              ],
            );
          }

          return ListView.separated(
            controller: data.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const AppEdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: data.items.length + (data.loadingMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= data.items.length) {
                return const Padding(
                  padding: AppEdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppPalette.primary,
                      ),
                    ),
                  ),
                );
              }

              final user = data.items[index];
              return _ConnectionUserRow(
                user: user,
                busy: actionUserId == user.userId,
                onTap: () => onTap(user),
                onActionsTap: (buttonContext) =>
                    onActionsTap(buttonContext, user, tab),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendRequestsPreviewSection extends StatelessWidget {
  const _FriendRequestsPreviewSection({
    required this.data,
    required this.actionUserId,
    required this.onViewAll,
    required this.onTap,
    required this.onActionsTap,
  });

  final _ConnectionTabData data;
  final String? actionUserId;
  final VoidCallback onViewAll;
  final ValueChanged<ProfileFollowerVm> onTap;
  final Future<void> Function(
    BuildContext buttonContext,
    ProfileFollowerVm user,
  )
  onActionsTap;

  @override
  Widget build(BuildContext context) {
    if ((data.loading && data.items.isEmpty) ||
        data.errorText != null ||
        data.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final user = data.items.first;

    return Padding(
      padding: const AppEdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileConnectionsFriendRequestsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (data.items.isNotEmpty)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.primary,
                    padding: const AppEdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.profileConnectionsFriendRequestsViewAll,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const AppTextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ConnectionUserRow(
            user: user,
            busy: actionUserId == user.userId,
            onTap: () => onTap(user),
            onActionsTap: (buttonContext) => onActionsTap(buttonContext, user),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestsSheet extends StatefulWidget {
  const _FriendRequestsSheet({
    required this.profileApi,
    required this.onOpenProfile,
    required this.onRequestResolved,
  });

  final ProfileApi profileApi;
  final ValueChanged<ProfileFollowerVm> onOpenProfile;
  final Future<void> Function({required bool accepted}) onRequestResolved;

  @override
  State<_FriendRequestsSheet> createState() => _FriendRequestsSheetState();
}

class _FriendRequestsSheetState extends State<_FriendRequestsSheet> {
  static const _sheetPageSize = 20;

  final _requestsSheetData = _ConnectionTabData();
  String? _actionUserId;

  @override
  void initState() {
    super.initState();
    _requestsSheetData.scrollController.addListener(_handleScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _requestsSheetData.scrollController.removeListener(_handleScroll);
    _requestsSheetData.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_requestsSheetData.scrollController.hasClients ||
        _requestsSheetData.loading ||
        _requestsSheetData.loadingMore) {
      return;
    }

    final position = _requestsSheetData.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      unawaited(_loadMore());
    }
  }

  Future<void> _reload() async {
    final requestEpoch = ++_requestsSheetData.requestEpoch;
    setState(() {
      _requestsSheetData.loading = true;
      _requestsSheetData.loadingMore = false;
      _requestsSheetData.errorText = null;
      _requestsSheetData.nextOffset = null;
      _requestsSheetData.items = const [];
    });

    try {
      final page = await widget.profileApi.getMyIncomingFriendRequests(
        limit: _sheetPageSize,
        offset: 0,
      );
      if (!mounted || requestEpoch != _requestsSheetData.requestEpoch) return;
      setState(() {
        _requestsSheetData.items = page.items;
        _requestsSheetData.nextOffset = page.nextOffset;
      });
    } catch (e) {
      if (!mounted || requestEpoch != _requestsSheetData.requestEpoch) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _requestsSheetData.errorText = e is DioException
            ? DioErrorMapper.toMessage(e)
            : l10n.profileConnectionsLoadFailed;
      });
    } finally {
      if (mounted && requestEpoch == _requestsSheetData.requestEpoch) {
        setState(() => _requestsSheetData.loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    final offset = _requestsSheetData.nextOffset;
    if (offset == null) return;

    final requestEpoch = _requestsSheetData.requestEpoch;
    setState(() => _requestsSheetData.loadingMore = true);

    try {
      final page = await widget.profileApi.getMyIncomingFriendRequests(
        limit: _sheetPageSize,
        offset: offset,
      );
      if (!mounted || requestEpoch != _requestsSheetData.requestEpoch) return;

      final merged = <String, ProfileFollowerVm>{
        for (final item in _requestsSheetData.items) item.userId: item,
      };
      for (final item in page.items) {
        merged[item.userId] = item;
      }

      setState(() {
        _requestsSheetData.items = merged.values.toList(growable: false);
        _requestsSheetData.nextOffset = page.nextOffset;
      });
    } catch (_) {
      if (!mounted || requestEpoch != _requestsSheetData.requestEpoch) return;
    } finally {
      if (mounted && requestEpoch == _requestsSheetData.requestEpoch) {
        setState(() => _requestsSheetData.loadingMore = false);
      }
    }
  }

  Future<void> _showRequestActions(
    BuildContext buttonContext,
    ProfileFollowerVm user,
  ) async {
    final position = _connectionMenuPositionFor(buttonContext);
    if (position == null) return;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final action = await showMenu<_ConnectionAction>(
      context: context,
      position: position,
      color: AppPalette.surfaceRaised,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(18)),
      items: [
        PopupMenuItem(
          value: _ConnectionAction.acceptFriendRequest,
          child: _ConnectionPopupActionRow(
            icon: Icons.person_add_alt_1_rounded,
            label: l10n.profileFriendRequestAcceptAction,
          ),
        ),
        PopupMenuItem(
          value: _ConnectionAction.declineFriendRequest,
          child: _ConnectionPopupActionRow(
            icon: Icons.person_remove_alt_1_rounded,
            label: l10n.profileFriendRequestDeclineAction,
            destructive: true,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ConnectionAction.acceptFriendRequest:
        await _resolveRequest(user, accept: true);
      case _ConnectionAction.declineFriendRequest:
        await _resolveRequest(user, accept: false);
      case _ConnectionAction.removeFriend:
      case _ConnectionAction.unfollow:
      case _ConnectionAction.message:
        break;
    }
  }

  Future<void> _resolveRequest(
    ProfileFollowerVm user, {
    required bool accept,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _actionUserId = user.userId);

    try {
      if (accept) {
        await widget.profileApi.acceptFriendRequest(user.userId);
      } else {
        await widget.profileApi.declineFriendRequest(user.userId);
      }
      if (!mounted) return;
      setState(() => _requestsSheetData.remove(user.userId));
      await widget.onRequestResolved(accepted: accept);
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileFriendshipUpdateFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) setState(() => _actionUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppModalSheetFrame(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: const AppBoxDecoration(
            color: AppPalette.surface,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(24),
            ),
            border: Border(top: BorderSide(color: AppPalette.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.profileConnectionsFriendRequestsTitle,
                clearLabel: l10n.cancel,
                onClear: () => Navigator.of(context).maybePop(),
                height: 74,
                horizontalPadding: 22,
                titleFontSize: 18,
              ),
              Flexible(child: _buildContent(context, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (_requestsSheetData.loading) {
      return ListView(
        controller: _requestsSheetData.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 120),
          Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppPalette.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (_requestsSheetData.errorText != null &&
        _requestsSheetData.items.isEmpty) {
      return ListView(
        controller: _requestsSheetData.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const AppEdgeInsets.fromLTRB(24, 84, 24, 24),
        children: [
          _ConnectionStateMessage(
            icon: Icons.wifi_off_rounded,
            title: l10n.profileConnectionsLoadFailed,
            subtitle: _requestsSheetData.errorText!,
          ),
        ],
      );
    }

    if (_requestsSheetData.items.isEmpty) {
      return ListView(
        controller: _requestsSheetData.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const AppEdgeInsets.fromLTRB(24, 84, 24, 24),
        children: [
          _ConnectionStateMessage(
            icon: Icons.person_add_alt_1_rounded,
            title: l10n.profileConnectionsFriendRequestsEmptyTitle,
            subtitle: l10n.profileConnectionsFriendRequestsEmptySubtitle,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _requestsSheetData.scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const AppEdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount:
          _requestsSheetData.items.length +
          (_requestsSheetData.loadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _requestsSheetData.items.length) {
          return const Padding(
            padding: AppEdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppPalette.primary,
                ),
              ),
            ),
          );
        }

        final user = _requestsSheetData.items[index];
        return _ConnectionUserRow(
          user: user,
          busy: _actionUserId == user.userId,
          onTap: () => widget.onOpenProfile(user),
          onActionsTap: (buttonContext) =>
              _showRequestActions(buttonContext, user),
        );
      },
    );
  }
}

class _ConnectionUserRow extends StatelessWidget {
  const _ConnectionUserRow({
    required this.user,
    required this.busy,
    required this.onTap,
    required this.onActionsTap,
  });

  final ProfileFollowerVm user;
  final bool busy;
  final VoidCallback onTap;
  final Future<void> Function(BuildContext buttonContext) onActionsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nickname = user.nicknameOrFallback(l10n.chatUserFallbackName);
    final presence = chatPresenceStatusLabelForValues(
      l10n,
      isOnline: user.isOnline,
      lastSeenAt: user.lastSeenAt,
    );

    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(18),
        child: Ink(
          padding: const AppEdgeInsets.all(14),
          decoration: AppBoxDecoration(
            color: AppPalette.surfaceRaised,
            borderRadius: AppBorderRadius.circular(18),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              _ConnectionAvatar(user: user),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        if (user.isOnline) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const AppBoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPalette.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            presence,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: user.isOnline
                                  ? AppPalette.primary
                                  : AppPalette.orangeMuted04,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppPalette.primary,
                  ),
                )
              else
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    onPressed: () => unawaited(onActionsTap(buttonContext)),
                    style: IconButton.styleFrom(
                      foregroundColor: AppPalette.primary,
                      minimumSize: const Size(42, 42),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionAvatar extends StatelessWidget {
  const _ConnectionAvatar({required this.user});

  final ProfileFollowerVm user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolvePublicFileContentUrl(user.avatarFileId ?? '');
    return Container(
      width: 54,
      height: 54,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: AppPalette.warmInk27,
          child: imageUrl == null
              ? _ConnectionAvatarFallback(initials: user.initials)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ConnectionAvatarFallback(initials: user.initials),
                ),
        ),
      ),
    );
  }
}

class _ConnectionAvatarFallback extends StatelessWidget {
  const _ConnectionAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.warmSurface78, AppPalette.warmInk27],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const AppTextStyle(
            color: AppPalette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ConnectionStateMessage extends StatelessWidget {
  const _ConnectionStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppPalette.orangeMuted04, size: 42),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const AppTextStyle(
            color: AppPalette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const AppTextStyle(
            color: AppPalette.orangeMuted04,
            fontSize: 14,
            height: 1.42,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConnectionPopupActionRow extends StatelessWidget {
  const _ConnectionPopupActionRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppPalette.danger : AppPalette.textPrimary;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionFiltersSheet extends StatefulWidget {
  const _ConnectionFiltersSheet({required this.initialFilters});

  final _ConnectionFilters initialFilters;

  @override
  State<_ConnectionFiltersSheet> createState() =>
      _ConnectionFiltersSheetState();
}

class _ConnectionFiltersSheetState extends State<_ConnectionFiltersSheet> {
  late _ConnectionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _clear() {
    setState(() => _filters = const _ConnectionFilters());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AppModalSheetFrame(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: const AppBoxDecoration(
            color: AppPalette.surface,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(24),
            ),
            border: Border(top: BorderSide(color: AppPalette.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.profileConnectionsFiltersTitle,
                clearLabel: l10n.excursionsFiltersClear,
                onClear: _clear,
                height: 74,
                horizontalPadding: 22,
                titleFontSize: 18,
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const AppEdgeInsets.fromLTRB(22, 26, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ConnectionFilterToggle(
                        icon: Icons.circle_rounded,
                        title: l10n.profileConnectionsFilterOnlineOnly,
                        subtitle:
                            l10n.profileConnectionsFilterOnlineOnlySubtitle,
                        value: _filters.onlineOnly,
                        onChanged: (value) {
                          setState(() {
                            _filters = _filters.copyWith(onlineOnly: value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppEdgeInsets.fromLTRB(22, 0, 22, bottomInset + 18),
                child: AppFilterApplyButton(
                  label: l10n.profileConnectionsFiltersShowResults,
                  onTap: () => Navigator.of(context).pop(_filters),
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

class _ConnectionFilterToggle extends StatelessWidget {
  const _ConnectionFilterToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppBorderRadius.circular(18),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: AppPalette.warmSurface28,
          borderRadius: AppBorderRadius.circular(18),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: AppPalette.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const AppTextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const AppTextStyle(
                        color: AppPalette.orangeSoft17,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                activeThumbColor: AppPalette.primary,
                activeTrackColor: AppPalette.primary.withValues(alpha: 0.32),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
