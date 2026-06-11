import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/order_provider.dart';
import '../widgets/menu_item_card.dart';

/// Full-screen menu browser — tap items to add them to the draft cart.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key, required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedMenuItemsProvider);
    final menuAsync = ref.watch(menuItemsStreamProvider);
    final totalItems = ref
        .watch(orderDraftProvider(tableId).select((s) => s.items))
        .fold(0, (s, i) => s + i.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Menu — Table $tableId'),
        actions: [
          if (totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.caramel,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$totalItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                label: const Text('Done'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _SearchBar(),
          ),
          // ── Category chips ───────────────────────────────────────────────
          const _CategoryBar(),
          const SizedBox(height: 6),
          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: menuAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.caramel)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) => grouped.isEmpty
                  ? _emptyState()
                  : _MenuGroupedList(
                      grouped: grouped, tableId: tableId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 52, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No items found', style: AppTextStyles.titleMedium),
          ],
        ),
      );
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: ref.read(menuSearchQueryProvider.notifier).update,
      decoration: InputDecoration(
        hintText: 'Search menu…',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _ctrl.clear();
                  ref.read(menuSearchQueryProvider.notifier).clear();
                },
              )
            : null,
      ),
    );
  }
}

// ── Category filter chips ─────────────────────────────────────────────────────

class _CategoryBar extends ConsumerWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMenuCategoryProvider);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            icon: Icons.grid_view_outlined,
            selected: selected == null,
            onTap: () =>
                ref.read(selectedMenuCategoryProvider.notifier).select(null),
          ),
          ...MenuCategory.values.map((cat) => _Chip(
                label: cat.displayName,
                icon: cat.icon,
                selected: selected == cat,
                onTap: () => ref
                    .read(selectedMenuCategoryProvider.notifier)
                    .select(cat),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.caramel : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.caramel : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grouped menu list ─────────────────────────────────────────────────────────

class _MenuGroupedList extends StatelessWidget {
  const _MenuGroupedList({required this.grouped, required this.tableId});
  final Map<MenuCategory, List<MenuItemModel>> grouped;
  final String tableId;

  @override
  Widget build(BuildContext context) {
    final categories = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final items = grouped[cat]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(cat.icon, size: 16, color: AppColors.caramel),
                  const SizedBox(width: 8),
                  Text(cat.displayName, style: AppTextStyles.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} item${items.length == 1 ? '' : 's'}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols(context),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (_, j) => MenuItemCard(
                key: ValueKey(items[j].id),
                item: items[j],
                tableId: tableId,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  int _cols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }
}
