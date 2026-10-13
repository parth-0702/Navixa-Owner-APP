import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/driver.dart';
import '../../../providers/operations_provider.dart';
import '../../common/app_card.dart';
import '../../common/empty_state.dart';
import '../../common/error_state.dart';
import '../../common/skeleton_loading.dart';

class DriversOverviewScreen extends StatefulWidget {
  const DriversOverviewScreen({super.key});

  @override
  State<DriversOverviewScreen> createState() => _DriversOverviewScreenState();
}

class _DriversOverviewScreenState extends State<DriversOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OperationsProvider>().loadDrivers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OperationsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search driver, phone, or licence',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: provider.setDriverSearch,
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const {
                        'all': 'All',
                        'on_duty': 'On duty',
                        'off_duty': 'Off duty',
                        'active': 'Available',
                        'inactive': 'Inactive',
                      }.entries) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: provider.driverStatus == entry.key,
                          onSelected: (_) =>
                              provider.setDriverStatus(entry.key),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _content(provider)),
        ],
      ),
    );
  }

  Widget _content(OperationsProvider provider) {
    if (provider.isLoadingDrivers && provider.drivers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonLoading(itemCount: 5, height: 110),
      );
    }
    if (provider.errorMessage != null && provider.drivers.isEmpty) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.loadDrivers,
      );
    }
    if (provider.drivers.isEmpty) {
      return const EmptyState(
        title: 'No drivers found',
        message: 'No drivers match the selected filter.',
        icon: Icons.badge_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadDrivers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.drivers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _DriverCard(driver: provider.drivers[index]),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final DriverSummary driver;

  @override
  Widget build(BuildContext context) {
    final onDuty = driver.status == 'on_duty';
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.12),
            child: Text(
              driver.name.isEmpty ? 'D' : driver.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.secondaryTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        driver.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: onDuty
                            ? AppColors.successSoft
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(driver.status),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: onDuty
                              ? AppColors.success
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  driver.phone.isEmpty ? 'No phone provided' : driver.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                if (driver.currentVehicleName != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: driver.currentVehicleId == null
                        ? null
                        : () =>
                              context.push('/fleet/${driver.currentVehicleId}'),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 16,
                          color: AppColors.secondaryTeal,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          driver.currentVehicleName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _metric('Safety', '${driver.safetyScore}')),
                    Expanded(child: _metric('Trips', '${driver.totalTrips}')),
                    Expanded(child: _metric('On time', driver.onTimeRate)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
      ),
    ],
  );

  String _statusLabel(String status) => switch (status) {
    'on_duty' => 'ON DUTY',
    'off_duty' => 'OFF DUTY',
    'inactive' => 'INACTIVE',
    _ => 'AVAILABLE',
  };
}
