import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/guides/models/public_guide_vm.dart';

void main() {
  test(
      'parses unique excursion language codes separately from guide profile languages',
      () {
    final guide = PublicGuideVm.fromJson({
      'guideProfile': {
        'id': 'guide-profile-id',
        'userId': 'guide-user-id',
        'type': 'PRIVATE',
        'status': 'ACTIVE',
        'headline': '',
        'about': '',
        'isPrivateGuideAvailable': true,
        'isActivityHostAvailable': false,
        'isExcursionGuideAvailable': true,
        'ratingAvg': 4.8,
        'reviewsCount': 12,
        'languageCodes': ['en', 'ru'],
      },
      'userProfile': {'displayName': 'Aruzhan'},
      'excursionLanguageCodes': ['ru', 'kk', 'ru', ''],
    });

    expect(guide.languageCodes, ['en', 'ru']);
    expect(guide.excursionLanguageCodes, ['ru', 'kk']);
  });

  test('prefers guide legal surname and first name over display nickname', () {
    final guide = PublicGuideVm.fromJson({
      'guideProfile': {
        'id': 'guide-profile-id',
        'userId': 'guide-user-id',
      },
      'userProfile': {
        'firstName': 'Аружан',
        'lastName': 'Тулегенова',
        'displayName': '@nomad_aru',
      },
    });

    expect(guide.preferredName, 'Тулегенова Аружан');
  });
}
