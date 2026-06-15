import '../../profile/data/profile_api.dart';
import '../../profile/models/profile_follower_vm.dart';
import '../models/feed_block_vm.dart';
import 'feed_api.dart';

class FeedSubscriptionsApi {
  FeedSubscriptionsApi({FeedApi? feedApi, ProfileApi? profileApi})
    : _feedApi = feedApi ?? FeedApi(),
      _profileApi = profileApi ?? ProfileApi();

  final FeedApi _feedApi;
  final ProfileApi _profileApi;

  Future<FeedSubscriptionsVm> getMySubscriptions({int limit = 20}) async {
    final safeLimit = limit <= 0 ? 20 : limit;
    final results = await Future.wait<Object>([
      _feedApi.listCommunities(onlyFollowed: true, limit: safeLimit),
      _profileApi.getMyFriends(limit: safeLimit),
      _profileApi.getMyFollowing(limit: safeLimit),
    ]);

    final communities = (results[0] as CommunityListPageVm).items
        .where((community) => community.followedByViewer)
        .toList(growable: false);
    final friends = (results[1] as ProfileFollowersPageVm).items;
    final following = (results[2] as ProfileFollowersPageVm).items;

    return FeedSubscriptionsVm(
      communities: communities,
      people: _mergePeople(friends: friends, following: following),
    );
  }
}

List<FeedPersonVm> _mergePeople({
  required List<ProfileFollowerVm> friends,
  required List<ProfileFollowerVm> following,
}) {
  final byUserId = <String, FeedPersonVm>{};

  void add(ProfileFollowerVm user, FeedPersonRelationship relationship) {
    final userId = user.userId.trim();
    if (userId.isEmpty) {
      return;
    }

    final current = byUserId[userId];
    final isFriend =
        relationship == FeedPersonRelationship.friend ||
        current?.relationship == FeedPersonRelationship.friend;
    byUserId[userId] = FeedPersonVm(
      userId: userId,
      nickname: _trimmedOrNull(user.nickname),
      avatarFileId: _trimmedOrNull(user.avatarFileId),
      relationship: isFriend
          ? FeedPersonRelationship.friend
          : FeedPersonRelationship.following,
      isOnline: user.isOnline || (current?.isOnline ?? false),
    );
  }

  for (final user in friends) {
    add(user, FeedPersonRelationship.friend);
  }
  for (final user in following) {
    add(user, FeedPersonRelationship.following);
  }

  final people = byUserId.values.toList(growable: false)
    ..sort((a, b) {
      final relationshipCompare = a.relationship.index.compareTo(
        b.relationship.index,
      );
      if (relationshipCompare != 0) {
        return relationshipCompare;
      }
      if (a.isOnline != b.isOnline) {
        return a.isOnline ? -1 : 1;
      }
      return a
          .displayName(a.userId)
          .toLowerCase()
          .compareTo(b.displayName(b.userId).toLowerCase());
    });
  return List<FeedPersonVm>.unmodifiable(people);
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
