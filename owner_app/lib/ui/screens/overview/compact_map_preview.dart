import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/vehicle.dart';

class CompactMapPreviewWidget extends StatelessWidget {
  const CompactMapPreviewWidget({
    super.key,
    required this.vehicles,
    required this.onOpenLiveMap,
  });

  final List<Vehicle> vehicles;
  final VoidCallback onOpenLiveMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Compute center point
    LatLng center = const LatLng(12.9716, 77.5946); // Bangalore default
    final validVehicles = vehicles.where((v) => v.lastLocation != null).toList();
    if (validVehicles.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (final v in validVehicles) {
        sumLat += v.lastLocation!.latitude;
        sumLng += v.lastLocation!.longitude;
      }
      center = LatLng(sumLat / validVehicles.length, sumLng / validVehicles.length);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.surfaceCard,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // Map Tiles
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // non-interactive preview
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.navixa.owner.owner_app',
                ),
                MarkerLayer(
                  markers: validVehicles.map((v) {
                    final lat = v.lastLocation!.latitude;
                    final lng = v.lastLocation!.longitude;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: v.status.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          v.status == VehicleStatus.moving
                              ? Icons.navigation_rounded
                              : Icons.local_shipping_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Gradient scrim for header visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondaryTeal),
                        const SizedBox(width: 4),
                        Text(
                          '${validVehicles.length} Vehicles on Map',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onOpenLiveMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Open Map',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
