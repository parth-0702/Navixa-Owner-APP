import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _keyThemeMode = 'pref_theme_mode';
  static const _keyCustomBaseUrl = 'pref_custom_base_url';
  static const _keyRememberIdentifier = 'pref_remember_identifier';

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    if (value == 'dark') return ThemeMode.dark;
    if (value == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value = 'system';
    if (mode == ThemeMode.dark) value = 'dark';
    if (mode == ThemeMode.light) value = 'light';
    await _prefs.setString(_keyThemeMode, value);
  }

  String? getCustomBaseUrl() {
    return _prefs.getString(_keyCustomBaseUrl);
  }

  Future<void> setCustomBaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_keyCustomBaseUrl);
    } else {
      await _prefs.setString(_keyCustomBaseUrl, url.trim());
    }
  }

  bool getRememberIdentifier() {
    return _prefs.getBool(_keyRememberIdentifier) ?? false;
  }

  Future<void> setRememberIdentifier(bool remember) async {
    await _prefs.setBool(_keyRememberIdentifier, remember);
  }
}
