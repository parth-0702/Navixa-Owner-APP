class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.name,
    this.phone = '',
    this.licenseNumber = '',
    this.safetyScore = 95,
    this.totalTrips = 0,
    this.onTimeRate = '98%',
    this.status = 'active',
    this.avatarUrl,
    this.currentVehicleId,
    this.currentVehicleName,
  });

  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final int safetyScore;
  final int totalTrips;
  final String onTimeRate;
  final String status;
  final String? avatarUrl;
  final String? currentVehicleId;
  final String? currentVehicleName;

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    final currentVehicle = json['currentVehicle'] is Map<String, dynamic>
        ? json['currentVehicle'] as Map<String, dynamic>
        : null;
    return DriverSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Assigned Driver',
      phone: json['phone']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 95,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      onTimeRate: json['onTimeRate']?.toString() ?? '98%',
      status: json['status']?.toString() ?? 'active',
      avatarUrl: json['avatarUrl']?.toString(),
      currentVehicleId: currentVehicle?['id']?.toString(),
      currentVehicleName:
          currentVehicle?['nickname']?.toString() ??
          currentVehicle?['plateNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'safetyScore': safetyScore,
      'totalTrips': totalTrips,
      'onTimeRate': onTimeRate,
      'status': status,
      'avatarUrl': avatarUrl,
      'currentVehicleId': currentVehicleId,
      'currentVehicleName': currentVehicleName,
    };
  }
}
