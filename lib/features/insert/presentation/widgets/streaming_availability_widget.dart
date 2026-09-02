import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';

class StreamingAvailabilityWidget extends StatelessWidget {
  final Map<String, bool> selectedServices;
  final Map<String, TextEditingController> urlControllers;
  final ValueChanged<String> onToggle;
  final bool showDefaultNotice;

  const StreamingAvailabilityWidget({
    super.key,
    required this.selectedServices,
    required this.urlControllers,
    required this.onToggle,
    this.showDefaultNotice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Streaming Availability',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            InfoTip(
              body: 'Tick every service where this record is available '
                  'to you and optionally store its URL.\n'
                  'If nothing is selected at Preview/Submit, Spotify is '
                  'auto-ticked once - unticking it afterwards persists.',
            ),
          ],
        ),
        if (showDefaultNotice) ...[
          const SizedBox(height: 4),
          const Text(
            'If no services selected, Spotify will be added by default.',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ...AppConstants.streamingServices.map((service) {
          final isSelected = selectedServices[service] ?? false;
          final controller =
              urlControllers.putIfAbsent(service, () => TextEditingController());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: isSelected,
                onChanged: (_) => onToggle(service),
                title: Text(
                  service,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.electricBlue,
                checkColor: AppColors.textPrimary,
              ),
              if (isSelected) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '$service URL (optional)',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}
