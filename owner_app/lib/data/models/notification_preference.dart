class NotificationPreference {
  const NotificationPreference({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.criticalAlerts = true,
    this.overspeedAlerts = true,
    this.idleAlerts = true,
    this.geofenceAlerts = true,
    this.routeDeviationAlerts = true,
    this.lowFuelAlerts = true,
    this.offlineAlerts = true,
    this.maintenanceReminders = true,
  });

  final bool pushNotifications;
  final bool emailNotifications;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool criticalAlerts;
  final bool overspeedAlerts;
  final bool idleAlerts;
  final bool geofenceAlerts;
  final bool routeDeviationAlerts;
  final bool lowFuelAlerts;
  final bool offlineAlerts;
  final bool maintenanceReminders;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart']?.toString() ?? '22:00',
      quietHoursEnd: json['quietHoursEnd']?.toString() ?? '07:00',
      criticalAlerts: json['criticalAlerts'] ?? true,
      overspeedAlerts: json['overspeedAlerts'] ?? true,
      idleAlerts: json['idleAlerts'] ?? true,
      geofenceAlerts: json['geofenceAlerts'] ?? true,
      routeDeviationAlerts: json['routeDeviationAlerts'] ?? true,
      lowFuelAlerts: json['lowFuelAlerts'] ?? true,
      offlineAlerts: json['offlineAlerts'] ?? true,
      maintenanceReminders: json['maintenanceReminders'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'criticalAlerts': criticalAlerts,
      'overspeedAlerts': overspeedAlerts,
      'idleAlerts': idleAlerts,
      'geofenceAlerts': geofenceAlerts,
      'routeDeviationAlerts': routeDeviationAlerts,
      'lowFuelAlerts': lowFuelAlerts,
      'offlineAlerts': offlineAlerts,
      'maintenanceReminders': maintenanceReminders,
    };
  }

  NotificationPreference copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? criticalAlerts,
    bool? overspeedAlerts,
    bool? idleAlerts,
    bool? geofenceAlerts,
    bool? routeDeviationAlerts,
    bool? lowFuelAlerts,
    bool? offlineAlerts,
    bool? maintenanceReminders,
  }) {
    return NotificationPreference(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      overspeedAlerts: overspeedAlerts ?? this.overspeedAlerts,
      idleAlerts: idleAlerts ?? this.idleAlerts,
      geofenceAlerts: geofenceAlerts ?? this.geofenceAlerts,
      routeDeviationAlerts: routeDeviationAlerts ?? this.routeDeviationAlerts,
      lowFuelAlerts: lowFuelAlerts ?? this.lowFuelAlerts,
      offlineAlerts: offlineAlerts ?? this.offlineAlerts,
      maintenanceReminders: maintenanceReminders ?? this.maintenanceReminders,
    );
  }
}
