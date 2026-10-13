import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  late final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'navixa_access_token';
  static const _keyRefreshToken = 'navixa_refresh_token';
  static const _keyBiometricEnabled = 'navixa_biometric_enabled';
  static const _keySavedIdentifier = 'navixa_saved_identifier';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> saveIdentifier(String identifier) async {
    await _storage.write(key: _keySavedIdentifier, value: identifier);
  }

  Future<String?> getSavedIdentifier() async {
    return _storage.read(key: _keySavedIdentifier);
  }
}
