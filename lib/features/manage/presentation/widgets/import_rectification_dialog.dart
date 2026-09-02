import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';

class ImportRectificationDialog extends StatefulWidget {
  final String message;
  final String currentValue;
  final List<Genre> allGenres;
  final List<Descriptor> allDescriptors;
  final List<Artist> allArtists;
  final bool isGenre;
  final bool isArtist;
  final double Function(String, dynamic) fuzzyMatch;

  const ImportRectificationDialog({
    super.key,
    required this.message,
    required this.currentValue,
    required this.allGenres,
    required this.allDescriptors,
    required this.allArtists,
    required this.isGenre,
    required this.isArtist,
    required this.fuzzyMatch,
  });

  static Future<ImportRectificationResult?> show(
    BuildContext context, {
    required String message,
    required String currentValue,
    required List<Genre> allGenres,
    required List<Descriptor> allDescriptors,
    required List<Artist> allArtists,
    required bool isGenre,
    required bool isArtist,
    required double Function(String, dynamic) fuzzyMatch,
  }) {
    return showDialog<ImportRectificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImportRectificationDialog(
        message: message,
        currentValue: currentValue,
        allGenres: allGenres,
        allDescriptors: allDescriptors,
        allArtists: allArtists,
        isGenre: isGenre,
        isArtist: isArtist,
        fuzzyMatch: fuzzyMatch,
      ),
    );
  }

  @override
  State<ImportRectificationDialog> createState() =>
      _ImportRectificationDialogState();
}

enum ImportRectificationAction { confirm, skipTuple, cancelImport }

class ImportRectificationResult {
  final ImportRectificationAction action;
  final int? selectedId;

  const ImportRectificationResult(this.action, {this.selectedId});
}

class _ImportRectificationDialogState
    extends State<ImportRectificationDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Genre> get _filteredGenres {
    if (_searchQuery.isEmpty) {
      return widget.allGenres;
    }
    return widget.allGenres
        .where((g) =>
            widget.fuzzyMatch(_searchQuery, g) > 0.3 ||
            g.genreName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => widget.fuzzyMatch(_searchQuery, b)
          .compareTo(widget.fuzzyMatch(_searchQuery, a)));
  }

  List<Descriptor> get _filteredDescriptors {
    if (_searchQuery.isEmpty) {
      return widget.allDescriptors;
    }
    return widget.allDescriptors
        .where((d) =>
            widget.fuzzyMatch(_searchQuery, d) > 0.3 ||
            d.descriptorName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => widget.fuzzyMatch(_searchQuery, b)
          .compareTo(widget.fuzzyMatch(_searchQuery, a)));
  }

  List<Artist> get _filteredArtists {
    if (_searchQuery.isEmpty) {
      return widget.allArtists;
    }
    return widget.allArtists
        .where((a) =>
            widget.fuzzyMatch(_searchQuery, a) > 0.3 ||
            a.artistName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => widget.fuzzyMatch(_searchQuery, b)
          .compareTo(widget.fuzzyMatch(_searchQuery, a)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
              const SizedBox(height: 8),

              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search for replacement...',
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),

              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: widget.isArtist
                    ? _buildArtistList()
                    : widget.isGenre
                        ? _buildGenreList()
                        : _buildDescriptorList(),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                        const ImportRectificationResult(
                            ImportRectificationAction.cancelImport)),
                    child: const Text('Cancel Import',
                        style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                        const ImportRectificationResult(
                            ImportRectificationAction.skipTuple)),
                    child: const Text('Skip Tuple',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      disabledBackgroundColor:
                          AppColors.grid.withOpacity(0.5),
                    ),
                    onPressed: _selectedId != null
                        ? () => Navigator.of(context).pop(
                            ImportRectificationResult(
                                ImportRectificationAction.confirm,
                                selectedId: _selectedId))
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

  Widget _buildGenreList() {
    final items = _filteredGenres;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No genres found.',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final genre = items[index];
        final selected = _selectedId == genre.genreId;
        return InkWell(
          onTap: () => setState(() {
            _selectedId = selected ? null : genre.genreId;
            _searchCtrl.text = selected ? '' : genre.genreName;
            _searchQuery = selected ? '' : genre.genreName;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: selected
                ? AppColors.electricBlue.withAlpha(30)
                : null,
            child: Text(
              genre.genreName,
              style: TextStyle(
                color: selected
                    ? AppColors.electricBlue
                    : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptorList() {
    final items = _filteredDescriptors;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No descriptors found.',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final desc = items[index];
        final selected = _selectedId == desc.descriptorId;
        return InkWell(
          onTap: () => setState(() {
            _selectedId = selected ? null : desc.descriptorId;
            _searchCtrl.text = selected ? '' : desc.descriptorName;
            _searchQuery = selected ? '' : desc.descriptorName;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: selected
                ? AppColors.electricBlue.withAlpha(30)
                : null,
            child: Text(
              desc.descriptorName,
              style: TextStyle(
                color: selected
                    ? AppColors.electricBlue
                    : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistList() {
    final items = _filteredArtists;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No artists found.',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final artist = items[index];
        final selected = _selectedId == artist.artistId;
        return InkWell(
          onTap: () => setState(() {
            _selectedId = selected ? null : artist.artistId;
            _searchCtrl.text = selected ? '' : artist.artistName;
            _searchQuery = selected ? '' : artist.artistName;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: selected
                ? AppColors.electricBlue.withAlpha(30)
                : null,
            child: Text(
              artist.artistName,
              style: TextStyle(
                color: selected
                    ? AppColors.electricBlue
                    : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}
