import '../../core/network/file_api.dart';
import '../../core/config/app_config.dart';
import 'models/tour_vm.dart';

String? resolveTourCoverUrl(TourVm tour) {
  final directUrl = (tour.coverImageUrl ?? '').trim();
  if (directUrl.isNotEmpty) {
    return _resolveTourCoverImageUrl(directUrl);
  }

  return resolvePublicFileContentUrl((tour.coverFileId ?? '').trim());
}

String _resolveTourCoverImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.hasAuthority) {
    return value;
  }

  if (value.startsWith('/')) {
    return '${Uri.parse(AppConfig.apiBaseUrl).origin}$value';
  }

  return '${AppConfig.apiBaseUrl}/$value';
}
