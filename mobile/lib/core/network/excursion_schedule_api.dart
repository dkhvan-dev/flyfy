import '../../features/excursions/models/excursion_schedule_vm.dart';
import 'api_client.dart';

class ExcursionScheduleApi {
  ExcursionScheduleApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ExcursionScheduleSlotVm>> getGuideSchedule({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/excursion-schedule',
      queryParameters: <String, dynamic>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    return _parseItems(response.data);
  }

  Future<List<ExcursionScheduleSlotVm>> getPublicSchedule({
    required String productId,
    required String offerId,
    required DateTime from,
    required DateTime to,
    int seats = 1,
  }) async {
    final encodedProductId = Uri.encodeComponent(productId.trim());
    final response = await _apiClient.dio.get(
      '/excursion-products/$encodedProductId/schedule',
      queryParameters: <String, dynamic>{
        'offerId': offerId.trim(),
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'seats': seats <= 0 ? 1 : seats,
      },
    );

    return _parseItems(response.data);
  }

  Future<ExcursionScheduleSlotVm> createSlot(
    CreateExcursionScheduleSlotRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/excursion-schedule/slots',
      data: request.toJson(),
    );

    return ExcursionScheduleSlotVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ExcursionScheduleSlotVm> updateSlot(
    String id,
    UpdateExcursionScheduleSlotRequest request,
  ) async {
    final encodedId = Uri.encodeComponent(id.trim());
    final response = await _apiClient.dio.patch(
      '/me/excursion-schedule/slots/$encodedId',
      data: request.toJson(),
    );

    return ExcursionScheduleSlotVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<ExcursionScheduleSlotVm>> createSeries(
    CreateExcursionScheduleSeriesRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/me/excursion-schedule/series',
      data: request.toJson(),
    );

    return _parseItems(response.data);
  }

  Future<ExcursionScheduleSlotVm> closeSlot(String id) async {
    final encodedId = Uri.encodeComponent(id.trim());
    final response = await _apiClient.dio.post(
      '/me/excursion-schedule/slots/$encodedId/close',
    );

    return ExcursionScheduleSlotVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ExcursionScheduleSlotVm> cancelSlot(String id, String reason) async {
    final encodedId = Uri.encodeComponent(id.trim());
    final trimmedReason = reason.trim();
    final response = await _apiClient.dio.post(
      '/me/excursion-schedule/slots/$encodedId/cancel',
      data: <String, dynamic>{
        if (trimmedReason.isNotEmpty) 'reason': trimmedReason,
      },
    );

    return ExcursionScheduleSlotVm.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteSlot(String id) async {
    final encodedId = Uri.encodeComponent(id.trim());
    await _apiClient.dio.delete('/me/excursion-schedule/slots/$encodedId');
  }

  List<ExcursionScheduleSlotVm> _parseItems(Object? data) {
    final items = data is Map<String, dynamic>
        ? data['items'] as List<dynamic>?
        : null;
    return (items ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ExcursionScheduleSlotVm.fromJson)
        .toList(growable: false);
  }
}
