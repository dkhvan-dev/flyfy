import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inflap/core/network/sticker_api.dart';
import 'package:inflap/features/chat/models/sticker_group_vm.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/sticker_catalog_provider.dart';
import 'package:inflap/screens/chat/widgets/sticker_picker_sheet.dart';

void main() {
  testWidgets('shows pack tabs and sticker grid', (tester) async {
    final provider = await _loadedProvider();

    await tester.pumpWidget(_buildTestApp(provider));

    expect(find.text('Travel Basics'), findsOneWidget);
    expect(find.byKey(const ValueKey('sticker-pack-tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('sticker-grid')), findsOneWidget);
  });

  testWidgets('tapping sticker sends selected sticker', (tester) async {
    final selected = <StickerVm>[];
    final provider = await _loadedProvider();

    await tester.pumpWidget(
      _buildTestApp(provider, onStickerSelected: selected.add),
    );

    await tester.tap(find.byKey(const ValueKey('sticker-sticker1')));
    await tester.pump();

    expect(selected.single.id, 'sticker1');
  });
}

Widget _buildTestApp(
  StickerCatalogProvider provider, {
  ValueChanged<StickerVm>? onStickerSelected,
}) {
  return ChangeNotifierProvider<StickerCatalogProvider>.value(
    value: provider,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StickerPickerSheet(
          onStickerSelected: onStickerSelected ?? (_) {},
        ),
      ),
    ),
  );
}

Future<StickerCatalogProvider> _loadedProvider() async {
  final provider = StickerCatalogProvider(api: _FakeStickerCatalogClient());
  await provider.loadCatalog(locale: 'en');
  return provider;
}

class _FakeStickerCatalogClient implements StickerCatalogClient {
  @override
  Future<StickerCatalogResponse> listOfficialCatalog({
    required String locale,
  }) async {
    return StickerCatalogResponse(
      version: 1,
      groups: [
        StickerGroupVm(
          id: 'group1',
          slug: 'travel',
          title: 'Travel',
          packs: [
            StickerPackVm(
              id: 'pack1',
              slug: 'travel-basics',
              title: const {'en': 'Travel Basics'},
              stickers: const [
                StickerVm(
                  id: 'sticker1',
                  packId: 'pack1',
                  slug: 'boarding-pass',
                  fileId: 'file1',
                  fallbackFileId: 'file1',
                  emoji: '✈️',
                  keywords: ['flight'],
                  status: 'active',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<List<StickerVm>> listPackStickers(
    String packId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return const [];
  }

  @override
  Future<List<StickerVm>> listRecentStickers({int limit = 40}) async {
    return const [];
  }

  @override
  Future<List<StickerVm>> searchStickers(
    String query, {
    required String locale,
    int limit = 50,
    int offset = 0,
  }) async {
    return const [];
  }
}
