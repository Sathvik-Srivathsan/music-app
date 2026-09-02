import 'package:flutter/material.dart';
import 'package:music_collection/core/constants/app_colors.dart';
import 'package:music_collection/features/manage/data/repositories/manage_repository.dart';
import 'package:music_collection/features/manage/presentation/providers/manage_provider.dart';
import 'package:music_collection/shared/widgets/info_tip.dart';
import 'package:provider/provider.dart';

class EntityTable<T> extends StatelessWidget {
  final List<EntityWithRefCount<T>> entities;
  final String Function(T) nameExtractor;
  final int Function(T) idExtractor;
  final void Function(T entity) onRowTap;
  final bool showHierarchyColumns;

  const EntityTable({
    super.key,
    required this.entities,
    required this.nameExtractor,
    required this.idExtractor,
    required this.onRowTap,
    this.showHierarchyColumns = false,
  });

  @override
  Widget build(BuildContext context) {
    final manage = context.watch<ManageProvider>();

    return Column(
      children: [
        _buildHeader(manage),
        const Divider(color: AppColors.border, height: 1),
        Expanded(
          child: entities.isEmpty
              ? Center(
                  child: Text(
                    manage.searchQuery.isNotEmpty
                        ? 'No matches found'
                        : 'No entities found',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    final entry = entities[index];
                    return _buildRow(entry);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSortHeader({
    required ManageProvider manage,
    required String label,
    required EntitySortField field,
    required bool showSortIcon,
    bool enabled = true,
    String? infoBody,
  }) {
    final isActive = manage.sortField == field && showSortIcon;
    return GestureDetector(
      onTap: enabled ? () => manage.setSortField(field) : null,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.textSecondary : AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              manage.sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: AppColors.electricBlue,
            ),
          ],
          if (infoBody != null) InfoTip(body: infoBody),
        ],
      ),
    );
  }

  Widget _buildHeader(ManageProvider manage) {
    final searchActive = manage.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildSortHeader(
              manage: manage,
              label: 'Name',
              field: EntitySortField.name,
              showSortIcon: true,
              enabled: !searchActive,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildSortHeader(
              manage: manage,
              label: 'References',
              field: EntitySortField.refCount,
              showSortIcon: true,
              enabled: !searchActive,
              infoBody: showHierarchyColumns
                  ? null
                  : 'Number of records directly linked to this entity.',
            ),
          ),
          if (showHierarchyColumns) ...[
            Expanded(
              flex: 1,
              child: _buildSortHeader(
                manage: manage,
                label: 'Children',
                field: EntitySortField.childrenCount,
                showSortIcon: true,
                enabled: !searchActive,
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildSortHeader(
                manage: manage,
                label: 'Total References',
                field: EntitySortField.totalRefCount,
                showSortIcon: true,
                enabled: !searchActive,
                infoBody:
                    'References: records directly linked to this genre.\n\nChildren: direct child genres in the hierarchy.\n\nTotal References: references of this genre plus all its descendants combined.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(EntityWithRefCount<T> entry) {
    final name = nameExtractor(entry.entity);

    return InkWell(
      onTap: () => onRowTap(entry.entity),
      hoverColor: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.grid, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${entry.refCount}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            if (showHierarchyColumns) ...[
              Expanded(
                flex: 1,
                child: Text(
                  '${entry.childrenCount ?? 0}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${entry.totalRefCount ?? entry.refCount}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
