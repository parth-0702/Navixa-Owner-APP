import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_preference.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_card.dart';
import '../../common/skeleton_loading.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  NotificationPreference? _currentPrefs;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      await settings.loadPreferences();
      if (mounted) {
        setState(() {
          _currentPrefs =
              settings.preferences ?? const NotificationPreference();
        });
      }
    });
  }

  void _updatePref(NotificationPreference updated) {
    setState(() {
      _currentPrefs = updated;
      _hasChanges = true;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_currentPrefs == null) return;
    final currentStr = isStart
        ? _currentPrefs!.quietHoursStart
        : _currentPrefs!.quietHoursEnd;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updatePref(
        isStart
            ? _currentPrefs!.copyWith(quietHoursStart: formatted)
            : _currentPrefs!.copyWith(quietHoursEnd: formatted),
      );
    }
  }

  Future<void> _savePreferences() async {
    if (_currentPrefs == null) return;
    final settings = context.read<SettingsProvider>();
    final success = await settings.savePreferences(_currentPrefs!);
    if (mounted) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Notification preferences saved'
                : 'Failed to save preferences',
          ),
          backgroundColor: success ? AppColors.secondaryTeal : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    if (settings.isLoading && _currentPrefs == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Preferences')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoading(itemCount: 4, height: 100),
        ),
      );
    }

    final p = _currentPrefs ?? const NotificationPreference();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Primary Delivery Channels
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY CHANNELS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts on this mobile device'),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.pushNotifications,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(pushNotifications: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email Notifications'),
                  subtitle: const Text(
                    'Receive daily digest and critical incident emails',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.emailNotifications,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(emailNotifications: val)),
                ),
              ],
            ),
          ),

          // Quiet Hours
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUIET HOURS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Quiet Hours'),
                  subtitle: const Text(
                    'Mute non-critical notifications during scheduled rest periods',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.quietHoursEnabled,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(quietHoursEnabled: val)),
                ),
                if (p.quietHoursEnabled) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: true),
                          child: Text('Start: ${p.quietHoursStart}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: false),
                          child: Text('End: ${p.quietHoursEnd}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Operational Alert Types
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIONAL ALERT TYPES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                // Critical safety alerts with policy warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 20,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Critical Safety Incidents',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: p.criticalAlerts,
                            activeThumbColor: AppColors.error,
                            onChanged: (val) {
                              if (!val) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Warning: Disable Critical Alerts?',
                                    ),
                                    content: const Text(
                                      'Critical alerts include crash detection, roll-over incidents, and high-speed violations. Disabling this may delay emergency fleet responses.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Keep Enabled'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _updatePref(
                                            p.copyWith(criticalAlerts: false),
                                          );
                                        },
                                        child: const Text('Disable Anyway'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                _updatePref(p.copyWith(criticalAlerts: true));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Immediate push notifications for severe vehicle events regardless of quiet hours.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white70
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Overspeed Violations'),
                  subtitle: const Text(
                    'Triggered when vehicle exceeds speed threshold',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.overspeedAlerts,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(overspeedAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Long Idle Alerts'),
                  subtitle: const Text(
                    'Triggered when vehicle idles with engine on for > 15m',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.idleAlerts,
                  onChanged: (val) => _updatePref(p.copyWith(idleAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Geofence Entry & Exit'),
                  subtitle: const Text('Boundary departure or arrival alerts'),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.geofenceAlerts,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(geofenceAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Route Deviation'),
                  subtitle: const Text('Vehicle leaves its planned route'),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.routeDeviationAlerts,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(routeDeviationAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Low Fuel'),
                  subtitle: const Text(
                    'Fuel level drops below the configured threshold',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.lowFuelAlerts,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(lowFuelAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Device Offline Alerts'),
                  subtitle: const Text(
                    'Notifies when GPS unit ceases pinging server',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.offlineAlerts,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(offlineAlerts: val)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Maintenance Reminders'),
                  subtitle: const Text(
                    'Scheduled servicing and diagnostic checks',
                  ),
                  activeThumbColor: AppColors.secondaryTeal,
                  value: p.maintenanceReminders,
                  onChanged: (val) =>
                      _updatePref(p.copyWith(maintenanceReminders: val)),
                ),
              ],
            ),
          ),

          // Save Changes CTA
          if (_hasChanges)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _savePreferences,
              child: const Text(
                'Save Notification Preferences',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
