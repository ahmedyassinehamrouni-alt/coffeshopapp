import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/table_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/order_totals_bar.dart';

/// Draft order screen — shown before the order is placed.
/// Waiter adds items via MenuScreen, edits quantities/notes here,
/// then confirms to fire createOrder() to Firestore.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableAsync = ref.watch(tableStreamProvider(tableId));
    final draft = ref.watch(orderDraftProvider(tableId));
    final orderState = ref.watch(orderProvider);
    final isLoading = orderState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: tableAsync.when(
          loading: () => const Text('New Order'),
          error: (_, __) => Text('Table $tableId'),
          data: (t) => Text(t != null ? 'Order — ${t.displayName}' : 'New Order'),
        ),
        actions: [
          if (draft.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.error, size: 18),
              label: const Text('Clear',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Table info banner ────────────────────────────────────────────
          tableAsync.whenData((t) {
            if (t == null) return const SizedBox.shrink();
            return Container(
              color: AppColors.surface,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.caramel,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${t.number}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.displayName, style: AppTextStyles.labelLarge),
                      Text(
                        '${t.capacityLabel} · ${t.section.displayName}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/tables/$tableId/order/menu'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Items'),
                  ),
                ],
              ),
            );
          }).value ??
              const SizedBox.shrink(),

          const Divider(height: 1),

          // ── Cart items ───────────────────────────────────────────────────
          Expanded(
            child: draft.items.isEmpty
                ? _EmptyCart(
                    onAddItems: () =>
                        context.push('/tables/$tableId/order/menu'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    children: [
                      // Item list
                      ...draft.items.map((item) => CartItemTile(
                            key: ValueKey(item.menuItemId),
                            item: item,
                            tableId: tableId,
                          )),

                      const SizedBox(height: 14),

                      // Order-level note
                      _OrderNoteField(tableId: tableId),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
      // ── Sticky totals + place order ────────────────────────────────────────
      bottomNavigationBar: OrderTotalsBar(
        tableId: tableId,
        isLoading: isLoading,
        onPlaceOrder: () => _placeOrder(context, ref),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final tableAsync = ref.read(tableStreamProvider(tableId));
    final table = tableAsync.value;
    if (table == null) return;

    final draft = ref.read(orderDraftProvider(tableId));
    final result = await ref.read(orderProvider.notifier).placeOrder(
          tableId: tableId,
          tableNumber: table.number,
          items: draft.items,
          notes: draft.note,
        );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Order placed — ${result.totalItemCount} items sent to kitchen'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate to order detail so waiter can track it
      context.replace('/orders/${result.id}');
    }
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Order?'),
        content: const Text('All items will be removed from this order.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(orderDraftProvider(tableId).notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── Empty cart state ──────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onAddItems});
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.caramel.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.coffee_outlined,
              size: 38,
              color: AppColors.caramel,
            ),
          ),
          const SizedBox(height: 18),
          Text('No items yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Add items from the menu to start the order.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddItems,
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }
}

// ── Order-level note field ────────────────────────────────────────────────────

class _OrderNoteField extends ConsumerStatefulWidget {
  const _OrderNoteField({required this.tableId});
  final String tableId;

  @override
  ConsumerState<_OrderNoteField> createState() => _OrderNoteFieldState();
}

class _OrderNoteFieldState extends ConsumerState<_OrderNoteField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final currentNote =
        ref.read(orderDraftProvider(widget.tableId)).note;
    _ctrl = TextEditingController(text: currentNote);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined,
                  size: 16, color: AppColors.caramel),
              const SizedBox(width: 8),
              Text('Order Note', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            minLines: 1,
            onChanged: (v) => ref
                .read(orderDraftProvider(widget.tableId).notifier)
                .setOrderNote(v),
            decoration: const InputDecoration(
              hintText: 'Allergy info, special requests…',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
