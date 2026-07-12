import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerAppAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/NotoEmoji-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Noto Emoji font'], license);
  });

  LicenseRegistry.addLicense(() async* {
    final notice = await rootBundle.loadString('assets/emoji/noto/NOTICE.txt');
    final license = await rootBundle.loadString(
      'assets/emoji/noto/LICENSE-APACHE-2.0.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Noto Emoji artwork',
    ], '$notice\n\n$license');
  });
}
