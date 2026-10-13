import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/alert.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/app_card.dart';
import 'acknowledge_modal.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final canAcknowledge = auth.isOwner || auth.isManager;

    return AppCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: !alert.isRead ? alert.severity.color.withValues(alpha: 0.5) : AppColors.lightBorder,
        width: !alert.isRead ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Severity, Title, Unread Indicator
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.severity.containerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(alert.severity.icon, color: alert.severity.color, size: 20),
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
                            alert.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.vehicleName}${alert.vehiclePlateNumber != null ? ' (${alert.vehiclePlateNumber})' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          if (alert.description.isNotEmpty) ...[
            Text(
              alert.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Location & Timestamp
          Row(
            children: [
              if (alert.location.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.location,
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                Formatters.timeAgo(alert.timestamp),
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Acknowledged metadata
          if (alert.isAcknowledged) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Acknowledged${alert.acknowledgedBy != null ? ' by ${alert.acknowledgedBy}' : ''}'
                      '${alert.acknowledgmentNote.isNotEmpty ? ': "${alert.acknowledgmentNote}"' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vehicle Detail Link
              if (alert.vehicleId != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.primaryNavy,
                  ),
                  icon: const Icon(Icons.directions_car_rounded, size: 16),
                  label: const Text('View Vehicle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    context.push('/fleet/${alert.vehicleId}');
                  },
                )
              else
                const SizedBox.shrink(),

              Row(
                children: [
                  // Mark as Read/Unread
                  if (!alert.isRead)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.secondaryText,
                      ),
                      onPressed: () {
                        context.read<AlertsProvider>().markAsRead(alert.id);
                      },
                      child: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                    ),

                  // Acknowledge Action (Owner & Manager only)
                  if (canAcknowledge && !alert.isAcknowledged) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => AcknowledgeModal.show(context, alert),
                      child: const Text('Acknowledge'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
