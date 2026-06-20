import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'place details lets authors manage excursion reviews from long press',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      expect(source, contains('showExcursionReviewActionsSheet('));
      expect(source, contains('showExcursionReviewEditSheet('));
      expect(source, contains('_openExcursionReviewActions'));
      expect(source, contains('onLongPress:'));
      expect(source, contains('review.author.userId'));
      expect(source, contains('saveExcursionReview('));
      expect(source, contains('deleteExcursionReview('));
    },
  );
}
