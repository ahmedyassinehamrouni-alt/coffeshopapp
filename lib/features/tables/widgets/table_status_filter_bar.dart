import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/table_model.dart';
import '../../../providers/table_provider.dart';

/// Scrollable chip bar for filtering tables by status and section.
class TableFilterBar extends ConsumerWidget {
  const TableFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(tableStatusFilterProvider);
    final selectedSection = ref.watch(selectedSectionFilterProvider);
    final counts = ref.watch(tableStatusCountsProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // ── All ────────────────────────────────────────────────────────
          _FilterChip(
            label: 'All',
            count: counts.values.fold<int>(0, (a, b) => a + (b ?? 0)),
            isSelected: selectedStatus == null && selectedSection == null,
            color: AppColors.caramel,
            onTap: () {
              ref.read(tableStatusFilterProvider.notifier).select(null);
              ref.read(selectedSectionFilterProvider.notifier).select(null);
            },
          ),
          const SizedBox(width: 8),

          // ── Status filters ─────────────────────────────────────────────
          ...TableStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: status.displayName,
                  count: counts[status] ?? 0,
                  isSelected: selectedStatus == status,
                  color: status.color,
                  onTap: () {
                    ref.read(tableStatusFilterProvider.notifier).select(
                          selectedStatus == status ? null : status,
                        );
                    ref
                        .read(selectedSectionFilterProvider.notifier)
                        .select(null);
                  },
                ),
              )),

          // ── Section divider ────────────────────────────────────────────
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            color: AppColors.divider,
          ),

          // ── Section filters ────────────────────────────────────────────
          ...TableSection.values.map((section) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: section.displayName,
                  isSelected: selectedSection == section,
                  color: AppColors.roast,
                  onTap: () {
                    ref.read(selectedSectionFilterProvider.notifier).select(
                          selectedSection == section ? null : section,
                        );
                    ref.read(tableStatusFilterProvider.notifier).select(null);
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : AppColors.foam,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
