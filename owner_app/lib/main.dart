import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/network/socket_service.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/alerts_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/fleet_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/alerts_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/fleet_provider.dart';
import 'providers/map_provider.dart';
import 'providers/overview_provider.dart';
import 'providers/operations_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs: prefs);
  final secureStorage = SecureStorageService();

  late final AuthProvider authProvider;
  final apiClient = ApiClient(
    secureStorage: secureStorage,
    preferencesService: preferencesService,
    onSessionExpired: () {
      authProvider.onSessionRevoked();
    },
  );

  final socketService = SocketService(preferencesService: preferencesService);

  final authRepo = AuthRepository(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
  final fleetRepo = FleetRepository(apiClient: apiClient);
  final alertsRepo = AlertsRepository(apiClient: apiClient);
  final settingsRepo = SettingsRepository(apiClient: apiClient);

  authProvider = AuthProvider(
    authRepository: authRepo,
    secureStorage: secureStorage,
    preferencesService: preferencesService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => OverviewProvider(
            fleetRepository: fleetRepo,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FleetProvider(
            fleetRepository: fleetRepo,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertsProvider(
            alertsRepository: alertsRepo,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MapProvider(
            fleetRepository: fleetRepo,
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OperationsProvider(fleetRepository: fleetRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            settingsRepository: settingsRepo,
            preferencesService: preferencesService,
          ),
        ),
      ],
      child: NavixaOwnerApp(authProvider: authProvider),
    ),
  );
}

class NavixaOwnerApp extends StatefulWidget {
  const NavixaOwnerApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<NavixaOwnerApp> createState() => _NavixaOwnerAppState();
}

class _NavixaOwnerAppState extends State<NavixaOwnerApp> {
  late final _router = AppRouter.createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      title: 'Navixa Owner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}
