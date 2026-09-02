import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/constants/app_constants.dart';

/// Dropdown-only picker for an invalid record `type`. No typing.
/// Returns the chosen canonical type, or null when dismissed.
class ImportRecordTypeDialog extends StatefulWidget {
  final String message;
  final String currentValue;

  const ImportRecordTypeDialog({
    super.key,
    required this.message,
    required this.currentValue,
  });

  static Future<String?> show(
    BuildContext context, {
    required String message,
    required String currentValue,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImportRecordTypeDialog(
        message: message,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<ImportRecordTypeDialog> createState() => _ImportRecordTypeDialogState();
}

class _ImportRecordTypeDialogState extends State<ImportRecordTypeDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text('Current: ${widget.currentValue}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selected,
                decoration: const InputDecoration(
                  hintText: 'Select a valid record type...',
                ),
                isExpanded: true,
                items: AppConstants.recordTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      disabledBackgroundColor:
                          AppColors.grid.withValues(alpha: 0.5),
                    ),
                    onPressed: _selected != null
                        ? () => Navigator.of(context).pop(_selected)
                        : null,
                    child: const Text('Confirm',
                        style: TextStyle(color: AppColors.background)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}