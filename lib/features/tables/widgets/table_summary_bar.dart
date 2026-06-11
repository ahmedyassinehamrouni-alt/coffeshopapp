import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/table_model.dart';
import '../../../providers/table_provider.dart';

/// Horizontal summary row showing occupied/available/reserved/cleaning counts.
class TableSummaryBar extends ConsumerWidget {
  const TableSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(tableStatusCountsProvider);
    final total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          // Occupancy mini progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total Tables',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: TableStatus.values.map((s) {
                        final count = counts[s] ?? 0;
                        return Expanded(
                          flex: total == 0 ? 1 : (count == 0 ? 0 : count),
                          child: Container(color: s.color),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Per-status mini counts
          Row(
            children: TableStatus.values.map((s) {
              final count = counts[s] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _StatDot(status: s, count: count),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot({required this.status, required this.count});
  final TableStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
