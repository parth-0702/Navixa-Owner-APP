import 'package:flutter/material.dart';
import '../../core/storage/preferences_service.dart';
import '../data/models/notification_preference.dart';
import '../data/models/user.dart';
import '../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsRepository settingsRepository,
    required PreferencesService preferencesService,
  })  : _settingsRepository = settingsRepository,
        _preferencesService = preferencesService {
    _themeMode = _preferencesService.getThemeMode();
  }

  final SettingsRepository _settingsRepository;
  final PreferencesService _preferencesService;

  late ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  NotificationPreference? _preferences;
  NotificationPreference? get preferences => _preferences;

  List<User> _teamMembers = [];
  List<User> get teamMembers => _teamMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _preferencesService.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preferences = await _settingsRepository.getNotificationPreferences();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePreferences(NotificationPreference updated) async {
    _isLoading = true;
    notifyListeners();

    try {
      _preferences = await _settingsRepository.updateNotificationPreferences(updated);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadTeam() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _teamMembers = await _settingsRepository.getTeam();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteMember({
    required String name,
    String? email,
    String? phone,
    required String role,
    String? tempPassword,
  }) async {
    try {
      final user = await _settingsRepository.inviteMember(
        name: name,
        email: email,
        phone: phone,
        role: role,
        tempPassword: tempPassword,
      );
      _teamMembers.insert(0, user);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMemberRole(String id, String role) async {
    try {
      await _settingsRepository.updateMemberRole(id, role);
      final idx = _teamMembers.indexWhere((m) => m.id == id);
      if (idx != -1) {
        // update role
        await loadTeam();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateMember(String id, bool isActive) async {
    try {
      await _settingsRepository.deactivateMember(id, isActive);
      await loadTeam();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
