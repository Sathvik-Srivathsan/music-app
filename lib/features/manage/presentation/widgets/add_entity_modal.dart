import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/widgets/edit_entity_modal.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';

enum TextFormatting {
  titleCase,
  removeSpaces,
  addSpaces,
  removeHyphens,
  addHyphens,
}

class AddEntityResult {
  final String name;
  final Set<int> parentIds;

  const AddEntityResult(this.name, {this.parentIds = const {}});
}

Future<AddEntityResult?> showAddEntityModal(
  BuildContext context, {
  String? title,
  required EntityType entityType,
  required List<Genre> allGenres,
  required List<Descriptor> allDescriptors,
  required double Function(String, dynamic) fuzzyMatch,
}) {
  return showDialog<AddEntityResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AddEntityModal(
      title: title ?? 'Add Entity',
      entityType: entityType,
      allGenres: allGenres,
      allDescriptors: allDescriptors,
      fuzzyMatch: fuzzyMatch,
    ),
  );
}

class _AddEntityModal extends StatefulWidget {
  final String title;
  final EntityType entityType;
  final List<Genre> allGenres;
  final List<Descriptor> allDescriptors;
  final double Function(String, dynamic) fuzzyMatch;

  const _AddEntityModal({
    required this.title,
    required this.entityType,
    required this.allGenres,
    required this.allDescriptors,
    required this.fuzzyMatch,
  });

  @override
  State<_AddEntityModal> createState() => _AddEntityModalState();
}

class _AddEntityModalState extends State<_AddEntityModal> {
  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _previewCtrl = TextEditingController();
  Set<TextFormatting> _selectedFormats = {};
  bool _saving = false;
  Set<int> _selectedParentIds = {};

  bool get _hasParentColumn =>
      widget.entityType == EntityType.genre ||
      widget.entityType == EntityType.descriptor;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _previewCtrl.dispose();
    super.dispose();
  }

  void _applyFormatting() {
    var text = _inputCtrl.text;
    for (final fmt in _selectedFormats) {
      switch (fmt) {
        case TextFormatting.titleCase:
          text = text
              .split(' ')
              .map((w) => w.isEmpty
                  ? w
                  : w[0].toUpperCase() + w.substring(1).toLowerCase())
              .join(' ');
          break;
        case TextFormatting.removeSpaces:
          text = text.replaceAll(' ', '');
          break;
        case TextFormatting.addSpaces:
          text = text.replaceAll('-', ' ');
          break;
        case TextFormatting.removeHyphens:
          text = text.replaceAll('-', '');
          break;
        case TextFormatting.addHyphens:
          text = text.replaceAll(' ', '-');
          break;
      }
    }
    _previewCtrl.text = text;
  }

  void _onClear() {
    setState(() {
      _inputCtrl.clear();
      _previewCtrl.clear();
      _selectedFormats.clear();
      _selectedParentIds.clear();
    });
  }

  bool get _hasFormatting => _selectedFormats.isNotEmpty;

  Future<void> _onOK() async {
    final name = _previewCtrl.text.trim();
    if (name.isEmpty) return;

    if (!_hasFormatting) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('No formatting applied',
              style: TextStyle(color: AppColors.warning)),
          content: const Text(
            'You haven\'t applied any text formatting. '
            'The name will be saved exactly as typed.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Go back',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save as-is',
                  style: TextStyle(color: AppColors.background)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    if (mounted) {
      Navigator.of(context).pop(AddEntityResult(
        name,
        parentIds: _selectedParentIds,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              const Text('Text Formatting',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: TextFormatting.values.map((fmt) {
                  final label = _formatLabel(fmt);
                  final selected = _selectedFormats.contains(fmt);
                  return FilterChip(
                    label: Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.background
                                : AppColors.textPrimary)),
                    selected: selected,
                    selectedColor: AppColors.electricBlue,
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.background,
                    side: BorderSide(
                        color: selected
                            ? AppColors.electricBlue
                            : AppColors.border),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFormats.add(fmt);
                        } else {
                          _selectedFormats.remove(fmt);
                        }
                        _applyFormatting();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _inputCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter name...',
                ),
                onChanged: (_) => _applyFormatting(),
                onSubmitted: (_) => _onOK(),
              ),
              const SizedBox(height: 12),

              if (_hasFormatting) ...[
                const Text('Preview',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: _previewCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],

              if (!_hasFormatting && _inputCtrl.text.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No text formatting has been applied.',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_hasParentColumn) ...[
                const SizedBox(height: 4),
                const Text('Parent',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                if (widget.entityType == EntityType.genre)
                  ChipInputField<Genre>(
                    labelText: 'Search genres...',
                    allItems: widget.allGenres,
                    itemToString: (g) => g.genreName,
                    similarityFn: (q, g) =>
                        CsvUtils.calculateSimilarity(q, g.genreName),
                    onCreateNew: (_) async => null,
                    onItemsChanged: (items) {
                      _selectedParentIds = items
                          .map((g) => g.genreId!)
                          .toSet();
                    },
                    allowCreate: false,
                  )
                else
                  ChipInputField<Descriptor>(
                    labelText: 'Search descriptors...',
                    allItems: widget.allDescriptors,
                    itemToString: (d) => d.descriptorName,
                    similarityFn: (q, d) =>
                        CsvUtils.calculateSimilarity(q, d.descriptorName),
                    onCreateNew: (_) async => null,
                    onItemsChanged: (items) {
                      _selectedParentIds = items
                          .map((d) => d.descriptorId!)
                          .toSet();
                    },
                    allowCreate: false,
                  ),
                const SizedBox(height: 4),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _onClear,
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      disabledBackgroundColor:
                          AppColors.grid.withOpacity(0.5),
                    ),
                    onPressed: (_previewCtrl.text.trim().isNotEmpty &&
                            !_saving)
                        ? _onOK
                        : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background))
                        : const Text('OK',
                            style:
                                TextStyle(color: AppColors.background)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLabel(TextFormatting fmt) {
    switch (fmt) {
      case TextFormatting.titleCase:
        return 'Title Case';
      case TextFormatting.removeSpaces:
        return 'Remove Spaces';
      case TextFormatting.addSpaces:
        return 'Add Spaces';
      case TextFormatting.removeHyphens:
        return 'Remove Hyphens';
      case TextFormatting.addHyphens:
        return 'Add Hyphens';
    }
  }
}
