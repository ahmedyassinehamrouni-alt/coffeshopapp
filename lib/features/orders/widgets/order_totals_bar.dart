import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/order_provider.dart';

/// Sticky bottom bar displayed in the cart / menu screen.
class OrderTotalsBar extends ConsumerWidget {
  const OrderTotalsBar({
    super.key,
    required this.tableId,
    required this.onPlaceOrder,
    this.isLoading = false,
  });

  final String tableId;
  final VoidCallback onPlaceOrder;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider(tableId));
    final notifier = ref.read(orderDraftProvider(tableId).notifier);

    final subtotal = notifier.subtotal;
    final tax = notifier.tax;
    final total = notifier.total;
    final itemCount = notifier.totalItems;
    final isEmpty = draft.items.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Totals breakdown ─────────────────────────────────────────────
          if (!isEmpty) ...[
            _TotalRow(label: 'Subtotal', amount: subtotal),
            const SizedBox(height: 4),
            _TotalRow(label: 'Tax (8%)', amount: tax),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _TotalRow(
              label: 'Total',
              amount: total,
              isTotal: true,
            ),
            const SizedBox(height: 14),
          ],

          // ── Place order button ────────────────────────────────────────────
          ElevatedButton(
            onPressed: isEmpty || isLoading ? null : onPlaceOrder,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isEmpty
                            ? 'Add items to place order'
                            : 'Place Order · $itemCount item${itemCount == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium,
        ),
        const Spacer(),
        Text(
          amount.asCurrency,
          style: isTotal
              ? AppTextStyles.titleMedium.copyWith(color: AppColors.caramel)
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
