import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/utils/toast_utils.dart';
import 'package:music_collection/features/insert/presentation/providers/insert_provider.dart';
import 'package:music_collection/features/insert/presentation/widgets/streaming_availability_widget.dart';
import 'package:music_collection/shared/widgets/chip_input_field.dart';
import 'package:music_collection/shared/widgets/entity_creation_modal.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:music_collection/shared/widgets/partial_date_picker.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/features/search/domain/record_collation.dart';

class InsertScreen extends StatefulWidget {
  const InsertScreen({super.key});

  @override
  State<InsertScreen> createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  final TextEditingController _recordNameController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  bool _spotifyAutoTicked = false;
  int _formResetKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<InsertProvider>().loadEntities();
      if (mounted) {
        final p = context.read<InsertProvider>();
        ToastUtils.showInfo(
            'Loaded: ${p.allArtists.length} artists, ${p.allGenres.length} genres, ${p.allDescriptors.length} descriptors');
      }
    });
  }

  @override
  void dispose() {
    _recordNameController.dispose();
    _releaseDateController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker(InsertProvider provider) async {
    final formatted = await showPartialDatePicker(context);
    if (!mounted || formatted == null) return;
    _applyReleaseDate(provider, formatted);
  }

  void _applyReleaseDate(InsertProvider provider, String formatted) {
    provider.setReleaseDate(formatted);
    _releaseDateController.text = formatted;
  }

  Widget _sectionTitle(
    String title,
    String? status,
    String body, {
    bool mandatory = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (mandatory)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFFF5722),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        InfoTip(status: status, body: body, isMandatory: mandatory),
      ],
    );
  }

  void _showPreview({required InsertProvider provider, bool isSubmit = false}) {
    final anySelected =
        provider.streamingSelected.values.any((v) => v);
    if (!anySelected && !_spotifyAutoTicked) {
      provider.autoTickSpotify();
      _spotifyAutoTicked = true;
    }

    final validationError = validateInsertInput(
      recordName: provider.recordName,
      artistCount: provider.selectedArtists.length,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final preview = provider.buildPreviewData();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSubmit ? 'Confirm Insert' : 'Preview',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: preview.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(isSubmit ? 'Back' : 'Close'),
                    ),
                    if (isSubmit) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final success = await provider.submit();
                          if (success && mounted) {
                            _recordNameController.clear();
                            _releaseDateController.clear();
                            _commentsController.clear();
                            _spotifyAutoTicked = false;
                            setState(() => _formResetKey++);
                          }
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsertProvider>(
      builder: (context, provider, child) {
        if (_recordNameController.text != provider.recordName) {
          _recordNameController.text = provider.recordName;
          _recordNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _recordNameController.text.length),
          );
        }
        if (_releaseDateController.text != (provider.releaseDate ?? '')) {
          _releaseDateController.text = provider.releaseDate ?? '';
        }
        if (_commentsController.text != provider.comments) {
          _commentsController.text = provider.comments;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.electricBlue,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insert New Record',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Record Name
                      _sectionTitle(
                        'Record Name',
                        'Mandatory field',
                        'The release title exactly as you want it stored.',
                        mandatory: true,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _recordNameController,
                        decoration: const InputDecoration(
                          labelText: 'Record Name',
                        ),
                        onChanged: (v) => provider.setRecordName(v),
                      ),
                      const SizedBox(height: 16),

                      // Artist(s)
                      _sectionTitle(
                        'Artist(s)',
                        'Mandatory - at least one artist',
                        'Artists credited on this release, in credit '
                            'order.\n'
                            'Type to search suggestions - Enter / comma / '
                            'the check button commits an exact match.\n'
                            'Grey text = already added.\n'
                            'Unknown names open a create dialog.\n'
                            'Drag the green handle to reorder - X removes '
                            'a chip.\n'
                            'Deleting typed text removes the matching '
                            'chips.',
                        mandatory: true,
                      ),
                      const SizedBox(height: 4),
                      ChipInputField<Artist>(
                        resetKey: ValueKey('artist$_formResetKey'),
                        labelText: 'Search artists...',
                        allItems: provider.allArtists,
                        itemToString: (a) => a.artistName,
                        similarityFn: (q, a) =>
                            provider.fuzzyMatch(q, a.artistName),
                        sortFn: (a, b) =>
                            compareRecordNames(a.artistName, b.artistName),
                        onItemsChanged: (items) =>
                            provider.setSelectedArtists(items),
                        onCreateNew: (name) async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => EntityCreationModal(
                              title: 'Create New Artist',
                              hintText: 'Artist name',
                              initialName: name,
                              onCreate: (createdName) async {
                                await provider.createArtist(createdName);
                              },
                            ),
                          );
                          if (result != null) {
                            return provider.allArtists.firstWhere(
                              (a) => a.artistName == result,
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Genres
                      _sectionTitle(
                        'Genres (drag to reorder)',
                        null,
                        'Genres follow RateYourMusic naming.\n'
                            'Type to search or paste a comma-separated '
                            'list - exact matches commit as chips ignoring '
                            'case/spacing.\n'
                            'Unknown names open a create dialog.\n'
                            'Order sets genre priority: drag chips to '
                            'reorder.',
                      ),
                      const SizedBox(height: 4),
                      ChipInputField<Genre>(
                        resetKey: ValueKey('genre$_formResetKey'),
                        labelText: 'Search genres...',
                        allItems: provider.allGenres,
                        itemToString: (g) => g.genreName,
                        similarityFn: (q, g) =>
                            provider.fuzzyMatch(q, g.genreName),
                        sortFn: (a, b) =>
                            compareRecordNames(a.genreName, b.genreName),
                        onItemsChanged: (items) =>
                            provider.setSelectedGenres(items),
                        onCreateNew: (name) async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => EntityCreationModal(
                              title: 'Create New Genre',
                              hintText: 'Genre name',
                              initialName: name,
                              onCreate: (createdName) async {
                                await provider.createGenre(createdName);
                              },
                            ),
                          );
                          if (result != null) {
                            return provider.allGenres.firstWhere(
                              (g) => g.genreName == result,
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descriptors
                      _sectionTitle(
                        'Descriptors',
                        null,
                        'Short tags describing the sound/mood (e.g. '
                            'rhythmic, male vocals, warm).\n'
                            'Behaves like the artist field.',
                      ),
                      const SizedBox(height: 4),
                      ChipInputField<Descriptor>(
                        resetKey: ValueKey('desc$_formResetKey'),
                        labelText: 'Search descriptors...',
                        allItems: provider.allDescriptors,
                        itemToString: (d) => d.descriptorName,
                        similarityFn: (q, d) =>
                            provider.fuzzyMatch(q, d.descriptorName),
                        sortFn: (a, b) =>
                            compareRecordNames(a.descriptorName, b.descriptorName),
                        onItemsChanged: (items) =>
                            provider.setSelectedDescriptors(items),
                        onCreateNew: (name) async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => EntityCreationModal(
                              title: 'Create New Descriptor',
                              hintText: 'Descriptor name',
                              initialName: name,
                              onCreate: (createdName) async {
                                await provider.createDescriptor(createdName);
                              },
                            ),
                          );
                          if (result != null) {
                            return provider.allDescriptors.firstWhere(
                              (d) => d.descriptorName == result,
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Record Type
                      _sectionTitle(
                        'Record Type',
                        'Mandatory - always set',
                        'Release format used when grouping records in '
                            'your database.\n'
                            'Defaults to Album.',
                        mandatory: true,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: provider.recordType,
                        decoration: const InputDecoration(
                          labelText: 'Record Type',
                        ),
                        items: AppConstants.recordTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) provider.setRecordType(v);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Release Date
                      _sectionTitle(
                        'Release Date',
                        null,
                        'Type YYYY, YYYY-MM or YYYY-MM-DD directly, or '
                            'tap the calendar.\n'
                            'In the calendar each tap advances instantly - '
                            'Done writes everything chosen so far (year '
                            'only, or year+month).',
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _releaseDateController,
                        decoration: InputDecoration(
                          labelText: 'Release Date (YYYY-MM-DD)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: AppColors.textHint, size: 20),
                            onPressed: () => _showDatePicker(provider),
                          ),
                        ),
                        onChanged: (v) =>
                            provider.setReleaseDate(v.isEmpty ? null : v),
                      ),
                      const SizedBox(height: 16),

                      // Streaming
                      StreamingAvailabilityWidget(
                        selectedServices: provider.streamingSelected,
                        urlControllers: provider.streamingUrlControllers,
                        onToggle: (s) => provider.toggleStreaming(s),
                        showDefaultNotice: true,
                      ),
                      const SizedBox(height: 16),

                      // Comments
                      _sectionTitle(
                        'Comments',
                        null,
                        'Free-form notes: pressing details, catalogue '
                        'number, condition, links...',
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _commentsController,
                        decoration: const InputDecoration(
                          labelText: 'Comments',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        onChanged: (v) => provider.setComments(v),
                      ),
                      const SizedBox(height: 16),

                      // Status
                      _sectionTitle(
                        'Status',
                        'Mandatory - always set',
                        'Track listening state.\n'
                            'Active = still in your rotation.\n'
                            'Finished = done with this entry.',
                        mandatory: true,
                      ),
                      const SizedBox(height: 4),
                      RadioGroup<bool>(
                        groupValue: provider.status,
                        onChanged: (v) {
                          if (v != null) provider.setStatus(v);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: const Radio<bool>(
                                  value: false,
                                  activeColor: AppColors.active,
                                ),
                                title: const Text('Active',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14)),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                leading: const Radio<bool>(
                                  value: true,
                                  activeColor: AppColors.finished,
                                ),
                                title: const Text('Finished',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14)),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showPreview(provider: provider, isSubmit: false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.electricBlue),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Preview'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: provider.isSaving
                                  ? null
                                  : () => _showPreview(
                                      provider: provider, isSubmit: true),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: provider.isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Submit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                provider.clearForm();
                                _recordNameController.clear();
                                _releaseDateController.clear();
                                _commentsController.clear();
                                _spotifyAutoTicked = false;
                                setState(() => _formResetKey++);
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: AppColors.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

