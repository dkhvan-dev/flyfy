import 'activity_list_item_vm.dart';

class ActivityListPageVm {
  const ActivityListPageVm({required this.items, required this.hasMore});

  final List<ActivityListItemVm> items;
  final bool hasMore;

  factory ActivityListPageVm.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ActivityListItemVm.fromJson)
              .toList(growable: false)
        : const <ActivityListItemVm>[];

    return ActivityListPageVm(items: items, hasMore: json['hasMore'] == true);
  }
}
