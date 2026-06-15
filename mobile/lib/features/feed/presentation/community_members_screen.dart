import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/community_moderation_api.dart';
import '../models/community_moderation_vm.dart';

class CommunityMembersScreen extends StatefulWidget {
  const CommunityMembersScreen({
    super.key,
    required this.communityId,
    this.communityTitle,
    this.moderationApi,
  });

  final String communityId;
  final String? communityTitle;
  final CommunityModerationApi? moderationApi;

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  static const _pageLimit = 20;
  static const _defaultStatus = 'ACTIVE';

  late final CommunityModerationApi _moderationApi =
      widget.moderationApi ?? CommunityModerationApi();
  late final ScrollController _scrollController;

  var _isLoading = true;
  var _isLoadingMore = false;
  var _hasMore = false;
  var _requestGeneration = 0;
  Object? _error;
  String? _roleFilter;
  String _statusFilter = _defaultStatus;
  List<CommunityMemberVm> _members = const [];
  Set<String> _updatingUserIds = const {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_maybeLoadMore);
    _loadMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({bool append = false}) async {
    if (append && (_isLoading || _isLoadingMore || !_hasMore)) {
      return;
    }

    final generation = ++_requestGeneration;
    final offset = append ? _members.length : 0;

    if (append && mounted) {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _hasMore = false;
        _error = null;
        _members = const [];
      });
    }

    try {
      final page = await _moderationApi.listMembers(
        communityId: widget.communityId,
        role: _roleFilter,
        status: _statusFilter,
        limit: _pageLimit,
        offset: offset,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _members = append ? [..._members, ...page.items] : page.items;
        _hasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 640) {
      return;
    }
    _loadMembers(append: true);
  }

  void _setRoleFilter(String? role) {
    if (_roleFilter == role) {
      return;
    }
    setState(() {
      _roleFilter = role;
    });
    _loadMembers();
  }

  void _setStatusFilter(String status) {
    if (_statusFilter == status) {
      return;
    }
    setState(() {
      _statusFilter = status;
    });
    _loadMembers();
  }

  bool _matchesCurrentFilters(CommunityMembershipVm membership) {
    final roleMatches =
        _roleFilter == null ||
        _roleFilter!.isEmpty ||
        membership.role == _roleFilter;
    return roleMatches && membership.status == _statusFilter;
  }

  void _applyMembershipUpdate({
    required String userId,
    required CommunityMembershipVm membership,
  }) {
    final updatedMembers = <CommunityMemberVm>[];
    for (final item in _members) {
      if (item.userId != userId) {
        updatedMembers.add(item);
        continue;
      }
      if (_matchesCurrentFilters(membership)) {
        updatedMembers.add(
          item.copyWith(
            role: membership.role,
            status: membership.status,
            updatedAt: membership.updatedAt,
          ),
        );
      }
    }
    _members = updatedMembers;
  }

  Future<void> _showRoleSheet(CommunityMemberVm member) async {
    final selectedRole = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.communityMembersChangeRoleAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in _roleOptions(l10n))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.label,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: member.role == option.value
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option.value),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selectedRole == null || selectedRole == member.role || !mounted) {
      return;
    }
    await _updateRole(member, selectedRole);
  }

  Future<void> _showRoleHistorySheet(CommunityMemberVm member) async {
    final userId = member.userId.trim();
    if (userId.isEmpty) {
      return;
    }

    final historyFuture = _moderationApi.listMemberRoleChanges(
      communityId: widget.communityId,
      userId: userId,
      limit: 20,
      offset: 0,
    );

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return _RoleHistorySheet(member: member, historyFuture: historyFuture);
      },
    );
  }

  Future<void> _showStatusSheet(CommunityMemberVm member) async {
    final selectedStatus = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.communityMembersChangeStatusAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in _statusActionOptions(l10n))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color: option.isDestructive
                            ? Colors.redAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: member.status == option.value
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option.value),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selectedStatus == null || selectedStatus == member.status || !mounted) {
      return;
    }
    await _updateStatus(member, selectedStatus);
  }

  Future<void> _updateRole(CommunityMemberVm member, String role) async {
    final userId = member.userId.trim();
    if (userId.isEmpty || _updatingUserIds.contains(userId)) {
      return;
    }

    setState(() {
      _updatingUserIds = {..._updatingUserIds, userId};
    });

    try {
      final membership = await _moderationApi.updateMemberRole(
        communityId: widget.communityId,
        userId: userId,
        role: role,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _applyMembershipUpdate(userId: userId, membership: membership);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.communityMembersRoleUpdatedMessage,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.communityMembersRoleUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingUserIds = {
            for (final id in _updatingUserIds)
              if (id != userId) id,
          };
        });
      }
    }
  }

  Future<void> _updateStatus(CommunityMemberVm member, String status) async {
    final userId = member.userId.trim();
    if (userId.isEmpty || _updatingUserIds.contains(userId)) {
      return;
    }

    setState(() {
      _updatingUserIds = {..._updatingUserIds, userId};
    });

    try {
      final membership = await _moderationApi.updateMemberStatus(
        communityId: widget.communityId,
        userId: userId,
        status: status,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _applyMembershipUpdate(userId: userId, membership: membership);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.communityMembersStatusUpdatedMessage,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.communityMembersStatusUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingUserIds = {
            for (final id in _updatingUserIds)
              if (id != userId) id,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final communityTitle = (widget.communityTitle ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          l10n.communityMembersTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(34),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                communityTitle.isNotEmpty
                    ? communityTitle
                    : l10n.communityMembersSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => _loadMembers(),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _members.isEmpty) {
      return const _MembersStateList(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null && _members.isEmpty) {
      return _MembersStateList(
        child: _MembersMessage(
          icon: Icons.wifi_off_rounded,
          title: l10n.communityMembersLoadFailedTitle,
          message: l10n.communityMembersLoadFailedMessage,
          action: FilledButton(
            onPressed: () => _loadMembers(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: Text(l10n.feedRetryAction),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          itemCount:
              1 +
              _members.length +
              (_isLoadingMore ? 1 : 0) +
              (_members.isEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MemberFilters(
                  selectedRole: _roleFilter,
                  selectedStatus: _statusFilter,
                  onRoleChanged: _setRoleFilter,
                  onStatusChanged: _setStatusFilter,
                ),
              );
            }

            final memberIndex = index - 1;
            if (_members.isEmpty && memberIndex == 0) {
              return _MembersMessage(
                icon: Icons.group_outlined,
                title: l10n.communityMembersEmptyTitle,
                message: l10n.communityMembersEmptyMessage,
              );
            }

            if (memberIndex >= _members.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              );
            }

            final member = _members[memberIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CommunityMemberTile(
                member: member,
                isUpdating: _updatingUserIds.contains(member.userId),
                onChangeRole: () => _showRoleSheet(member),
                onChangeStatus: () => _showStatusSheet(member),
                onShowHistory: () => _showRoleHistorySheet(member),
              ),
            );
          },
        );
      },
    );
  }
}

class _MemberFilters extends StatelessWidget {
  const _MemberFilters({
    required this.selectedRole,
    required this.selectedStatus,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  final String? selectedRole;
  final String selectedStatus;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final roleField = DropdownButtonFormField<String?>(
                  key: const ValueKey('community-members-role-filter'),
                  initialValue: selectedRole,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: _filterDecoration(
                    l10n.communityMembersRoleFilterLabel,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.communityMembersAllFilter),
                    ),
                    for (final option in _roleOptions(l10n))
                      DropdownMenuItem<String?>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                  ],
                  onChanged: onRoleChanged,
                );
                final statusField = DropdownButtonFormField<String>(
                  key: const ValueKey('community-members-status-filter'),
                  initialValue: selectedStatus,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: _filterDecoration(
                    l10n.communityMembersStatusFilterLabel,
                  ),
                  items: [
                    for (final option in _statusFilterOptions(l10n))
                      DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                );

                if (constraints.maxWidth < 460) {
                  return Column(
                    children: [
                      roleField,
                      const SizedBox(height: 12),
                      statusField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: roleField),
                    const SizedBox(width: 12),
                    Expanded(child: statusField),
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

class _CommunityMemberTile extends StatelessWidget {
  const _CommunityMemberTile({
    required this.member,
    required this.isUpdating,
    required this.onChangeRole,
    required this.onChangeStatus,
    required this.onShowHistory,
  });

  final CommunityMemberVm member;
  final bool isUpdating;
  final VoidCallback onChangeRole;
  final VoidCallback onChangeStatus;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _MemberAvatar(label: member.user.preferredName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.user.preferredName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusPill(label: member.role),
                          _StatusPill(label: member.status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('member-role-history-${member.userId}'),
                      tooltip: l10n.communityMembersRoleHistoryAction,
                      onPressed: onShowHistory,
                      icon: const Icon(Icons.history_rounded),
                    ),
                    IconButton(
                      key: ValueKey('change-role-${member.userId}'),
                      tooltip: l10n.communityMembersChangeRoleAction,
                      onPressed: isUpdating ? null : onChangeRole,
                      icon: isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.manage_accounts_rounded),
                    ),
                    IconButton(
                      key: ValueKey('change-status-${member.userId}'),
                      tooltip: l10n.communityMembersChangeStatusAction,
                      onPressed: isUpdating ? null : onChangeStatus,
                      icon: const Icon(Icons.block_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleHistorySheet extends StatelessWidget {
  const _RoleHistorySheet({required this.member, required this.historyFuture});

  final CommunityMemberVm member;
  final Future<CommunityMemberRoleChangePageVm> historyFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.communityMembersRoleHistoryTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                member.user.preferredName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<CommunityMemberRoleChangePageVm>(
                  future: historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _MembersMessage(
                        icon: Icons.wifi_off_rounded,
                        title: l10n.communityMembersRoleHistoryLoadFailedTitle,
                        message:
                            l10n.communityMembersRoleHistoryLoadFailedMessage,
                      );
                    }

                    final changes = snapshot.data?.items ?? const [];
                    if (changes.isEmpty) {
                      return _MembersMessage(
                        icon: Icons.history_toggle_off_rounded,
                        title: l10n.communityMembersRoleHistoryEmptyTitle,
                        message: l10n.communityMembersRoleHistoryEmptyMessage,
                      );
                    }

                    return ListView.separated(
                      itemCount: changes.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        return _RoleHistoryTile(change: changes[index]);
                      },
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

class _RoleHistoryTile extends StatelessWidget {
  const _RoleHistoryTile({required this.change});

  final CommunityMemberRoleChangeVm change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actorName = change.actor.preferredName;
    final changedAt = _formatRoleChangeDate(change.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${change.previousRole} -> ${change.nextRole}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.communityMembersRoleHistoryChangedBy} $actorName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (changedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              changedAt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty ? 'I' : label.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accent.withValues(alpha: 0.18),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MembersStateList extends StatelessWidget {
  const _MembersStateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}

class _MembersMessage extends StatelessWidget {
  const _MembersMessage({
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
            Icon(icon, color: AppColors.textSecondary, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _StatusOption {
  const _StatusOption({
    required this.value,
    required this.label,
    this.isDestructive = false,
  });

  final String value;
  final String label;
  final bool isDestructive;
}

List<_RoleOption> _roleOptions(AppLocalizations l10n) {
  return [
    _RoleOption(value: 'MEMBER', label: l10n.communityMembersMemberRole),
    _RoleOption(
      value: 'TRUSTED_MEMBER',
      label: l10n.communityMembersTrustedRole,
    ),
    _RoleOption(value: 'MODERATOR', label: l10n.communityMembersModeratorRole),
    _RoleOption(value: 'ADMIN', label: l10n.communityMembersAdminRole),
  ];
}

List<_StatusOption> _statusFilterOptions(AppLocalizations l10n) {
  return [
    _StatusOption(value: 'ACTIVE', label: l10n.communityMembersActiveStatus),
    _StatusOption(value: 'MUTED', label: l10n.communityMembersMutedStatus),
    _StatusOption(value: 'BANNED', label: l10n.communityMembersBannedStatus),
    _StatusOption(value: 'LEFT', label: l10n.communityMembersLeftStatus),
  ];
}

List<_StatusOption> _statusActionOptions(AppLocalizations l10n) {
  return [
    _StatusOption(value: 'ACTIVE', label: l10n.communityMembersRestoreAction),
    _StatusOption(value: 'MUTED', label: l10n.communityMembersMuteAction),
    _StatusOption(
      value: 'BANNED',
      label: l10n.communityMembersBanAction,
      isDestructive: true,
    ),
    _StatusOption(
      value: 'LEFT',
      label: l10n.communityMembersRemoveAction,
      isDestructive: true,
    ),
  ];
}

InputDecoration _filterDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
  );
}

double _horizontalPadding(double width) {
  if (width >= 840) {
    return 32;
  }
  if (width >= 600) {
    return 24;
  }
  return 16;
}

String _formatRoleChangeDate(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
