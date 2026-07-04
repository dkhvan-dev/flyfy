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

  test('activity review sheet uses adaptive V2 palette', () async {
    final source = await File(
      'lib/screens/activities/widgets/activity_review_sheet.dart',
    ).readAsString();
    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(dialogContext)'));
    expect(source, contains('AppButtonStyles.primary(colors)'));
    expect(source, contains('AppButtonStyles.primary(dialogColors)'));
    expect(source, contains('_activityReviewSheetDecoration('));
    expect(source, contains('_activityReviewEditorDecoration('));
    expect(source, contains('_activityReviewInputDecoration('));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, contains('colors.danger'));
    expect(source, contains('colors.transparent'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'activity review confirmation dialog keeps responsive confirmation flow',
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
      expect(submitSource, contains('dialogColors.surfaceRaised'));
      expect(submitSource, contains('dialogColors.background'));
      expect(submitSource, contains('dialogColors.borderPrimary'));
      expect(submitSource, contains('dialogColors.primary'));
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
      expect(editorSource, contains('color: colors.transparent'));
    },
  );

  test(
    'activity review sheet uses secondary only for neutral criteria hints',
    () async {
      final source = await File(
        'lib/screens/activities/widgets/activity_review_sheet.dart',
      ).readAsString();
      final helperStart = source.indexOf('class _ActivityReviewCriteriaHint');
      final editorStart = source.indexOf('class _ActivityReviewEditor');
      final inputStart = source.indexOf(
        'InputDecoration _activityReviewInputDecoration',
      );

      expect(helperStart, isNonNegative);
      expect(editorStart, isNonNegative);
      expect(inputStart, isNonNegative);

      final helperSource = source.substring(helperStart, editorStart);
      final editorSource = source.substring(editorStart, inputStart);

      expect(helperSource, contains('colors.secondaryContainer'));
      expect(helperSource, contains('colors.borderSecondary'));
      expect(helperSource, contains('color: colors.secondary'));
      expect(helperSource, contains('l10n.myExcursionsReviewRating'));
      expect(editorSource, contains('_ActivityReviewCriteriaHint('));
      expect(editorSource, contains('color: colors.primary'));
    },
  );
}
