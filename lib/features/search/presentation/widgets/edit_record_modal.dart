import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/utils/toast_utils.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';
import 'package:music_collection/features/insert/presentation/widgets/streaming_availability_widget.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/record_details.dart';
import 'package:music_collection/shared/models/streaming_service.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';
import 'package:music_collection/shared/widgets/entity_creation_modal.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:music_collection/shared/widgets/partial_date_picker.dart';
import 'package:provider/provider.dart';

/// Edit popup mirroring the INSERT form. Every volunteered field is
/// editable; Date Added stays display-only. Status flips via a single
/// colour-coded toggle button; deletion lives in its own danger
/// section behind a confirmation dialog.
Future<void> showEditRecordModal(BuildContext context, RecordDetails details,
    {String originTab = 'search'}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<InsertProvider>()),
        ChangeNotifierProvider<SearchResultsProvider>.value(
          value: context.read<SearchResultsProvider>(),
        ),
      ],
      child: _EditRecordDialog(details: details, originTab: originTab),
    ),
  );
}

class _EditRecordDialog extends StatefulWidget {
  final RecordDetails details;
  final String originTab;

  const _EditRecordDialog({required this.details, required this.originTab});

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _releaseCtrl;
  late final TextEditingController _commentsCtrl;
  late String? _recordType;
  late bool _statusActive;

  late List<Artist> _artists;
  late List<Genre> _genres;
  late List<Descriptor> _descriptors;
  late Map<String, bool> _selectedServices;
  late Map<String, TextEditingController> _urlCtrls;

  bool _saving = false;
  String? _saveError;

  /// Revert-aware dirtiness: recomputed against the ORIGINAL saved
  /// tuple every build, so undoing a change re-disables Update.
  bool get _isDirty {
    final r = widget.details.record;
    if (_nameCtrl.text.trim() != r.recordName) return true;
    if (_recordType != r.recordType) return true;
    if ((_releaseCtrl.text.trim().isEmpty
            ? null
            : _releaseCtrl.text.trim()) !=
        r.releaseDate) {
      return true;
    }
    if ((_commentsCtrl.text.trim().isEmpty
            ? null
            : _commentsCtrl.text.trim()) !=
        r.comments) {
      return true;
    }
    if (!_statusActive != r.status) return true;

    if (!_seqEq([for (final a in _artists) a.artistId],
        [for (final a in widget.details.artists) a.artistId])) {
      return true;
    }
    if (!_seqEq([for (final g in _genres) g.genreId],
        [for (final g in widget.details.genres) g.genreId])) {
      return true;
    }
    if (!_seqEq([for (final d in _descriptors) d.descriptorId],
        [for (final d in widget.details.descriptors) d.descriptorId])) {
      return true;
    }

    final savedNames = <String>{
      for (final s in widget.details.streaming) s.serviceName,
    };
    final pickedNames = <String>{
      for (final e in _selectedServices.entries)
        if (e.value) e.key,
    };
    if (!_setEq(pickedNames, savedNames)) return true;
    for (final s in widget.details.streaming) {
      final cur = _urlCtrls[s.serviceName]?.text.trim() ?? '';
      if (cur != s.serviceUrl) return true;
    }
    return false;
  }

  static bool _seqEq<T>(Iterable<T?> a, Iterable<T?> b) {
    final la = a.toList();
    final lb = b.toList();
    if (la.length != lb.length) return false;
    for (var i = 0; i < la.length; i++) {
      if (la[i] != lb[i]) return false;
    }
    return true;
  }

  static bool _setEq<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void initState() {
    super.initState();
    final r = widget.details.record;
    _nameCtrl = TextEditingController(text: r.recordName);
    _releaseCtrl = TextEditingController(text: r.releaseDate ?? '');
    _commentsCtrl = TextEditingController(text: r.comments ?? '');
    _recordType = r.recordType;
    _statusActive = !r.status;
    _artists = List.of(widget.details.artists);
    _genres = List.of(widget.details.genres);
    _descriptors = List.of(widget.details.descriptors);
    _selectedServices = {};
    _urlCtrls = {};
    for (final s in widget.details.streaming) {
      _selectedServices[s.serviceName] = true;
      _urlCtrls[s.serviceName] = TextEditingController(text: s.serviceUrl);
    }
    _nameCtrl.addListener(_refresh);
    _releaseCtrl.addListener(_refresh);
    _commentsCtrl.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _releaseCtrl.dispose();
    _commentsCtrl.dispose();
    for (final c in _urlCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  RecordDetails _buildUpdated() {
    return RecordDetails(
      record: widget.details.record.copyWith(
        recordName: _nameCtrl.text.trim(),
        recordType: _recordType,
        releaseDate:
            _releaseCtrl.text.trim().isEmpty ? null : _releaseCtrl.text.trim(),
        comments: _commentsCtrl.text.trim().isEmpty
            ? null
            : _commentsCtrl.text.trim(),
        status: !_statusActive,
      ),
      artists: List.of(_artists),
      genres: List.of(_genres),
      descriptors: List.of(_descriptors),
      streaming: [
        for (final entry in _selectedServices.entries)
          if (entry.value)
            StreamingService(
              serviceName: entry.key,
              serviceUrl: _urlCtrls[entry.key]?.text.trim().isNotEmpty == true
                  ? _urlCtrls[entry.key]!.text.trim()
                  : '',
            ),
      ],
    );
  }

  Future<void> _onUpdate() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final updated = _buildUpdated();
    if (!mounted) return;
    final err =
        await context
            .read<SearchResultsProvider>()
            .saveEdits(updated, originTab: widget.originTab);
    if (!mounted) return;
    if (err == null) {
      ToastUtils.showSuccess(
          'Record "${widget.details.record.recordName}" updated.');
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _saveError = err;
      });
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete this record?',
            style: TextStyle(color: AppColors.coralRed)),
        content: Text(
          '"${widget.details.record.recordName}" and all of its links '
          '(artists, genres, descriptors, streaming) will be removed '
          'permanently.',
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

  Future<void> _onDelete() async {
    final confirmed = await _confirmDelete();
    if (confirmed != true || !mounted) return;
    final err = await context
        .read<SearchResultsProvider>()
        .deleteById(widget.details.record.recordId!,
            originTab: widget.originTab);
    if (!mounted) return;
    if (err == null) {
      ToastUtils.showSuccess(
          'Record "${widget.details.record.recordName}" deleted.');
      Navigator.of(context).pop();
    } else {
      setState(() => _saveError = err);
    }
  }

  Future<void> _pickDate() async {
    final formatted = await showPartialDatePicker(context);
    if (formatted != null) {
      setState(() => _releaseCtrl.text = formatted);
    }
  }

  Widget _sectionLabel(String title, {String? tip}) {
    return Row(children: [
      Text(title,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12)),
      if (tip != null) InfoTip(body: tip),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final insert = context.watch<InsertProvider>();
    // The results provider in scope (SearchProvider on the SEARCH tab,
    // DatabaseProvider on the DATABASE tab) is the reliable suggestion
    // and persistence source here — it always has its own entities loaded.
    final search = context.watch<SearchResultsProvider>();

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderLight)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: 920,
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Edit Record',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        size: 20, color: AppColors.textSecondary),
                    tooltip: 'Copy artist(s) + record name',
                    onPressed: () {
                      final artists = widget.details.artistsCsv;
                      final name =
                          widget.details.record.recordName;
                      final text = artists.isEmpty
                          ? name
                          : '$artists - $name';
                      Clipboard.setData(ClipboardData(text: text));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Record Name *'),
                              TextField(controller: _nameCtrl),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Status',
                                  tip: 'Green = Active, gold = Finished. '
                                      'Click to flip, then press Update.'),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _statusActive
                                        ? AppColors.active
                                            .withOpacity(0.22)
                                        : AppColors.amberGold
                                            .withOpacity(0.22),
                                    side: BorderSide(
                                      color: _statusActive
                                          ? AppColors.active
                                          : AppColors.amberGold,
                                    ),
                                  ),
                                  icon: Icon(
                                    _statusActive
                                        ? Icons.play_circle_outline
                                        : Icons.stop_circle_outlined,
                                    color: _statusActive
                                        ? AppColors.active
                                        : AppColors.amberGold,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _statusActive ? 'ACTIVE' : 'FINISHED',
                                    style: TextStyle(
                                      color: _statusActive
                                          ? AppColors.active
                                          : AppColors.amberGold,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _statusActive = !_statusActive;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Release Date'),
                              TextField(
                                controller: _releaseCtrl,
                                readOnly: false,
                                decoration: InputDecoration(
                                  hintText: 'YYYY / YYYY-MM / YYYY-MM-DD',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    onPressed: _pickDate,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Record Type'),
                              DropdownButtonFormField<String>(
                                initialValue: _recordType,
                                hint: const Text('-',
                                    style: TextStyle(
                                        color: AppColors.textHint)),
                                dropdownColor: AppColors.card,
                                items: AppConstants.recordTypes
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textPrimary))))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _recordType = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Date Added',
                                  tip: 'App-generated timestamp - not '
                                      'editable.'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground
                                      .withOpacity(0.4),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.inputBorder),
                                ),
                                child: Text(
                                  widget.details.record.dateAdded ?? '-',
                                  style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Artists *',
                        tip: 'Drag to reorder priority. Unknown names '
                            'open a create dialog.'),
                    ChipInputField<Artist>(
                      labelText: 'Search artists...',
                      allItems: search.allArtists,
                      initialItems: widget.details.artists,
                      itemToString: (a) => a.artistName,
                      similarityFn: (q, a) =>
                          search.fuzzyMatch(q, a.artistName),
                      onItemsChanged: (items) {
                        setState(() => _artists = items);
                      },
                      onCreateNew: (name) async =>
                          _createEntity<Artist>(
                        title: 'Create New Artist',
                        hint: 'Artist name',
                        initial: name,
                        run: () =>
                            insert.createArtist(name, originTab: widget.originTab),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _sectionLabel('Genres',
                        tip: 'Order sets genre priority.'),
                    ChipInputField<Genre>(
                      labelText: 'Search genres...',
                      allItems: search.allGenres,
                      initialItems: widget.details.genres,
                      itemToString: (g) => g.genreName,
                      similarityFn: (q, g) =>
                          search.fuzzyMatch(q, g.genreName),
                      onItemsChanged: (items) {
                        setState(() => _genres = items);
                      },
                      onCreateNew: (name) async =>
                          _createEntity<Genre>(
                        title: 'Create New Genre',
                        hint: 'Genre name',
                        initial: name,
                        run: () =>
                            insert.createGenre(name, originTab: widget.originTab),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _sectionLabel('Descriptors'),
                    ChipInputField<Descriptor>(
                      labelText: 'Search descriptors...',
                      allItems: search.allDescriptors,
                      initialItems: widget.details.descriptors,
                      itemToString: (d) => d.descriptorName,
                      similarityFn: (q, d) =>
                          search.fuzzyMatch(q, d.descriptorName),
                      onItemsChanged: (items) {
                        setState(() => _descriptors = items);
                      },
                      onCreateNew: (name) async =>
                          _createEntity<Descriptor>(
                        title: 'Create New Descriptor',
                        hint: 'Descriptor name',
                        initial: name,
                        run: () => insert
                            .createDescriptor(name, originTab: widget.originTab),
                      ),
                    ),
                    const SizedBox(height: 16),

                    StreamingAvailabilityWidget(
                      selectedServices: _selectedServices,
                      urlControllers: _urlCtrls,
                      onToggle: (service) {
                        setState(() {
                          _selectedServices[service] =
                              !(_selectedServices[service] ?? false);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    _sectionLabel('Comments'),
                    TextField(
                      controller: _commentsCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                    ),

                    const Divider(color: AppColors.border, height: 40),
                    Row(
                      children: [
                        // Deletion is only offered for records whose
                        // SAVED status is Finished - flipping the
                        // toggle in this session does not reveal it.
                        if (widget.details.record.status)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.coralRed,
                              side: const BorderSide(
                                  color: AppColors.coralRed),
                            ),
                            icon: const Icon(Icons.delete_outline,
                                size: 18),
                            label: const Text('Delete Record'),
                            onPressed: _onDelete,
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            disabledBackgroundColor:
                                AppColors.grid.withOpacity(0.5),
                          ),
                          onPressed:
                              (_isDirty && !_saving && _nameCtrl.text.trim()
                                      .isNotEmpty)
                                  ? _onUpdate
                                  : null,
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.background))
                              : Text(
                                  _isDirty ? 'Update' : 'No changes',
                                  style: const TextStyle(
                                      color: AppColors.background),
                                ),
                        ),
                      ],
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 10),
                      Text(_saveError!,
                          style: const TextStyle(color: AppColors.error)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates the entity through InsertProvider (so it persists and
  /// joins every dropdown app-wide), then resolves it by name.
  Future<T?> _createEntity<T>({
    required String title,
    required String hint,
    required String initial,
    required Future<Object?> Function() run,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => EntityCreationModal(
        title: title,
        hintText: hint,
        initialName: initial,
        onCreate: (_) => run(),
      ),
    );
    if (result == null || !mounted) return null;
    final insert = context.read<InsertProvider>();
    Object? created;
    if (T == Artist) {
      created = insert.allArtists
          .where((a) => a.artistName == result)
          .first;
    } else if (T == Genre) {
      created =
          insert.allGenres.where((g) => g.genreName == result).first;
    } else {
      created = insert.allDescriptors
          .where((d) => d.descriptorName == result)
          .first;
    }
    // Refresh the results provider's entity caches so the new entity is
    // immediately suggestible in the remaining chip fields.
    context.read<SearchResultsProvider>().loadEntities();
    return created as T?;
  }
}
