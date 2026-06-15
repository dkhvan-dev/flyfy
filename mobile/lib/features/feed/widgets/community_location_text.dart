import 'package:flutter/material.dart';

import '../../../shared/reference/app_location_label_resolver.dart';
import '../../../shared/widgets/app_localized_location_text.dart';
import '../models/feed_block_vm.dart';
import 'community_display_helpers.dart';

class FeedCommunityLocationText extends StatelessWidget {
  const FeedCommunityLocationText({
    super.key,
    required this.community,
    this.includeCountry = false,
    this.resolver,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final FeedCommunityVm community;
  final bool includeCountry;
  final AppLocationLabelResolver? resolver;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final fallbackText = feedCommunityLocationLabel(
      community,
      includeCountry: includeCountry,
    );

    return AppLocalizedLocationText(
      countryCode: community.countryCode,
      cityId: community.cityId,
      cityName: community.cityName,
      fallbackText: fallbackText,
      includeCountry: includeCountry,
      resolver: resolver,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
