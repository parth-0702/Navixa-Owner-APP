import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/vehicle.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fleet_provider.dart';
import '../../common/app_card.dart';
import '../../common/error_state.dart';
import '../../common/metric_tile.dart';
import '../../common/skeleton_loading.dart';
import '../../common/status_badge.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().loadVehicleDetails(widget.vehicleId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditNicknameDialog(Vehicle vehicle) {
    final textController = TextEditingController(text: vehicle.nickname);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Vehicle Nickname'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Nickname',
              hintText: 'e.g. North Delivery Van #2',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = textController.text.trim();
                Navigator.pop(ctx);
                final success = await context.read<FleetProvider>().updateNickname(vehicle.id, newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Nickname updated successfully' : 'Failed to update nickname'),
                      backgroundColor: success ? AppColors.secondaryTeal : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOwner = context.watch<AuthProvider>().isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => context.read<FleetProvider>().loadVehicleDetails(widget.vehicleId),
          ),
        ],
      ),
      body: Consumer<FleetProvider>(
        builder: (context, fleet, _) {
          if (fleet.isLoadingDetails && fleet.selectedVehicle == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonLoading(itemCount: 4, height: 120),
            );
          }

          if (fleet.errorMessage != null && fleet.selectedVehicle == null) {
            return ErrorState(
              message: fleet.errorMessage!,
              isOffline: fleet.isOffline,
              onRetry: () => fleet.loadVehicleDetails(widget.vehicleId),
            );
          }

          final vehicle = fleet.selectedVehicle;
          if (vehicle == null) {
            return const Center(child: Text('Vehicle not found'));
          }

          return Column(
            children: [
              // Stale Location Alert Banner
              if (vehicle.isStale)
                Container(
                  width: double.infinity,
                  color: AppColors.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB25E00), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location data may be stale (${Formatters.timeAgo(vehicle.lastLocationUpdatedAt ?? vehicle.lastCommunicationAt)}). Vehicle might be out of cellular range.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.warning : const Color(0xFFB25E00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Header Card
              Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: AppColors.primaryNavy, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      vehicle.displayName,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _showEditNicknameDialog(vehicle),
                                      child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondaryTeal),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.plateNumber} • ${vehicle.make} ${vehicle.model} (${vehicle.year})',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: vehicle.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.secondaryTeal,
                      labelColor: AppColors.secondaryTeal,
                      unselectedLabelColor: AppColors.secondaryText,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'OVERVIEW'),
                        Tab(text: 'TRIPS'),
                        Tab(text: 'INFO'),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, vehicle),
                    _buildTripsTab(context, fleet.vehicleTrips),
                    _buildInfoTab(context, vehicle),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Vehicle vehicle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Telemetry Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              MetricTile(
                title: 'Current Speed',
                value: '${vehicle.speedKmh.toStringAsFixed(0)} km/h',
                icon: Icons.speed_rounded,
                accentColor: vehicle.status == VehicleStatus.moving ? AppColors.secondaryTeal : AppColors.secondaryText,
              ),
              MetricTile(
                title: 'Ignition State',
                value: vehicle.ignitionOn ? 'ON' : 'OFF',
                icon: Icons.power_settings_new_rounded,
                accentColor: vehicle.ignitionOn ? AppColors.success : AppColors.secondaryText,
              ),
              MetricTile(
                title: "Today's Distance",
                value: Formatters.distance(vehicle.todayDistanceKm),
                icon: Icons.route_rounded,
              ),
              MetricTile(
                title: 'Odometer',
                value: Formatters.odometer(vehicle.odometerKm),
                icon: Icons.straighten_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fuel or Battery Level
          if (vehicle.fuelPercent != null || vehicle.batteryPercent != null)
            AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            vehicle.fuelPercent != null ? Icons.local_gas_station_rounded : Icons.battery_charging_full_rounded,
                            color: AppColors.accentGold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicle.fuelPercent != null ? 'Fuel Level' : 'Battery Level',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${(vehicle.fuelPercent ?? vehicle.batteryPercent ?? 0).toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((vehicle.fuelPercent ?? vehicle.batteryPercent ?? 0) / 100).clamp(0.0, 1.0),
                      backgroundColor: isDark ? Colors.grey[800] : AppColors.lightBorder,
                      color: (vehicle.fuelPercent ?? vehicle.batteryPercent ?? 0) < 20
                          ? AppColors.error
                          : AppColors.secondaryTeal,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

          // Latest Location Card with Map CTA
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LATEST KNOWN LOCATION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      Formatters.timeAgo(vehicle.lastLocationUpdatedAt ?? vehicle.lastCommunicationAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.secondaryTeal, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.lastLocation?.address ?? 'Coordinates available',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (vehicle.lastLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${vehicle.lastLocation!.latitude.toStringAsFixed(5)}, Lng: ${vehicle.lastLocation!.longitude.toStringAsFixed(5)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('View on Live Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.lightBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      context.push('/fleet/${vehicle.id}/map');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Assigned Driver Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED DRIVER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (vehicle.assignedDriver != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
                        child: Text(
                          vehicle.assignedDriver!.name.isNotEmpty
                              ? vehicle.assignedDriver!.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.assignedDriver!.name,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (vehicle.assignedDriver!.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                vehicle.assignedDriver!.phone,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (vehicle.assignedDriver!.phone.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone_outlined, color: AppColors.secondaryTeal),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Call ${vehicle.assignedDriver!.phone}')),
                            );
                          },
                        ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No driver assigned to this vehicle',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsTab(BuildContext context, List trips) {
    final theme = Theme.of(context);

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route_rounded, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: 12),
            Text('No Recent Trips Recorded', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Trips will automatically appear once completed.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return AppCard(
          onTap: () {
            context.push('/trips/${trip.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip.startTime != null ? DateFormat('MMM d, yyyy • h:mm a').format(trip.startTime!) : '—',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trip.isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trip.isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: trip.isCompleted ? AppColors.success : AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.radio_button_checked, size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.startAddress.isNotEmpty ? trip.startAddress : 'Start point',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(thickness: 1.5, color: AppColors.lightBorder),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.endAddress.isNotEmpty ? trip.endAddress : 'In route...',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${trip.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    Formatters.durationMinutes(trip.durationMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.secondaryText),
                  ),
                  const Row(
                    children: [
                      Text('View Route', style: TextStyle(fontSize: 12, color: AppColors.secondaryTeal, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.secondaryTeal),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(BuildContext context, Vehicle vehicle) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPECIFICATIONS & REGISTRATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpecRow('Registration Plate', vehicle.plateNumber),
            const Divider(height: 16),
            _buildSpecRow('VIN / Chassis', vehicle.vin),
            const Divider(height: 16),
            _buildSpecRow('Make & Model', '${vehicle.make} ${vehicle.model}'),
            const Divider(height: 16),
            _buildSpecRow('Model Year', vehicle.year.toString()),
            const Divider(height: 16),
            _buildSpecRow('Status', vehicle.status.name.toUpperCase()),
            const Divider(height: 16),
            _buildSpecRow('Last Communication', DateFormat('MMM d, yyyy h:mm a').format(vehicle.lastCommunicationAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
