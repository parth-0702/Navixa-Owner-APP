import '../../core/network/api_client.dart';
import '../models/notification_preference.dart';
import '../models/user.dart';

class SettingsRepository {
  SettingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<NotificationPreference> getNotificationPreferences() async {
    final response = await _apiClient.get('/notification-preferences');
    return NotificationPreference.fromJson(response['preferences'] as Map<String, dynamic>);
  }

  Future<NotificationPreference> updateNotificationPreferences(NotificationPreference prefs) async {
    final response = await _apiClient.put('/notification-preferences', body: prefs.toJson());
    return NotificationPreference.fromJson(response['preferences'] as Map<String, dynamic>);
  }

  Future<List<User>> getTeam() async {
    final response = await _apiClient.get('/team');
    final list = (response['team'] as List? ?? [])
        .map((m) => User.fromJson(m as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<User> inviteMember({
    required String name,
    String? email,
    String? phone,
    required String role,
    String? tempPassword,
  }) async {
    final response = await _apiClient.post(
      '/team/invitations',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'tempPassword': ?tempPassword,
      },
    );
    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> updateMemberRole(String id, String role) async {
    await _apiClient.patch('/team/$id', body: {'role': role});
  }

  Future<void> deactivateMember(String id, bool isActive) async {
    await _apiClient.patch('/team/$id', body: {'isActive': isActive});
  }
}
