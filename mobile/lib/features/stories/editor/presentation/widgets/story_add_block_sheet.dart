import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../../../core/ui/filter_sheet_chrome.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../user_routes/user_route_feature_flags.dart';
import '../../../story_ui.dart';
import '../../domain/story_document.dart';
import 'story_editor_style.dart';

class StoryAddBlockSheet extends StatelessWidget {
  const StoryAddBlockSheet({super.key, required this.onSelected});

  final ValueChanged<StoryBlockType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = adaptive.scale(18);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final options = <_BlockOption>[
      _BlockOption(
        StoryBlockType.paragraph,
        storyBlockTypeLabel(l10n, StoryBlockType.paragraph),
        l10n.storyEditorBlockParagraphDescription,
        Icons.notes_rounded,
      ),
      _BlockOption(
        StoryBlockType.heading,
        storyBlockTypeLabel(l10n, StoryBlockType.heading),
        l10n.storyEditorBlockHeadingDescription,
        Icons.title_rounded,
      ),
      _BlockOption(
        StoryBlockType.bulletedList,
        storyBlockTypeLabel(l10n, StoryBlockType.bulletedList),
        l10n.storyEditorBlockListDescription,
        Icons.format_list_bulleted_rounded,
      ),
      _BlockOption(
        StoryBlockType.image,
        storyBlockTypeLabel(l10n, StoryBlockType.image),
        l10n.storyEditorBlockImageDescription,
        Icons.image_outlined,
      ),
      _BlockOption(
        StoryBlockType.gallery,
        storyBlockTypeLabel(l10n, StoryBlockType.gallery),
        l10n.storyEditorBlockGalleryDescription,
        Icons.photo_library_outlined,
      ),
      _BlockOption(
        StoryBlockType.quote,
        storyBlockTypeLabel(l10n, StoryBlockType.quote),
        l10n.storyEditorBlockQuoteDescription,
        Icons.format_quote_rounded,
      ),
      _BlockOption(
        StoryBlockType.callout,
        storyBlockTypeLabel(l10n, StoryBlockType.callout),
        l10n.storyEditorBlockCalloutDescription,
        Icons.lightbulb_outline_rounded,
      ),
      _BlockOption(
        StoryBlockType.divider,
        storyBlockTypeLabel(l10n, StoryBlockType.divider),
        l10n.storyEditorBlockDividerDescription,
        Icons.horizontal_rule_rounded,
      ),
      _BlockOption(
        StoryBlockType.placeReference,
        storyBlockTypeLabel(l10n, StoryBlockType.placeReference),
        l10n.storyEditorBlockPlaceReferenceDescription,
        Icons.place_outlined,
      ),
      if (UserRouteFeatureFlags.customRoutesEnabled)
        _BlockOption(
          StoryBlockType.routeReference,
          storyBlockTypeLabel(l10n, StoryBlockType.routeReference),
          l10n.storyEditorBlockRouteReferenceDescription,
          Icons.route_rounded,
        ),
    ];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          key: const ValueKey('story-add-block-sheet-chrome'),
          decoration: AppBoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppPalette.warmSurface21, AppPalette.warmInk63],
            ),
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(adaptive.radius(28)),
            ),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.black.withValues(alpha: 0.36),
                blurRadius: adaptive.scale(30),
                offset: Offset(0, adaptive.scale(-8)),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterSheetHeader(
                  title: l10n.storyEditorAddBlockTitle,
                  clearLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonLabel,
                  onClear: () => Navigator.maybePop(context),
                  height: adaptive.scale(46),
                  horizontalPadding: horizontalPadding,
                  titleFontSize: adaptive.scale(16),
                  clearFontSize: adaptive.scale(12),
                ),
                Flexible(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: AppEdgeInsets.fromLTRB(
                      horizontalPadding,
                      adaptive.scale(14),
                      horizontalPadding,
                      adaptive.scale(18) + safeBottomInset,
                    ),
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: adaptive.scale(10)),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return _BlockOptionTile(
                        option: option,
                        onTap: () => onSelected(option.type),
                      );
                    },
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

class _BlockOptionTile extends StatelessWidget {
  const _BlockOptionTile({required this.option, required this.onTap});

  final _BlockOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final radius = AppBorderRadius.circular(adaptive.radius(18));
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          key: ValueKey('story-add-block-option-${option.type.name}'),
          decoration: AppBoxDecoration(
            color: AppPalette.warmSurface28,
            borderRadius: radius,
            border: Border.all(
              color: AppPalette.primary.withValues(alpha: 0.13),
            ),
          ),
          child: Padding(
            padding: AppEdgeInsets.symmetric(
              horizontal: adaptive.scale(14),
              vertical: adaptive.scale(13),
            ),
            child: Row(
              children: [
                Container(
                  width: adaptive.scale(42),
                  height: adaptive.scale(42),
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.primary.withValues(alpha: 0.13),
                    border: Border.all(
                      color: AppPalette.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    option.icon,
                    color: AppPalette.primary,
                    size: adaptive.scale(21),
                  ),
                ),
                SizedBox(width: adaptive.scale(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: StoryPalette.text,
                          fontSize: adaptive.scale(15.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: adaptive.scale(4)),
                      Text(
                        option.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: StoryPalette.textSoft.withValues(alpha: 0.82),
                          fontSize: adaptive.scale(12.5),
                          height: 1.22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: adaptive.scale(8)),
                Icon(
                  Icons.add_rounded,
                  color: AppPalette.primary,
                  size: adaptive.scale(22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockOption {
  const _BlockOption(this.type, this.title, this.subtitle, this.icon);

  final StoryBlockType type;
  final String title;
  final String subtitle;
  final IconData icon;
}
