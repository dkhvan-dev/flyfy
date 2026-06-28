import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Help Center localization does not keep legacy support request keys',
    () {
      const legacyKeys = [
        'helpCenterCategoryAccount',
        'helpCenterCategoryActivities',
        'helpCenterCategoryExcursions',
        'helpCenterCategoryPlaces',
        'helpCenterCategoryPayments',
        'helpCenterCategoryCurrency',
        'helpCenterCategoryTechnical',
        'supportTicketCreated',
        'supportRequestsTitle',
        'supportRequestsEmptyTitle',
        'supportRequestsEmptyMessage',
        'supportRequestsCreateTicket',
        'supportRequestsCreatingTicket',
        'supportRequestsCreateFailed',
        'supportTicketAttachmentComingSoon',
      ];
      final files = [
        'lib/l10n/app_en.arb',
        'lib/l10n/app_ru.arb',
        'lib/l10n/app_kk.arb',
        'lib/l10n/generated/app_localizations.dart',
        'lib/l10n/generated/app_localizations_en.dart',
        'lib/l10n/generated/app_localizations_ru.dart',
        'lib/l10n/generated/app_localizations_kk.dart',
      ];

      for (final file in files) {
        final contents = File(file).readAsStringSync();
        for (final key in legacyKeys) {
          expect(
            contents.contains(key),
            isFalse,
            reason: '$key should not remain in $file',
          );
        }
      }
    },
  );
}
