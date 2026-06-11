import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/staff_model.dart';
import '../../../models/table_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/table_provider.dart';
import 'table_status_badge.dart';

/// Shows a context-sensitive bottom sheet of actions for a table.
void showTableActionSheet(BuildContext context, TableModel table) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TableActionSheet(table: table),
  );
}

class _TableActionSheet extends ConsumerWidget {
  const _TableActionSheet({required this.table});
  final TableModel table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider) ?? StaffRole.waiter;
    final notifier = ref.read(tableNotifierProvider.notifier);
    final isAdmin = role == StaffRole.admin;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: table.status.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${table.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Table ${table.number}',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      TableStatusBadge(status: table.status),
                      const SizedBox(width: 8),
                      Text(
                        '· ${table.capacityLabel} · ${table.section.displayName}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // ── Primary action: New Order (available only) ─────────────────
          if (table.status == TableStatus.available)
            _ActionTile(
              icon: Icons.add_circle_outline,
              label: 'New Order',
              subtitle: 'Start taking order for this table',
              color: AppColors.caramel,
              onTap: () {
                Navigator.pop(context);
                context.push('/tables/${table.id}/order');
              },
            ),

          // ── View current order (occupied) ──────────────────────────────
          if (table.status == TableStatus.occupied &&
              table.currentOrderId != null)
            _ActionTile(
              icon: Icons.receipt_long_outlined,
              label: 'View Order',
              subtitle: 'See current order details',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                context.push('/orders/${table.currentOrderId}');
              },
            ),

          // ── Status transitions ─────────────────────────────────────────
          ...table.status.allowedTransitions.map((nextStatus) => _ActionTile(
                icon: nextStatus.icon,
                label: 'Mark as ${nextStatus.displayName}',
                subtitle: _transitionLabel(table.status, nextStatus),
                color: nextStatus.color,
                onTap: () async {
                  Navigator.pop(context);
                  await notifier.updateStatus(
                    tableId: table.id,
                    status: nextStatus,
                    // Clear order ID when freeing table
                    currentOrderId: nextStatus == TableStatus.available ||
                            nextStatus == TableStatus.cleaning
                        ? null
                        : table.currentOrderId,
                  );
                },
              )),

          // ── Admin: Edit table ──────────────────────────────────────────
          if (isAdmin) ...[
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 4),
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Table',
              subtitle: 'Change capacity or section',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, table);
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Remove Table',
              subtitle: 'Permanently remove this table',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, ref, table);
              },
            ),
          ],

          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _transitionLabel(TableStatus from, TableStatus to) => switch ((from, to)) {
        (TableStatus.available, TableStatus.occupied) =>
          'Mark table as occupied without an order',
        (TableStatus.available, TableStatus.reserved) =>
          'Hold this table for a reservation',
        (TableStatus.occupied, TableStatus.cleaning) =>
          'Guest has left — table needs cleaning',
        (TableStatus.occupied, TableStatus.available) =>
          'Free the table immediately',
        (TableStatus.reserved, TableStatus.occupied) =>
          'Guest has arrived for reservation',
        (TableStatus.reserved, TableStatus.available) =>
          'Cancel the reservation',
        (TableStatus.cleaning, TableStatus.available) =>
          'Table is clean and ready',
        _ => '',
      };
}

// ── Edit dialog ───────────────────────────────────────────────────────────────

void _showEditDialog(BuildContext context, WidgetRef ref, TableModel table) {
  int capacity = table.capacity;
  TableSection section = table.section;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Edit Table ${table.number}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: capacity > 1
                      ? () => setState(() => capacity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$capacity', style: AppTextStyles.titleMedium),
                IconButton(
                  onPressed: capacity < 20
                      ? () => setState(() => capacity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Section', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TableSection.values.map((s) {
                final sel = section == s;
                return GestureDetector(
                  onTap: () => setState(() => section = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.caramel : AppColors.foam,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel ? AppColors.caramel : AppColors.divider),
                    ),
                    child: Text(
                      s.displayName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: sel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(tableNotifierProvider.notifier).editTable(
                    tableId: table.id,
                    capacity: capacity,
                    section: section,
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ── Delete confirm ────────────────────────────────────────────────────────────

void _showDeleteConfirm(BuildContext context, WidgetRef ref, TableModel table) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove Table?'),
      content: Text(
        'Table ${table.number} will be permanently removed. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(context);
            await ref
                .read(tableNotifierProvider.notifier)
                .deleteTable(table.id);
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

// ── Reusable action tile ──────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodyMedium),
      trailing: Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
    );
  }
}
