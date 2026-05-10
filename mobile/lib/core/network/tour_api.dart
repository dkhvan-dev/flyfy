import '../../features/tours/models/create_tour_request.dart';
import '../../features/tours/models/tour_vm.dart';
import 'api_client.dart';

class TourApi {
  TourApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TourVm> createTour(CreateTourRequest request) async {
    final response = await _apiClient.dio.post(
      '/me/tours',
      data: request.toJson(),
    );

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TourVm> publishTour(String tourId) async {
    final response = await _apiClient.dio.post('/me/tours/$tourId/publish');

    return TourVm.fromJson(response.data as Map<String, dynamic>);
  }
}
