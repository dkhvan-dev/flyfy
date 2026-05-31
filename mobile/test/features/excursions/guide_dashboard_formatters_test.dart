import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:inflap/features/excursions/guide_dashboard_formatters.dart';

void main() {
  test('formats guide revenue as full amount like excursion list', () {
    expect(
      formatGuideDashboardRevenue(
        amount: 123456,
        currency: 'KZT',
        localeName: 'ru',
      ),
      NumberFormat.simpleCurrency(name: 'KZT', decimalDigits: 0).format(123456),
    );
    expect(
      formatGuideDashboardRevenue(
        amount: 1250000,
        currency: 'KZT',
        localeName: 'ru',
      ),
      NumberFormat.simpleCurrency(
        name: 'KZT',
        decimalDigits: 0,
      ).format(1250000),
    );
  });
}
