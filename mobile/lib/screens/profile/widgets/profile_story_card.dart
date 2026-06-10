import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../features/stories/models/story_vm.dart';
import '../../../features/stories/story_ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../profile_style.dart';

class ProfileStoryCard extends StatelessWidget {
  const ProfileStoryCard({super.key, required this.story, required this.onTap});

  final StoryVm story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coverSize = profileScaled(context, 96, min: 84, max: 108);
    final gap = profileScaled(context, 14, min: 12, max: 16);
    final metaText = [
      formatStoryCategory(l10n, story.category),
      formatStoryDate(context, story.publishedAt ?? story.createdAt),
    ].where((item) => item.trim().isNotEmpty).join(' • ');

    return Semantics(
      button: true,
      container: true,
      label: story.title,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            profileScaled(context, 22, min: 18, max: 22),
          ),
          child: Ink(
            decoration: profileCardDecoration(context, highlighted: true),
            child: Padding(
              padding: EdgeInsets.all(profileScaled(context, 12, min: 10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: coverSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        profileScaled(context, 18, min: 14, max: 20),
                      ),
                      child: StoryCoverImage(url: story.coverUrl),
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
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
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
                        if (story.excerpt.trim().isNotEmpty) ...[
                          SizedBox(height: profileScaled(context, 7, min: 6)),
                          Text(
                            story.excerpt.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
                              color: AppColors.accent.withValues(alpha: 0.78),
                            ),
                            SizedBox(width: profileScaled(context, 5, min: 4)),
                            Flexible(
                              child: Text(
                                '${formatStoryCountCompact(story.stats.views)} ${l10n.storyViewsSuffix}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
