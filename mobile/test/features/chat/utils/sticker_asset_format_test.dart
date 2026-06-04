import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/chat/utils/sticker_asset_format.dart';

void main() {
  group('resolveStickerAssetContentFormat', () {
    test('detects gzip tgs bytes without relying on response content type', () {
      final bytes = Uint8List.fromList([0x1f, 0x8b, 0x08, 0x00]);

      expect(
        resolveStickerAssetContentFormat(bytes),
        StickerAssetContentFormat.tgsGzip,
      );
    });

    test('detects raw lottie json when proxy strips sticker mime type', () {
      final bytes = Uint8List.fromList(
        utf8.encode(
          '{"v":"5.7.4","fr":60,"ip":0,"op":60,"w":512,"h":512,"layers":[]}',
        ),
      );

      expect(
        resolveStickerAssetContentFormat(bytes),
        StickerAssetContentFormat.lottieJson,
      );
    });

    test(
      'uses declared sticker content type when response type is generic',
      () {
        final bytes = Uint8List.fromList(
          utf8.encode('{"v":"5.7.4","layers":[]}'),
        );

        expect(
          resolveStickerAssetContentFormat(
            bytes,
            responseContentType: 'application/octet-stream',
            declaredContentType: 'application/x-tgsticker',
          ),
          StickerAssetContentFormat.lottieJson,
        );
      },
    );

    test('keeps normal image bytes as raster images', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);

      expect(
        resolveStickerAssetContentFormat(
          bytes,
          responseContentType: 'image/png',
        ),
        StickerAssetContentFormat.rasterImage,
      );
    });

    test(
      'prefers raster byte signature over declared sticker content type',
      () {
        final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);

        expect(
          resolveStickerAssetContentFormat(
            bytes,
            responseContentType: 'application/octet-stream',
            declaredContentType: 'application/x-tgsticker',
          ),
          StickerAssetContentFormat.rasterImage,
        );
      },
    );
  });
}
