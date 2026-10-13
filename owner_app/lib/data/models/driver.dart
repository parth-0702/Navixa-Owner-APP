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

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
