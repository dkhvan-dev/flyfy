import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/models/save_story_request.dart';

void main() {
  test('SaveStoryRequest includes normalized place city id', () {
    final request = SaveStoryRequest(
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
