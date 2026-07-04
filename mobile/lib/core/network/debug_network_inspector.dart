import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef DebugNetworkInspectorFactory = Interceptor Function();

final class DebugNetworkInspector {
  const DebugNetworkInspector._();

  static const bool isEnabled =
      kDebugMode && bool.fromEnvironment('ENABLE_DEBUG_NETWORK_INSPECTOR');

  static GlobalKey<NavigatorState>? get navigatorKey {
    if (!isEnabled) return null;
    _configure();
    return ChuckerFlutter.navigatorKey;
  }

  static void attachToDio(
    Dio dio, {
    bool enabled = isEnabled,
    DebugNetworkInspectorFactory? factory,
  }) {
    if (!enabled) return;
    _configure();
    dio.interceptors.add((factory ?? ChuckerDioInterceptor.new)());
  }

  static void _configure() {
    ChuckerFlutter.configure(showOnRelease: false, showNotification: true);
  }
}
