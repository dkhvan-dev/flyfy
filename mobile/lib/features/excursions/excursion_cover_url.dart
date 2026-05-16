import '../../core/network/file_api.dart';
import '../../core/config/app_config.dart';
import 'models/excursion_vm.dart';

String? resolveExcursionCoverUrl(ExcursionVm excursion) {
  final directUrl = (excursion.coverImageUrl ?? '').trim();
  if (directUrl.isNotEmpty) {
    return _resolveExcursionCoverImageUrl(directUrl);
  }

  return resolvePublicFileContentUrl((excursion.coverFileId ?? '').trim());
}

String _resolveExcursionCoverImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.hasAuthority) {
    return value;
  }

  if (value.startsWith('/')) {
    return '${Uri.parse(AppConfig.apiBaseUrl).origin}$value';
  }

  return '${AppConfig.apiBaseUrl}/$value';
}
