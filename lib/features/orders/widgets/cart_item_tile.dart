import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';

/// Used inside the draft cart (before the order is placed).
class CartItemTile extends ConsumerWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.tableId,
  });

  final OrderItem item;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(orderDraftProvider(tableId).notifier);

    return Dismissible(
      key: ValueKey(item.menuItemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        draft.removeItem(item.menuItemId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  // Item name + price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          item.unitPrice.asCurrency,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.caramel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Line total
                  Text(
                    item.lineTotal.asCurrency,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.caramel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantity stepper
                  _QuantityStepper(
                    quantity: item.quantity,
                    onDecrement: () {
                      HapticFeedback.lightImpact();
                      draft.setQuantity(item.menuItemId, item.quantity - 1);
                    },
                    onIncrement: () {
                      HapticFeedback.lightImpact();
                      draft.setQuantity(item.menuItemId, item.quantity + 1);
                    },
                  ),
                ],
              ),
            ),
            // Per-item note row
            _NoteRow(item: item, tableId: tableId),
          ],
        ),
      ),
    );
  }
}

// ── Live order item tile (for an already-placed order) ────────────────────────

/// Used inside the order-detail view for a live Firestore order.
class LiveOrderItemTile extends ConsumerWidget {
  const LiveOrderItemTile({
    super.key,
    required this.item,
    required this.orderId,
    required this.isEditable,
  });

  final OrderItem item;
  final String orderId;
  final bool isEditable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: _itemStatusColor(item.itemStatus),
                    shape: BoxShape.circle,
                  ),
                ),
                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        item.unitPrice.asCurrency,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.caramel),
                      ),
                    ],
                  ),
                ),
                // Line total
                Text(
                  item.lineTotal.asCurrency,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.caramel),
                ),
                if (isEditable) ...[
                  const SizedBox(width: 12),
                  _QuantityStepper(
                    quantity: item.quantity,
                    onDecrement: () => notifier.setQuantity(
                      orderId: orderId,
                      menuItemId: item.menuItemId,
                      quantity: item.quantity - 1,
                    ),
                    onIncrement: () => notifier.setQuantity(
                      orderId: orderId,
                      menuItemId: item.menuItemId,
                      quantity: item.quantity + 1,
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '×${item.quantity}',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
              ],
            ),
          ),
          // Notes
          if (item.notes.isNotEmpty || isEditable)
            _LiveNoteRow(item: item, orderId: orderId, isEditable: isEditable),
        ],
      ),
    );
  }

  Color _itemStatusColor(String status) => switch (status) {
        'preparing' => AppColors.preparing,
        'ready' => AppColors.ready,
        _ => AppColors.textHint,
      };
}

// ── Quantity stepper ──────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
          icon: quantity <= 1 ? Icons.delete_outline : Icons.remove,
          color: quantity <= 1 ? AppColors.error : AppColors.textSecondary,
          onTap: onDecrement,
        ),
        SizedBox(
          width: 32,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          color: AppColors.caramel,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Per-item note row (draft) ─────────────────────────────────────────────────

class _NoteRow extends ConsumerStatefulWidget {
  const _NoteRow({required this.item, required this.tableId});
  final OrderItem item;
  final String tableId;

  @override
  ConsumerState<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends ConsumerState<_NoteRow> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: _editing
          ? Row(
              children: [
                const Icon(Icons.notes_outlined,
                    size: 15, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'e.g. no sugar, extra hot…',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                TextButton(onPressed: _save, child: const Text('Save')),
              ],
            )
          : GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Row(
                children: [
                  Icon(Icons.notes_outlined,
                      size: 15,
                      color: widget.item.notes.isEmpty
                          ? AppColors.textHint
                          : AppColors.caramel),
                  const SizedBox(width: 8),
                  Text(
                    widget.item.notes.isEmpty
                        ? 'Add note…'
                        : widget.item.notes,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: widget.item.notes.isEmpty
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                      fontStyle: widget.item.notes.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _save() {
    ref
        .read(orderDraftProvider(widget.tableId).notifier)
        .setItemNote(widget.item.menuItemId, _ctrl.text.trim());
    setState(() => _editing = false);
  }
}

// ── Live note row (placed order) ──────────────────────────────────────────────

class _LiveNoteRow extends ConsumerStatefulWidget {
  const _LiveNoteRow({
    required this.item,
    required this.orderId,
    required this.isEditable,
  });
  final OrderItem item;
  final String orderId;
  final bool isEditable;

  @override
  ConsumerState<_LiveNoteRow> createState() => _LiveNoteRowState();
}

class _LiveNoteRowState extends ConsumerState<_LiveNoteRow> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: _editing
          ? Row(
              children: [
                const Icon(Icons.notes_outlined,
                    size: 15, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'e.g. no sugar, extra hot…',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                TextButton(onPressed: _save, child: const Text('Save')),
              ],
            )
          : GestureDetector(
              onTap: widget.isEditable
                  ? () => setState(() => _editing = true)
                  : null,
              child: Row(
                children: [
                  Icon(Icons.notes_outlined,
                      size: 15,
                      color: widget.item.notes.isEmpty
                          ? AppColors.textHint
                          : AppColors.caramel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.notes.isEmpty
                          ? (widget.isEditable ? 'Add note…' : '')
                          : widget.item.notes,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: widget.item.notes.isEmpty
                            ? AppColors.textHint
                            : AppColors.textSecondary,
                        fontStyle: widget.item.notes.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _save() {
    ref.read(orderNotifierProvider.notifier).setItemNote(
          orderId: widget.orderId,
          menuItemId: widget.item.menuItemId,
          note: _ctrl.text.trim(),
        );
    setState(() => _editing = false);
  }
}
