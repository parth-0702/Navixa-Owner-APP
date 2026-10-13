import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/fleet_provider.dart';
import '../../common/empty_state.dart';
import '../../common/error_state.dart';
import '../../common/search_bar_widget.dart';
import '../../common/skeleton_loading.dart';
import 'vehicle_card.dart';

class FleetListScreen extends StatefulWidget {
  const FleetListScreen({super.key});

  @override
  State<FleetListScreen> createState() => _FleetListScreenState();
}

class _FleetListScreenState extends State<FleetListScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _statusFilters = const [
    {'id': 'all', 'label': 'All'},
    {'id': 'moving', 'label': 'Moving'},
    {'id': 'idle', 'label': 'Idle'},
    {'id': 'stopped', 'label': 'Stopped'},
    {'id': 'parked', 'label': 'Parked'},
    {'id': 'offline', 'label': 'Offline'},
    {'id': 'maintenance', 'label': 'In Shop'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fleet = context.read<FleetProvider>();
      if (fleet.vehicles.isEmpty) {
        fleet.loadVehicles(resetPage: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FleetProvider>().loadMoreVehicles();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortSheet() {
    final fleet = context.read<FleetProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Vehicles By',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  title: const Text('Last Updated Time'),
                  trailing: fleet.selectedSort == 'lastUpdated'
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () {
                    fleet.setSort('lastUpdated');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('Vehicle Name & Plate'),
                  trailing: fleet.selectedSort == 'name'
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () {
                    fleet.setSort('name');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('Operational Status'),
                  trailing: fleet.selectedSort == 'status'
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () {
                    fleet.setSort('status');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text("Today's Distance"),
                  trailing: fleet.selectedSort == 'distance'
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () {
                    fleet.setSort('distance');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkPageBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Fleet Vehicles'),
        actions: [
          IconButton(
            tooltip: 'Sort Fleet',
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBarWidget(
              onChanged: fleet.onSearchChanged,
              onFilterTap: _showSortSheet,
            ),
          ),

          // Horizontal Status Filter Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = fleet.selectedStatus == filter['id'];

                return ChoiceChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      fleet.setFilterStatus(filter['id']!);
                    }
                  },
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.primaryText),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceCard
                      : AppColors.surfaceCard,
                  selectedColor: AppColors.primaryNavy,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryNavy
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // List Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (fleet.isLoading && fleet.vehicles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonLoading(itemCount: 4, height: 110),
                  );
                }

                if (fleet.errorMessage != null && fleet.vehicles.isEmpty) {
                  return ErrorState(
                    message: fleet.errorMessage!,
                    isOffline: fleet.isOffline,
                    onRetry: () => fleet.loadVehicles(resetPage: true),
                  );
                }

                if (fleet.vehicles.isEmpty) {
                  return EmptyState(
                    title: 'No Vehicles Found',
                    message:
                        fleet.searchQuery.isNotEmpty ||
                            fleet.selectedStatus != 'all'
                        ? 'No vehicles match your active search or filters. Try adjusting your query.'
                        : 'Your fleet currently has no active vehicles registered.',
                    icon: Icons.local_shipping_outlined,
                    actionLabel:
                        fleet.searchQuery.isNotEmpty ||
                            fleet.selectedStatus != 'all'
                        ? 'Reset Filters'
                        : null,
                    onAction: () {
                      fleet.onSearchChanged('');
                      fleet.setFilterStatus('all');
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => fleet.loadVehicles(resetPage: true),
                  color: AppColors.secondaryTeal,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: fleet.vehicles.length + (fleet.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == fleet.vehicles.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final vehicle = fleet.vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        onTap: () => context.push('/fleet/${vehicle.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
