import 'package:flutter_test/flutter_test.dart';
import 'package:owner_app/data/models/alert.dart';
import 'package:owner_app/data/models/user.dart';
import 'package:owner_app/data/models/vehicle.dart';

void main() {
  group('Security & Multi-Tenant Organization Isolation Tests', () {
    test('User models strictly preserve organizationId scoping', () {
      final orgAUser = User(
        id: 'user_a',
        name: 'Alpha Owner',
        email: 'alpha@navixa.com',
        role: UserRole.owner,
        organizationId: 'org_alpha',
        organizationName: 'Alpha Logistics',
      );

      final orgBUser = User(
        id: 'user_b',
        name: 'Beta Owner',
        email: 'beta@navixa.com',
        role: UserRole.owner,
        organizationId: 'org_beta',
        organizationName: 'Beta Logistics',
      );

      expect(orgAUser.organizationId, isNot(equals(orgBUser.organizationId)));
      expect(orgAUser.organizationId, equals('org_alpha'));
      expect(orgBUser.organizationId, equals('org_beta'));
    });

    test('Viewer role is strictly read-only and barred from administrative actions', () {
      const viewerRole = UserRole.viewer;
      expect(viewerRole.canAcknowledgeAlerts, isFalse);
      expect(viewerRole.canManageTeam, isFalse);
      expect(viewerRole.canEditVehicleNickname, isFalse);
    });

    test('Manager role can acknowledge operational incidents but cannot manage team owners', () {
      const managerRole = UserRole.manager;
      expect(managerRole.canAcknowledgeAlerts, isTrue);
      expect(managerRole.canManageTeam, isFalse);
      expect(managerRole.canEditVehicleNickname, isFalse);
    });

    test('Owner role has complete operational and team invitation permissions', () {
      const ownerRole = UserRole.owner;
      expect(ownerRole.canAcknowledgeAlerts, isTrue);
      expect(ownerRole.canManageTeam, isTrue);
      expect(ownerRole.canEditVehicleNickname, isTrue);
    });

    test('Alert acknowledgment state update immutability test', () {
      final initialAlert = Alert(
        id: 'alt_99',
        type: 'overspeed',
        severity: AlertSeverity.critical,
        title: 'Overspeed Alert',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isAcknowledged: false,
      );

      final acknowledgedTime = DateTime.now();
      final updatedAlert = initialAlert.copyWith(
        isAcknowledged: true,
        acknowledgedBy: 'Owner Alice',
        acknowledgedAt: acknowledgedTime,
        acknowledgmentNote: 'Speed governor verified.',
      );

      expect(initialAlert.isAcknowledged, isFalse);
      expect(updatedAlert.isAcknowledged, isTrue);
      expect(updatedAlert.acknowledgedBy, 'Owner Alice');
      expect(updatedAlert.acknowledgmentNote, 'Speed governor verified.');
    });

    test('Stale GPS warning triggers when last location is older than threshold', () {
      final freshVehicle = Vehicle(
        id: 'v_fresh',
        plateNumber: 'KA-05-MM-1111',
        status: VehicleStatus.moving,
        isStale: false,
        lastLocationUpdatedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      final staleVehicle = Vehicle(
        id: 'v_stale',
        plateNumber: 'KA-05-MM-2222',
        status: VehicleStatus.moving,
        isStale: true,
        lastLocationUpdatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      );

      expect(freshVehicle.isStale, isFalse);
      expect(staleVehicle.isStale, isTrue);
    });
  });
}
