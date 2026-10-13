import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorageService secureStorage,
    required PreferencesService preferencesService,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage,
        _preferencesService = preferencesService;

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  final PreferencesService _preferencesService;
  PreferencesService get preferencesService => _preferencesService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  User? _user;
  User? get user => _user;
  User? get currentUser => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isBiometricAvailable = false;
  bool get isBiometricAvailable => _isBiometricAvailable;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  String? _savedIdentifier;
  String? get savedIdentifier => _savedIdentifier;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isOwner => _user?.role == UserRole.owner;
  bool get isManager => _user?.role == UserRole.manager;
  bool get isViewer => _user?.role == UserRole.viewer;

  void onSessionRevoked() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  Future<void> initialize() async {
    _savedIdentifier = await _secureStorage.getSavedIdentifier();
    _isBiometricEnabled = await _secureStorage.isBiometricEnabled();

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _isBiometricAvailable = canCheck && isDeviceSupported;
    } catch (_) {
      _isBiometricAvailable = false;
    }

    // Try session restoration
    final user = await _authRepository.restoreSession();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
    bool rememberSession = false,
  }) async {
    if (_status == AuthStatus.authenticating) return false;

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        identifier: identifier.trim(),
        password: password,
      );

      _user = user;
      _status = AuthStatus.authenticated;

      if (rememberSession) {
        await _secureStorage.saveIdentifier(identifier.trim());
        _savedIdentifier = identifier.trim();
      } else {
        await _secureStorage.saveIdentifier('');
        _savedIdentifier = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_isBiometricAvailable || !_isBiometricEnabled) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Navixa Fleet Dashboard',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        final restored = await _authRepository.restoreSession();
        if (restored != null) {
          _user = restored;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    await _secureStorage.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile({required String name, required String phone, required String email}) async {
    try {
      await _authRepository.updateProfile(name: name, phone: phone, email: email);
      _user = _authRepository.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
