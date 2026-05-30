import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/pagination_bar.dart';

void main() {
  testWidgets('shows adjacent page numbers on regular width pages', (
    tester,
  ) async {
    int? selectedPage;

    await tester.pumpWidget(
      _PaginationTestApp(
        width: 430,
        child: InflapPaginationBar(
          currentPage: 5,
          totalPages: 10,
          onPageChanged: (page) => selectedPage = page,
          showLabel: false,
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.text('6'));
    expect(selectedPage, 6);
  });

  testWidgets('keeps adjacent page numbers on compact width pages', (
    tester,
  ) async {
    int? selectedPage;

    await tester.pumpWidget(
      _PaginationTestApp(
        width: 390,
        child: InflapPaginationBar(
          currentPage: 5,
          totalPages: 10,
          onPageChanged: (page) => selectedPage = page,
          showLabel: false,
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.text('4'));
    expect(selectedPage, 4);
  });
}

class _PaginationTestApp extends StatelessWidget {
  const _PaginationTestApp({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: child,
          ),
        ),
      ),
    );
  }
}
