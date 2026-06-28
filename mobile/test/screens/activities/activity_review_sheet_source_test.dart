import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'activity review publish asks for confirmation before closing sheet',
    () async {
      final source = await File(
        'lib/screens/activities/widgets/activity_review_sheet.dart',
      ).readAsString();
      final submitStart = source.indexOf('Future<void> _submit()');
      final buildStart = source.indexOf('@override', submitStart);

      expect(submitStart, isNonNegative);
      expect(buildStart, greaterThan(submitStart));

      final submitSource = source.substring(submitStart, buildStart);
      final dialogStart = submitSource.indexOf('showAppModalDialog<bool>');
      final popStart = submitSource.indexOf(
        'Navigator.of(context).pop(\n      SaveActivityReviewsRequest',
      );

      expect(dialogStart, isNonNegative);
      expect(popStart, greaterThan(dialogStart));
      expect(submitSource, contains('Dialog('));
      expect(submitSource, contains('activityReviewPublishConfirmTitle'));
      expect(submitSource, contains('activityReviewPublishConfirmDescription'));
      expect(submitSource, contains('activityReviewPublishConfirmButton'));
      expect(submitSource, contains('confirmed != true'));
    },
  );

  test(
    'activity review confirmation dialog uses activity filter palette',
    () async {
      final source = await File(
        'lib/screens/activities/widgets/activity_review_sheet.dart',
      ).readAsString();
      final submitStart = source.indexOf('Future<void> _submit()');
      final buildStart = source.indexOf('@override', submitStart);
      expect(submitStart, isNonNegative);
      expect(buildStart, greaterThan(submitStart));

      final submitSource = source.substring(submitStart, buildStart);
      expect(submitSource, contains('LinearGradient('));
      expect(submitSource, contains('AppPalette.warmSurface21'));
      expect(submitSource, contains('AppPalette.warmInk63'));
      expect(submitSource, contains('AppPalette.warmSurface66'));
      expect(submitSource, contains('AppPalette.primary'));
      expect(submitSource, contains('Wrap('));
    },
  );

  test(
    'activity review editor gives SwitchListTile a Material ancestor',
    () async {
      final source = await File(
        'lib/screens/activities/widgets/activity_review_sheet.dart',
      ).readAsString();
      final editorStart = source.indexOf('class _ActivityReviewEditor');
      expect(editorStart, isNonNegative);

      final editorSource = source.substring(editorStart);
      final materialStart = editorSource.indexOf('Material(');
      final switchStart = editorSource.indexOf('SwitchListTile.adaptive(');

      expect(materialStart, isNonNegative);
      expect(switchStart, isNonNegative);
      expect(materialStart, lessThan(switchStart));
      expect(editorSource, contains('color: AppPalette.transparent'));
    },
  );
}
