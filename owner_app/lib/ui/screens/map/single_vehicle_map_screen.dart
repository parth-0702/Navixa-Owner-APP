import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/trip.dart';
import '../../../providers/fleet_provider.dart';
import '../../../providers/map_provider.dart';
import '../../common/skeleton_loading.dart';

class SingleVehicleMapScreen extends StatefulWidget {
  const SingleVehicleMapScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<SingleVehicleMapScreen> createState() => _SingleVehicleMapScreenState();
}

class _SingleVehicleMapScreenState extends State<SingleVehicleMapScreen> {
  final MapController _mapController = MapController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicleAndTrips();
    });
  }

  Future<void> _loadVehicleAndTrips() async {
    final fleet = context.read<FleetProvider>();
    await fleet.loadVehicleDetails(widget.vehicleId);
    if (fleet.vehicleTrips.isNotEmpty) {
      final tripId = fleet.vehicleTrips.first.id;
      if (mounted) {
        await context.read<MapProvider>().loadTripDetails(tripId);
        _fitTripRoute();
      }
    }
  }

  void _fitTripRoute() {
    final trip = context.read<MapProvider>().selectedTrip;
    if (trip == null || trip.polyline.isEmpty) return;

    final points = trip.polyline.map((p) => LatLng(p.latitude, p.longitude)).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _selectTrip(Trip trip) async {
    await context.read<MapProvider>().loadTripDetails(trip.id);
    _fitTripRoute();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // In production, would fetch trips for this specific date
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fleet = context.watch<FleetProvider>();
    final mapProv = context.watch<MapProvider>();
    final vehicle = fleet.selectedVehicle;
    final trip = mapProv.selectedTrip;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle != null ? '${vehicle.displayName} Route' : 'Vehicle Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Filter by date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: fleet.isLoadingDetails && vehicle == null
          ? const Center(child: SkeletonLoading(itemCount: 3, height: 100))
          : Column(
              children: [
                // Top Date & Vehicle Summary Strip
                Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 18, color: AppColors.secondaryTeal),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.secondaryTeal,
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: const Text('Change Date'),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),

                // Map View Area
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      _buildMap(trip, vehicle),

                      // Fit Bounds Action
                      if (trip != null && trip.polyline.isNotEmpty)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'fit_single_trip',
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: AppColors.primaryNavy,
                            onPressed: _fitTripRoute,
                            tooltip: 'Fit Route',
                            child: const Icon(Icons.crop_free_rounded),
                          ),
                        ),

                      // Playback Control Bar Overlay
                      if (trip != null && trip.polyline.isNotEmpty)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _buildPlaybackBar(context, mapProv, trip),
                        ),
                    ],
                  ),
                ),

                // Trips List for Selected Date
                Expanded(
                  flex: 2,
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TRIPS FOR TODAY (${fleet.vehicleTrips.length})',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryText,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              if (trip != null)
                                Text(
                                  'Selected: ${trip.distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.secondaryTeal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: fleet.vehicleTrips.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.route_rounded, size: 36, color: AppColors.secondaryText),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No recorded trips for this date',
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: fleet.vehicleTrips.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final t = fleet.vehicleTrips[index];
                                    final isSelected = trip?.id == t.id;

                                    return InkWell(
                                      onTap: () => _selectTrip(t),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.secondaryTeal.withValues(alpha: isDark ? 0.2 : 0.08)
                                              : (isDark ? const Color(0xFF131F33) : AppColors.pageBackground),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? AppColors.secondaryTeal : AppColors.lightBorder,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.secondaryTeal
                                                    : AppColors.primaryNavy.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.directions_car_rounded,
                                                size: 18,
                                                color: isSelected ? Colors.white : AppColors.primaryNavy,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${t.startTime != null ? DateFormat('h:mm a').format(t.startTime!) : '—'} - ${t.endTime != null ? DateFormat('h:mm a').format(t.endTime!) : 'Ongoing'}',
                                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${t.startAddress.isNotEmpty ? t.startAddress : 'Start'} → ${t.endAddress.isNotEmpty ? t.endAddress : 'In transit'}',
                                                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${t.distanceKm.toStringAsFixed(1)} km',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                                ),
                                                Text(
                                                  Formatters.durationMinutes(t.durationMinutes),
                                                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMap(Trip? trip, vehicle) {
    final center = trip != null && trip.polyline.isNotEmpty
        ? LatLng(trip.polyline.first.latitude, trip.polyline.first.longitude)
        : (vehicle?.lastLocation != null
            ? LatLng(vehicle.lastLocation!.latitude, vehicle.lastLocation!.longitude)
            : const LatLng(12.9716, 77.5946));

    final polylines = <Polyline>[];
    final markers = <Marker>[];

    if (trip != null && trip.polyline.isNotEmpty) {
      // Polyline
      polylines.add(
        Polyline(
          points: trip.polyline.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          strokeWidth: 4.5,
          color: AppColors.secondaryTeal,
        ),
      );

      // Start marker (Green)
      if (trip.startLocation != null) {
        markers.add(
          Marker(
            point: LatLng(trip.startLocation!.latitude, trip.startLocation!.longitude),
            width: 36,
            height: 36,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
          ),
        );
      }

      // End marker (Red)
      if (trip.endLocation != null) {
        markers.add(
          Marker(
            point: LatLng(trip.endLocation!.latitude, trip.endLocation!.longitude),
            width: 36,
            height: 36,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
            ),
          ),
        );
      }

      // Stop & Idle markers
      for (final stop in trip.stops) {
        if (stop.location != null) {
          markers.add(
            Marker(
              point: LatLng(stop.location!.latitude, stop.location!.longitude),
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.pause_rounded, color: Colors.white, size: 16),
              ),
            ),
          );
        }
      }

      // Playback vehicle marker
      final mapProv = context.watch<MapProvider>();
      if (mapProv.playbackIndex < trip.polyline.length) {
        final playbackPoint = trip.polyline[mapProv.playbackIndex];
        markers.add(
          Marker(
            point: LatLng(playbackPoint.latitude, playbackPoint.longitude),
            width: 44,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                ],
              ),
              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
            ),
          ),
        );
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.navixa.owner_app',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildPlaybackBar(BuildContext context, MapProvider mapProv, Trip trip) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              mapProv.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: AppColors.secondaryTeal,
              size: 36,
            ),
            onPressed: () {
              if (mapProv.isPlaying) {
                mapProv.stopPlayback();
              } else {
                mapProv.startPlayback();
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Route Playback',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${mapProv.playbackIndex + 1} / ${trip.polyline.length} pts',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: mapProv.playbackIndex.toDouble().clamp(0.0, (trip.polyline.length - 1).toDouble()),
                    min: 0,
                    max: (trip.polyline.length - 1).toDouble(),
                    activeColor: AppColors.secondaryTeal,
                    inactiveColor: AppColors.lightBorder,
                    onChanged: (val) {
                      // manual scrubber
                    },
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 20, color: AppColors.secondaryText),
            tooltip: 'Restart Playback',
            onPressed: () => mapProv.resetPlayback(),
          ),
        ],
      ),
    );
  }
}
