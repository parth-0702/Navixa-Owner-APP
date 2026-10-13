import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip.dart';
import '../../../providers/operations_provider.dart';
import '../../common/app_card.dart';
import '../../common/empty_state.dart';
import '../../common/error_state.dart';
import '../../common/skeleton_loading.dart';

class TripsOverviewScreen extends StatefulWidget {
  const TripsOverviewScreen({super.key});

  @override
  State<TripsOverviewScreen> createState() => _TripsOverviewScreenState();
}

class _TripsOverviewScreenState extends State<TripsOverviewScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OperationsProvider>();
      provider.loadTrips();
      if (provider.drivers.isEmpty) provider.loadDrivers();
      if (provider.vehicles.isEmpty) provider.loadVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(OperationsProvider provider) async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        actions: [
          IconButton(
            tooltip: 'Reports',
            onPressed: () => context.push('/reports'),
            icon: const Icon(Icons.assessment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search trip number',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: () =>
                          provider.setTripSearch(_searchController.text.trim()),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                  onSubmitted: provider.setTripSearch,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const {
                        'all': 'All',
                        'in_progress': 'Current',
                        'completed': 'Completed',
                        'scheduled': 'Scheduled',
                        'cancelled': 'Cancelled',
                      }.entries) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: provider.tripStatus == entry.key,
                          onSelected: (_) => provider.setTripStatus(entry.key),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: provider.vehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All vehicles'),
                          ),
                          ...provider.vehicles.map(
                            (vehicle) => DropdownMenuItem<String?>(
                              value: vehicle.id,
                              child: Text(
                                vehicle.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: provider.setVehicleFilter,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: provider.driverId,
                        decoration: const InputDecoration(
                          labelText: 'Driver',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All drivers'),
                          ),
                          ...provider.drivers.map(
                            (driver) => DropdownMenuItem<String?>(
                              value: driver.id,
                              child: Text(
                                driver.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: provider.setDriverFilter,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickDateRange(provider),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    provider.dateRange == null
                        ? 'Any date'
                        : '${DateFormat('d MMM').format(provider.dateRange!.start)} – ${DateFormat('d MMM').format(provider.dateRange!.end)}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(provider)),
        ],
      ),
    );
  }

  Widget _buildContent(OperationsProvider provider) {
    if (provider.isLoadingTrips && provider.trips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonLoading(itemCount: 5, height: 116),
      );
    }
    if (provider.errorMessage != null && provider.trips.isEmpty) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.loadTrips,
      );
    }
    if (provider.trips.isEmpty) {
      return const EmptyState(
        title: 'No trips found',
        message: 'Try changing the status, driver, date, or search filters.',
        icon: Icons.route_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadTrips,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _TripCard(trip: provider.trips[index]),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final active = trip.status == TripStatus.inProgress;
    return AppCard(
      onTap: () => context.push('/trips/${trip.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.successSoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.success : AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.tripNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trip.startAddress.isEmpty ? 'Start' : trip.startAddress}  →  ${trip.endAddress.isEmpty ? 'Destination' : trip.endAddress}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _meta(
                Icons.local_shipping_outlined,
                trip.vehicleNickname.isEmpty
                    ? trip.vehiclePlateNumber
                    : trip.vehicleNickname,
              ),
              _meta(Icons.person_outline, trip.driver?.name ?? 'Unassigned'),
              _meta(
                Icons.route_outlined,
                '${trip.distanceKm.toStringAsFixed(1)} km',
              ),
              _meta(Icons.schedule_outlined, '${trip.durationMinutes} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.secondaryTeal),
      const SizedBox(width: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
      ),
    ],
  );
}
