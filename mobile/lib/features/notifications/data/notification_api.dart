import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum PushPlatform {
  android('android'),
  ios('ios');

  const PushPlatform(this.wireValue);

  final String wireValue;
}

enum PushProvider {
  fcm('fcm'),
  apns('apns'),
  hms('hms');

  const PushProvider(this.wireValue);

  final String wireValue;
}

enum PushEnvironment {
  sandbox('sandbox'),
  production('production');

  const PushEnvironment(this.wireValue);

  final String wireValue;
}

class DeviceTokenRegistration {
  const DeviceTokenRegistration({
    required this.platform,
    required this.provider,
    required this.environment,
    required this.token,
    required this.appBundleId,
    required this.appVersion,
    required this.deviceModel,
    required this.manufacturer,
    required this.locale,
    required this.timezone,
  });

  final PushPlatform platform;
  final PushProvider provider;
  final PushEnvironment environment;
  final String token;
  final String appBundleId;
  final String appVersion;
  final String deviceModel;
  final String manufacturer;
  final String locale;
  final String timezone;

  Map<String, Object?> toJson() {
    return {
      'platform': platform.wireValue,
      'provider': provider.wireValue,
      'environment': environment.wireValue,
      'token': token.trim(),
      'appBundleId': appBundleId.trim(),
      'appVersion': appVersion.trim(),
      'deviceModel': deviceModel.trim(),
      'manufacturer': manufacturer.trim(),
      'locale': locale.trim(),
      'timezone': timezone.trim(),
    };
  }
}

class RegisteredDeviceToken {
  const RegisteredDeviceToken({required this.id});

  factory RegisteredDeviceToken.fromJson(Map<String, dynamic> json) {
    return RegisteredDeviceToken(id: json['id']?.toString() ?? '');
  }

  final String id;
}

abstract interface class NotificationDeviceTokenClient {
  Future<RegisteredDeviceToken> registerDeviceToken(
    DeviceTokenRegistration registration,
  );

  Future<void> deleteDeviceToken(String deviceTokenId);
}

class NotificationApi implements NotificationDeviceTokenClient {
  NotificationApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<RegisteredDeviceToken> registerDeviceToken(
    DeviceTokenRegistration registration,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/notifications/device-tokens',
      data: registration.toJson(),
    );
    return RegisteredDeviceToken.fromJson(response.data ?? {});
  }

  @override
  Future<void> deleteDeviceToken(String deviceTokenId) async {
    final encodedDeviceTokenId = Uri.encodeComponent(deviceTokenId.trim());
    await _apiClient.dio.delete<void>(
      '/notifications/device-tokens/$encodedDeviceTokenId',
      options: Options(extra: const <String, dynamic>{'requiresAuth': true}),
    );
  }
}
