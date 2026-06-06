import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/time/app_time.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/activities/activity_currency.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

class ActivityPaymentRouteArgs {
  const ActivityPaymentRouteArgs({
    required this.activity,
    required this.hostName,
  });

  final ActivityListItemVm activity;
  final String hostName;
}

class ActivityPaymentScreen extends StatefulWidget {
  const ActivityPaymentScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
    this.initialHostName,
  });

  final String activityId;
  final ActivityListItemVm? initialActivity;
  final String? initialHostName;

  @override
  State<ActivityPaymentScreen> createState() => _ActivityPaymentScreenState();
}

class _ActivityPaymentScreenState extends State<ActivityPaymentScreen> {
  ActivityListItemVm? _activity;
  String? _hostName;
  String? _loadError;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.initialActivity;
    _hostName = widget.initialHostName;
    _isLoading = widget.initialActivity == null;

    if (_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureActivityLoaded();
      });
    }
  }

  Future<void> _ensureActivityLoaded() async {
    final provider = context.read<ActivityProvider>();
    final cached = provider.selectedActivity;
    if (cached != null && cached.id == widget.activityId) {
      if (!mounted) return;
      setState(() {
        _activity = cached;
        _isLoading = false;
        _loadError = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    await provider.loadActivityDetails(widget.activityId);

    if (!mounted) return;

    final loaded = provider.selectedActivity;
    setState(() {
      _activity = loaded?.id == widget.activityId ? loaded : null;
      _isLoading = false;
      _loadError = _activity == null ? provider.errorMessage : null;
    });
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _PaymentColors.base,
        body: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF24150A), Color(0xFF140B04)],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      );
    }

    final activity = _activity;
    if (activity == null) {
      return Scaffold(
        backgroundColor: _PaymentColors.base,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF24150A), Color(0xFF140B04)],
            ),
          ),
          child: SafeArea(
            child: ErrorView(
              message: _loadError ?? l10n.activityDetailsLoadFailed,
              onRetry: _ensureActivityLoaded,
            ),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final hostName = (_hostName ?? '').trim().isNotEmpty
        ? _hostName!.trim()
        : l10n.activityDetailsHostFallbackName;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final totalLabel = formatActivityMoney(
      amount: activity.priceAmount,
      currency: activity.currency,
      countryCode: activity.countryCode,
      localeName: locale,
    );

    return Scaffold(
      backgroundColor: _PaymentColors.base,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24150A), Color(0xFF140B04)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = compact ? 16.0 : 20.0;
              final contentWidth = constraints.maxWidth > 440
                  ? 440.0
                  : constraints.maxWidth;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PaymentTopBar(
                                title: l10n.activityPaymentScreenTitle,
                              ),
                              const SizedBox(height: 18),
                              _PaymentModeNotice(
                                title: l10n.activityPaymentMockNoticeTitle,
                                body: l10n.activityPaymentMockNoticeBody,
                              ),
                              const SizedBox(height: 22),
                              _PaymentSectionTitle(
                                title: l10n.activityPaymentSummaryTitle,
                              ),
                              const SizedBox(height: 14),
                              _SummaryCard(
                                activity: activity,
                                compact: compact,
                                hostLabel: l10n.activityPaymentHostedBy(
                                  hostName,
                                ),
                                dateLabel: _formatPaymentDateTime(
                                  activity.startAt,
                                  activity.timezone,
                                  locale,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _PaymentSectionTitle(
                                title: l10n.activityPaymentBreakdownTitle,
                              ),
                              const SizedBox(height: 14),
                              _PriceBreakdownCard(
                                admissionLabel:
                                    l10n.activityPaymentAdmissionLabel,
                                admissionValue: totalLabel,
                                serviceFeeLabel:
                                    l10n.activityPaymentServiceFeeLabel,
                                serviceFeeValue: formatActivityMoney(
                                  amount: 0,
                                  currency: activity.currency,
                                  countryCode: activity.countryCode,
                                  localeName: locale,
                                ),
                                totalLabel: l10n.activityDetailsTotalLabel,
                                totalValue: totalLabel,
                              ),
                              const SizedBox(height: 20),
                              _PaymentSectionTitle(
                                title: l10n.activityPaymentMethodTitle,
                              ),
                              const SizedBox(height: 14),
                              _SandboxPaymentMethodOption(
                                label: l10n.activityPaymentSandboxMethodLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _PaymentFooter(
                        compact: compact,
                        totalLabel: totalLabel,
                        isSubmitting: _isSubmitting,
                        onConfirm: _handleConfirm,
                      ),
                    ],
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

abstract final class _PaymentColors {
  static const base = Color(0xFF140B04);
  static const text = Color(0xFFF5F2EF);
  static const muted = Color(0xFFAEB9D6);
  static const stroke = Color(0x42FF9900);
}

class _PaymentFooter extends StatelessWidget {
  const _PaymentFooter({
    required this.compact,
    required this.totalLabel,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final bool compact;
  final String totalLabel;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF140B04).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF5A7BC0).withValues(alpha: 0.34),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: compact ? 64 : 70),
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.accent,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.activityPaymentConfirmButton(
                                      totalLabel,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: compact ? 18 : 22,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.activityPaymentMockSecureNote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7D8BAD),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentModeNotice extends StatelessWidget {
  const _PaymentModeNotice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_rounded,
              color: AppColors.accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PaymentColors.text,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: _PaymentColors.text.withValues(alpha: 0.72),
                    fontSize: 12,
                    height: 1.38,
                    fontWeight: FontWeight.w500,
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

class _PaymentTopBar extends StatelessWidget {
  const _PaymentTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(width: 40, height: 40),
      ],
    );
  }
}

class _PaymentSectionTitle extends StatelessWidget {
  const _PaymentSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _PaymentColors.text,
        fontSize: 28,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.activity,
    required this.compact,
    required this.hostLabel,
    required this.dateLabel,
  });

  final ActivityListItemVm activity;
  final bool compact;
  final String hostLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      height: compact ? 154 : 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCBE6F1),
            Color(0xFFF0D6A8),
            Color(0xFFF0B150),
            Color(0xFF375F75),
            Color(0xFF214B67),
          ],
          stops: [0, 0.38, 0.6, 0.61, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: RadialGradient(
                  center: const Alignment(0.55, -0.65),
                  radius: 0.78,
                  colors: [
                    Colors.white.withValues(alpha: 0.34),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Icon(
              Icons.directions_boat_filled_rounded,
              color: Colors.white,
              size: 58,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _PaymentColors.stroke, width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x05F4F2F2), Color(0x1A3A2109)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryTextContent(
                  hostLabel: hostLabel,
                  activityTitle: activity.title,
                  dateLabel: dateLabel,
                ),
                const SizedBox(height: 14),
                image,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _SummaryTextContent(
                    hostLabel: hostLabel,
                    activityTitle: activity.title,
                    dateLabel: dateLabel,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(width: 132, child: image),
              ],
            ),
    );
  }
}

class _SummaryTextContent extends StatelessWidget {
  const _SummaryTextContent({
    required this.hostLabel,
    required this.activityTitle,
    required this.dateLabel,
  });

  final String hostLabel;
  final String activityTitle;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hostLabel,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          activityTitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _PaymentColors.text,
            fontSize: 24,
            height: 1.06,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: _PaymentColors.muted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateLabel,
                style: const TextStyle(
                  color: _PaymentColors.muted,
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  const _PriceBreakdownCard({
    required this.admissionLabel,
    required this.admissionValue,
    required this.serviceFeeLabel,
    required this.serviceFeeValue,
    required this.totalLabel,
    required this.totalValue,
  });

  final String admissionLabel;
  final String admissionValue;
  final String serviceFeeLabel;
  final String serviceFeeValue;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _PaymentColors.stroke, width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F2C08), Color(0xFF3C2006)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _BreakdownRow(label: admissionLabel, value: admissionValue),
          const _BreakdownDivider(),
          _BreakdownRow(label: serviceFeeLabel, value: serviceFeeValue),
          const _BreakdownDivider(),
          _BreakdownRow(label: totalLabel, value: totalValue, isTotal: true),
        ],
      ),
    );
  }
}

class _BreakdownDivider extends StatelessWidget {
  const _BreakdownDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(top: 2),
      color: const Color(0x4DFF9900),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: isTotal ? _PaymentColors.text : _PaymentColors.muted,
      fontSize: isTotal ? 20 : 18,
      height: 1.2,
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
      letterSpacing: isTotal ? -0.4 : 0,
    );
    final valueStyle = TextStyle(
      color: isTotal ? AppColors.accent : _PaymentColors.text,
      fontSize: isTotal ? 23 : 18,
      height: 1.2,
      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
      letterSpacing: isTotal ? -0.7 : -0.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

class _SandboxPaymentMethodOption extends StatelessWidget {
  const _SandboxPaymentMethodOption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent, width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F2C08), Color(0xFF3C2006)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 3),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPaymentDateTime(DateTime value, String timezone, String locale) {
  final zoned = eventDateTime(value, timezone);
  final date = DateFormat.MMMd(locale).format(zoned);
  final time = DateFormat.jm(locale).format(zoned);
  return '$date • $time · ${formatUtcOffset(zoned.timeZoneOffset)}';
}
