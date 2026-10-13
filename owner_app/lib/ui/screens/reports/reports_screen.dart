import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/operations_provider.dart';
import '../../common/app_card.dart';
import '../../common/metric_tile.dart';

enum ReportType { trips, distance, travel }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _type = ReportType.trips;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OperationsProvider>().loadTrips(),
    );
  }

  Future<void> _pickDates(OperationsProvider provider) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: provider.dateRange,
    );
    if (result != null) provider.setDateRange(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OperationsProvider>();
    final range = provider.dateRange;
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Reports')),
      body: RefreshIndicator(
        onRefresh: provider.loadTrips,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ReportType>(
              segments: const [
                ButtonSegment(
                  value: ReportType.trips,
                  label: Text('Trips'),
                  icon: Icon(Icons.route_outlined),
                ),
                ButtonSegment(
                  value: ReportType.distance,
                  label: Text('Distance'),
                  icon: Icon(Icons.straighten_outlined),
                ),
                ButtonSegment(
                  value: ReportType.travel,
                  label: Text('Travel'),
                  icon: Icon(Icons.schedule_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickDates(provider),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                range == null
                    ? 'Choose report period'
                    : '${DateFormat('d MMM yyyy').format(range.start)} – ${DateFormat('d MMM yyyy').format(range.end)}',
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _summaryTiles(provider),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${provider.trips.length} records',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (provider.isLoadingTrips)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.trips.isEmpty)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No data for this report period'),
                  ),
                ),
              )
            else
              ...provider.trips.map(
                (trip) => AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () => context.push('/trips/${trip.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_icon, color: AppColors.secondaryTeal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.tripNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${trip.vehicleNickname} • ${trip.driver?.name ?? 'Unassigned'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _value(trip.distanceKm, trip.durationMinutes),
                        style: const TextStyle(fontWeight: FontWeight.w800),
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

  List<Widget> _summaryTiles(OperationsProvider p) => switch (_type) {
    ReportType.trips => [
      MetricTile(
        title: 'Total Trips',
        value: '${p.trips.length}',
        icon: Icons.route_rounded,
        accentColor: AppColors.primaryNavy,
      ),
      MetricTile(
        title: 'Completed',
        value: '${p.completedTrips}',
        icon: Icons.check_circle_outline,
        accentColor: AppColors.secondaryTeal,
      ),
      MetricTile(
        title: 'Current',
        value: '${p.activeTrips}',
        icon: Icons.navigation_rounded,
        accentColor: AppColors.accentGold,
      ),
      MetricTile(
        title: 'Stops',
        value: '${p.totalStops}',
        icon: Icons.stop_circle_outlined,
      ),
    ],
    ReportType.distance => [
      MetricTile(
        title: 'Total Distance',
        value: '${p.totalDistance.toStringAsFixed(1)} km',
        icon: Icons.straighten_rounded,
        accentColor: AppColors.secondaryTeal,
      ),
      MetricTile(
        title: 'Average / Trip',
        value:
            '${p.trips.isEmpty ? '0.0' : (p.totalDistance / p.trips.length).toStringAsFixed(1)} km',
        icon: Icons.analytics_outlined,
      ),
      MetricTile(
        title: 'Completed',
        value: '${p.completedTrips}',
        icon: Icons.check_circle_outline,
      ),
      MetricTile(
        title: 'Trips',
        value: '${p.trips.length}',
        icon: Icons.route_outlined,
      ),
    ],
    ReportType.travel => [
      MetricTile(
        title: 'Travel Time',
        value: Formatters.durationMinutes(p.totalDuration),
        icon: Icons.schedule_rounded,
        accentColor: AppColors.primaryNavy,
      ),
      MetricTile(
        title: 'Average / Trip',
        value: Formatters.durationMinutes(
          p.trips.isEmpty ? 0 : (p.totalDuration / p.trips.length).round(),
        ),
        icon: Icons.timer_outlined,
      ),
      MetricTile(
        title: 'Stops',
        value: '${p.totalStops}',
        icon: Icons.stop_circle_outlined,
      ),
      MetricTile(
        title: 'Trips',
        value: '${p.trips.length}',
        icon: Icons.route_outlined,
      ),
    ],
  };

  String get _title => switch (_type) {
    ReportType.trips => 'Trip Report',
    ReportType.distance => 'Distance Report',
    ReportType.travel => 'Travel Report',
  };
  IconData get _icon => switch (_type) {
    ReportType.trips => Icons.route_outlined,
    ReportType.distance => Icons.straighten_outlined,
    ReportType.travel => Icons.schedule_outlined,
  };
  String _value(double distance, int duration) => switch (_type) {
    ReportType.trips => 'View',
    ReportType.distance => '${distance.toStringAsFixed(1)} km',
    ReportType.travel => Formatters.durationMinutes(duration),
  };
}
