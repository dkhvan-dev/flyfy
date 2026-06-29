import '../../core/network/file_api.dart';
import '../../core/config/app_config.dart';
import 'models/excursion_booking_vm.dart';
import 'models/excursion_vm.dart';

String? resolveExcursionCoverUrl(ExcursionVm excursion) {
  final directUrl = (excursion.coverImageUrl ?? '').trim();
  if (directUrl.isNotEmpty) {
    return _resolveExcursionCoverImageUrl(directUrl);
  }

  return resolvePublicFileContentUrl((excursion.coverFileId ?? '').trim());
}

List<String> resolveExcursionPhotoUrls(ExcursionVm excursion) {
  final urls = <String>[];
  final seen = <String>{};

  void addUrl(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || !seen.add(normalized)) {
      return;
    }
    urls.add(normalized);
  }

  for (final fileId in excursion.photoFileIds) {
    addUrl(resolvePublicFileContentUrl(fileId));
  }
  for (final imageUrl in excursion.photoImageUrls) {
    addUrl(resolveExcursionImageUrl(imageUrl));
  }
  addUrl(resolveExcursionCoverUrl(excursion));

  return List.unmodifiable(urls);
}

String? resolveOwnedExcursionCoverUrl(ExcursionVm excursion) {
  final fileUrl = resolvePublicFileContentUrl(
    (excursion.coverFileId ?? '').trim(),
  );
  if (fileUrl != null) return fileUrl;

  return resolveExcursionCoverUrl(excursion);
}

String? resolveExcursionBookingCoverUrl(ExcursionBookingVm booking) {
  return resolvePublicFileContentUrl((booking.coverFileId ?? '').trim());
}

String _resolveExcursionCoverImageUrl(String value) {
  return resolveExcursionImageUrl(value);
}

String resolveExcursionImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.hasAuthority) {
    return value;
  }

  if (value.startsWith('/')) {
    return '${Uri.parse(AppConfig.apiBaseUrl).origin}$value';
  }

  return '${AppConfig.apiBaseUrl}/$value';
}
