import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/models/save_post_request.dart';

void main() {
  test('SavePostRequest defaults to editor article format', () {
    final request = SavePostRequest(
      title: 'Title',
      content: 'Body',
      category: 'JOURNAL',
      status: 'DRAFT',
    );

    expect(request.toJson()['format'], 'ARTICLE');
    expect(request.toJson(), isNot(contains('expiresAt')));
  });

  test('SavePostRequest includes normalized place city id', () {
    final request = SavePostRequest(
      title: 'Title',
      content: 'Body',
      category: 'JOURNAL',
      status: 'PUBLISHED',
      placeName: 'Almaty, Kazakhstan',
      placeCountryCode: ' kz ',
      placeCityId: ' almaty ',
    );

    expect(request.toJson()['placeCountryCode'], 'KZ');
    expect(request.toJson()['placeCityId'], 'almaty');
  });
}
