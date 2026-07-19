import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../features/stories/models/post_vm.dart';
import '../../../features/stories/story_ui.dart';
import '../../../features/feed/widgets/post_saved_bookmark_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../profile_style.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({super.key, required this.post, required this.onTap});

  final PostVm post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final coverSize = profileScaled(context, 96, min: 84, max: 108);
    final gap = profileScaled(context, 14, min: 12, max: 16);
    final metaText = [
      formatStoryCategory(l10n, post.category),
      formatStoryDate(context, post.publishedAt ?? post.createdAt),
    ].where((item) => item.trim().isNotEmpty).join(' • ');

    return Semantics(
      button: true,
      container: true,
      label: post.title,
      onTap: onTap,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(
            profileScaled(context, 22, min: 18, max: 22),
          ),
          child: Ink(
            decoration: profileCardDecoration(context, highlighted: true),
            child: Padding(
              padding: AppEdgeInsets.all(profileScaled(context, 12, min: 10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: coverSize,
                    child: ClipRRect(
                      borderRadius: AppBorderRadius.circular(
                        profileScaled(context, 18, min: 14, max: 20),
                      ),
                      child: StoryCoverImage(url: post.coverUrl),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (metaText.isNotEmpty) ...[
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
                        ],
                        Text(
                          post.title,
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
                        if (post.excerpt.trim().isNotEmpty) ...[
                          SizedBox(height: profileScaled(context, 7, min: 6)),
                          Text(
                            post.excerpt.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: colors.textSecondary,
                              fontSize: profileScaled(
                                context,
                                13,
                                min: 12,
                                max: 14,
                              ),
                              height: 1.25,
                            ),
                          ),
                        ],
                        SizedBox(height: profileScaled(context, 10, min: 8)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: profileScaled(
                                context,
                                15,
                                min: 14,
                                max: 16,
                              ),
                              color: colors.primary.withValues(alpha: 0.78),
                            ),
                            SizedBox(width: profileScaled(context, 5, min: 4)),
                            Flexible(
                              child: Text(
                                '${formatStoryCountCompact(post.stats.views)} ${l10n.storyViewsSuffix}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.textSecondary,
                                  fontSize: profileScaled(
                                    context,
                                    12,
                                    min: 11,
                                    max: 13,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PostSavedBookmarkButton(post: post),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
