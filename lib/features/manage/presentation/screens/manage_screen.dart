import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/core/utils/csv_utils.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_import_export_screen.dart';
import 'package:music_collection/features/manage/presentation/screens/manage_tree_screen.dart';
import 'package:music_collection/features/manage/presentation/widgets/add_entity_modal.dart';
import 'package:music_collection/features/manage/presentation/widgets/edit_entity_modal.dart';
import 'package:music_collection/features/manage/presentation/widgets/entity_table.dart';
import 'package:music_collection/shared/models/artist.dart';
import 'package:music_collection/shared/models/genre.dart';
import 'package:music_collection/shared/models/descriptor.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:provider/provider.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManageProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _addTitle {
    final tab = context.read<ManageProvider>().subTab;
    switch (tab) {
      case ManageSubTab.artists:
        return 'Add Artist';
      case ManageSubTab.genres:
        return 'Add Genre';
      case ManageSubTab.descriptors:
        return 'Add Descriptor';
      case ManageSubTab.importExport:
        return '';
    }
  }

  EntityType _entityTypeFromTab(ManageSubTab tab) {
    switch (tab) {
      case ManageSubTab.artists:
        return EntityType.artist;
      case ManageSubTab.genres:
        return EntityType.genre;
      case ManageSubTab.descriptors:
        return EntityType.descriptor;
      case ManageSubTab.importExport:
        return EntityType.artist;
    }
  }

  void _onAdd() async {
    final manage = context.read<ManageProvider>();
    final result = await showAddEntityModal(
      context,
      title: _addTitle,
      entityType: _entityTypeFromTab(manage.subTab),
      allGenres: manage.rawGenres.map((e) => e.entity).toList(),
      allDescriptors: manage.rawDescriptors.map((e) => e.entity).toList(),
      fuzzyMatch: (q, e) {
        if (e is Genre) return CsvUtils.calculateSimilarity(q, e.genreName);
        if (e is Descriptor) {
          return CsvUtils.calculateSimilarity(q, e.descriptorName);
        }
        return 0.0;
      },
    );
    if (result == null || !mounted) return;

    String? err;
    switch (manage.subTab) {
      case ManageSubTab.artists:
        err = await manage.createArtist(result.name);
        break;
      case ManageSubTab.genres:
        err = await manage.createGenre(result.name,
            parentIds: result.parentIds);
        break;
      case ManageSubTab.descriptors:
        err = await manage.createDescriptor(result.name,
            parentIds: result.parentIds);
        break;
      case ManageSubTab.importExport:
        break;
    }
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  void _onRowTapArtist(Artist artist, int refCount) {
    showEditEntityModal(
      context,
      entityType: EntityType.artist,
      entityId: artist.artistId!,
      currentName: artist.artistName,
      refCount: refCount,
    );
  }

  void _onRowTapGenre(Genre genre, int refCount, int childrenCount) async {
    final manage = context.read<ManageProvider>();
    final parentIds = await manage.fetchGenreParentIds(genre.genreId!);
    if (!mounted) return;
    showEditEntityModal(
      context,
      entityType: EntityType.genre,
      entityId: genre.genreId!,
      currentName: genre.genreName,
      refCount: refCount,
      currentParentIds: parentIds,
      childrenCount: childrenCount,
      allGenres: manage.rawGenres.map((e) => e.entity).toList(),
      allDescriptors: manage.rawDescriptors.map((e) => e.entity).toList(),
      fuzzyMatch: (q, e) {
        if (e is Genre) return CsvUtils.calculateSimilarity(q, e.genreName);
        if (e is Descriptor) {
          return CsvUtils.calculateSimilarity(q, e.descriptorName);
        }
        return 0.0;
      },
    );
  }

  void _onRowTapDescriptor(
      Descriptor descriptor, int refCount, int childrenCount) async {
    final manage = context.read<ManageProvider>();
    final parentIds =
        await manage.fetchDescriptorParentIds(descriptor.descriptorId!);
    if (!mounted) return;
    showEditEntityModal(
      context,
      entityType: EntityType.descriptor,
      entityId: descriptor.descriptorId!,
      currentName: descriptor.descriptorName,
      refCount: refCount,
      currentParentIds: parentIds,
      childrenCount: childrenCount,
      allGenres: manage.rawGenres.map((e) => e.entity).toList(),
      allDescriptors: manage.rawDescriptors.map((e) => e.entity).toList(),
      fuzzyMatch: (q, e) {
        if (e is Genre) return CsvUtils.calculateSimilarity(q, e.genreName);
        if (e is Descriptor) {
          return CsvUtils.calculateSimilarity(q, e.descriptorName);
        }
        return 0.0;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManageProvider>(
      builder: (context, manage, _) {
        if (manage.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.electricBlue),
                SizedBox(height: 16),
                Text('Loading entities...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (manage.loadError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(manage.loadError!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => manage.loadAll(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSubTabBar(manage),
            if (manage.subTab != ManageSubTab.importExport) ...[
              if (manage.view == ManageView.table) ...[
                _buildTreeButton(manage),
                _buildToolbar(manage),
              ],
              Expanded(
                child: manage.view == ManageView.table
                    ? _buildTable(manage)
                    : _buildTree(manage),
              ),
            ] else ...[
              const Expanded(child: ManageImportExportScreen()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubTabBar(ManageProvider manage) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Center(
        child: SizedBox(
          width: 680,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<ManageSubTab>(
                  segments: const [
                    ButtonSegment(
                        value: ManageSubTab.artists,
                        label: Text('Artists', style: labelStyle)),
                    ButtonSegment(
                        value: ManageSubTab.genres,
                        label: Text('Genres', style: labelStyle)),
                    ButtonSegment(
                        value: ManageSubTab.descriptors,
                        label: Text('Descriptors', style: labelStyle)),
                    ButtonSegment(
                        value: ManageSubTab.importExport,
                        label: Text('Import/Export', style: labelStyle)),
                  ],
                  selected: {manage.subTab},
                  onSelectionChanged: (s) {
                    manage.setSubTab(s.first);
                    _searchCtrl.clear();
                  },
                  style: SegmentedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    selectedForegroundColor: AppColors.background,
                    selectedBackgroundColor: AppColors.electricBlue,
                  ),
                ),
              ),
              const InfoTip(
                  body:
                      'Switch between Artists, Genres, Descriptors, and Import/Export.\n\nEach sub-tab manages a different entity type. Import/Export lets you download or upload CSV files.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ManageProvider manage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.textHint),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          manage.setSearchQuery('');
                        },
                      ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              onChanged: (v) {
                manage.setSearchQuery(v);
                setState(() {});
              },
            ),
          ),
          const InfoTip(body: _searchInfo),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            onPressed: manage.isLoading ? null : () => manage.loadAll(),
            icon: const Icon(Icons.refresh, color: AppColors.electricBlue),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
            ),
            icon: const Icon(Icons.add,
                size: 18, color: AppColors.background),
            label: const Text('Add',
                style: TextStyle(color: AppColors.background)),
            onPressed: _onAdd,
          ),
          InfoTip(body: _addInfo(manage.subTab)),
        ],
      ),
    );
  }

  static const _searchInfo =
      'Fuzzy search across all entity names in the current sub-tab.\n\nWhen search is active, column sorting is replaced by fuzzy relevance. Clear the search to restore column sorting.';

  String _addInfo(ManageSubTab tab) {
    switch (tab) {
      case ManageSubTab.artists:
        return 'Add a new artist entity. Opens a dialog to type the artist name.';
      case ManageSubTab.genres:
        return 'Add a new genre entity. Opens a dialog to type the genre name.';
      case ManageSubTab.descriptors:
        return 'Add a new descriptor entity. Opens a dialog to type the descriptor name.';
      case ManageSubTab.importExport:
        return '';
    }
  }

  Widget _buildTable(ManageProvider manage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (manage.subTab) {
          ManageSubTab.artists => EntityTable<Artist>(
              entities: manage.artists,
              nameExtractor: (a) => a.artistName,
              idExtractor: (a) => a.artistId!,
              onRowTap: (a) {
                final entry = manage.rawArtists.firstWhere(
                  (e) => e.entity.artistId == a.artistId,
                  orElse: () => throw StateError('not found'),
                );
                _onRowTapArtist(a, entry.refCount);
              },
            ),
          ManageSubTab.genres => EntityTable<Genre>(
              entities: manage.genres,
              nameExtractor: (g) => g.genreName,
              idExtractor: (g) => g.genreId!,
              showHierarchyColumns: true,
              onRowTap: (g) {
                final entry = manage.rawGenres.firstWhere(
                  (e) => e.entity.genreId == g.genreId,
                  orElse: () => throw StateError('not found'),
                );
                _onRowTapGenre(g, entry.refCount, entry.childrenCount);
              },
            ),
          ManageSubTab.descriptors => EntityTable<Descriptor>(
              entities: manage.descriptors,
              nameExtractor: (d) => d.descriptorName,
              idExtractor: (d) => d.descriptorId!,
              showHierarchyColumns: true,
              onRowTap: (d) {
                final entry = manage.rawDescriptors.firstWhere(
                  (e) => e.entity.descriptorId == d.descriptorId,
                  orElse: () => throw StateError('not found'),
                );
                _onRowTapDescriptor(
                    d, entry.refCount, entry.childrenCount);
              },
            ),
          ManageSubTab.importExport => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildTreeButton(ManageProvider manage) {
    if (manage.subTab == ManageSubTab.artists) {
      return const SizedBox.shrink();
    }

    final isGenre = manage.subTab == ManageSubTab.genres;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.electricBlue,
                side: const BorderSide(color: AppColors.electricBlue),
              ),
              icon: const Icon(Icons.account_tree, size: 16),
              label:
                  Text(isGenre ? 'View Genre Tree' : 'View Descriptor Tree'),
              onPressed: () {
                if (isGenre) {
                  manage.openGenreTree();
                } else {
                  manage.openDescriptorTree();
                }
              },
            ),
            InfoTip(
                body: isGenre
                    ? 'Opens a hierarchical tree view of all genres and their parent-child relationships.\n\nA "Back to Manage" button is always available at the top to return here.'
                    : 'Opens a hierarchical tree view of all descriptors and their parent-child relationships.\n\nA "Back to Manage" button is always available at the top to return here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildTree(ManageProvider manage) {
    final isGenre = manage.view == ManageView.genreTree;
    return ManageTreeScreen(
      title: isGenre ? 'Genre Tree' : 'Descriptor Tree',
      nodes: isGenre ? manage.genreTree : manage.descriptorTree,
      expandedIds: isGenre ? manage.expandedGenreIds : manage.expandedDescriptorIds,
      isLoading: manage.treeLoading,
      error: manage.treeError,
      onToggle: isGenre ? manage.toggleGenreNode : manage.toggleDescriptorNode,
      onExpandAll: isGenre ? manage.expandAllGenreNodes : manage.expandAllDescriptorNodes,
      onCollapseAll: isGenre ? manage.collapseAllGenreNodes : manage.collapseAllDescriptorNodes,
      onBack: manage.backToTable,
      onRetry: () {
        if (isGenre) {
          manage.openGenreTree();
        } else {
          manage.openDescriptorTree();
        }
      },
    );
  }
}
