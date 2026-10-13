import 'alert.dart';
import 'trip.dart';
import 'vehicle.dart';

class StatusCounts {
  const StatusCounts({
    this.total = 0,
    this.moving = 0,
    this.idle = 0,
    this.parked = 0,
    this.offline = 0,
    this.maintenance = 0,
  });

  final int total;
  final int moving;
  final int idle;
  final int parked;
  final int offline;
  final int maintenance;

  factory StatusCounts.fromJson(Map<String, dynamic> json) {
    return StatusCounts(
      total: (json['total'] as num?)?.toInt() ?? 0,
      moving: (json['moving'] as num?)?.toInt() ?? 0,
      idle: (json['idle'] as num?)?.toInt() ?? 0,
      parked: (json['parked'] as num?)?.toInt() ?? 0,
      offline: (json['offline'] as num?)?.toInt() ?? 0,
      maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
    );
  }
}

class CriticalAlertBanner {
  const CriticalAlertBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.vehicleName,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String description;
  final String vehicleName;
  final DateTime timestamp;

  factory CriticalAlertBanner.fromJson(Map<String, dynamic> json) {
    return CriticalAlertBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Critical Attention Needed',
      description: json['description']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? 'Fleet Vehicle',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class OverviewData {
  const OverviewData({
    required this.greeting,
    required this.organizationName,
    required this.lastUpdated,
    this.unreadCount = 0,
    this.criticalAlertsCount = 0,
    this.statusCounts = const StatusCounts(),
    this.criticalAlertBanner,
    this.fleetMapPreview = const [],
    this.recentAlerts = const [],
    this.recentTrips = const [],
  });

  final String greeting;
  final String organizationName;
  final DateTime lastUpdated;
  final int unreadCount;
  final int criticalAlertsCount;
  final StatusCounts statusCounts;
  final CriticalAlertBanner? criticalAlertBanner;
  final List<Vehicle> fleetMapPreview;
  final List<Alert> recentAlerts;
  final List<Trip> recentTrips;

  factory OverviewData.fromJson(Map<String, dynamic> json) {
    final statusCountsJson = json['statusCounts'] as Map<String, dynamic>? ?? {};
    final bannerJson = json['criticalAlertBanner'] as Map<String, dynamic>?;

    List<Vehicle> mapVehicles = [];
    if (json['fleetMapPreview'] is List) {
      mapVehicles = (json['fleetMapPreview'] as List)
          .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    List<Alert> alerts = [];
    if (json['recentAlerts'] is List) {
      alerts = (json['recentAlerts'] as List)
          .map((a) => Alert.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<Trip> trips = [];
    if (json['recentTrips'] is List) {
      trips = (json['recentTrips'] as List)
          .map((t) => Trip.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return OverviewData(
      greeting: json['greeting']?.toString() ?? 'Good day',
      organizationName: json['organizationName']?.toString() ?? 'Navixa Fleet',
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      criticalAlertsCount: (json['criticalAlertsCount'] as num?)?.toInt() ?? 0,
      statusCounts: StatusCounts.fromJson(statusCountsJson),
      criticalAlertBanner: bannerJson != null ? CriticalAlertBanner.fromJson(bannerJson) : null,
      fleetMapPreview: mapVehicles,
      recentAlerts: alerts,
      recentTrips: trips,
    );
  }
}
