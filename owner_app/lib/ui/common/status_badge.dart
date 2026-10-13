import 'package:flutter/material.dart';
import '../../data/models/vehicle.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.isStale = false,
    this.compact = false,
  });

  final VehicleStatus status;
  final bool isStale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStatus = isStale ? VehicleStatus.offline : status;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: effectiveStatus.containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveStatus.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveStatus.color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isStale ? 'Delayed' : effectiveStatus.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: effectiveStatus.color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
