import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/activity_api.dart';
import 'package:inflap/features/activities/models/activity_category_vm.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';
import 'package:inflap/providers/activity_provider.dart';

void main() {
  group('ActivityProvider pagination', () {
    test(
      'loadActivities fetches every page instead of only first 100',
      () async {
        final api = _PagingActivityApi(
          discoverPages: [
            _activities('discover', 100),
            _activities('discover-next', 25),
          ],
        );
        final provider = ActivityProvider(activityApi: api);

        await provider.loadActivities();

        expect(provider.state, ActivitiesState.success);
        expect(provider.items, hasLength(125));
        expect(api.discoverOffsets, [0, 100]);
      },
    );

    test('my and joined activities also fetch all available pages', () async {
      final api = _PagingActivityApi(
        hostedPages: [
          _activities('hosted', 100),
          _activities('hosted-next', 1),
        ],
        joinedPages: [
          _activities('joined', 100),
          _activities('joined-next', 3),
        ],
      );
      final provider = ActivityProvider(activityApi: api);

      await provider.loadMyActivities();
      await provider.loadJoinedActivities();

      expect(provider.myItems, hasLength(101));
      expect(provider.joinedItems, hasLength(103));
      expect(api.hostedOffsets, [0, 100]);
      expect(api.joinedOffsets, [0, 100]);
    });
  });
}

class _PagingActivityApi extends ActivityApi {
  _PagingActivityApi({
    this.discoverPages = const [],
    this.hostedPages = const [],
    this.joinedPages = const [],
  });

  final List<List<ActivityListItemVm>> discoverPages;
  final List<List<ActivityListItemVm>> hostedPages;
  final List<List<ActivityListItemVm>> joinedPages;

  final List<int> discoverOffsets = [];
  final List<int> hostedOffsets = [];
  final List<int> joinedOffsets = [];

  @override
  Future<List<ActivityCategoryVm>> getActivityCategories() async => const [];

  @override
  Future<List<ActivityListItemVm>> getActivities({
    int limit = 20,
    int offset = 0,
    String? hostUserId,
    String? status,
    String? categorySlug,
    String? subcategorySlug,
    String? cityId,
    String? cityName,
    String? query,
  }) async {
    discoverOffsets.add(offset);
    return _page(discoverPages, offset, limit);
  }

  @override
  Future<List<ActivityListItemVm>> getMyHostedActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    hostedOffsets.add(offset);
    return _page(hostedPages, offset, limit);
  }

  @override
  Future<List<ActivityListItemVm>> getMyJoinedActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    joinedOffsets.add(offset);
    return _page(joinedPages, offset, limit);
  }

  List<ActivityListItemVm> _page(
    List<List<ActivityListItemVm>> pages,
    int offset,
    int limit,
  ) {
    final pageIndex = offset ~/ limit;
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return const [];
    }
    return pages[pageIndex];
  }
}

List<ActivityListItemVm> _activities(String prefix, int count) {
  return List<ActivityListItemVm>.generate(
    count,
    (index) => ActivityListItemVm(
      id: '$prefix-$index',
      hostUserId: 'host-user',
      title: 'Activity $prefix $index',
      description: 'Description',
      format: 'OFFLINE',
      status: 'PUBLISHED',
      moderationStatus: 'APPROVED',
      visibility: 'PUBLIC',
      joinMode: 'OPEN',
      categorySlug: 'walks',
      languageCode: 'ru',
      timezone: 'Asia/Almaty',
      startAt: DateTime.parse('2026-05-01T10:00:00Z'),
      endAt: DateTime.parse('2026-05-01T12:00:00Z'),
      capacityType: 'LIMITED',
      priceType: 'FREE',
      requiresProfileCompletion: false,
      requiresAttendanceConfirmation: false,
    ),
  );
}
