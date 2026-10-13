import 'package:flutter/material.dart';

/// Centralized Design Tokens for Navixa Owner Application.
/// Strictly matches the Navixa visual identity specification.
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primaryNavy = Color(0xFF041534);
  static const Color secondaryTeal = Color(0xFF006B5D);
  static const Color accentGold = Color(0xFFCF7F30);

  // Surfaces & Backgrounds (Light)
  static const Color pageBackground = Color(0xFFF8F9FF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F4FC);

  // Text & Borders (Light)
  static const Color primaryText = Color(0xFF0B1C30);
  static const Color secondaryText = Color(0xFF45464E);
  static const Color lightBorder = Color(0xFFE5EEFF);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Feedback & Semantic Status
  static const Color success = Color(0xFF006B5D);
  static const Color warning = Color(0xFFFFB779);
  static const Color warningDark = Color(0xFFC76A14);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorSoft = Color(0xFFFFDAD6);

  // Vehicle Status Palette
  static const Color statusMoving = Color(0xFF006B5D);
  static const Color statusIdle = Color(0xFFCF7F30);
  static const Color statusStopped = Color(0xFFB54708);
  static const Color statusParked = Color(0xFF45464E);
  static const Color statusOffline = Color(0xFF8F909A);
  static const Color statusMaintenance = Color(0xFF4F46E5);
  static const Color statusAlert = Color(0xFFBA1A1A);

  // Dark Theme Tokens
  static const Color darkPageBackground = Color(0xFF090E17);
  static const Color darkSurfaceCard = Color(0xFF111827);
  static const Color darkSurfaceMuted = Color(0xFF1E293B);
  static const Color darkPrimaryText = Color(0xFFF8F9FF);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E293B);

  // Helper Soft Containers
  static const Color successSoft = Color(0xFFE0F2E9);
  static const Color warningSoft = Color(0xFFFFF3E5);
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color offlineSoft = Color(0xFFF1F5F9);
}
