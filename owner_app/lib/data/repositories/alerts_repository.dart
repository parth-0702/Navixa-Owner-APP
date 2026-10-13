import '../../core/network/api_client.dart';
import '../models/alert.dart';

class AlertsResult {
  const AlertsResult({
    required this.alerts,
    required this.today,
    required this.yesterday,
    required this.earlier,
    required this.total,
    required this.unreadCount,
    required this.criticalCount,
    required this.page,
    required this.totalPages,
  });

  final List<Alert> alerts;
  final List<Alert> today;
  final List<Alert> yesterday;
  final List<Alert> earlier;
  final int total;
  final int unreadCount;
  final int criticalCount;
  final int page;
  final int totalPages;
}

class AlertsRepository {
  AlertsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AlertsResult> getAlerts({
    String? status = 'all',
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'status': status,
      'type': type,
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.get('/alerts', queryParams: params);
    final allAlerts = (response['alerts'] as List? ?? [])
        .map((a) => Alert.fromJson(a as Map<String, dynamic>))
        .toList();

    List<Alert> parseGroup(dynamic listJson) {
      if (listJson is List) {
        return listJson.map((a) => Alert.fromJson(a as Map<String, dynamic>)).toList();
      }
      return [];
    }

    final groups = response['groups'] as Map<String, dynamic>? ?? {};

    return AlertsResult(
      alerts: allAlerts,
      today: parseGroup(groups['today']),
      yesterday: parseGroup(groups['yesterday']),
      earlier: parseGroup(groups['earlier']),
      total: (response['total'] as num?)?.toInt() ?? allAlerts.length,
      unreadCount: (response['unreadCount'] as num?)?.toInt() ?? 0,
      criticalCount: (response['criticalCount'] as num?)?.toInt() ?? 0,
      page: (response['page'] as num?)?.toInt() ?? 1,
      totalPages: (response['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> markAlertAsRead(String id) async {
    await _apiClient.patch('/alerts/$id/read');
  }

  Future<void> markAllAlertsAsRead() async {
    await _apiClient.patch('/alerts/read-all');
  }

  Future<Alert> acknowledgeAlert(String id, {String note = ''}) async {
    final response = await _apiClient.patch(
      '/alerts/$id/acknowledge',
      body: {'note': note},
    );
    return Alert.fromJson(response['alert'] as Map<String, dynamic>);
  }
}
