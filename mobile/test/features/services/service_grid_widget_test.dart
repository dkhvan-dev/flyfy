import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/services/service_catalog.dart';
import 'package:inflap/features/services/widgets/service_grid.dart';

void main() {
  testWidgets(
    'service grid does not overflow on compact width with long labels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.35),
            ),
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: ServiceGrid(
                  services: const [
                    TravelServiceEntry(
                      title: 'Достопримечательности',
                      icon: Icons.account_balance_rounded,
                      route: '/attractions',
                    ),
                    TravelServiceEntry(
                      title: 'Курсы валют',
                      icon: Icons.currency_exchange_rounded,
                      route: '/currency-converter',
                    ),
                    TravelServiceEntry(
                      title: 'Транспорт',
                      icon: Icons.directions_car_filled_rounded,
                      route: '/car-rentals',
                      isAvailable: false,
                    ),
                  ],
                  onServiceTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}
