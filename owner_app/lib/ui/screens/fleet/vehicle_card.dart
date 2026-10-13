import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/vehicle.dart';
import '../../common/app_card.dart';
import '../../common/status_badge.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Vehicle Name, Plate Number & Status Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.plateNumber,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: vehicle.status, isStale: vehicle.isStale),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Location Address
          if (vehicle.lastLocation?.address.isNotEmpty == true) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vehicle.lastLocation!.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Stale Warning Indicator (if applicable)
          if (vehicle.isStale &&
              vehicle.status != VehicleStatus.maintenance) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 13,
                    color: AppColors.warningDark,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Signal delayed • ${vehicle.lastUpdatedAgo.isNotEmpty ? vehicle.lastUpdatedAgo : Formatters.timeAgo(vehicle.lastLocationUpdatedAt)}',
                    style: const TextStyle(
                      color: AppColors.warningDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Row 3: Metrics (Speed, Fuel, Today's Distance, Driver)
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed
              _metricItem(
                context,
                icon: Icons.speed_rounded,
                label: 'Speed',
                value: vehicle.status == VehicleStatus.moving
                    ? Formatters.formatSpeed(vehicle.speedKmh)
                    : vehicle.status == VehicleStatus.idle
                    ? '0 (Idle)'
                    : vehicle.status.label,
              ),
              // Fuel
              _metricItem(
                context,
                icon: Icons.local_gas_station_outlined,
                label: 'Fuel',
                value: '${vehicle.currentFuelLevel}%',
              ),
              // Today's Distance
              _metricItem(
                context,
                icon: Icons.straighten_rounded,
                label: 'Today',
                value: Formatters.formatDistance(vehicle.todayDistanceKm),
              ),
              // Driver
              _metricItem(
                context,
                icon: Icons.person_outline_rounded,
                label: 'Driver',
                value:
                    vehicle.assignedDriver?.name.split(' ').first ??
                    'Unassigned',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 13,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 5),
              Text(
                vehicle.lastUpdatedAgo.isNotEmpty
                    ? vehicle.lastUpdatedAgo
                    : Formatters.timeAgo(vehicle.lastLocationUpdatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.secondaryText,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
