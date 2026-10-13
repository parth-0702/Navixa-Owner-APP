import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<User> login({required String identifier, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
      requiresAuth: false,
    );

    final accessToken = response['accessToken']?.toString();
    final refreshToken = response['refreshToken']?.toString();
    final userData = response['user'] as Map<String, dynamic>;

    if (accessToken != null && refreshToken != null) {
      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    }

    _currentUser = User.fromJson(userData);
    return _currentUser!;
  }

  Future<User?> restoreSession() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _apiClient.get('/auth/me');
      if (response['user'] != null) {
        _currentUser = User.fromJson(response['user'] as Map<String, dynamic>);
        return _currentUser;
      }
    } catch (_) {
      // Token might be invalid or expired
      await _secureStorage.clearTokens();
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post('/auth/logout', body: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _secureStorage.clearTokens();
      _currentUser = null;
    }
  }

  Future<void> updateProfile({required String name, required String phone, required String email}) async {
    final response = await _apiClient.put(
      '/auth/profile',
      body: {'name': name, 'phone': phone, 'email': email},
    );
    if (response['user'] != null) {
      _currentUser = User.fromJson(response['user'] as Map<String, dynamic>);
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _apiClient.post(
      '/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
