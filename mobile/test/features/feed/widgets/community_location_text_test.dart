import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/widgets/community_location_text.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';

void main() {
  testWidgets(
    'localizes city-only community location using country-aware lookup',
    (tester) async {
      final resolver = _CountryAwareResolver();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FeedCommunityLocationText(
              community: FeedCommunityVm(
                id: 'community-1',
                title: 'Афиша',
                countryCode: 'KZ',
                cityId: 'almaty',
                cityName: 'Almaty',
              ),
              resolver: resolver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resolver.countryCodes, ['KZ']);
      expect(find.text('Алматы'), findsOneWidget);
      expect(find.text('Алматы, Казахстан'), findsNothing);
      expect(find.text('Almaty'), findsNothing);
    },
  );
}

class _CountryAwareResolver extends AppLocationLabelResolver {
  final List<String?> countryCodes = [];

  @override
  Future<String> resolve({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) async {
    countryCodes.add(countryCode);
    if (countryCode == null || countryCode.trim().isEmpty) {
      return cityName ?? cityId ?? '';
    }
    return localeName.startsWith('ru') ? 'Алматы, Казахстан' : 'Almaty, KZ';
  }
}
