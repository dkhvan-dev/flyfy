import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';
import 'package:inflap/shared/widgets/app_localized_location_text.dart';

void main() {
  testWidgets('shows readable fallback while resolving structured location', (
    tester,
  ) async {
    final completer = Completer<String>();
    final resolver = _FakeLocationLabelResolver((_) => completer.future);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: AppLocalizedLocationText(
            countryCode: 'KZ',
            cityId: 'almaty',
            cityName: 'Almaty',
            fallbackText: 'Almaty, KZ',
            resolver: resolver,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Almaty, KZ'), findsOneWidget);

    completer.complete('Алматы, Казахстан');
    await tester.pump();
    await tester.pump();

    expect(find.text('Алматы, Казахстан'), findsOneWidget);
  });

  testWidgets('shows readable fallback while resolving legacy city name', (
    tester,
  ) async {
    final completer = Completer<String>();
    final resolver = _FakeLocationLabelResolver((_) => completer.future);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: AppLocalizedLocationText(
            countryCode: null,
            cityId: null,
            cityName: 'Almaty',
            fallbackText: 'Almaty',
            resolver: resolver,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Almaty'), findsOneWidget);

    completer.complete('Алматы');
    await tester.pump();
    await tester.pump();

    expect(find.text('Алматы'), findsOneWidget);
  });

  testWidgets(
    'localizes structured location while preserving address details',
    (tester) async {
      final completer = Completer<String>();
      final resolver = _FakeLocationLabelResolver(
        (_) => Future.value('Алматы, Казахстан'),
        resolveAddress: (_) => completer.future,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: AppLocalizedLocationText(
              countryCode: 'KZ',
              cityId: 'almaty',
              cityName: 'Almaty',
              fallbackText: 'Almaty, Kazakhstan, Bayzakova 127',
              addressText: 'Almaty, Kazakhstan, Bayzakova 127',
              resolver: resolver,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Almaty, Kazakhstan, Bayzakova 127'), findsOneWidget);

      completer.complete('Алматы, Казахстан, Bayzakova 127');
      await tester.pump();
      await tester.pump();

      expect(find.text('Алматы, Казахстан, Bayzakova 127'), findsOneWidget);
    },
  );
}

class _FakeLocationLabelResolver extends AppLocationLabelResolver {
  _FakeLocationLabelResolver(this._resolve, {this._resolveAddress});

  final Future<String> Function(_LocationLookupRequest request) _resolve;
  final Future<String> Function(_AddressLookupRequest request)? _resolveAddress;

  @override
  Future<String> resolve({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) {
    return _resolve(
      _LocationLookupRequest(
        countryCode: countryCode,
        cityId: cityId,
        cityName: cityName,
        localeName: localeName,
      ),
    );
  }

  @override
  Future<String> resolveAddress({
    String? countryCode,
    String? cityId,
    String? cityName,
    String? addressText,
    required String localeName,
  }) {
    final handler = _resolveAddress;
    if (handler == null) {
      return super.resolveAddress(
        countryCode: countryCode,
        cityId: cityId,
        cityName: cityName,
        addressText: addressText,
        localeName: localeName,
      );
    }

    return handler(
      _AddressLookupRequest(
        countryCode: countryCode,
        cityId: cityId,
        cityName: cityName,
        addressText: addressText,
        localeName: localeName,
      ),
    );
  }
}

class _LocationLookupRequest {
  const _LocationLookupRequest({
    required this.countryCode,
    required this.cityId,
    required this.cityName,
    required this.localeName,
  });

  final String? countryCode;
  final String? cityId;
  final String? cityName;
  final String localeName;
}

class _AddressLookupRequest extends _LocationLookupRequest {
  const _AddressLookupRequest({
    required super.countryCode,
    required super.cityId,
    required super.cityName,
    required this.addressText,
    required super.localeName,
  });

  final String? addressText;
}
