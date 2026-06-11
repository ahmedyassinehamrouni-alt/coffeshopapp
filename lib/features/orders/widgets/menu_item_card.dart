import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/order_provider.dart';

class MenuItemCard extends ConsumerWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.tableId,
  });

  final MenuItemModel item;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
      orderDraftProvider(tableId).select(
        (s) => s.items
            .where((i) => i.menuItemId == item.id)
            .fold(0, (_, i) => i.quantity),
      ),
    );
    final draft = ref.read(orderDraftProvider(tableId).notifier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0 ? AppColors.caramel : AppColors.divider,
          width: qty > 0 ? 1.5 : 1.0,
        ),
        boxShadow: qty > 0
            ? [
                BoxShadow(
                  color: AppColors.caramel.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            draft.addItem(item);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top: name + quantity badge ───────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (qty > 0)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.caramel,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Description ──────────────────────────────────────────
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // ── Bottom: price + prep time + controls ─────────────────
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.price.asCurrency,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.caramel,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 11, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '${item.preparationTimeMin}m',
                              style: AppTextStyles.labelSmall
                                  .copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // ── Quick controls when qty > 0 ──────────────────────
                    if (qty > 0)
                      Row(
                        children: [
                          _MiniBtn(
                            icon: qty == 1
                                ? Icons.delete_outline
                                : Icons.remove,
                            color: qty == 1
                                ? AppColors.error
                                : AppColors.textSecondary,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              draft.setQuantity(item.id, qty - 1);
                            },
                          ),
                          const SizedBox(width: 8),
                          _MiniBtn(
                            icon: Icons.add,
                            color: AppColors.caramel,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              draft.addItem(item);
                            },
                          ),
                        ],
                      )
                    else
                      _MiniBtn(
                        icon: Icons.add,
                        color: AppColors.caramel,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          draft.addItem(item);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
