import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/search/domain/date_operator_logic.dart';
import 'package:music_collection/features/search/domain/record_collation.dart';
import 'package:music_collection/features/search/domain/search_query.dart';
import 'package:music_collection/features/search/presentation/providers/search_provider.dart';
import 'package:music_collection/features/search/presentation/widgets/search_results_view.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:music_collection/shared/widgets/partial_date_picker.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _releaseCtrl1 = TextEditingController();
  final TextEditingController _releaseCtrl2 = TextEditingController();
  final TextEditingController _addedCtrl1 = TextEditingController();
  final TextEditingController _addedCtrl2 = TextEditingController();

  List<Artist> _artists = [];
  List<Genre> _genres = [];
  List<Descriptor> _descriptors = [];
  final Set<String> _types = {};
  DateOperator _releaseOp = DateOperator.exactDate;
  DateOperator _addedOp = DateOperator.exactDate;
  final Set<String> _services = {};
  bool _genresAll = false;
  bool _descriptorsAll = false;
  bool _streamingAll = false;
  String? _formError;
  int _chipResetKey = 0;

  @override
  void initState() {
    super.initState();
    _commentsController.addListener(_onCommentsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadEntities();
    });
  }

  void _onCommentsChanged() => setState(() {});

  @override
  void dispose() {
    _commentsController.removeListener(_onCommentsChanged);
    _nameController.dispose();
    _commentsController.dispose();
    _releaseCtrl1.dispose();
    _releaseCtrl2.dispose();
    _addedCtrl1.dispose();
    _addedCtrl2.dispose();
    super.dispose();
  }

  void _syncIntoQuery(SearchProvider p) {
    final q = p.query;
    q.nameText = _nameController.text;
    q.commentsText = _commentsController.text;
    q.artistIds
      ..clear()
      ..addAll(_artists.map((a) => a.artistId!));
    q.genreIds
      ..clear()
      ..addAll(_genres.map((g) => g.genreId!));
    q.genresMode =
        _genresAll ? StreamingFilterMode.all : StreamingFilterMode.any;
    q.descriptorIds
      ..clear()
      ..addAll(_descriptors.map((d) => d.descriptorId!));
    q.descriptorsMode =
        _descriptorsAll ? StreamingFilterMode.all : StreamingFilterMode.any;
    q.recordTypes
      ..clear()
      ..addAll(_types);
    q.releaseOperator =
        _releaseCtrl1.text.trim().isEmpty ? null : _releaseOp;
    q.releaseValue1 = _releaseCtrl1.text;
    q.releaseValue2 = _releaseCtrl2.text;
    q.addedOperator = _addedCtrl1.text.trim().isEmpty ? null : _addedOp;
    q.addedValue1 = _addedCtrl1.text;
    q.addedValue2 = _addedCtrl2.text;
    q.streamingServices
      ..clear()
      ..addAll(_services);
    q.streamingMode =
        _streamingAll ? StreamingFilterMode.all : StreamingFilterMode.any;
  }

  bool _validateDates() {
    for (final pair in [
      (_releaseOp, [_releaseCtrl1, _releaseCtrl2]),
      (_addedOp, [_addedCtrl1, _addedCtrl2]),
    ]) {
      final op = pair.$1;
      final v1 = pair.$2[0].text.trim();
      if (v1.isEmpty) continue;
      if (parseFlexibleDate(v1) == null) return false;
      if (op.needsSecondValue) {
        final v2 = pair.$2[1].text.trim();
        if (parseFlexibleDate(v2) == null) return false;
      }
    }
    return true;
  }

  /// Both buttons land here. [canRun] decides whether the dialog
  /// carries the Confirm action (Submit) or only Close (Preview).
  Future<void> _openPreview(SearchProvider p, {required bool canRun}) async {
    setState(() => _formError = null);
    _syncIntoQuery(p);

    if (!_validateDates()) {
      setState(() {
        _formError = 'Unrecognised date. Accepted: YYYY, MM-YYYY, '
            'YYYY-MM, DD-MM-YYYY, YYYY-MM-DD (- or /).';
      });
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Consumer<SearchProvider>(
        builder: (context, provider, _) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            canRun ? 'Submit — Search Parameters' : 'Preview',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line
                    in SearchQueryEngine.previewLines(
                      provider.query,
                      artistNames: {
                        for (final a in provider.allArtists)
                          a.artistId!: a.artistName,
                      },
                      genreNames: {
                        for (final g in provider.allGenres)
                          g.genreId!: g.genreName,
                      },
                      descriptorNames: {
                        for (final d in provider.allDescriptors)
                          d.descriptorId!: d.descriptorName,
                      },
                    ))
                    ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${line.key}: ',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text: line.value,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (canRun) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Confirm runs this against the whole database.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(canRun ? 'Back' : 'Close',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            if (canRun)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue),
                icon: const Icon(Icons.search,
                    size: 18, color: AppColors.background),
                onPressed: () => Navigator.of(ctx).pop(true),
                label: const Text('Confirm Search',
                    style: TextStyle(color: AppColors.background)),
              ),
          ],
        ),
      ),
    );

    if (confirmed == true && canRun && mounted) {
      await context.read<SearchProvider>().executeSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        switch (provider.phase) {
          case SearchPhase.form:
            return _buildForm(context, provider);
          case SearchPhase.loading:
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.electricBlue),
                  SizedBox(height: 16),
                  Text('Searching...',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          case SearchPhase.results:
            return ChangeNotifierProvider<SearchResultsProvider>.value(
              value: provider,
              child: SearchResultsView(
                onBackToSearch: () =>
                    context.read<SearchProvider>().backToForm(),
              ),
            );
        }
      },
    );
  }

  /// Selectable, copyable diagnostics. Red = fatal (no rows), amber =
  /// partial (rows rendered but a relation failed).
  Widget _errorBanner(BuildContext context, SearchProvider provider) {
    final fatal = provider.loadErrorFatal;
    final color = fatal ? AppColors.error : AppColors.amberGold;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              fatal
                  ? Icons.error_outline
                  : Icons.warning_amber_outlined,
              color: color,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              provider.loadError!,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Copy error to clipboard',
            icon: Icon(Icons.copy, size: 16, color: color),
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: provider.loadError!));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.card,
                  content: Text('Error copied',
                      style:
                          TextStyle(color: AppColors.textPrimary)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, SearchProvider provider) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEARCH',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Fill any combination - all chosen parameters must '
                    'match (AND); switches pick ANY/ALL within a group.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  if (provider.loadError != null)
                    _errorBanner(context, provider),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Record Name'),
                            const InfoTip(
                                body: 'Substring or fuzzy match '
                                    '(fuzzy threshold > 0.3).\n'
                                    'Leave everything blank to browse '
                                    'the entire database.'),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. Kind of Blue'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _sectionLabel('Record Type'),
                              InfoTip(
                                  body: 'Tap types to filter (ANY of '
                                      'them).\nNo chips selected = all '
                                      'types.'),
                            ]),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: -4,
                              children: AppConstants.recordTypes
                                  .map((t) => FilterChip(
                                        label: Text(t,
                                            style:
                                                const TextStyle(
                                                    fontSize: 12)),
                                        selected: _types.contains(t),
                                        selectedColor: AppColors
                                            .electricBlue
                                            .withOpacity(0.35),
                                        checkmarkColor:
                                            AppColors.textPrimary,
                                        labelStyle: TextStyle(
                                          color: _types.contains(t)
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                        onSelected: (sel) => setState(
                                            () => sel
                                                ? _types.add(t)
                                                : _types.remove(t)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildArtistField(provider)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildGenreField(provider)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDescriptorField(provider)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildStreamingSection()),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDateSection(
                          title: 'Release Date',
                          tip: 'Leave blank to ignore.\nOperators compare '
                              "the record's release window against your "
                              'query.\nAccepted formats: YYYY, MM-YYYY, '
                              'YYYY-MM, DD-MM-YYYY, YYYY-MM-DD '
                              '(- or / separators).',
                          operator: _releaseOp,
                          onOperatorChanged: (v) =>
                              setState(() => _releaseOp = v),
                          ctrl1: _releaseCtrl1,
                          ctrl2: _releaseCtrl2,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildDateSection(
                          title: 'Date Added',
                          tip: 'When you inserted the record into the app.\n'
                              'Leave blank to ignore.\nAccepted formats: '
                              'YYYY, MM-YYYY, YYYY-MM, DD-MM-YYYY, '
                              'YYYY-MM-DD (- or / separators).',
                          operator: _addedOp,
                          onOperatorChanged: (v) =>
                              setState(() => _addedOp = v),
                          ctrl1: _addedCtrl1,
                          ctrl2: _addedCtrl2,
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 10),

                   _buildCommentsSection(),
                   const SizedBox(height: 8),

                   if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _formError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vividOrange,
                          foregroundColor: AppColors.background,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: _resetForm,
                        child: const Text('Clear',
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.electricBlue,
                          side: const BorderSide(
                              color: AppColors.electricBlue),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 36),
                        ),
                        icon: const Icon(Icons.visibility_outlined,
                            size: 16),
                        label: const Text('Preview'),
                        onPressed: () =>
                            _openPreview(provider, canRun: false),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                        ),
                        icon: const Icon(Icons.search,
                            color: AppColors.background, size: 18),
                        label: const Text('Submit Search',
                            style: TextStyle(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold)),
                        onPressed: () =>
                            _openPreview(provider, canRun: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _chipResetKey++;
      _nameController.clear();
      _commentsController.clear();
      _releaseCtrl1.clear();
      _releaseCtrl2.clear();
      _addedCtrl1.clear();
      _addedCtrl2.clear();
      _artists = [];
      _genres = [];
      _descriptors = [];
      _types.clear();
      _releaseOp = DateOperator.exactDate;
      _addedOp = DateOperator.exactDate;
      _services.clear();
      _genresAll = false;
      _descriptorsAll = false;
      _streamingAll = false;
      _formError = null;
    });
  }

  /// Bigger section titles (SEARCH form has no mandatory fields).
  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Title row carrying an OR/AND slider switch right next to it.
  Widget _modeTitle(String title, String tip, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        _sectionLabel(title),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.amberGold,
            activeTrackColor: AppColors.amberGold.withOpacity(0.35),
            inactiveThumbColor: AppColors.electricBlue,
            inactiveTrackColor: AppColors.electricBlue.withOpacity(0.25),
          ),
        ),
        Text(
          value ? 'ALL' : 'ANY',
          style: TextStyle(
            color: value ? AppColors.amberGold : AppColors.electricBlue,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        InfoTip(body: tip),
      ],
    );
  }

  Widget _buildArtistField(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel('Artists'),
          InfoTip(body: 'Multiple artists match records having ANY of them.'),
        ]),
        ChipInputField<Artist>(
          key: ValueKey('artist_$_chipResetKey'),
          resetKey: ValueKey(_chipResetKey),
          labelText: 'Filter by artists...',
          allItems: provider.allArtists,
          initialItems: _artists,
          itemToString: (a) => a.artistName,
          similarityFn: (q, a) => provider.fuzzyMatch(q, a.artistName),
          allowCreate: false,
          sortFn: (a, b) => compareRecordNames(a.artistName, b.artistName),
          onCreateNew: (_) async => null,
          onItemsChanged: (items) => setState(() => _artists = items),
        ),
      ],
    );
  }

  Widget _buildGenreField(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modeTitle(
          'Genres',
          'Switch left = ANY of the chosen genres.\n'
              'Switch right = ALL of the chosen genres.',
          _genresAll,
          (v) => setState(() => _genresAll = v),
        ),
        ChipInputField<Genre>(
          key: ValueKey('genre_$_chipResetKey'),
          resetKey: ValueKey(_chipResetKey),
          labelText: 'Filter by genres...',
          allItems: provider.allGenres,
          initialItems: _genres,
          itemToString: (g) => g.genreName,
          similarityFn: (q, g) => provider.fuzzyMatch(q, g.genreName),
          allowCreate: false,
          sortFn: (a, b) => compareRecordNames(a.genreName, b.genreName),
          usedIds: provider.usedGenreIds,
          getId: (g) => g.genreId!,
          onCreateNew: (_) async => null,
          onItemsChanged: (items) => setState(() => _genres = items),
        ),
      ],
    );
  }

  Widget _buildDescriptorField(SearchProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modeTitle(
          'Descriptors',
          'Switch left = ANY of the chosen descriptors.\n'
              'Switch right = ALL of the chosen descriptors.',
          _descriptorsAll,
          (v) => setState(() => _descriptorsAll = v),
        ),
        ChipInputField<Descriptor>(
          key: ValueKey('descriptor_$_chipResetKey'),
          resetKey: ValueKey(_chipResetKey),
          labelText: 'Filter by descriptors...',
          allItems: provider.allDescriptors,
          initialItems: _descriptors,
          itemToString: (d) => d.descriptorName,
          similarityFn: (q, d) => provider.fuzzyMatch(q, d.descriptorName),
          allowCreate: false,
          sortFn: (a, b) =>
              compareRecordNames(a.descriptorName, b.descriptorName),
          usedIds: provider.usedDescriptorIds,
          getId: (d) => d.descriptorId!,
          onCreateNew: (_) async => null,
          onItemsChanged: (items) => setState(() => _descriptors = items),
        ),
      ],
    );
  }

  Widget _buildStreamingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _modeTitle(
          'Streaming Availability',
          'Tick services the record must be on.\n'
              'Switch left = ANY ticked service present.\n'
              'Switch right = EVERY ticked service present.',
          _streamingAll,
          (v) => setState(() => _streamingAll = v),
        ),
        Wrap(
          spacing: 4,
          runSpacing: -6,
          children: AppConstants.streamingServices
              .map((s) => FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: _services.contains(s),
                    selectedColor:
                        AppColors.electricBlue.withOpacity(0.35),
                    checkmarkColor: AppColors.textPrimary,
                    labelStyle: TextStyle(
                      color: _services.contains(s)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    onSelected: (sel) => setState(() =>
                        sel ? _services.add(s) : _services.remove(s)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel('Comments'),
          InfoTip(
              body: 'Fuzzy match only (threshold > 0.3) against the '
                  'comments field - no substring shortcut.\n'
                  'The X button clears only this filter.'),
        ]),
        TextField(
          controller: _commentsController,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. gatefold sleeve, slight ring wear...',
            isDense: true,
            suffixIcon: _commentsController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () =>
                        setState(() => _commentsController.clear()),
                  ),
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDateSection({
    required String title,
    required String tip,
    required DateOperator operator,
    required ValueChanged<DateOperator> onOperatorChanged,
    required TextEditingController ctrl1,
    required TextEditingController ctrl2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel(title),
          InfoTip(body: tip),
        ]),
        DropdownButtonFormField<DateOperator>(
          initialValue: operator,
          dropdownColor: AppColors.card,
          isDense: true,
          items: DateOperator.values
              .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o.label,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13))))
              .toList(),
          onChanged: (v) => onOperatorChanged(v ?? DateOperator.exactDate),
        ),
        const SizedBox(height: 8),
        _dateValueField(ctrl1, operator),
        if (operator.needsSecondValue) ...[
          const SizedBox(height: 8),
          _dateValueField(ctrl2, operator, hint: 'to...'),
        ],
      ],
    );
  }

  Widget _dateValueField(TextEditingController ctrl, DateOperator op,
      {String? hint}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint ?? 'e.g. 2026 · 07-2026 · 05-07-2026',
        suffixIcon: IconButton(
          tooltip: 'Pick partial date',
          icon: const Icon(Icons.calendar_today,
              size: 18, color: AppColors.textSecondary),
          onPressed: () async {
            final formatted = await showPartialDatePicker(context);
            if (formatted != null) ctrl.text = formatted;
          },
        ),
      ),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    );
  }
}
