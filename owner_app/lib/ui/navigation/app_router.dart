import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../screens/alerts/alert_center_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/fleet/fleet_list_screen.dart';
import '../screens/fleet/vehicle_detail_screen.dart';
import '../screens/map/live_fleet_map_screen.dart';
import '../screens/map/single_vehicle_map_screen.dart';
import '../screens/overview/overview_screen.dart';
import '../screens/profile/notification_preferences_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/team_management_screen.dart';
import '../screens/trips/trip_detail_screen.dart';
import '../screens/trips/trips_overview_screen.dart';
import '../screens/drivers/drivers_overview_screen.dart';
import '../screens/reports/reports_screen.dart';
import 'scaffold_with_nav_bar.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isSplash = loc == '/splash';
        final isLogin = loc == '/login';

        if (authProvider.status == AuthStatus.initial) {
          return null;
        }

        if (authProvider.isAuthenticated) {
          if (isSplash || isLogin) {
            return '/overview';
          }
          return null;
        }

        if (!authProvider.isAuthenticated && !isLogin && !isSplash) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/overview',
                  builder: (context, state) => const OverviewScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/fleet',
                  builder: (context, state) => const FleetListScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/map',
                  builder: (context, state) => const LiveFleetMapScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/alerts',
                  builder: (context, state) => const AlertCenterScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/fleet/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return VehicleDetailScreen(vehicleId: id);
          },
        ),
        GoRoute(
          path: '/fleet/:id/map',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return SingleVehicleMapScreen(vehicleId: id);
          },
        ),
        GoRoute(
          path: '/trips/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return TripDetailScreen(tripId: id);
          },
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsOverviewScreen(),
        ),
        GoRoute(
          path: '/drivers',
          builder: (context, state) => const DriversOverviewScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings/preferences',
          builder: (context, state) => const NotificationPreferencesScreen(),
        ),
        GoRoute(
          path: '/settings/team',
          builder: (context, state) => const TeamManagementScreen(),
        ),
      ],
    );
  }
}
