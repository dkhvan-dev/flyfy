import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/app_colors.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final date = item.completedAt ?? item.endAt;
    final dateText = DateFormat.MMMd(
      localeName,
    ).add_Hm().format(date.toLocal());
    final locationFallbackText = activityLocationFallbackText(item, l10n);
    final priceText = item.isFree
        ? l10n.createPriceFree
        : item.formattedPriceLabel(localeName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 22),
        ),
        child: Ink(
          decoration: profileCardDecoration(context, highlighted: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    profileScaled(context, 22, min: 18, max: 22),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _ProfileActivityCover(item: item),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(
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
                      style: TextStyle(
                        color: AppColors.textPrimary,
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

class _ProfileActivityCover extends StatelessWidget {
  const _ProfileActivityCover({required this.item});

  final ActivityListItemVm item;

  @override
  Widget build(BuildContext context) {
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 10, min: 8, max: 10),
        vertical: profileScaled(context, 6, min: 5, max: 6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: profileScaled(context, 14, min: 13, max: 14),
            color: AppColors.accent,
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
              style: TextStyle(
                color: profileTextSoft,
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
    return Row(
      children: [
        Icon(
          icon,
          size: profileScaled(context, 17, min: 15, max: 17),
          color: AppColors.accent.withValues(alpha: 0.82),
        ),
        SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: profileTextMuted,
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
  });

  final ActivityListItemVm item;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: profileTextMuted,
      fontSize: profileScaled(context, 13, min: 12, max: 13),
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: profileScaled(context, 1, min: 0)),
          child: Icon(
            Icons.place_outlined,
            size: profileScaled(context, 17, min: 15, max: 17),
            color: AppColors.accent.withValues(alpha: 0.82),
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
