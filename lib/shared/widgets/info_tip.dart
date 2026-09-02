import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';

/// Circled-"i" badge explaining a field.
///
/// The popup is a structured note, not one wrapped blob. Mandatory
/// fields lead with a bold tinted status line ([status], soft salmon),
/// a blank line, then [body] rendered verbatim - author it with \n so
/// each rule sits on its own indented-left line. Non-mandatory fields
/// show just the body, no status line at all.
///
/// Background is zinc-600 (#52525B), the classic elevated-tooltip gray,
/// with off-white zinc-200 text for AA contrast.
class InfoTip extends StatelessWidget {
  final String? status;
  final String body;
  final bool isMandatory;

  const InfoTip({
    super.key,
    this.status,
    required this.body,
    this.isMandatory = false,
  });

  double get _maxWidth {
    final len = (status?.length ?? 0) + body.length;
    if (len <= 60) return 220;
    if (len <= 180) return 300;
    return 380;
  }

  static const _bg = Color(0xFF52525B);
  static const _border = Color(0x24FFFFFF);
  static const _textMain = Color(0xFFE4E4E7);
  static const _accentSalmon = Color(0xFFFFAB91);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: TooltipTheme(
          data: TooltipThemeData(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            textStyle: const TextStyle(
              color: _textMain,
              fontSize: 12.5,
              height: 1.45,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            preferBelow: true,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            waitDuration: const Duration(milliseconds: 120),
            showDuration: const Duration(seconds: 8),
          ),
          child: Tooltip(
            key: ValueKey('tip_$status$body'),
            richMessage: TextSpan(
              children: [
                if (isMandatory && status != null) ...[
                  TextSpan(
                    text: status,
                    style: const TextStyle(
                      color: _accentSalmon,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const TextSpan(text: '\n\n'),
                ],
                TextSpan(text: body),
              ],
            ),
            triggerMode: TooltipTriggerMode.tap,
            constraints: BoxConstraints(maxWidth: _maxWidth),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
