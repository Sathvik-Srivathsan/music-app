import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';
import 'package:provider/provider.dart';

enum EntityType { artist, genre, descriptor }

enum _DeleteChoice { leave, adopt }

Future<void> showEditEntityModal(
  BuildContext context, {
  required EntityType entityType,
  required int entityId,
  required String currentName,
  required int refCount,
  Set<int> currentParentIds = const {},
  int childrenCount = 0,
  List<Genre> allGenres = const [],
  List<Descriptor> allDescriptors = const [],
  double Function(String, dynamic)? fuzzyMatch,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EditEntityModal(
      entityType: entityType,
      entityId: entityId,
      currentName: currentName,
      refCount: refCount,
      currentParentIds: currentParentIds,
      childrenCount: childrenCount,
      allGenres: allGenres,
      allDescriptors: allDescriptors,
      fuzzyMatch: fuzzyMatch,
    ),
  );
}

class _EditEntityModal extends StatefulWidget {
  final EntityType entityType;
  final int entityId;
  final String currentName;
  final int refCount;
  final Set<int> currentParentIds;
  final int childrenCount;
  final List<Genre> allGenres;
  final List<Descriptor> allDescriptors;
  final double Function(String, dynamic)? fuzzyMatch;

  const _EditEntityModal({
    required this.entityType,
    required this.entityId,
    required this.currentName,
    required this.refCount,
    this.currentParentIds = const {},
    this.childrenCount = 0,
    this.allGenres = const [],
    this.allDescriptors = const [],
    this.fuzzyMatch,
  });

  @override
  State<_EditEntityModal> createState() => _EditEntityModalState();
}

class _EditEntityModalState extends State<_EditEntityModal> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;
  late Set<int> _selectedParentIds;

  bool get _isDirty => _nameCtrl.text.trim() != widget.currentName;
  bool get _canDelete =>
      widget.entityType != EntityType.artist || widget.refCount == 0;
  bool get _hasParentSection =>
      widget.entityType == EntityType.genre ||
      widget.entityType == EntityType.descriptor;

  bool get _isParentDirty =>
      _selectedParentIds != widget.currentParentIds;

  bool get _canSave => (_isDirty || _isParentDirty) && !_saving;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _selectedParentIds = Set<int>.from(widget.currentParentIds);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _entityLabel {
    switch (widget.entityType) {
      case EntityType.artist:
        return 'Artist';
      case EntityType.genre:
        return 'Genre';
      case EntityType.descriptor:
        return 'Descriptor';
    }
  }

  String get _entityLabelLower {
    switch (widget.entityType) {
      case EntityType.artist:
        return 'artist';
      case EntityType.genre:
        return 'genre';
      case EntityType.descriptor:
        return 'descriptor';
    }
  }

  Future<void> _onSave() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final manage = context.read<ManageProvider>();
    String? err;

    if (_isDirty) {
      switch (widget.entityType) {
        case EntityType.artist:
          err = await manage.renameArtist(widget.entityId, newName);
          break;
        case EntityType.genre:
          err = await manage.renameGenre(widget.entityId, newName);
          break;
        case EntityType.descriptor:
          err = await manage.renameDescriptor(widget.entityId, newName);
          break;
      }
    }

    if (err == null && _isParentDirty && _hasParentSection) {
      if (widget.entityType == EntityType.genre) {
        err = await manage.setGenreParents(
            widget.entityId, _selectedParentIds);
      } else {
        err = await manage.setDescriptorParents(
            widget.entityId, _selectedParentIds);
      }
    }

    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  Future<void> _showCannotDeleteDialog() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Cannot delete $_entityLabelLower',
            style: const TextStyle(color: AppColors.error)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${widget.currentName}" is referenced by '
                '${widget.refCount} record(s). '
                'Remove it from those records first.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPlainDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete this $_entityLabelLower?',
            style: const TextStyle(color: AppColors.coralRed)),
        content: Text(
          '"${widget.currentName}" will be permanently removed.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, delete',
                style: TextStyle(color: AppColors.background)),
          ),
        ],
      ),
    );
  }

  /// Shown only when deleting a genre/descriptor that has BOTH children and
  /// parents. Lets the user choose whether A's children are adopted by all of
  /// A's parents, or left exactly as they are. Compact 2-button dialog.
  Future<_DeleteChoice?> _showParentingDeleteDialog() {
    final choiceLabel = widget.entityType == EntityType.genre
        ? 'genres'
        : 'descriptors';
    return showDialog<_DeleteChoice>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete "${widget.currentName}"?',
                    style: const TextStyle(
                      color: AppColors.coralRed,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                Text(
                  'This $choiceLabel has ${widget.childrenCount} child'
                  '${widget.childrenCount == 1 ? '' : 'ren'} and '
                  '${widget.currentParentIds.length} parent'
                  '${widget.currentParentIds.length == 1 ? '' : 's'}.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(_DeleteChoice.leave),
                        child: const Text("Leave A's Children As-is",
                            textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.of(ctx).pop(_DeleteChoice.adopt),
                        child: const Text("A's Parents Adopt all of A's Children",
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('As-is: children keep only their own other parents; '
                    'those with none become root.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Adopt: children gain all of A\'s parents as extra parents.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete() async {
    final hasParentingOption =
        (widget.entityType == EntityType.genre ||
            widget.entityType == EntityType.descriptor) &&
        widget.childrenCount > 0 &&
        widget.currentParentIds.isNotEmpty;

    _DeleteChoice? choice;
    if (hasParentingOption) {
      choice = await _showParentingDeleteDialog();
      if (choice == null || !mounted) return; // cancelled
    } else {
      if (!_canDelete) {
        await _showCannotDeleteDialog();
        return;
      }
      final confirmed = await _showPlainDeleteDialog();
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final manage = context.read<ManageProvider>();
    String? err;

    switch (widget.entityType) {
      case EntityType.artist:
        err = await manage.deleteArtist(widget.entityId);
        break;
      case EntityType.genre:
        err = choice == _DeleteChoice.adopt
            ? await manage.adoptThenDeleteGenre(widget.entityId)
            : await manage.deleteGenre(widget.entityId);
        break;
      case EntityType.descriptor:
        err = choice == _DeleteChoice.adopt
            ? await manage.adoptThenDeleteDescriptor(widget.entityId)
            : await manage.deleteDescriptor(widget.entityId);
        break;
    }

    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Edit $_entityLabel',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 24),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_entityLabel Name',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter name...',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_canSave) _onSave();
                    },
                  ),
                  const SizedBox(height: 12),

                  if (widget.refCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Referenced by ${widget.refCount} record(s). '
                              'Renaming will update all of them.',
                              style: const TextStyle(
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

                  if (_hasParentSection) ...[
                    const Text('Parents',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    if (widget.entityType == EntityType.genre)
                      ChipInputField<Genre>(
                        key: ValueKey(
                            'edit_parent_${widget.entityId}_${_selectedParentIds.length}'),
                        labelText: 'Add parent genre...',
                        allItems: widget.allGenres,
                        initialItems: widget.allGenres
                            .where(
                                (g) => _selectedParentIds.contains(g.genreId))
                            .toList(),
                        itemToString: (g) => g.genreName,
                        similarityFn: (q, g) =>
                            CsvUtils.calculateSimilarity(q, g.genreName),
                        onCreateNew: (_) async => null,
                        onItemsChanged: (items) {
                          setState(() {
                            _selectedParentIds =
                                items.map((g) => g.genreId!).toSet();
                          });
                        },
                        allowCreate: false,
                      )
                    else
                      ChipInputField<Descriptor>(
                        key: ValueKey(
                            'edit_parent_${widget.entityId}_${_selectedParentIds.length}'),
                        labelText: 'Add parent descriptor...',
                        allItems: widget.allDescriptors,
                        initialItems: widget.allDescriptors
                            .where((d) =>
                                _selectedParentIds.contains(d.descriptorId))
                            .toList(),
                        itemToString: (d) => d.descriptorName,
                        similarityFn: (q, d) =>
                            CsvUtils.calculateSimilarity(q, d.descriptorName),
                        onCreateNew: (_) async => null,
                        onItemsChanged: (items) {
                          setState(() {
                            _selectedParentIds =
                                items.map((d) => d.descriptorId!).toSet();
                          });
                        },
                        allowCreate: false,
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (_canDelete)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coralRed,
                        side: const BorderSide(color: AppColors.coralRed),
                      ),
                      icon:
                          const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      onPressed: _saving ? null : _onDelete,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      disabledBackgroundColor:
                          AppColors.grid.withOpacity(0.5),
                    ),
                    onPressed: _canSave ? _onSave : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background))
                        : Text(
                            _canSave ? 'Update' : 'No changes',
                            style: const TextStyle(
                                color: AppColors.background),
                          ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
