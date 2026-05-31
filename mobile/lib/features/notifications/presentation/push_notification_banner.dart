import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import 'push_notification_coordinator.dart';

class PushNotificationBannerController {
  final StreamController<PushNotificationDisplay> _events =
      StreamController<PushNotificationDisplay>.broadcast();

  void Function(String route)? _onTap;

  Stream<PushNotificationDisplay> get events => _events.stream;

  void show(PushNotificationDisplay display) {
    if (_events.isClosed) return;
    _events.add(display);
  }

  void open(PushNotificationDisplay display) {
    final route = display.route.trim();
    if (route.isEmpty) return;
    _onTap?.call(route);
  }

  void _attachTapHandler(void Function(String route) onTap) {
    _onTap = onTap;
  }

  Future<void> dispose() {
    _onTap = null;
    return _events.close();
  }
}

class InAppPushNotificationPresenter implements PushNotificationPresenter {
  InAppPushNotificationPresenter({required this._controller});

  final PushNotificationBannerController _controller;

  @override
  Future<void> initialize({required void Function(String route) onTap}) async {
    _controller._attachTapHandler(onTap);
  }

  @override
  Future<void> show(PushNotificationDisplay display) async {
    _controller.show(display);
  }
}

class PushNotificationBannerHost extends StatefulWidget {
  const PushNotificationBannerHost({
    super.key,
    required this.controller,
    required this.child,
    this.visibleDuration = const Duration(seconds: 5),
  });

  final PushNotificationBannerController controller;
  final Widget child;
  final Duration visibleDuration;

  @override
  State<PushNotificationBannerHost> createState() =>
      _PushNotificationBannerHostState();
}

class _PushNotificationBannerHostState
    extends State<PushNotificationBannerHost> {
  static const _animationDuration = Duration(milliseconds: 260);

  final Queue<PushNotificationDisplay> _queue =
      Queue<PushNotificationDisplay>();

  StreamSubscription<PushNotificationDisplay>? _subscription;
  Timer? _timer;
  PushNotificationDisplay? _current;
  bool _visible = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.events.listen(_handleDisplay);
  }

  @override
  void didUpdateWidget(covariant PushNotificationBannerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _subscription?.cancel();
    _subscription = widget.controller.events.listen(_handleDisplay);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _current;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: display == null,
              child: AnimatedSlide(
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                offset: Offset(0, _visible ? 0 : -1.15),
                child: AnimatedOpacity(
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  opacity: _visible ? 1 : 0,
                  child: AnimatedScale(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    scale: _visible ? 1 : 0.98,
                    child: display == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: AppNotificationBanner(
                              display: display,
                              onTap: _openCurrent,
                              onDismiss: _dismissCurrent,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDisplay(PushNotificationDisplay display) {
    if (_current != null || _dismissing) {
      _queue.add(display);
      return;
    }
    _show(display);
  }

  void _show(PushNotificationDisplay display) {
    _timer?.cancel();
    setState(() {
      _current = display;
      _visible = true;
      _dismissing = false;
    });
    _timer = Timer(widget.visibleDuration, _dismissCurrent);
  }

  void _openCurrent() {
    final display = _current;
    if (display == null) return;
    widget.controller.open(display);
    _dismissCurrent();
  }

  Future<void> _dismissCurrent() async {
    if (_current == null || _dismissing) return;
    _timer?.cancel();
    setState(() {
      _visible = false;
      _dismissing = true;
    });

    await Future<void>.delayed(_animationDuration);
    if (!mounted) return;

    final next = _queue.isEmpty ? null : _queue.removeFirst();
    if (next == null) {
      setState(() {
        _current = null;
        _dismissing = false;
      });
      return;
    }

    setState(() {
      _current = null;
      _dismissing = false;
    });
    _show(next);
  }
}

class AppNotificationBanner extends StatelessWidget {
  const AppNotificationBanner({
    super.key,
    required this.display,
    required this.onTap,
    required this.onDismiss,
  });

  final PushNotificationDisplay display;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationBannerVisual.forChannel(display.channel);
    final textTheme = Theme.of(context).textTheme;
    final body = display.body.trim();
    final title = display.title.trim().isEmpty
        ? 'Inflap'
        : display.title.trim();

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final veryCompact = constraints.maxWidth < 300;
              final iconSize = veryCompact ? 34.0 : (compact ? 38.0 : 42.0);
              final closeSize = compact ? 32.0 : 36.0;
              final horizontalGap = compact ? 8.0 : 11.0;
              final contentPadding = EdgeInsetsDirectional.fromSTEB(
                compact ? 14 : 16,
                compact ? 10 : 12,
                compact ? 8 : 10,
                compact ? 10 : 12,
              );

              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2A1E11).withValues(alpha: 0.98),
                          const Color(0xFF20170E).withValues(alpha: 0.98),
                          AppColors.surface.withValues(alpha: 0.98),
                        ],
                      ),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.34),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          start: 0,
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accent,
                                  AppColors.accent.withValues(alpha: 0.72),
                                ],
                              ),
                            ),
                            child: const SizedBox(width: 4),
                          ),
                        ),
                        Padding(
                          padding: contentPadding,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NotificationBannerIcon(
                                visual: visual,
                                size: iconSize,
                              ),
                              SizedBox(width: horizontalGap),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _NotificationBannerMeta(
                                      visual: visual,
                                      showChannel: !veryCompact,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      title,
                                      maxLines: compact ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          textTheme.titleSmall?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ) ??
                                          const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                    ),
                                    if (body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        maxLines: compact ? 3 : 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                              height: 1.25,
                                            ) ??
                                            const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(width: compact ? 4 : 6),
                              _NotificationBannerCloseButton(
                                size: closeSize,
                                iconSize: compact ? 17 : 18,
                                onDismiss: onDismiss,
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
          ),
        ),
      ),
    );
  }
}

class _NotificationBannerMeta extends StatelessWidget {
  const _NotificationBannerMeta({
    required this.visual,
    required this.showChannel,
  });

  final _NotificationBannerVisual visual;
  final bool showChannel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style =
        textTheme.labelSmall?.copyWith(
          color: AppColors.textCaption,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0,
        ) ??
        const TextStyle(
          color: AppColors.textCaption,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Inflap',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (showChannel) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.86),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 4),
            ),
          ),
          Flexible(
            child: Text(
              visual.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationBannerCloseButton extends StatelessWidget {
  const _NotificationBannerCloseButton({
    required this.size,
    required this.iconSize,
    required this.onDismiss,
  });

  final double size;
  final double iconSize;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dismiss notification',
      button: true,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: AppColors.surfaceLight,
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: onDismiss,
            containedInkWell: true,
            radius: size / 2,
            customBorder: const CircleBorder(),
            child: Icon(
              Icons.close_rounded,
              size: iconSize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBannerIcon extends StatelessWidget {
  const _NotificationBannerIcon({required this.visual, required this.size});

  final _NotificationBannerVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Icon(visual.icon, color: AppColors.accent, size: size * 0.54),
    );
  }
}

class _NotificationBannerVisual {
  const _NotificationBannerVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  static _NotificationBannerVisual forChannel(PushNotificationChannel channel) {
    return switch (channel) {
      PushNotificationChannel.activity => const _NotificationBannerVisual(
        icon: Icons.event_available_rounded,
        color: AppColors.accent,
        label: 'Activity',
      ),
      PushNotificationChannel.messages => const _NotificationBannerVisual(
        icon: Icons.chat_bubble_rounded,
        color: AppColors.accent,
        label: 'Messages',
      ),
      PushNotificationChannel.system => const _NotificationBannerVisual(
        icon: Icons.notifications_active_rounded,
        color: AppColors.accent,
        label: 'System',
      ),
    };
  }
}
