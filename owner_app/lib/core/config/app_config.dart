import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Default API host resolution based on running platform.
  /// On Android emulator, localhost is 10.0.2.2.
  /// On real devices/web/desktop, localhost is used unless overridden.
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  static String get defaultSocketUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String appVersion = '1.0.0';
  static String appBuildNumber = '1';
  static String appName = 'Navixa Owner';
}
