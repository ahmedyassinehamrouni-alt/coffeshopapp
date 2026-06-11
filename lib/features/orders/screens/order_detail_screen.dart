import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/order_status_badge.dart';

/// Live order-detail view — streams from Firestore in real time.
/// Waiters can edit items/notes while status is pending.
/// Shows status timeline, total, and action buttons.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));
    final role = ref.watch(currentRoleProvider) ?? StaffRole.waiter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: orderAsync.when(
          loading: () => const Text('Order'),
          error: (_, __) => const Text('Order'),
          data: (o) => Text(o != null ? 'Table ${o.tableNumber}' : 'Order'),
        ),
        actions: [
          orderAsync.whenData((order) {
            if (order == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              onSelected: (v) => _handleMenu(context, ref, order, v),
              itemBuilder: (_) => [
                if (order.status.isEditable)
                  const PopupMenuItem(
                    value: 'add_items',
                    child: ListTile(
                      leading: Icon(Icons.add_circle_outline),
                      title: Text('Add More Items'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (order.status != OrderStatus.cancelled &&
                    order.status != OrderStatus.paid)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(Icons.cancel_outlined, color: AppColors.error),
                      title: Text('Cancel Order',
                          style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            );
          }).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.caramel)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => order == null
            ? const Center(child: Text('Order not found'))
            : _OrderBody(order: order, role: role),
      ),
    );
  }

  void _handleMenu(
      BuildContext context, WidgetRef ref, OrderModel order, String action) {
    switch (action) {
      case 'add_items':
        context.push('/tables/${order.tableId}/order/menu');
      case 'cancel':
        _showCancelDialog(context, ref, order);
    }
  }

  void _showCancelDialog(
      BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
            'This will cancel the order and free the table. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(orderProvider.notifier)
                  .cancelOrder(order.id);
              if (context.mounted) context.go('/tables');
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}

// ── Order body ────────────────────────────────────────────────────────────────

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order, required this.role});
  final OrderModel order;
  final StaffRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditable = order.status.isEditable;
    final isCashier =
        role == StaffRole.admin || role == StaffRole.cashier;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Status card ────────────────────────────────────────────────────
        _StatusCard(order: order),
        const SizedBox(height: 14),

        // ── Status timeline ────────────────────────────────────────────────
        _StatusTimeline(currentStatus: order.status),
        const SizedBox(height: 14),

        // ── Items ──────────────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.receipt_long_outlined,
          title: 'Items',
          trailing: isEditable
              ? TextButton.icon(
                  onPressed: () =>
                      context.push('/tables/${order.tableId}/order/menu'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                )
              : null,
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) => LiveOrderItemTile(
              key: ValueKey(item.menuItemId),
              item: item,
              orderId: order.id,
              isEditable: isEditable,
            )),

        // ── Order note ─────────────────────────────────────────────────────
        if (order.notes.isNotEmpty || isEditable) ...[
          const SizedBox(height: 14),
          _SectionHeader(
              icon: Icons.notes_outlined, title: 'Order Note'),
          const SizedBox(height: 8),
          _LiveOrderNoteField(order: order, isEditable: isEditable),
        ],

        // ── Totals ─────────────────────────────────────────────────────────
        const SizedBox(height: 14),
        _TotalsCard(order: order),

        // ── Actions ────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _ActionButtons(order: order, role: role, isCashier: isCashier),
      ],
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: order.status.lightColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: order.status.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: order.status.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(order.status.icon,
                color: order.status.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Order #${order.id.substring(0, 6).toUpperCase()}',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(width: 8),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'}'
                  ' · ${order.staffName}'
                  ' · ${order.createdAt?.timeAgo ?? 'just now'}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status timeline ────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});
  final OrderStatus currentStatus;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.served,
    OrderStatus.paid,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled ||
        currentStatus == OrderStatus.draft) {
      return const SizedBox.shrink();
    }

    final currentIdx = _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            final isPast = stepIdx < currentIdx;
            return Expanded(
              child: Container(
                height: 2,
                color: isPast
                    ? AppColors.caramel
                    : AppColors.divider,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final step = _steps[stepIdx];
          final isPast = stepIdx < currentIdx;
          final isCurrent = stepIdx == currentIdx;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.caramel
                      : isPast
                          ? AppColors.caramel.withOpacity(0.2)
                          : AppColors.foam,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent || isPast
                        ? AppColors.caramel
                        : AppColors.divider,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isCurrent || isPast ? Icons.check : step.icon,
                  size: 13,
                  color: isCurrent
                      ? Colors.white
                      : isPast
                          ? AppColors.caramel
                          : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: isCurrent
                      ? AppColors.caramel
                      : isPast
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Totals card ───────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _Row('Subtotal', order.subtotal.asCurrency),
          const SizedBox(height: 6),
          _Row('Tax (8%)', order.tax.asCurrency),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _Row('Total', order.total.asCurrency, isTotal: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.isTotal = false});
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: isTotal
                ? AppTextStyles.titleMedium
                : AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value,
            style: isTotal
                ? AppTextStyles.titleMedium
                    .copyWith(color: AppColors.caramel)
                : AppTextStyles.bodyMedium),
      ],
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.order,
    required this.role,
    required this.isCashier,
  });
  final OrderModel order;
  final StaffRole role;
  final bool isCashier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderProvider.notifier);

    return switch (order.status) {
      OrderStatus.pending => ElevatedButton.icon(
          onPressed: () => notifier.updateStatus(
              orderId: order.id, status: OrderStatus.served),
          icon: const Icon(Icons.room_service_outlined, size: 18),
          label: const Text('Mark as Served'),
        ),
      OrderStatus.ready => ElevatedButton.icon(
          onPressed: () => notifier.updateStatus(
              orderId: order.id, status: OrderStatus.served),
          icon: const Icon(Icons.room_service_outlined, size: 18),
          label: const Text('Mark as Served'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ready),
        ),
      OrderStatus.served when isCashier => ElevatedButton.icon(
          onPressed: () =>
              context.push('/orders/${order.id}/payment'),
          icon: const Icon(Icons.payment_outlined, size: 18),
          label: const Text('Process Payment'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success),
        ),
      OrderStatus.paid => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Payment Complete',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.success)),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.caramel),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ── Live order note field ─────────────────────────────────────────────────────

class _LiveOrderNoteField extends ConsumerStatefulWidget {
  const _LiveOrderNoteField({
    required this.order,
    required this.isEditable,
  });
  final OrderModel order;
  final bool isEditable;

  @override
  ConsumerState<_LiveOrderNoteField> createState() =>
      _LiveOrderNoteFieldState();
}

class _LiveOrderNoteFieldState extends ConsumerState<_LiveOrderNoteField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.order.notes);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: _ctrl,
        enabled: widget.isEditable,
        maxLines: 3,
        minLines: 1,
        onChanged: (v) =>
            ref.read(orderProvider.notifier).setOrderNote(
                  orderId: widget.order.id,
                  note: v,
                ),
        decoration: const InputDecoration(
          hintText: 'Allergy info, special requests…',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
