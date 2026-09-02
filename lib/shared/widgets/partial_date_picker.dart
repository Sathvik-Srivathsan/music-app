import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';

/// Sequential partial-date picker shared by the INSERT form and the
/// SEARCH edit popup. Tapping cells advances instantly; the Done button
/// in a dialog finalizes everything chosen SO FAR:
///   Done in Month dialog -> "YYYY"
///   Done in Day dialog   -> "YYYY-MM"
///   Day tap              -> "YYYY-MM-DD"
/// There is no back button anywhere - Cancel aborts entirely.
/// Returns null when the flow was cancelled.
Future<String?> showPartialDatePicker(BuildContext context) async {
  final now = DateTime.now();

  final selectedYear = await showDialog<int>(
    context: context,
    builder: (ctx) => _YearPickerDialog(currentYear: now.year),
  );
  if (selectedYear == null) return null;

  final monthOutcome = await showDialog<_PickerOutcome>(
    context: context,
    builder: (ctx) => _MonthPickerDialog(year: selectedYear),
  );
  if (monthOutcome == null) return null;
  if (!monthOutcome.advance) return '$selectedYear';
  final selectedMonth = monthOutcome.value;

  final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
  final dayOutcome = await showDialog<_PickerOutcome>(
    context: context,
    builder: (ctx) => _DayPickerDialog(
      year: selectedYear,
      month: selectedMonth,
      maxDay: daysInMonth,
      currentDay:
          (selectedYear == now.year && selectedMonth == now.month) ? now.day : null,
    ),
  );
  if (dayOutcome == null) return null;
  if (!dayOutcome.advance) {
    return '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
  }

  return '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-'
      '${dayOutcome.value.toString().padLeft(2, '0')}';
}

class _PickerOutcome {
  final int value;
  final bool advance;
  const _PickerOutcome(this.value, {required this.advance});
}

class _YearPickerDialog extends StatelessWidget {
  final int currentYear;
  const _YearPickerDialog({required this.currentYear});

  @override
  Widget build(BuildContext context) {
    final years = List.generate(currentYear - 1899, (i) => 1900 + i);
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 450),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Year',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: years.length,
                itemBuilder: (ctx, i) {
                  final year = years[years.length - 1 - i];
                  final isCurrent = year == currentYear;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(year),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.electricBlue.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: AppColors.electricBlue)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$year',
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.electricBlue
                              : AppColors.textPrimary,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatelessWidget {
  final int year;
  const _MonthPickerDialog({required this.year});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Month ($year)',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  final monthNum = i + 1;
                  final isCurrent = year == now.year && monthNum == now.month;
                  return InkWell(
                    onTap: () =>
                        Navigator.of(ctx).pop(_PickerOutcome(monthNum, advance: true)),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.electricBlue.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: AppColors.electricBlue)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _months[i],
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.electricBlue
                              : AppColors.textPrimary,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pop(const _PickerOutcome(0, advance: false)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPickerDialog extends StatelessWidget {
  final int year;
  final int month;
  final int maxDay;
  final int? currentDay;

  const _DayPickerDialog({
    required this.year,
    required this.month,
    required this.maxDay,
    this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  'Select Day (${year}-${month.toString().padLeft(2, '0')})',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: maxDay,
                itemBuilder: (ctx, i) {
                  final day = i + 1;
                  final isCurrent = day == currentDay;
                  return InkWell(
                    onTap: () =>
                        Navigator.of(ctx).pop(_PickerOutcome(day, advance: true)),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.electricBlue.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: AppColors.electricBlue)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.electricBlue
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pop(_PickerOutcome(currentDay ?? 1, advance: false)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
