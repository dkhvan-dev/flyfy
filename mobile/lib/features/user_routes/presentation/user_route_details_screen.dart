import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/error_view.dart';
import '../../../features/routing/models/routing_models.dart';
import '../../../features/routing/widgets/route_summary_card.dart';
import '../../../features/user_routes/models/user_route_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/routing_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/user_routes_provider.dart';
import '../../../screens/map/map_screen.dart';

class UserRouteDetailsScreen extends StatefulWidget {
  const UserRouteDetailsScreen({
    super.key,
    required this.routeId,
    this.initialRoute,
  });

  final String routeId;
  final UserRouteVm? initialRoute;

  @override
  State<UserRouteDetailsScreen> createState() => _UserRouteDetailsScreenState();
}

class _UserRouteDetailsScreenState extends State<UserRouteDetailsScreen> {
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialRoute = widget.initialRoute;
      if (initialRoute != null) {
        context.read<UserRoutesProvider>().setSelectedRoute(initialRoute);
      }
      unawaited(_loadRoute());
    });
  }

  Future<void> _loadRoute() async {
    await context.read<UserRoutesProvider>().getRoute(widget.routeId);
  }

  UserRouteVm? _routeFrom(UserRoutesProvider provider) {
    final selected = provider.selectedRoute;
    if (selected != null && selected.id == widget.routeId) {
      return selected;
    }
    final initial = widget.initialRoute;
    if (initial != null && initial.id == widget.routeId) {
      return initial;
    }
    return null;
  }

  bool _isAuthenticated() {
    return context.read<AuthProvider>().state == AuthState.authenticated;
  }

  Future<bool> _requireAuth() async {
    if (_isAuthenticated()) {
      return true;
    }
    await context.push(
      '/login?from=${Uri.encodeComponent('/user-routes/${widget.routeId}')}',
    );
    return false;
  }

  Future<void> _toggleSaved(UserRouteVm route) async {
    if (!await _requireAuth() || _actionLoading) {
      return;
    }
    if (!mounted) return;

    setState(() => _actionLoading = true);
    final provider = context.read<UserRoutesProvider>();
    try {
      if (route.savedByMe) {
        await provider.unsaveRoute(route.id);
      } else {
        await provider.saveRoute(route.id);
      }
      if (!mounted) return;
      final message = provider.errorMessage;
      if (message != null && message.trim().isNotEmpty) {
        _showSnack(message);
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _copyRoute(UserRouteVm route) async {
    if (!await _requireAuth() || _actionLoading) {
      return;
    }
    if (!mounted) return;

    setState(() => _actionLoading = true);
    final provider = context.read<UserRoutesProvider>();
    try {
      final copied = await provider.copyRoute(route.id);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (copied == null) {
        _showSnack(provider.errorMessage ?? l10n.userRoutesSaveFailed);
        return;
      }
      _showSnack(l10n.userRoutesCopied);
      context.push(
        '/user-routes/${Uri.encodeComponent(copied.id)}',
        extra: copied,
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _editRoute(UserRouteVm route) async {
    if (!await _requireAuth() || _actionLoading) {
      return;
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<_RouteEditResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => _EditRouteSheet(route: route),
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() => _actionLoading = true);
    final provider = context.read<UserRoutesProvider>();
    try {
      final updated = await provider.updateRoute(
        route.id,
        UpdateUserRouteRequestVm(
          title: result.title,
          description: result.description,
          visibility: result.visibility,
        ),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showSnack(
        updated == null
            ? provider.errorMessage ?? l10n.userRoutesUpdateFailed
            : l10n.userRoutesUpdateSuccess,
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _editRoutePoints(UserRouteVm route) async {
    if (!await _requireAuth() || _actionLoading) {
      return;
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<_RoutePointsEditResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => _EditRoutePointsSheet(route: route),
    );
    if (result == null || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    if (result.points.length < 2) {
      _showSnack(l10n.userRoutesEditPointsMinStops);
      return;
    }

    setState(() => _actionLoading = true);
    final routingProvider = context.read<RoutingProvider>();
    final userRoutesProvider = context.read<UserRoutesProvider>();
    try {
      final builtRoute = await routingProvider.buildRoute(
        RouteRequestVm(
          profile: route.profile,
          points: result.points
              .map((point) => point.toRoutePoint())
              .toList(growable: false),
        ),
      );
      if (!mounted) return;
      if (builtRoute == null) {
        _showSnack(
          routingProvider.errorMessage ?? l10n.userRoutesRebuildFailed,
        );
        return;
      }

      final updated = await userRoutesProvider.updateRoute(
        route.id,
        UpdateUserRouteRequestVm(
          profile: builtRoute.profile,
          points: result.points,
          snapshot: UserRouteSnapshotVm.fromRouteResponse(builtRoute),
        ),
      );
      if (!mounted) return;
      _showSnack(
        updated == null
            ? userRoutesProvider.errorMessage ?? l10n.userRoutesUpdateFailed
            : l10n.userRoutesStopsUpdateSuccess,
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _copyShareLink(UserRouteVm route) async {
    await Clipboard.setData(ClipboardData(text: _buildRouteShareLink(route)));
    if (!mounted) return;
    _showSnack(AppLocalizations.of(context)!.userRoutesShareCopied);
  }

  String _buildRouteShareLink(UserRouteVm route) {
    return 'https://inflap.app/user-routes/${Uri.encodeComponent(route.id)}';
  }

  void _openOnMap(UserRouteVm route) {
    final routePoints = route.points
        .map((point) => point.toRoutePoint())
        .toList(growable: false);
    final lastPoint = routePoints.isEmpty ? null : routePoints.last;
    context.push(
      '/map',
      extra: MapRoutePreview(
        route: route.snapshot.toRouteResponse(),
        routePoints: routePoints,
        destination: lastPoint == null
            ? null
            : MapTarget(
                title: lastPoint.name?.trim().isNotEmpty == true
                    ? lastPoint.name!.trim()
                    : route.title,
                latitude: lastPoint.latitude,
                longitude: lastPoint.longitude,
              ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.select<SessionProvider, String>(
      (session) => session.profile?.userId.trim() ?? '',
    );

    return Scaffold(
      backgroundColor: AppPalette.backgroundWarm,
      appBar: AppBar(
        title: Text(l10n.userRoutesTitle),
        backgroundColor: AppPalette.backgroundWarm,
        foregroundColor: AppPalette.textPrimary,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<UserRoutesProvider>(
          builder: (context, provider, _) {
            final route = _routeFrom(provider);
            final loading =
                provider.state == UserRoutesState.loading && route == null;
            final failed =
                provider.state == UserRoutesState.error && route == null;

            if (loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppPalette.primary),
              );
            }

            if (failed) {
              return ErrorView(
                message: provider.errorMessage ?? l10n.userRoutesSaveFailed,
                onRetry: _loadRoute,
              );
            }

            if (route == null) {
              return ErrorView(
                message: l10n.userRoutesSaveFailed,
                onRetry: _loadRoute,
              );
            }

            final canEdit =
                currentUserId.isNotEmpty &&
                route.ownerUserId.trim() == currentUserId;
            final canShare = route.visibility != UserRouteVisibility.private;

            return RefreshIndicator(
              color: AppPalette.primary,
              onRefresh: _loadRoute,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const AppEdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _RouteHeader(route: route),
                  const SizedBox(height: 14),
                  RouteSummaryCard(route: route.snapshot.toRouteResponse()),
                  const SizedBox(height: 14),
                  _RouteActions(
                    route: route,
                    loading: _actionLoading,
                    onOpenMap: () => _openOnMap(route),
                    onToggleSaved: () => _toggleSaved(route),
                    onCopy: () => _copyRoute(route),
                    canEdit: canEdit,
                    canShare: canShare,
                    onEdit: () => _editRoute(route),
                    onShare: () => _copyShareLink(route),
                  ),
                  const SizedBox(height: 18),
                  _RouteStopsSection(
                    route: route,
                    canEdit: canEdit,
                    loading: _actionLoading,
                    onEditStops: () => _editRoutePoints(route),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RouteEditResult {
  const _RouteEditResult({
    required this.title,
    required this.description,
    required this.visibility,
  });

  final String title;
  final String description;
  final UserRouteVisibility visibility;
}

class _EditRouteSheet extends StatefulWidget {
  const _EditRouteSheet({required this.route});

  final UserRouteVm route;

  @override
  State<_EditRouteSheet> createState() => _EditRouteSheetState();
}

class _EditRouteSheetState extends State<_EditRouteSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late UserRouteVisibility _visibility;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.route.title);
    _descriptionController = TextEditingController(
      text: widget.route.description ?? '',
    );
    _visibility = widget.route.visibility;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.length < 3) {
      return;
    }
    Navigator.of(context).pop(
      _RouteEditResult(
        title: title,
        description: _descriptionController.text.trim(),
        visibility: _visibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.56,
        minChildSize: 0.36,
        maxChildSize: 0.88,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const AppBoxDecoration(
              color: AppPalette.warmInk41,
              borderRadius: AppBorderRadius.vertical(
                top: AppRadiusValue.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const AppEdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: AppBoxDecoration(
                        color: AppPalette.white.withValues(alpha: 0.22),
                        borderRadius: AppBorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.userRoutesEditRoute,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    style: const AppTextStyle(color: AppPalette.textPrimary),
                    decoration: _routeEditInputDecoration(
                      context,
                      label: l10n.userRoutesEditTitleLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 2000,
                    style: const AppTextStyle(color: AppPalette.textPrimary),
                    decoration: _routeEditInputDecoration(
                      context,
                      label: l10n.userRoutesEditDescriptionLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.userRoutesEditVisibilityLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: SegmentedButton<UserRouteVisibility>(
                            selected: {_visibility},
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppPalette.warmInk90;
                                    }
                                    return AppPalette.textPrimary;
                                  }),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppPalette.primary;
                                    }
                                    return AppPalette.white.withValues(
                                      alpha: 0.04,
                                    );
                                  }),
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: AppPalette.primary.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                            ),
                            segments: [
                              ButtonSegment(
                                value: UserRouteVisibility.private,
                                label: Text(l10n.userRoutesVisibilityPrivate),
                              ),
                              ButtonSegment(
                                value: UserRouteVisibility.unlisted,
                                label: Text(l10n.userRoutesVisibilityUnlisted),
                              ),
                              ButtonSegment(
                                value: UserRouteVisibility.public,
                                label: Text(l10n.userRoutesVisibilityPublic),
                              ),
                            ],
                            onSelectionChanged: (value) {
                              setState(() => _visibility = value.single);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: AppPalette.warmInk90,
                      padding: const AppEdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.userRoutesEditSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _routeEditInputDecoration(
    BuildContext context, {
    required String label,
  }) {
    return AppInputDecoration(
      labelText: label,
      labelStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
      counterStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
      filled: true,
      fillColor: AppPalette.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(8),
        borderSide: BorderSide(color: AppPalette.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.circular(8),
        borderSide: const BorderSide(color: AppPalette.primary),
      ),
    );
  }
}

class _RoutePointsEditResult {
  const _RoutePointsEditResult({required this.points});

  final List<UserRoutePointVm> points;
}

class _EditableRouteStop {
  _EditableRouteStop(this.point)
    : nameController = TextEditingController(text: point.name ?? ''),
      noteController = TextEditingController(text: point.note ?? '');

  final UserRoutePointVm point;
  final TextEditingController nameController;
  final TextEditingController noteController;

  UserRoutePointVm toRoutePoint() {
    return UserRoutePointVm(
      id: point.id,
      latitude: point.latitude,
      longitude: point.longitude,
      name: nameController.text.trim(),
      note: noteController.text.trim(),
      sourceType: point.sourceType,
      sourceId: point.sourceId,
      stopDurationMinutes: point.stopDurationMinutes,
    );
  }

  void dispose() {
    nameController.dispose();
    noteController.dispose();
  }
}

class _EditRoutePointsSheet extends StatefulWidget {
  const _EditRoutePointsSheet({required this.route});

  final UserRouteVm route;

  @override
  State<_EditRoutePointsSheet> createState() => _EditRoutePointsSheetState();
}

class _EditRoutePointsSheetState extends State<_EditRoutePointsSheet> {
  late final List<_EditableRouteStop> _stops;

  @override
  void initState() {
    super.initState();
    _stops = widget.route.points.map(_EditableRouteStop.new).toList();
  }

  @override
  void dispose() {
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  void _moveStop(int index, int delta) {
    final targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= _stops.length) {
      return;
    }
    setState(() {
      final stop = _stops.removeAt(index);
      _stops.insert(targetIndex, stop);
    });
  }

  void _submit() {
    if (_stops.length < 2) {
      return;
    }
    Navigator.of(context).pop(
      _RoutePointsEditResult(
        points: _stops
            .map((stop) => stop.toRoutePoint())
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const AppBoxDecoration(
              color: AppPalette.warmInk41,
              borderRadius: AppBorderRadius.vertical(
                top: AppRadiusValue.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const AppEdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: AppBoxDecoration(
                        color: AppPalette.white.withValues(alpha: 0.22),
                        borderRadius: AppBorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.userRoutesEditStops,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.userRoutesEditStopsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textCoolSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var index = 0; index < _stops.length; index++) ...[
                    _EditableRouteStopCard(
                      stop: _stops[index],
                      order: index + 1,
                      canMoveUp: index > 0,
                      canMoveDown: index < _stops.length - 1,
                      onMoveUp: () => _moveStop(index, -1),
                      onMoveDown: () => _moveStop(index, 1),
                    ),
                    if (index < _stops.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _stops.length < 2 ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: AppPalette.warmInk90,
                      disabledBackgroundColor: AppPalette.primary.withValues(
                        alpha: 0.4,
                      ),
                      disabledForegroundColor: AppPalette.warmInk90.withValues(
                        alpha: 0.56,
                      ),
                      padding: const AppEdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.route_rounded),
                    label: Text(l10n.userRoutesRebuildAndSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditableRouteStopCard extends StatelessWidget {
  const _EditableRouteStopCard({
    required this.stop,
    required this.order,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final _EditableRouteStop stop;
  final int order;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.warmInk75,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppPalette.primary,
                  child: Text(
                    order.toString(),
                    style: const AppTextStyle(
                      color: AppPalette.warmInk90,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.userRoutesMoveStopUp,
                  onPressed: canMoveUp ? onMoveUp : null,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  color: AppPalette.primary,
                ),
                IconButton(
                  tooltip: l10n.userRoutesMoveStopDown,
                  onPressed: canMoveDown ? onMoveDown : null,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  color: AppPalette.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stop.nameController,
              textInputAction: TextInputAction.next,
              maxLength: 120,
              style: const AppTextStyle(color: AppPalette.textPrimary),
              decoration: _routePointInputDecoration(
                context,
                label: l10n.userRoutesEditStopNameLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stop.noteController,
              minLines: 2,
              maxLines: 3,
              maxLength: 500,
              style: const AppTextStyle(color: AppPalette.textPrimary),
              decoration: _routePointInputDecoration(
                context,
                label: l10n.userRoutesEditStopNoteLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _routePointInputDecoration(
  BuildContext context, {
  required String label,
}) {
  return AppInputDecoration(
    labelText: label,
    labelStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
    counterStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
    filled: true,
    fillColor: AppPalette.white.withValues(alpha: 0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(8),
      borderSide: BorderSide(color: AppPalette.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(8),
      borderSide: const BorderSide(color: AppPalette.primary),
    ),
  );
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.route});

  final UserRouteVm route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = route.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VisibilityChip(visibility: route.visibility),
            if (route.savedByMe)
              _SmallAmberChip(
                icon: Icons.bookmark_rounded,
                label: AppLocalizations.of(context)!.userRoutesSavedTab,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          route.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.textCoolSecondary,
              height: 1.42,
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteActions extends StatelessWidget {
  const _RouteActions({
    required this.route,
    required this.loading,
    required this.onOpenMap,
    required this.onToggleSaved,
    required this.onCopy,
    required this.canEdit,
    required this.canShare,
    required this.onEdit,
    required this.onShare,
  });

  final UserRouteVm route;
  final bool loading;
  final VoidCallback onOpenMap;
  final VoidCallback onToggleSaved;
  final VoidCallback onCopy;
  final bool canEdit;
  final bool canShare;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onOpenMap,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primary,
            foregroundColor: AppPalette.warmInk90,
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.map_rounded),
          label: Text(l10n.userRoutesOpenOnMap),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onToggleSaved,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.primary,
            side: BorderSide(color: AppPalette.primary.withValues(alpha: 0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
          ),
          icon: Icon(
            route.savedByMe
                ? Icons.bookmark_remove_rounded
                : Icons.bookmark_add_rounded,
          ),
          label: Text(
            route.savedByMe
                ? l10n.userRoutesUnsaveRoute
                : l10n.userRoutesSaveRoute,
          ),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onCopy,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.textPrimary,
            side: BorderSide(color: AppPalette.white.withValues(alpha: 0.22)),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.userRoutesCopyRoute),
        ),
        if (canShare)
          OutlinedButton.icon(
            onPressed: loading ? null : onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.textPrimary,
              side: BorderSide(color: AppPalette.white.withValues(alpha: 0.22)),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(l10n.userRoutesShareRoute),
          ),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: loading ? null : onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.primary,
              side: BorderSide(
                color: AppPalette.primary.withValues(alpha: 0.7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: Text(l10n.userRoutesEditRoute),
          ),
      ],
    );
  }
}

class _RouteStopsSection extends StatelessWidget {
  const _RouteStopsSection({
    required this.route,
    required this.canEdit,
    required this.loading,
    required this.onEditStops,
  });

  final UserRouteVm route;
  final bool canEdit;
  final bool loading;
  final VoidCallback onEditStops;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.userRoutesStopsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: loading ? null : onEditStops,
                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                label: Text(
                  l10n.userRoutesEditStops,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppPalette.primary,
                  padding: const AppEdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < route.points.length; i++) ...[
          _RouteStopTile(order: i + 1, point: route.points[i]),
          if (i < route.points.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RouteStopTile extends StatelessWidget {
  const _RouteStopTile({required this.order, required this.point});

  final int order;
  final UserRoutePointVm point;

  @override
  Widget build(BuildContext context) {
    final title = point.name?.trim();
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.warmInk75,
        borderRadius: AppBorderRadius.circular(8),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppPalette.primary,
              child: Text(
                order.toString(),
                style: const AppTextStyle(
                  color: AppPalette.warmInk90,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == null || title.isEmpty
                        ? l10n.routeStopSemantic(order)
                        : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textCoolSecondary,
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

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.visibility});

  final UserRouteVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (visibility) {
      UserRouteVisibility.private => l10n.userRoutesVisibilityPrivate,
      UserRouteVisibility.unlisted => l10n.userRoutesVisibilityUnlisted,
      UserRouteVisibility.public => l10n.userRoutesVisibilityPublic,
    };
    return _SmallAmberChip(icon: Icons.visibility_rounded, label: label);
  }
}

class _SmallAmberChip extends StatelessWidget {
  const _SmallAmberChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppPalette.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppPalette.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
