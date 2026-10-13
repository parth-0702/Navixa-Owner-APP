import 'driver.dart';

enum TripStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  static TripStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
      case 'active':
        return TripStatus.inProgress;
      case 'completed':
      case 'delivered':
        return TripStatus.completed;
      case 'cancelled':
      case 'canceled':
        return TripStatus.cancelled;
      case 'scheduled':
      default:
        return TripStatus.scheduled;
    }
  }

  String get label {
    switch (this) {
      case TripStatus.scheduled:
        return 'Scheduled';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class LatLngPoint {
  const LatLngPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory LatLngPoint.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final lat = (json['lat'] ?? json['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (json['lng'] ?? json['longitude'] as num?)?.toDouble() ?? 0.0;
      return LatLngPoint(latitude: lat, longitude: lng);
    } else if (json is List && json.length >= 2) {
      return LatLngPoint(
        longitude: (json[0] as num).toDouble(),
        latitude: (json[1] as num).toDouble(),
      );
    }
    return const LatLngPoint(latitude: 0, longitude: 0);
  }

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
}

class StopEvent {
  const StopEvent({
    required this.name,
    this.arrivalTime,
    this.departureTime,
    this.durationMinutes = 0,
    this.location,
  });

  final String name;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final int durationMinutes;
  final LatLngPoint? location;

  factory StopEvent.fromJson(Map<String, dynamic> json) {
    DateTime? arr;
    DateTime? dep;
    if (json['arrivalTime'] != null) arr = DateTime.tryParse(json['arrivalTime'].toString());
    if (json['departureTime'] != null) dep = DateTime.tryParse(json['departureTime'].toString());

    LatLngPoint? pt;
    if (json['coordinates'] != null) {
      pt = LatLngPoint.fromJson(json['coordinates']);
    }

    return StopEvent(
      name: json['name']?.toString() ?? 'Stop',
      arrivalTime: arr,
      departureTime: dep,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      location: pt,
    );
  }
}

class IdleEvent {
  const IdleEvent({
    this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.location,
  });

  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final LatLngPoint? location;

  factory IdleEvent.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;
    if (json['startTime'] != null) start = DateTime.tryParse(json['startTime'].toString());
    if (json['endTime'] != null) end = DateTime.tryParse(json['endTime'].toString());

    LatLngPoint? pt;
    if (json['coordinates'] != null) {
      pt = LatLngPoint.fromJson(json['coordinates']);
    }

    return IdleEvent(
      startTime: start,
      endTime: end,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      location: pt,
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.tripNumber,
    this.status = TripStatus.scheduled,
    this.startTime,
    this.endTime,
    this.distanceKm = 0.0,
    this.durationMinutes = 0,
    this.startAddress = '',
    this.endAddress = '',
    this.startLocation,
    this.endLocation,
    this.maxSpeedKmh = 0.0,
    this.averageSpeedKmh = 0.0,
    this.safetyScore = 100,
    this.polyline = const [],
    this.stops = const [],
    this.idleEvents = const [],
    this.vehicleNickname = '',
    this.vehiclePlateNumber = '',
    this.vehicleType = 'truck',
    this.driver,
  });

  final String id;
  final String tripNumber;
  final TripStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationMinutes;
  final String startAddress;
  final String endAddress;
  final LatLngPoint? startLocation;
  final LatLngPoint? endLocation;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final int safetyScore;
  final List<LatLngPoint> polyline;
  final List<StopEvent> stops;
  final List<IdleEvent> idleEvents;
  final String vehicleNickname;
  final String vehiclePlateNumber;
  final String vehicleType;
  final DriverSummary? driver;

  bool get isCompleted => status == TripStatus.completed;

  factory Trip.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;
    if (json['startTime'] != null) start = DateTime.tryParse(json['startTime'].toString());
    if (json['endTime'] != null) end = DateTime.tryParse(json['endTime'].toString());

    List<LatLngPoint> poly = [];
    if (json['polyline'] is List) {
      poly = (json['polyline'] as List).map((p) => LatLngPoint.fromJson(p)).toList();
    }

    List<StopEvent> stopList = [];
    if (json['stops'] is List) {
      stopList = (json['stops'] as List).map((s) => StopEvent.fromJson(s as Map<String, dynamic>)).toList();
    }

    List<IdleEvent> idleList = [];
    if (json['idleEvents'] is List) {
      idleList = (json['idleEvents'] as List).map((i) => IdleEvent.fromJson(i as Map<String, dynamic>)).toList();
    }

    String vNick = '';
    String vPlate = '';
    String vType = 'truck';
    if (json['vehicle'] is Map<String, dynamic>) {
      final v = json['vehicle'] as Map<String, dynamic>;
      vNick = v['nickname']?.toString() ?? '';
      vPlate = v['plateNumber']?.toString() ?? '';
      vType = v['type']?.toString() ?? 'truck';
    } else if (json['vehicleName'] != null) {
      vNick = json['vehicleName'].toString();
    }

    DriverSummary? drv;
    if (json['driver'] is Map<String, dynamic>) {
      drv = DriverSummary.fromJson(json['driver'] as Map<String, dynamic>);
    } else if (json['driverName'] != null) {
      drv = DriverSummary(id: '', name: json['driverName'].toString());
    }

    return Trip(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      tripNumber: json['tripNumber']?.toString() ?? 'TRIP',
      status: TripStatus.fromString(json['status']?.toString()),
      startTime: start,
      endTime: end,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      startAddress: json['startAddress']?.toString() ?? '',
      endAddress: json['endAddress']?.toString() ?? '',
      startLocation: json['startLocation'] != null ? LatLngPoint.fromJson(json['startLocation']) : null,
      endLocation: json['endLocation'] != null ? LatLngPoint.fromJson(json['endLocation']) : null,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 100,
      polyline: poly,
      stops: stopList,
      idleEvents: idleList,
      vehicleNickname: vNick,
      vehiclePlateNumber: vPlate,
      vehicleType: vType,
      driver: drv,
    );
  }
}
