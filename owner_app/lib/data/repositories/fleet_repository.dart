import '../../core/network/api_client.dart';
import '../models/overview_data.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';

class FleetResult {
  const FleetResult({
    required this.vehicles,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<Vehicle> vehicles;
  final int total;
  final int page;
  final int totalPages;
}

class FleetRepository {
  FleetRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  OverviewData? _cachedOverview;
  OverviewData? get cachedOverview => _cachedOverview;

  Future<OverviewData> getOverview() async {
    final response = await _apiClient.get('/owner/overview');
    _cachedOverview = OverviewData.fromJson(response as Map<String, dynamic>);
    return _cachedOverview!;
  }

  Future<FleetResult> getVehicles({
    String? search,
    String? status,
    String? sort = 'lastUpdated',
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'search': search,
      'status': status,
      'sort': sort,
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.get('/vehicles', queryParams: params);
    final list = (response['vehicles'] as List? ?? [])
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList();

    return FleetResult(
      vehicles: list,
      total: (response['total'] as num?)?.toInt() ?? list.length,
      page: (response['page'] as num?)?.toInt() ?? 1,
      totalPages: (response['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<Vehicle> getVehicleById(String id) async {
    final response = await _apiClient.get('/vehicles/$id');
    return Vehicle.fromJson(response['vehicle'] as Map<String, dynamic>);
  }

  Future<String> updateVehicleNickname(String id, String nickname) async {
    final response = await _apiClient.patch('/vehicles/$id/nickname', body: {'nickname': nickname});
    return response['nickname']?.toString() ?? nickname;
  }

  Future<List<Trip>> getVehicleTrips(String id, {String? date, int page = 1}) async {
    final params = <String, dynamic>{'date': date, 'page': page};
    final response = await _apiClient.get('/vehicles/$id/trips', queryParams: params);
    final list = (response['trips'] as List? ?? [])
        .map((t) => Trip.fromJson(t as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<Trip> getTripById(String id) async {
    final response = await _apiClient.get('/trips/$id');
    return Trip.fromJson(response['trip'] as Map<String, dynamic>);
  }
}
