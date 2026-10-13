enum UserRole {
  owner,
  manager,
  viewer,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
      case 'fleet_owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'viewer':
      default:
        return UserRole.viewer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Fleet Owner';
      case UserRole.manager:
        return 'Operations Manager';
      case UserRole.viewer:
        return 'Viewer (Read-Only)';
      case UserRole.admin:
        return 'Platform Admin';
    }
  }

  bool get canAcknowledgeAlerts => this == UserRole.owner || this == UserRole.manager || this == UserRole.admin;
  bool get canManageTeam => this == UserRole.owner || this == UserRole.admin;
  bool get canEditVehicleNickname => this == UserRole.owner || this == UserRole.admin;
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.organizationId = '',
    this.organizationName = '',
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String organizationId;
  final String organizationName;
  final String? avatarUrl;
  final bool isActive;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
      organizationId: json['organizationId']?.toString() ?? json['companyId']?.toString() ?? '',
      organizationName: json['organizationName']?.toString() ?? 'Navixa Fleet',
      avatarUrl: json['avatarUrl']?.toString(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }
}
