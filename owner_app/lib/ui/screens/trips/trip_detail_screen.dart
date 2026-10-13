import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/map_provider.dart';
import '../../common/app_card.dart';
import '../../common/metric_tile.dart';
import '../../common/skeleton_loading.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mapProv = context.read<MapProvider>();
      await mapProv.loadTripDetails(widget.tripId);
      _fitRoute();
    });
  }

  void _fitRoute() {
    final trip = context.read<MapProvider>().selectedTrip;
    if (trip == null ||
        (trip.polyline.isEmpty && trip.plannedPolyline.isEmpty)) {
      return;
    }

    final route = trip.polyline.isNotEmpty
        ? trip.polyline
        : trip.plannedPolyline;
    final points = route.map((p) => LatLng(p.latitude, p.longitude)).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapProv = context.watch<MapProvider>();
    final trip = mapProv.selectedTrip;

    if (mapProv.isLoading && trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Telemetry')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoading(itemCount: 4, height: 120),
        ),
      );
    }

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Telemetry')),
        body: const Center(
          child: Text('Trip not found or no telemetry available'),
        ),
      );
    }

    final center = trip.polyline.isNotEmpty
        ? LatLng(trip.polyline.first.latitude, trip.polyline.first.longitude)
        : const LatLng(12.9716, 77.5946);

    final polylines = <Polyline>[
      if (trip.plannedPolyline.isNotEmpty)
        Polyline(
          points: trip.plannedPolyline
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          strokeWidth: 7,
          color: AppColors.primaryNavy.withValues(alpha: 0.28),
        ),
      if (trip.polyline.isNotEmpty)
        Polyline(
          points: trip.polyline
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          strokeWidth: 4.5,
          color: AppColors.secondaryTeal,
        ),
    ];

    final markers = <Marker>[];
    if (trip.startLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            trip.startLocation!.latitude,
            trip.startLocation!.longitude,
          ),
          width: 36,
          height: 36,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (trip.endLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            trip.endLocation!.latitude,
            trip.endLocation!.longitude,
          ),
          width: 36,
          height: 36,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

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
              child: const Icon(
                Icons.pause_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      }
    }

    if (trip.polyline.isNotEmpty) {
      final point = trip
          .polyline[mapProv.playbackIndex.clamp(0, trip.polyline.length - 1)];
      markers.add(
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Trip #${trip.tripNumber}')),
      body: ListView(
        children: [
          // Route Map View (260 px height)
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 13.0),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.navixa.owner_app',
                    ),
                    PolylineLayer(polylines: polylines),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'fit_route_btn',
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: AppColors.primaryNavy,
                    onPressed: _fitRoute,
                    tooltip: 'Fit Route',
                    child: const Icon(Icons.crop_free_rounded),
                  ),
                ),
              ],
            ),
          ),

          if (trip.polyline.isNotEmpty)
            Container(
              color: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: mapProv.isPlaying
                        ? 'Pause route playback'
                        : 'Play route history',
                    onPressed: mapProv.isPlaying
                        ? mapProv.stopPlayback
                        : mapProv.startPlayback,
                    icon: Icon(
                      mapProv.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: mapProv.playbackIndex.toDouble(),
                      min: 0,
                      max: (trip.polyline.length - 1).toDouble(),
                      activeColor: AppColors.accentGold,
                      inactiveColor: Colors.white24,
                      onChanged: (value) => mapProv.seekPlayback(value.round()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Restart playback',
                    onPressed: mapProv.resetPlayback,
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.plannedPolyline.isNotEmpty) ...[
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 5,
                          color: AppColors.primaryNavy.withValues(alpha: 0.28),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Planned route',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Container(
                          width: 28,
                          height: 5,
                          color: AppColors.secondaryTeal,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Actual route',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Start & End Locations Card
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.radio_button_checked,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ORIGIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trip.startAddress.isNotEmpty
                                      ? trip.startAddress
                                      : 'Start Location',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (trip.startTime != null)
                                  Text(
                                    DateFormat(
                                      'MMM d, yyyy • h:mm a',
                                    ).format(trip.startTime!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            thickness: 1.5,
                            color: AppColors.lightBorder,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESTINATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trip.endAddress.isNotEmpty
                                      ? trip.endAddress
                                      : 'End Location',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (trip.endTime != null)
                                  Text(
                                    DateFormat(
                                      'MMM d, yyyy • h:mm a',
                                    ).format(trip.endTime!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Telemetry Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    MetricTile(
                      title: 'Distance',
                      value: '${trip.distanceKm.toStringAsFixed(1)} km',
                      icon: Icons.route_rounded,
                      accentColor: AppColors.secondaryTeal,
                    ),
                    MetricTile(
                      title: 'Duration',
                      value: Formatters.durationMinutes(trip.durationMinutes),
                      icon: Icons.timer_outlined,
                      accentColor: AppColors.primaryNavy,
                    ),
                    MetricTile(
                      title: 'Max Speed',
                      value: '${trip.maxSpeedKmh.toStringAsFixed(0)} km/h',
                      icon: Icons.speed_rounded,
                    ),
                    MetricTile(
                      title: 'Average Speed',
                      value: '${trip.averageSpeedKmh.toStringAsFixed(0)} km/h',
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stops & Idle Events
                if (trip.stops.isNotEmpty || trip.idleEvents.isNotEmpty) ...[
                  Text(
                    'STOPS & IDLE EVENTS (${trip.stops.length + trip.idleEvents.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...trip.stops.map(
                    (stop) => AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stop_circle_outlined,
                            color: AppColors.accentGold,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              stop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${stop.durationMinutes} min',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...trip.idleEvents.map(
                    (idle) => AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pause_circle_outline,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Engine Idle Event',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${idle.durationMinutes} min',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
