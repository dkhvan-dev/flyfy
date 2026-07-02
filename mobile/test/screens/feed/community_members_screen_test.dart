import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/data/community_moderation_api.dart';
import 'package:inflap/features/feed/models/community_moderation_vm.dart';
import 'package:inflap/features/feed/presentation/community_members_screen.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  test('community members screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/features/feed/presentation/community_members_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceHigh'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.border'));
    expect(source, isNot(contains('AppPalette.')));
  });

  testWidgets('loads members and updates selected member role', (tester) async {
    final api = _FakeCommunityModerationApi(
      members: [
        _member(userId: 'user-admin', role: 'ADMIN', nickname: 'Aigerim'),
        _member(userId: 'user-member', role: 'MEMBER', nickname: 'Daniyar'),
      ],
    );

    await tester.pumpWidget(_membersApp(api));
    await tester.pumpAndSettle();

    expect(api.listMemberCalls, ['community-1:ACTIVE::0']);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Aigerim'), findsOneWidget);
    expect(find.text('Daniyar'), findsOneWidget);
    expect(find.text('MEMBER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('change-role-user-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moderator').last);
    await tester.pumpAndSettle();

    expect(api.updatedRoles, {'user-member': 'MODERATOR'});
    expect(find.text('MODERATOR'), findsOneWidget);
    expect(find.text('Role updated'), findsOneWidget);
  });

  testWidgets('renders members screen on narrow width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeCommunityModerationApi(
      members: [
        _member(
          userId: 'user-long',
          role: 'TRUSTED_MEMBER',
          nickname: 'A very long localized member name',
        ),
      ],
    );

    await tester.pumpWidget(_membersApp(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('very long localized'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows selected member role change history', (tester) async {
    final api = _FakeCommunityModerationApi(
      members: [
        _member(userId: 'user-member', role: 'MODERATOR', nickname: 'Daniyar'),
      ],
      roleChanges: {
        'user-member': [
          _roleChange(
            targetUserId: 'user-member',
            actorUserId: 'user-admin',
            actorNickname: 'Aigerim',
            previousRole: 'MEMBER',
            nextRole: 'MODERATOR',
          ),
        ],
      },
    );

    await tester.pumpWidget(_membersApp(api));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('member-role-history-user-member')),
    );
    await tester.pumpAndSettle();

    expect(api.roleChangeCalls, ['community-1:user-member:0']);
    expect(find.text('Role history'), findsOneWidget);
    expect(find.text('MEMBER -> MODERATOR'), findsOneWidget);
    expect(find.textContaining('Aigerim'), findsOneWidget);
  });

  testWidgets('filters members by selected status', (tester) async {
    final api = _FakeCommunityModerationApi(
      members: [
        _member(userId: 'user-active', role: 'MEMBER', nickname: 'Aigerim'),
        _member(
          userId: 'user-banned',
          role: 'MEMBER',
          nickname: 'Daniyar',
          status: 'BANNED',
        ),
      ],
    );

    await tester.pumpWidget(_membersApp(api));
    await tester.pumpAndSettle();

    expect(api.listMemberCalls, ['community-1:ACTIVE::0']);
    expect(find.text('Aigerim'), findsOneWidget);
    expect(find.text('Daniyar'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('community-members-status-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banned').last);
    await tester.pumpAndSettle();

    expect(api.listMemberCalls.last, 'community-1:BANNED::0');
    expect(find.text('Daniyar'), findsOneWidget);
    expect(find.text('Aigerim'), findsNothing);
  });

  testWidgets('bans selected member from status actions', (tester) async {
    final api = _FakeCommunityModerationApi(
      members: [
        _member(userId: 'user-member', role: 'MEMBER', nickname: 'Daniyar'),
      ],
    );

    await tester.pumpWidget(_membersApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('change-status-user-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ban member').last);
    await tester.pumpAndSettle();

    expect(api.updatedStatuses, {'user-member': 'BANNED'});
    expect(find.text('Status updated'), findsOneWidget);
    expect(find.text('Daniyar'), findsNothing);
  });
}

Widget _membersApp(CommunityModerationApi api) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CommunityMembersScreen(
      communityId: 'community-1',
      communityTitle: 'Investments',
      moderationApi: api,
    ),
  );
}

CommunityMemberVm _member({
  required String userId,
  required String role,
  required String nickname,
  String status = 'ACTIVE',
}) {
  final now = DateTime.utc(2026, 6, 11);
  return CommunityMemberVm(
    communityId: 'community-1',
    userId: userId,
    role: role,
    status: status,
    user: PostAuthorVm(
      userId: userId,
      nickname: nickname,
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    createdAt: now,
    updatedAt: now,
  );
}

CommunityMemberRoleChangeVm _roleChange({
  required String targetUserId,
  required String actorUserId,
  required String actorNickname,
  required String previousRole,
  required String nextRole,
}) {
  return CommunityMemberRoleChangeVm(
    id: 'change-$targetUserId',
    communityId: 'community-1',
    targetUserId: targetUserId,
    actorUserId: actorUserId,
    actor: PostAuthorVm(
      userId: actorUserId,
      nickname: actorNickname,
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    previousRole: previousRole,
    nextRole: nextRole,
    createdAt: DateTime.utc(2026, 6, 11, 12),
  );
}

class _FakeCommunityModerationApi implements CommunityModerationApi {
  _FakeCommunityModerationApi({
    required List<CommunityMemberVm> members,
    Map<String, List<CommunityMemberRoleChangeVm>> roleChanges = const {},
  }) : _members = [...members],
       _roleChanges = Map.unmodifiable(roleChanges);

  final List<CommunityMemberVm> _members;
  final Map<String, List<CommunityMemberRoleChangeVm>> _roleChanges;
  final List<String> listMemberCalls = [];
  final List<String> roleChangeCalls = [];
  final Map<String, String> updatedRoles = {};
  final Map<String, String> updatedStatuses = {};

  @override
  Future<CommunityMemberPageVm> listMembers({
    required String communityId,
    String? role,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    listMemberCalls.add('$communityId:${status ?? ''}:${role ?? ''}:$offset');
    final items = _members
        .where((member) {
          final roleMatches =
              role == null || role.isEmpty || member.role == role;
          final statusMatches =
              status == null || status.isEmpty || member.status == status;
          return roleMatches && statusMatches;
        })
        .toList(growable: false);
    return CommunityMemberPageVm(
      items: items,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<CommunityMembershipVm> updateMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    updatedRoles[userId] = role;
    final index = _members.indexWhere((member) => member.userId == userId);
    if (index < 0) {
      throw StateError('Missing member $userId');
    }
    final updated = _members[index].copyWith(role: role);
    _members[index] = updated;
    return CommunityMembershipVm(
      communityId: communityId,
      userId: userId,
      role: role,
      status: updated.status,
      createdAt: updated.createdAt,
      updatedAt: DateTime.utc(2026, 6, 11, 12),
    );
  }

  @override
  Future<CommunityMembershipVm> updateMemberStatus({
    required String communityId,
    required String userId,
    required String status,
  }) async {
    updatedStatuses[userId] = status;
    final index = _members.indexWhere((member) => member.userId == userId);
    if (index < 0) {
      throw StateError('Missing member $userId');
    }
    final updated = _members[index].copyWith(status: status);
    _members[index] = updated;
    return CommunityMembershipVm(
      communityId: communityId,
      userId: userId,
      role: updated.role,
      status: status,
      createdAt: updated.createdAt,
      updatedAt: DateTime.utc(2026, 6, 11, 13),
    );
  }

  @override
  Future<CommunityMemberRoleChangePageVm> listMemberRoleChanges({
    required String communityId,
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    roleChangeCalls.add('$communityId:$userId:$offset');
    return CommunityMemberRoleChangePageVm(
      items: _roleChanges[userId] ?? const [],
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<CommunityModerationPostPageVm> listPendingPosts({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PostVm> approvePost({
    required String communityId,
    required String postId,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PostVm> rejectPost({
    required String communityId,
    required String postId,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PostModerationDecisionPageVm> listPostDecisions({
    required String communityId,
    required String postId,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }
}
