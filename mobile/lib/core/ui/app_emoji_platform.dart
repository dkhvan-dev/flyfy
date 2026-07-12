import 'app_emoji_platform_stub.dart'
    if (dart.library.io) 'app_emoji_platform_io.dart'
    as platform;

bool get requiresBundledEmojiTextFallback =>
    platform.requiresBundledEmojiTextFallback;
