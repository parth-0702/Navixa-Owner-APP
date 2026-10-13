import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fleet_provider.dart';
import '../../../providers/overview_provider.dart';
import '../../common/app_card.dart';
import '../../common/error_state.dart';
import '../../common/skeleton_loading.dart';
import 'compact_map_preview.dart';
import 'critical_alert_banner.dart';
import 'status_summary_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OverviewProvider>().loadOverview();
    });
  }

  void _navigateToFleetWithFilter(String status) {
    context.read<FleetProvider>().setFilterStatus(status);
    context.go('/fleet');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final overview = context.watch<OverviewProvider>();

    if (overview.isLoading && overview.data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fleet Overview')),
        body: const DashboardSkeleton(),
      );
    }

    if (overview.errorMessage != null && overview.data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fleet Overview')),
        body: ErrorState(
          message: overview.errorMessage!,
          isOffline: overview.isOffline,
          onRetry: () => overview.loadOverview(),
        ),
      );
    }

    final data = overview.data;
    final counts = data?.statusCounts;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPageBackground : AppColors.pageBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data?.greeting ?? 'Good day',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              data?.organizationName ?? 'Navixa Fleet',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            icon: Badge(
              isLabelVisible: (data?.unreadCount ?? 0) > 0,
              label: Text('${data?.unreadCount ?? 0}'),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.go('/alerts'),
          ),
          IconButton(
            tooltip: 'Account & Settings',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
              child: Text(
                auth.user?.name.isNotEmpty == true ? auth.user!.name[0].toUpperCase() : 'O',
                style: const TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => overview.loadOverview(silent: true),
        color: AppColors.secondaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline notice banner if network dropped
              if (overview.isOffline) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warningDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing cached fleet status. Reconnecting to live feed...',
                          style: TextStyle(color: AppColors.warningDark, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Critical Alert Banner
              if (data?.criticalAlertBanner != null) ...[
                CriticalAlertBannerWidget(
                  banner: data!.criticalAlertBanner!,
                  onTap: () => context.go('/alerts'),
                ),
                const SizedBox(height: 16),
              ],

              // Status Summary Grid
              Row(
                children: [
                  Expanded(
                    child: StatusSummaryCard(
                      title: 'Total Fleet',
                      count: counts?.total ?? 0,
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primaryNavy,
                      onTap: () => _navigateToFleetWithFilter('all'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusSummaryCard(
                      title: 'Moving',
                      count: counts?.moving ?? 0,
                      icon: Icons.navigation_rounded,
                      color: AppColors.statusMoving,
                      containerColor: AppColors.successSoft,
                      onTap: () => _navigateToFleetWithFilter('moving'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatusSummaryCard(
                      title: 'Idle (Eng. ON)',
                      count: counts?.idle ?? 0,
                      icon: Icons.pause_circle_filled_rounded,
                      color: AppColors.statusIdle,
                      containerColor: AppColors.warningSoft,
                      onTap: () => _navigateToFleetWithFilter('idle'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusSummaryCard(
                      title: 'Parked',
                      count: counts?.parked ?? 0,
                      icon: Icons.local_parking_rounded,
                      color: AppColors.statusParked,
                      onTap: () => _navigateToFleetWithFilter('parked'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatusSummaryCard(
                      title: 'Offline',
                      count: counts?.offline ?? 0,
                      icon: Icons.cloud_off_rounded,
                      color: AppColors.statusOffline,
                      containerColor: AppColors.offlineSoft,
                      onTap: () => _navigateToFleetWithFilter('offline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Compact Fleet Map Preview
              CompactMapPreviewWidget(
                vehicles: data?.fleetMapPreview ?? [],
                onOpenLiveMap: () => context.go('/map'),
              ),
              const SizedBox(height: 24),

              // Recent Alerts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/alerts'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (data?.recentAlerts.isEmpty ?? true)
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.secondaryTeal, size: 28),
                        const SizedBox(height: 6),
                        Text('All vehicles operating normally', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                ...data!.recentAlerts.take(3).map((alert) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => context.go('/alerts'),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: alert.severity.containerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(alert.severity.icon, size: 18, color: alert.severity.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.title,
                                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${alert.vehicleName} • ${Formatters.timeAgo(alert.timestamp)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Recent Activity / Trips Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Trips & Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/fleet'),
                    child: const Text('View Fleet'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (data?.recentTrips.isEmpty ?? true)
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.route_outlined, color: AppColors.secondaryText, size: 28),
                        const SizedBox(height: 6),
                        Text('No recent trip logs recorded today', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                ...data!.recentTrips.take(3).map((trip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => context.push('/trips/${trip.id}'),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  trip.tripNumber,
                                  style: const TextStyle(
                                    color: AppColors.secondaryTeal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${Formatters.formatDistance(trip.distanceKm)} • ${trip.durationMinutes} min',
                                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.navigation_rounded, size: 14, color: AppColors.secondaryTeal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${trip.vehicleNickname} • Driver: ${trip.driver?.name ?? "Assigned"}',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (trip.endAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Destination: ${trip.endAddress}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
