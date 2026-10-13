import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/vehicle.dart';
import '../../../providers/map_provider.dart';
import '../../common/search_bar_widget.dart';
import 'vehicle_bottom_sheet.dart';

class LiveFleetMapScreen extends StatefulWidget {
  const LiveFleetMapScreen({super.key});

  @override
  State<LiveFleetMapScreen> createState() => _LiveFleetMapScreenState();
}

class _LiveFleetMapScreenState extends State<LiveFleetMapScreen> {
  final MapController _mapController = MapController();

  final List<Map<String, String>> _statusFilters = const [
    {'id': 'all', 'label': 'All'},
    {'id': 'moving', 'label': 'Moving'},
    {'id': 'idle', 'label': 'Idle'},
    {'id': 'stopped', 'label': 'Stopped'},
    {'id': 'parked', 'label': 'Parked'},
    {'id': 'offline', 'label': 'Offline'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().loadMapVehicles();
    });
  }

  void _fitAllVehicles(List<Vehicle> vehicles) {
    final validLocations = vehicles
        .where((v) => v.lastLocation != null)
        .map((v) => LatLng(v.lastLocation!.latitude, v.lastLocation!.longitude))
        .toList();

    if (validLocations.isEmpty) return;

    if (validLocations.length == 1) {
      _mapController.move(validLocations.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(validLocations);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void _onMarkerTapped(Vehicle vehicle) {
    context.read<MapProvider>().selectVehicle(vehicle);
    if (vehicle.lastLocation != null) {
      _mapController.move(
        LatLng(vehicle.lastLocation!.latitude, vehicle.lastLocation!.longitude),
        15,
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VehicleBottomSheet(vehicle: vehicle),
    );
  }

  Color _getStatusMarkerColor(VehicleStatus status, bool isStale) {
    if (isStale) return AppColors.warning;
    switch (status) {
      case VehicleStatus.moving:
        return AppColors.secondaryTeal;
      case VehicleStatus.idle:
        return AppColors.accentGold;
      case VehicleStatus.stopped:
        return AppColors.statusStopped;
      case VehicleStatus.parked:
        return AppColors.primaryNavy;
      case VehicleStatus.offline:
        return const Color(0xFF757575);
      case VehicleStatus.maintenance:
        return Colors.deepOrange;
      case VehicleStatus.alert:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh positions',
            onPressed: () => context.read<MapProvider>().loadMapVehicles(),
          ),
        ],
      ),
      body: Consumer<MapProvider>(
        builder: (context, mapProv, _) {
          final vehicles = mapProv.filteredVehicles;

          // Default center: Bangalore coordinates if no vehicles, otherwise first vehicle
          final initialCenter =
              vehicles.isNotEmpty && vehicles.first.lastLocation != null
              ? LatLng(
                  vehicles.first.lastLocation!.latitude,
                  vehicles.first.lastLocation!.longitude,
                )
              : const LatLng(12.9716, 77.5946);

          final markers = vehicles.where((v) => v.lastLocation != null).map((
            v,
          ) {
            final loc = v.lastLocation!;
            final color = _getStatusMarkerColor(v.status, v.isStale);
            final isSelected = mapProv.selectedVehicle?.id == v.id;

            return Marker(
              point: LatLng(loc.latitude, loc.longitude),
              width: isSelected ? 56 : 46,
              height: isSelected ? 56 : 46,
              child: GestureDetector(
                onTap: () => _onMarkerTapped(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.9),
                      width: isSelected ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: isSelected ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    v.status == VehicleStatus.moving
                        ? Icons.navigation_rounded
                        : Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: isSelected ? 26 : 20,
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              // OpenStreetMap Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 12.0,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.navixa.owner_app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Search and Status Filters Overlay at Top
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    SearchBarWidget(
                      hintText: 'Search map by vehicle or driver...',
                      onChanged: (q) => mapProv.setSearchFilter(q),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusFilters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final f = _statusFilters[index];
                          final isSelected = mapProv.statusFilter == f['id'];

                          return ChoiceChip(
                            label: Text(f['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                mapProv.setStatusFilter(f['id']!),
                            selectedColor: AppColors.primaryNavy,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryText,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : AppColors.lightBorder,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Controls at Bottom Right
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total visible badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '${markers.length} Vehicles',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Fit bounds button
                    FloatingActionButton.small(
                      heroTag: 'fit_bounds',
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: AppColors.primaryNavy,
                      onPressed: () => _fitAllVehicles(vehicles),
                      tooltip: 'Fit All Vehicles',
                      child: const Icon(Icons.crop_free_rounded),
                    ),
                    const SizedBox(height: 8),

                    // Recenter on first/selected
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: AppColors.secondaryTeal,
                      onPressed: () {
                        if (mapProv.selectedVehicle?.lastLocation != null) {
                          final loc = mapProv.selectedVehicle!.lastLocation!;
                          _mapController.move(
                            LatLng(loc.latitude, loc.longitude),
                            14,
                          );
                        } else if (vehicles.isNotEmpty &&
                            vehicles.first.lastLocation != null) {
                          final loc = vehicles.first.lastLocation!;
                          _mapController.move(
                            LatLng(loc.latitude, loc.longitude),
                            14,
                          );
                        }
                      },
                      tooltip: 'Recenter',
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ],
                ),
              ),

              // Loading indicator
              if (mapProv.isLoading)
                const Positioned(
                  top: 96,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Updating positions...',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
