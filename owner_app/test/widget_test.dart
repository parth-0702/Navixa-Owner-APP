import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_app/core/theme/app_colors.dart';
import 'package:owner_app/core/utils/formatters.dart';
import 'package:owner_app/data/models/alert.dart';
import 'package:owner_app/data/models/notification_preference.dart';
import 'package:owner_app/data/models/trip.dart';
import 'package:owner_app/data/models/user.dart';
import 'package:owner_app/data/models/vehicle.dart';
import 'package:owner_app/ui/common/app_card.dart';
import 'package:owner_app/ui/common/empty_state.dart';
import 'package:owner_app/ui/common/error_state.dart';
import 'package:owner_app/ui/common/metric_tile.dart';
import 'package:owner_app/ui/common/status_badge.dart';

void main() {
  group('Domain Models & RBAC Tests', () {
    test('User roles enforce proper permissions', () {
      final owner = User(
        id: 'u1',
        name: 'Owner User',
        email: 'owner@navixa.com',
        role: UserRole.owner,
      );
      final manager = User(
        id: 'u2',
        name: 'Manager User',
        email: 'manager@navixa.com',
        role: UserRole.manager,
      );
      final viewer = User(
        id: 'u3',
        name: 'Viewer User',
        email: 'viewer@navixa.com',
        role: UserRole.viewer,
      );

      // Owner permissions
      expect(owner.role.canManageTeam, isTrue);
      expect(owner.role.canAcknowledgeAlerts, isTrue);
      expect(owner.role.canEditVehicleNickname, isTrue);

      // Manager permissions
      expect(manager.role.canManageTeam, isFalse);
      expect(manager.role.canAcknowledgeAlerts, isTrue);
      expect(manager.role.canEditVehicleNickname, isFalse);

      // Viewer permissions (Strict read-only)
      expect(viewer.role.canManageTeam, isFalse);
      expect(viewer.role.canAcknowledgeAlerts, isFalse);
      expect(viewer.role.canEditVehicleNickname, isFalse);
    });

    test('Vehicle model correctly parses JSON and calculates stale status', () {
      final json = {
        '_id': 'veh_123',
        'plateNumber': 'KA-01-AB-1234',
        'nickname': 'Swift Truck',
        'status': 'moving',
        'speed': 62.5,
        'ignition': true,
        'isStale': false,
        'location': {
          'latitude': 12.9716,
          'longitude': 77.5946,
          'address': 'MG Road, Bangalore',
        },
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.id, 'veh_123');
      expect(vehicle.displayName, 'Swift Truck');
      expect(vehicle.status, VehicleStatus.moving);
      expect(vehicle.ignitionOn, isTrue);
      expect(vehicle.isStale, isFalse);
      expect(vehicle.lastLocation?.latitude, 12.9716);
      expect(vehicle.lastLocation?.address, 'MG Road, Bangalore');
    });

    test('Trip model calculates completion and handles polylines', () {
      final trip = Trip(
        id: 'trip_1',
        tripNumber: 'TRP-101',
        status: TripStatus.completed,
        distanceKm: 24.8,
        durationMinutes: 48,
        startAddress: 'Warehouse A',
        endAddress: 'Customer Hub B',
      );

      expect(trip.isCompleted, isTrue);
      expect(trip.distanceKm, 24.8);
      expect(trip.durationMinutes, 48);
    });

    test('Alert model correctly evaluates severity styling', () {
      final alert = Alert(
        id: 'alt_1',
        type: 'overspeed',
        severity: AlertSeverity.critical,
        title: 'High Speed Detected (88 km/h)',
        timestamp: DateTime.now(),
      );

      expect(alert.severity, AlertSeverity.critical);
      expect(alert.severity.color, AppColors.error);
      expect(alert.isAcknowledged, isFalse);
    });

    test('NotificationPreference serialization', () {
      const prefs = NotificationPreference(
        pushNotifications: true,
        quietHoursEnabled: true,
        quietHoursStart: '23:00',
        quietHoursEnd: '06:00',
      );

      final json = prefs.toJson();
      expect(json['pushNotifications'], isTrue);
      expect(json['quietHoursEnabled'], isTrue);
      expect(json['quietHoursStart'], '23:00');

      final deserialized = NotificationPreference.fromJson(json);
      expect(deserialized.quietHoursStart, '23:00');
    });
  });

  group('Formatters Tests', () {
    test('Formatters format duration correctly', () {
      expect(Formatters.durationMinutes(35), '35 min');
      expect(Formatters.durationMinutes(75), '1h 15m');
      expect(Formatters.durationMinutes(0), '0 min');
    });

    test('Formatters format distance and odometer correctly', () {
      expect(Formatters.distance(12.34), '12.3 km');
      expect(Formatters.odometer(45200.7), '45201 km');
    });

    test('Formatters relative timeAgo returns friendly string', () {
      final now = DateTime.now();
      expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 10))), 'Just now');
      expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 8))), '8m ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 3))), '3h ago');
    });
  });

  group('Common UI Component Tests', () {
    testWidgets('StatusBadge renders correct status and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: VehicleStatus.moving),
          ),
        ),
      );

      expect(find.text('Moving'), findsOneWidget);
    });

    testWidgets('StatusBadge renders Delayed when GPS data is stale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: VehicleStatus.moving,
              isStale: true,
            ),
          ),
        ),
      );

      expect(find.text('Delayed'), findsOneWidget);
    });

    testWidgets('MetricTile displays title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricTile(
              title: 'Current Speed',
              value: '64 km/h',
              icon: Icons.speed_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Current Speed'), findsOneWidget);
      expect(find.text('64 km/h'), findsOneWidget);
    });

    testWidgets('AppCard handles tap interaction', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Tappable Card Content'), findsOneWidget);
      await tester.tap(find.text('Tappable Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('EmptyState renders icon, title and description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No Vehicles Registered',
              message: 'Your fleet currently has no vehicles.',
              icon: Icons.local_shipping_outlined,
            ),
          ),
        ),
      );

      expect(find.text('No Vehicles Registered'), findsOneWidget);
      expect(find.text('Your fleet currently has no vehicles.'), findsOneWidget);
    });

    testWidgets('ErrorState renders error message and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Failed to connect to server',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect to server'), findsOneWidget);
      final retryBtn = find.text('Try Again');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      expect(retried, isTrue);
    });
  });
}
