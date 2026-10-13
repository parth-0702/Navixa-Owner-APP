import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/vehicle.dart';
import '../../common/status_badge.dart';

class VehicleBottomSheet extends StatelessWidget {
  const VehicleBottomSheet({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.plateNumber} • ${vehicle.make} ${vehicle.model}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: vehicle.status),
              ],
            ),
            const SizedBox(height: 14),

            // Stale indicator if applicable
            if (vehicle.isStale)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFB25E00)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS delayed (${Formatters.timeAgo(vehicle.lastLocationUpdatedAt ?? vehicle.lastCommunicationAt)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.warning : const Color(0xFFB25E00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Telemetry quick strip
            Row(
              children: [
                _buildQuickMetric(
                  context,
                  'Speed',
                  '${vehicle.speedKmh.toStringAsFixed(0)} km/h',
                  Icons.speed_rounded,
                  vehicle.status == VehicleStatus.moving ? AppColors.secondaryTeal : AppColors.secondaryText,
                ),
                const SizedBox(width: 12),
                _buildQuickMetric(
                  context,
                  'Today Dist.',
                  Formatters.distance(vehicle.todayDistanceKm),
                  Icons.route_rounded,
                  AppColors.primaryNavy,
                ),
                const SizedBox(width: 12),
                _buildQuickMetric(
                  context,
                  'Driver',
                  vehicle.assignedDriver?.name ?? 'Unassigned',
                  Icons.person_outline_rounded,
                  AppColors.secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: AppColors.secondaryTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicle.lastLocation?.address ?? 'Coordinates available',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/fleet/${vehicle.id}/map');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Trip Route'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/fleet/${vehicle.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Full Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16253D) : AppColors.pageBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppColors.secondaryText, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
