import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/providers/search_results_provider.dart';
import 'package:music_collection/features/database/presentation/providers/database_provider.dart';
import 'package:music_collection/features/search/presentation/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  /// Width below which the search row goes compact: the DATABASE heading
  /// and the refresh button leave the search row (refresh moves onto the
  /// Active/Finished toggle line instead). Measured from content: heading
  /// (~110) + search minimum (~180) + filter dropdown (~120) + refresh
  /// (48) + gaps/padding (~90). A single fixed threshold keeps the layout
  /// stable while typing (the dropdown appearing must not flip the row).
  static const double _compactThreshold = 600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<DatabaseProvider>();
      if (!db.isLoaded) {
        db.loadAllRecords();
        db.loadEntities();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, _) {
        if (db.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.electricBlue),
                SizedBox(height: 16),
                Text('Loading records...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (db.loadError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(db.loadError!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    db.loadAllRecords();
                    db.loadEntities();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, cons) {
              final compact = cons.maxWidth < _compactThreshold;
              return Column(
                children: [
                  _buildSearchBar(context, db, compact: compact),
                  Expanded(
                    child:
                        ChangeNotifierProvider<SearchResultsProvider>.value(
                      value: db,
                      child: SearchResultsView(
                        originTab: 'db',
                        onRefresh: compact && !db.isLoading
                            ? () {
                                db.loadAllRecords();
                                db.loadEntities();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, DatabaseProvider db,
      {required bool compact}) {
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          if (!compact) ...[
            const Text(
              'DATABASE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _buildSearchField(db),
          ),
          if (hasQuery) ...[
            const SizedBox(width: 8),
            _buildFilterDropdown(db),
          ],
          if (!compact) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh database',
              onPressed: db.isLoading
                  ? null
                  : () {
                      db.loadAllRecords();
                      db.loadEntities();
                    },
              icon: const Icon(Icons.refresh, color: AppColors.electricBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(DatabaseProvider db) {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Search all fields...',
        prefixIcon:
            const Icon(Icons.search, size: 18, color: AppColors.textHint),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  db.clearSearch();
                },
              ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      onChanged: (v) {
        db.setSearchQuery(v);
        setState(() {});
      },
    );
  }

  Widget _buildFilterDropdown(DatabaseProvider db) {
    final currentField = db.searchFilterField;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: currentField,
        isDense: true,
        dropdownColor: AppColors.background,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All fields'),
          ),
          ...DatabaseProvider.filterFieldLabels.entries.map(
            (e) => DropdownMenuItem<String?>(
              value: e.key,
              child: Text(e.value),
            ),
          ),
        ],
        onChanged: (String? value) {
          db.setSearchFilterField(value);
          setState(() {});
        },
      ),
    );
  }
}
