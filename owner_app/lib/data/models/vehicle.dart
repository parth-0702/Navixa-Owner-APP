import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'driver.dart';

enum VehicleStatus {
  moving,
  idle,
  parked,
  offline,
  maintenance,
  alert;

  static VehicleStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'moving':
        return VehicleStatus.moving;
      case 'idle':
        return VehicleStatus.idle;
      case 'parked':
        return VehicleStatus.parked;
      case 'offline':
        return VehicleStatus.offline;
      case 'maintenance':
        return VehicleStatus.maintenance;
      case 'alert':
        return VehicleStatus.alert;
      default:
        return VehicleStatus.parked;
    }
  }

  String get label {
    switch (this) {
      case VehicleStatus.moving:
        return 'Moving';
      case VehicleStatus.idle:
        return 'Idle';
      case VehicleStatus.parked:
        return 'Parked';
      case VehicleStatus.offline:
        return 'Offline';
      case VehicleStatus.maintenance:
        return 'In Shop';
      case VehicleStatus.alert:
        return 'Alert';
    }
  }

  Color get color {
    switch (this) {
      case VehicleStatus.moving:
        return AppColors.statusMoving;
      case VehicleStatus.idle:
        return AppColors.statusIdle;
      case VehicleStatus.parked:
        return AppColors.statusParked;
      case VehicleStatus.offline:
        return AppColors.statusOffline;
      case VehicleStatus.maintenance:
        return AppColors.statusMaintenance;
      case VehicleStatus.alert:
        return AppColors.statusAlert;
    }
  }

  Color get containerColor {
    switch (this) {
      case VehicleStatus.moving:
        return AppColors.successSoft;
      case VehicleStatus.idle:
        return AppColors.warningSoft;
      case VehicleStatus.parked:
        return AppColors.surfaceMuted;
      case VehicleStatus.offline:
        return AppColors.offlineSoft;
      case VehicleStatus.maintenance:
        return const Color(0xFFEEF2FF);
      case VehicleStatus.alert:
        return AppColors.errorSoft;
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleStatus.moving:
        return Icons.navigation_rounded;
      case VehicleStatus.idle:
        return Icons.pause_circle_filled_rounded;
      case VehicleStatus.parked:
        return Icons.local_parking_rounded;
      case VehicleStatus.offline:
        return Icons.cloud_off_rounded;
      case VehicleStatus.maintenance:
        return Icons.build_rounded;
      case VehicleStatus.alert:
        return Icons.warning_rounded;
    }
  }
}

class VehicleLocation {
  const VehicleLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.speed = 0,
    this.heading = 0,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final String address;
  final double speed;
  final double heading;
  final DateTime? timestamp;

  factory VehicleLocation.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lng = 0.0;

    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    } else if (json['coordinates'] is List && (json['coordinates'] as List).length >= 2) {
      final coords = json['coordinates'] as List;
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    DateTime? time;
    if (json['timestamp'] != null) {
      time = DateTime.tryParse(json['timestamp'].toString());
    }

    return VehicleLocation(
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString() ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: time,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.plateNumber,
    this.nickname = '',
    this.type = 'truck',
    this.make = '',
    this.model = '',
    this.year = 2024,
    this.status = VehicleStatus.parked,
    this.speedKmh = 0.0,
    this.heading = 0.0,
    this.ignition = false,
    this.fuelType = 'diesel',
    this.currentFuelLevel = 80,
    this.batteryLevel = 100,
    this.odometerKm = 0.0,
    this.todayDistanceKm = 0.0,
    this.hasHardwareGps = true,
    this.lastLocation,
    this.lastLocationUpdatedAt,
    this.lastUpdatedAgo = '',
    this.isStale = false,
    this.assignedDriver,
    this.openAlertsCount = 0,
  });

  final String id;
  final String plateNumber;
  final String nickname;
  final String type;
  final String make;
  final String model;
  final int year;
  final VehicleStatus status;
  final double speedKmh;
  final double heading;
  final bool ignition;
  final String fuelType;
  final int currentFuelLevel;
  final int batteryLevel;
  final double odometerKm;
  final double todayDistanceKm;
  final bool hasHardwareGps;
  final VehicleLocation? lastLocation;
  final DateTime? lastLocationUpdatedAt;
  final String lastUpdatedAgo;
  final bool isStale;
  final DriverSummary? assignedDriver;
  final int openAlertsCount;

  String get displayName => nickname.isNotEmpty ? nickname : plateNumber;
  bool get ignitionOn => ignition;
  int? get fuelPercent => currentFuelLevel;
  int? get batteryPercent => batteryLevel;
  DateTime get lastCommunicationAt => lastLocationUpdatedAt ?? DateTime.now();
  String get vin => 'VIN-${plateNumber.replaceAll(' ', '')}';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    VehicleLocation? loc;
    if (json['lastKnownLocation'] != null && json['lastKnownLocation'] is Map<String, dynamic>) {
      loc = VehicleLocation.fromJson(json['lastKnownLocation'] as Map<String, dynamic>);
    } else if (json['location'] != null && json['location'] is Map<String, dynamic>) {
      loc = VehicleLocation.fromJson(json['location'] as Map<String, dynamic>);
    } else if (json['latitude'] != null && json['longitude'] != null) {
      loc = VehicleLocation.fromJson(json);
    }

    DateTime? lastUpdate;
    if (json['lastLocationUpdatedAt'] != null) {
      lastUpdate = DateTime.tryParse(json['lastLocationUpdatedAt'].toString());
    }

    DriverSummary? driver;
    if (json['assignedDriver'] != null && json['assignedDriver'] is Map<String, dynamic>) {
      driver = DriverSummary.fromJson(json['assignedDriver'] as Map<String, dynamic>);
    } else if (json['assignedDriverId'] != null && json['assignedDriverId'] is Map<String, dynamic>) {
      driver = DriverSummary.fromJson(json['assignedDriverId'] as Map<String, dynamic>);
    }

    return Vehicle(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      type: json['type']?.toString() ?? 'truck',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? 2024,
      status: VehicleStatus.fromString(json['status']?.toString()),
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      ignition: json['ignition'] ?? false,
      fuelType: json['fuelType']?.toString() ?? 'diesel',
      currentFuelLevel: (json['currentFuelLevel'] as num?)?.toInt() ?? 80,
      batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 100,
      odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0.0,
      todayDistanceKm: (json['todayDistanceKm'] as num?)?.toDouble() ?? 0.0,
      hasHardwareGps: json['hasHardwareGps'] ?? true,
      lastLocation: loc,
      lastLocationUpdatedAt: lastUpdate,
      lastUpdatedAgo: json['lastUpdatedAgo']?.toString() ?? '',
      isStale: json['isStale'] ?? false,
      assignedDriver: driver,
      openAlertsCount: (json['openAlerts'] is List) ? (json['openAlerts'] as List).length : 0,
    );
  }

  Vehicle copyWith({
    String? nickname,
    VehicleStatus? status,
    double? speedKmh,
    double? heading,
    bool? ignition,
    int? currentFuelLevel,
    VehicleLocation? lastLocation,
    DateTime? lastLocationUpdatedAt,
    bool? isStale,
  }) {
    return Vehicle(
      id: id,
      plateNumber: plateNumber,
      nickname: nickname ?? this.nickname,
      type: type,
      make: make,
      model: model,
      year: year,
      status: status ?? this.status,
      speedKmh: speedKmh ?? this.speedKmh,
      heading: heading ?? this.heading,
      ignition: ignition ?? this.ignition,
      fuelType: fuelType,
      currentFuelLevel: currentFuelLevel ?? this.currentFuelLevel,
      batteryLevel: batteryLevel,
      odometerKm: odometerKm,
      todayDistanceKm: todayDistanceKm,
      hasHardwareGps: hasHardwareGps,
      lastLocation: lastLocation ?? this.lastLocation,
      lastLocationUpdatedAt: lastLocationUpdatedAt ?? this.lastLocationUpdatedAt,
      lastUpdatedAgo: lastUpdatedAgo,
      isStale: isStale ?? this.isStale,
      assignedDriver: assignedDriver,
      openAlertsCount: openAlertsCount,
    );
  }
}
