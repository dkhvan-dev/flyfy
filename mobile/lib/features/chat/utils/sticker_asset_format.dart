import 'dart:convert';
import 'dart:typed_data';

const telegramTGSContentType = 'application/x-tgsticker';

enum StickerAssetContentFormat { tgsGzip, lottieJson, rasterImage, unknown }

StickerAssetContentFormat resolveStickerAssetContentFormat(
  Uint8List bytes, {
  String responseContentType = '',
  String declaredContentType = '',
}) {
  final responseType = _normalizeContentType(responseContentType);
  final declaredType = _normalizeContentType(declaredContentType);

  if (hasGZipMagic(bytes)) {
    return StickerAssetContentFormat.tgsGzip;
  }
  if (_hasRasterImageMagic(bytes)) {
    return StickerAssetContentFormat.rasterImage;
  }
  if (_looksLikeLottieJson(bytes)) {
    return StickerAssetContentFormat.lottieJson;
  }
  if (_isRasterImage(responseType) || _isRasterImage(declaredType)) {
    return StickerAssetContentFormat.rasterImage;
  }
  if (responseType == telegramTGSContentType ||
      declaredType == telegramTGSContentType) {
    return StickerAssetContentFormat.lottieJson;
  }

  return StickerAssetContentFormat.unknown;
}

bool hasGZipMagic(Uint8List bytes) {
  return bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
}

String _normalizeContentType(String value) {
  return value.split(';').first.trim().toLowerCase();
}

bool _isRasterImage(String contentType) {
  return contentType.startsWith('image/');
}

bool _hasRasterImageMagic(Uint8List bytes) {
  return _hasPngMagic(bytes) ||
      _hasJpegMagic(bytes) ||
      _hasGifMagic(bytes) ||
      _hasWebPMagic(bytes);
}

bool _hasPngMagic(Uint8List bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47;
}

bool _hasJpegMagic(Uint8List bytes) {
  return bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
}

bool _hasGifMagic(Uint8List bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38;
}

bool _hasWebPMagic(Uint8List bytes) {
  return bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}

bool _looksLikeLottieJson(Uint8List bytes) {
  if (bytes.isEmpty) {
    return false;
  }

  final probeLength = bytes.length < 4096 ? bytes.length : 4096;
  final probe = utf8
      .decode(bytes.sublist(0, probeLength), allowMalformed: true)
      .trimLeft();

  return probe.startsWith('{') &&
      probe.contains('"v"') &&
      probe.contains('"layers"');
}
