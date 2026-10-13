import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/alerts_provider.dart';
import '../../common/empty_state.dart';
import '../../common/error_state.dart';
import '../../common/skeleton_loading.dart';
import 'alert_card.dart';

class AlertCenterScreen extends StatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen> {
  final List<Map<String, String>> _statusTabs = const [
    {'id': 'all', 'label': 'All Alerts'},
    {'id': 'unread', 'label': 'Unread'},
    {'id': 'critical', 'label': 'Critical'},
  ];

  final List<Map<String, String?>> _typeOptions = const [
    {'id': null, 'label': 'All Types'},
    {'id': 'overspeed', 'label': 'Overspeed'},
    {'id': 'long_idle', 'label': 'Long Idle'},
    {'id': 'geofence_entry', 'label': 'Geofence Entry'},
    {'id': 'geofence_exit', 'label': 'Geofence Exit'},
    {'id': 'route_deviation', 'label': 'Route Deviation'},
    {'id': 'low_fuel', 'label': 'Low Fuel'},
    {'id': 'device_offline', 'label': 'Device Offline'},
    {'id': 'maintenance_due', 'label': 'Maintenance'},
    {'id': 'safety_event', 'label': 'Safety Event'},
    {'id': 'low_battery', 'label': 'Low Battery'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertsProv = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Center'),
        actions: [
          if (alertsProv.unreadCount > 0)
            TextButton(
              onPressed: () => alertsProv.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => alertsProv.loadAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Type Selector Header
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Primary Filter Chips (All, Unread, Critical)
                Row(
                  children: _statusTabs.map((tab) {
                    final isSelected = alertsProv.selectedStatus == tab['id'];
                    int badgeCount = 0;
                    if (tab['id'] == 'unread') {
                      badgeCount = alertsProv.unreadCount;
                    }
                    if (tab['id'] == 'critical') {
                      badgeCount = alertsProv.criticalCount;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tab['label']!),
                            if (badgeCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tab['id'] == 'critical'
                                      ? AppColors.error
                                      : (isSelected
                                            ? Colors.white
                                            : AppColors.secondaryTeal),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$badgeCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: tab['id'] == 'critical'
                                        ? Colors.white
                                        : (isSelected
                                              ? AppColors.secondaryTeal
                                              : Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        selectedColor: AppColors.primaryNavy,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (_) =>
                            alertsProv.setFilterStatus(tab['id']!),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Type Filter Dropdown
                Row(
                  children: [
                    const Text(
                      'Filter by Type:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: alertsProv.selectedType,
                          isDense: true,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.secondaryTeal,
                          ),
                          items: _typeOptions.map((opt) {
                            return DropdownMenuItem<String?>(
                              value: opt['id'],
                              child: Text(
                                opt['label']!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => alertsProv.setFilterType(val),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Alert Content Area
          Expanded(
            child: Consumer<AlertsProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading && prov.alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonLoading(itemCount: 4, height: 110),
                  );
                }

                if (prov.errorMessage != null && prov.alerts.isEmpty) {
                  return ErrorState(
                    message: prov.errorMessage!,
                    isOffline: prov.isOffline,
                    onRetry: () => prov.loadAlerts(),
                  );
                }

                if (prov.alerts.isEmpty) {
                  return EmptyState(
                    title: 'No Alerts Found',
                    message:
                        prov.selectedStatus != 'all' ||
                            prov.selectedType != null
                        ? 'There are no alerts matching your selected filter criteria.'
                        : 'Your fleet is running smoothly. No operational alerts have been reported.',
                    icon: Icons.check_circle_outline_rounded,
                    actionLabel:
                        prov.selectedStatus != 'all' ||
                            prov.selectedType != null
                        ? 'Clear Filters'
                        : null,
                    onAction: () {
                      prov.setFilterStatus('all');
                      prov.setFilterType(null);
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => prov.loadAlerts(),
                  color: AppColors.secondaryTeal,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (prov.today.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'TODAY',
                          prov.today.length,
                        ),
                        ...prov.today.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AlertCard(alert: a),
                          ),
                        ),
                      ],
                      if (prov.yesterday.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'YESTERDAY',
                          prov.yesterday.length,
                        ),
                        ...prov.yesterday.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AlertCard(alert: a),
                          ),
                        ),
                      ],
                      if (prov.earlier.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'EARLIER',
                          prov.earlier.length,
                        ),
                        ...prov.earlier.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AlertCard(alert: a),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryText,
              letterSpacing: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
