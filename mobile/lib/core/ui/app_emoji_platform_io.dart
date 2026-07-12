import 'dart:io';

bool get requiresBundledEmojiTextFallback {
  if (!Platform.isIOS) return false;
  final majorVersion = parseOperatingSystemMajorVersion(
    Platform.operatingSystemVersion,
  );
  return majorVersion != null && majorVersion >= 26;
}

int? parseOperatingSystemMajorVersion(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
