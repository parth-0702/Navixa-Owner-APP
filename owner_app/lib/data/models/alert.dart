import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AlertSeverity {
  info,
  warning,
  critical;

  static AlertSeverity fromString(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
      case 'danger':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      case 'info':
      default:
        return AlertSeverity.info;
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.warning:
        return AppColors.warningDark;
      case AlertSeverity.info:
        return AppColors.secondaryTeal;
    }
  }

  Color get containerColor {
    switch (this) {
      case AlertSeverity.critical:
        return AppColors.errorSoft;
      case AlertSeverity.warning:
        return AppColors.warningSoft;
      case AlertSeverity.info:
        return AppColors.infoSoft;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }
}

class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    this.description = '',
    this.location = '',
    this.coordinates = const [0.0, 0.0],
    required this.timestamp,
    this.isRead = false,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.acknowledgmentNote = '',
    this.vehicleName = 'Fleet Vehicle',
    this.vehicleId,
    this.vehiclePlateNumber,
  });

  final String id;
  final String type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String location;
  final List<double> coordinates;
  final DateTime timestamp;
  final bool isRead;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String acknowledgmentNote;
  final String vehicleName;
  final String? vehicleId;
  final String? vehiclePlateNumber;

  factory Alert.fromJson(Map<String, dynamic> json) {
    DateTime time = DateTime.now();
    if (json['timestamp'] != null) {
      time = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      time = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    DateTime? ackTime;
    if (json['acknowledgedAt'] != null) {
      ackTime = DateTime.tryParse(json['acknowledgedAt'].toString());
    }

    List<double> coords = [0.0, 0.0];
    if (json['coordinates'] is List && (json['coordinates'] as List).length >= 2) {
      final list = json['coordinates'] as List;
      coords = [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
    }

    String vName = json['vehicleName']?.toString() ?? 'Fleet Vehicle';
    String? vId = json['vehicleId']?.toString();
    String? vPlate;

    if (json['vehicle'] is Map<String, dynamic>) {
      final v = json['vehicle'] as Map<String, dynamic>;
      vName = v['nickname']?.toString() ?? v['plateNumber']?.toString() ?? vName;
      vId = v['id']?.toString() ?? v['_id']?.toString() ?? vId;
      vPlate = v['plateNumber']?.toString();
    }

    return Alert(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      severity: AlertSeverity.fromString(json['severity']?.toString()),
      title: json['title']?.toString() ?? 'Alert Notification',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      coordinates: coords,
      timestamp: time,
      isRead: json['isRead'] ?? json['read'] ?? false,
      isAcknowledged: json['isAcknowledged'] ?? false,
      acknowledgedAt: ackTime,
      acknowledgedBy: json['acknowledgedBy']?.toString(),
      acknowledgmentNote: json['acknowledgmentNote']?.toString() ?? '',
      vehicleName: vName,
      vehicleId: vId,
      vehiclePlateNumber: vPlate,
    );
  }

  Alert copyWith({
    bool? isRead,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? acknowledgmentNote,
  }) {
    return Alert(
      id: id,
      type: type,
      severity: severity,
      title: title,
      description: description,
      location: location,
      coordinates: coordinates,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgmentNote: acknowledgmentNote ?? this.acknowledgmentNote,
      vehicleName: vehicleName,
      vehicleId: vehicleId,
      vehiclePlateNumber: vehiclePlateNumber,
    );
  }
}
