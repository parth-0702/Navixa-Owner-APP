import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/alert.dart';
import '../../../providers/alerts_provider.dart';

class AcknowledgeModal extends StatefulWidget {
  const AcknowledgeModal({super.key, required this.alert});

  final Alert alert;

  static Future<bool?> show(BuildContext context, Alert alert) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcknowledgeModal(alert: alert),
    );
  }

  @override
  State<AcknowledgeModal> createState() => _AcknowledgeModalState();
}

class _AcknowledgeModalState extends State<AcknowledgeModal> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitAcknowledgment() async {
    setState(() => _isSubmitting = true);
    final note = _noteController.text.trim();
    final alertsProv = context.read<AlertsProvider>();

    final success = await alertsProv.acknowledgeAlert(widget.alert.id, note: note);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Incident acknowledged and logged to audit trail' : 'Failed to acknowledge alert',
          ),
          backgroundColor: success ? AppColors.secondaryTeal : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(widget.alert.severity.icon, color: widget.alert.severity.color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acknowledge Incident',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.alert.title} • ${widget.alert.vehicleName}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (widget.alert.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.alert.description,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Resolution Note (Optional)',
                hintText: 'e.g. Driver contacted, issue investigated and cleared.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAcknowledgment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
