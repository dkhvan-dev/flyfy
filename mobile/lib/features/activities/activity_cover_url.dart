import '../../core/config/app_config.dart';
import 'models/activity_list_item_vm.dart';

String? resolveActivityCoverUrl(ActivityListItemVm item) {
  final activityId = item.id.trim();
  final coverFileId = (item.coverFileId ?? '').trim();

  if (activityId.isNotEmpty && coverFileId.isNotEmpty) {
    return '${AppConfig.apiBaseUrl}/activities/$activityId/cover';
  }

  final rawUrl = (item.coverImageUrl ?? '').trim();
  if (rawUrl.isEmpty) {
    return null;
  }
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${AppConfig.apiBaseUrl}$rawUrl';
  }
  return '${AppConfig.apiBaseUrl}/$rawUrl';
}
