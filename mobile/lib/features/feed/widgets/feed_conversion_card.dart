import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../models/feed_block_vm.dart';

class FeedConversionCard extends StatelessWidget {
  const FeedConversionCard({super.key, required this.block, this.onOpen});

  final FeedBlockVm block;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final title = _stringData(block, 'title') ?? '';
    final subtitle = _stringData(block, 'subtitle');
    final actionLabel = _stringData(block, 'actionLabel');
    final textTheme = Theme.of(context).textTheme;
    final icon = switch (block.type) {
      FeedBlockType.officialNewsCard => Icons.verified_outlined,
      FeedBlockType.profileCard => Icons.person_outline_rounded,
      _ => Icons.auto_awesome_outlined,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('open-feed-conversion-${block.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: AppColors.accent, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (actionLabel != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: onOpen,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              actionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
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

bool isRenderableFeedConversionBlock(FeedBlockVm block) {
  return _stringData(block, 'title') != null;
}

String? _stringData(FeedBlockVm block, String key) {
  final value = block.data[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
