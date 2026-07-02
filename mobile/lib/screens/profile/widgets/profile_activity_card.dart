import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/time/app_time.dart';
import '../../../features/activities/activity_category_art.dart';
import '../../../features/activities/activity_cover_url.dart';
import '../../../features/activities/activity_formatters.dart';
import '../../../features/activities/models/activity_list_item_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_localized_location_text.dart';
import '../profile_style.dart';

class ProfileActivityCard extends StatelessWidget {
  const ProfileActivityCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ActivityListItemVm item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final date = item.completedAt ?? item.endAt;
    final dateText = formatEventDateTime(
      date,
      timezoneId: item.timezone,
      localeName: localeName,
    );
    final locationFallbackText = activityLocationFallbackText(item, l10n);
    final priceText = item.isFree
        ? l10n.createPriceFree
        : item.formattedPriceLabel(localeName);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 22),
        ),
        child: Ink(
          decoration: _profileActivityCardDecoration(context, colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppBorderRadius.vertical(
                  top: AppRadiusValue.circular(
                    profileScaled(context, 22, min: 18, max: 22),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _ProfileActivityCover(item: item),
                ),
              ),
              Padding(
                padding: AppEdgeInsets.all(
                  profileScaled(context, 16, min: 14, max: 18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: profileScaled(context, 8, min: 6, max: 8),
                      runSpacing: profileScaled(context, 8, min: 6, max: 8),
                      children: [
                        _ProfileActivityChip(
                          icon: Icons.check_circle_outline_rounded,
                          label: formatActivityDisplayStatus(item, l10n),
                        ),
                        _ProfileActivityChip(
                          icon: _formatIcon(item.format),
                          label: formatActivityFormat(item.format, l10n),
                        ),
                        _ProfileActivityChip(
                          icon: Icons.payments_outlined,
                          label: priceText,
                        ),
                      ],
                    ),
                    SizedBox(height: profileScaled(context, 12, min: 10)),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: profileScaled(context, 16, min: 14, max: 17),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 10, min: 8)),
                    _ProfileActivityMetaLine(
                      icon: Icons.event_available_outlined,
                      label: dateText,
                    ),
                    SizedBox(height: profileScaled(context, 8, min: 6)),
                    _ProfileActivityLocationLine(
                      item: item,
                      fallbackText: locationFallbackText,
                    ),
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

class ProfileCompactActivityCard extends StatelessWidget {
  const ProfileCompactActivityCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ActivityListItemVm item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final metaText = _compactActivityMetaText(item, l10n, localeName);
    final priceText = item.isFree
        ? l10n.createPriceFree
        : item.formattedPriceLabel(localeName);
    final locationFallbackText = activityLocationFallbackText(item, l10n);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 22),
        ),
        child: Ink(
          decoration: _profileActivityCardDecoration(context, colors),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = profileScaled(context, 12, min: 10);
              final gap = profileScaled(context, 14, min: 12, max: 16);
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth - padding * 2
                  : MediaQuery.sizeOf(context).width - padding * 2;
              final coverSize = (availableWidth * 0.36).clamp(58.0, 108.0);

              return Padding(
                padding: AppEdgeInsets.all(padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          width: coverSize,
                          height: coverSize,
                        ),
                        child: ClipRRect(
                          borderRadius: AppBorderRadius.circular(
                            profileScaled(context, 18, min: 14, max: 20),
                          ),
                          child: _ProfileActivityCover(item: item),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metaText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: colors.textSecondary,
                              fontSize: profileScaled(
                                context,
                                12,
                                min: 11,
                                max: 12,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: profileScaled(context, 7, min: 6)),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: colors.textPrimary,
                              fontSize: profileScaled(
                                context,
                                15,
                                min: 14,
                                max: 16,
                              ),
                              fontWeight: FontWeight.w900,
                              height: 1.16,
                            ),
                          ),
                          SizedBox(height: profileScaled(context, 8, min: 6)),
                          _ProfileActivityLocationLine(
                            item: item,
                            fallbackText: locationFallbackText,
                            compact: true,
                          ),
                          SizedBox(height: profileScaled(context, 9, min: 7)),
                          Row(
                            children: [
                              Flexible(
                                child: _ProfileActivityTinyBadge(
                                  icon: _formatIcon(item.format),
                                  label: formatActivityFormat(
                                    item.format,
                                    l10n,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: profileScaled(context, 7, min: 6),
                              ),
                              Flexible(
                                child: _ProfileActivityTinyBadge(
                                  icon: Icons.payments_outlined,
                                  label: priceText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _compactActivityMetaText(
  ActivityListItemVm item,
  AppLocalizations l10n,
  String localeName,
) {
  final date = item.completedAt ?? item.endAt;
  final dateText = formatEventDate(
    date,
    timezoneId: item.timezone,
    localeName: localeName,
  );
  final statusText = formatActivityDisplayStatus(item, l10n);
  return '$dateText • $statusText';
}

class _ProfileActivityCover extends StatelessWidget {
  const _ProfileActivityCover({required this.item});

  final ActivityListItemVm item;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final imageUrl = resolveActivityCoverUrl(item);
    final cover = ActivityDecorativeCover(
      spec: activityCardArtForItem(item),
      imageUrl: imageUrl,
    );

    if (imageUrl == null) {
      return cover;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        cover,
        DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.transparent,
                colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActivityChip extends StatelessWidget {
  const _ProfileActivityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 10, min: 8, max: 10),
        vertical: profileScaled(context, 6, min: 5, max: 6),
      ),
      decoration: AppBoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: profileScaled(context, 14, min: 13, max: 14),
            color: colors.primary,
          ),
          SizedBox(width: profileScaled(context, 5, min: 4, max: 6)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.48,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: profileScaled(context, 11, min: 10, max: 11),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActivityMetaLine extends StatelessWidget {
  const _ProfileActivityMetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      children: [
        Icon(
          icon,
          size: profileScaled(context, 17, min: 15, max: 17),
          color: colors.primary.withValues(alpha: 0.82),
        ),
        SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: profileScaled(context, 13, min: 12, max: 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActivityLocationLine extends StatelessWidget {
  const _ProfileActivityLocationLine({
    required this.item,
    required this.fallbackText,
    this.compact = false,
  });

  final ActivityListItemVm item;
  final String fallbackText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final style = AppTextStyle(
      color: colors.textSecondary,
      fontSize: profileScaled(
        context,
        compact ? 12 : 13,
        min: compact ? 11 : 12,
        max: 13,
      ),
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppEdgeInsets.only(top: profileScaled(context, 1, min: 0)),
          child: Icon(
            Icons.place_outlined,
            size: profileScaled(context, compact ? 15 : 17, min: 14, max: 17),
            color: colors.primary.withValues(alpha: 0.82),
          ),
        ),
        SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
        Expanded(
          child: AppLocalizedLocationText(
            countryCode: item.countryCode,
            cityId: item.cityId,
            cityName: item.cityName,
            fallbackText: fallbackText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _ProfileActivityTinyBadge extends StatelessWidget {
  const _ProfileActivityTinyBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: profileScaled(context, 14, min: 13, max: 15),
          color: colors.primary.withValues(alpha: 0.78),
        ),
        SizedBox(width: profileScaled(context, 5, min: 4)),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: profileScaled(context, 12, min: 11, max: 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _profileActivityCardDecoration(
  BuildContext context,
  AppColors colors,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: AppBorderRadius.circular(
      profileScaled(context, 22, min: 18, max: 28),
    ),
    border: Border.all(
      color: isDark
          ? colors.borderPrimary.withValues(alpha: 0.54)
          : colors.border,
    ),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.24),
              blurRadius: profileScaled(context, 20, min: 14, max: 24),
              offset: Offset(0, profileScaled(context, 8, min: 5, max: 10)),
            ),
          ]
        : const [],
  );
}

IconData _formatIcon(String value) {
  switch (value.toUpperCase()) {
    case 'ONLINE':
      return Icons.videocam_outlined;
    case 'HYBRID':
      return Icons.hub_outlined;
    default:
      return Icons.map_outlined;
  }
}
