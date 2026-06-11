import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

part 'menu_provider.g.dart';

// ── All available items stream ────────────────────────────────────────────────

@riverpod
Stream<List<MenuItemModel>> menuItemsStream(MenuItemsStreamRef ref) =>
    ref.watch(menuRepositoryProvider).watchAvailableItems();

// ── All items (admin) ─────────────────────────────────────────────────────────

@riverpod
Stream<List<MenuItemModel>> allMenuItemsStream(AllMenuItemsStreamRef ref) =>
    ref.watch(menuRepositoryProvider).watchAllItems();

// ── Items by category ─────────────────────────────────────────────────────────

@riverpod
Stream<List<MenuItemModel>> menuItemsByCategory(
  MenuItemsByCategoryRef ref,
  MenuCategory category,
) =>
    ref.watch(menuRepositoryProvider).watchByCategory(category);

// ── Selected category (UI state) ──────────────────────────────────────────────

@riverpod
class SelectedMenuCategory extends _$SelectedMenuCategory {
  @override
  MenuCategory? build() => null; // null = all categories

  void select(MenuCategory? cat) => state = cat;
}

// ── Search query (UI state) ───────────────────────────────────────────────────

@riverpod
class MenuSearchQuery extends _$MenuSearchQuery {
  @override
  String build() => '';

  void update(String q) => state = q.toLowerCase().trim();
  void clear() => state = '';
}

// ── Filtered + searched items (derived) ──────────────────────────────────────

@riverpod
List<MenuItemModel> filteredMenuItems(FilteredMenuItemsRef ref) {
  final all = ref.watch(menuItemsStreamProvider).valueOrNull ?? [];
  final category = ref.watch(selectedMenuCategoryProvider);
  final query = ref.watch(menuSearchQueryProvider);

  var result = all;

  if (category != null) {
    result = result.where((i) => i.category == category).toList();
  }

  if (query.isNotEmpty) {
    result = result
        .where((i) =>
            i.name.toLowerCase().contains(query) ||
            i.description.toLowerCase().contains(query))
        .toList();
  }

  return result;
}

// ── Items grouped by category (for menu display) ──────────────────────────────

@riverpod
Map<MenuCategory, List<MenuItemModel>> groupedMenuItems(
    GroupedMenuItemsRef ref) {
  final items = ref.watch(filteredMenuItemsProvider);
  final map = <MenuCategory, List<MenuItemModel>>{};
  for (final item in items) {
    map.putIfAbsent(item.category, () => []).add(item);
  }
  return map;
}

// ── Menu CRUD notifier ────────────────────────────────────────────────────────

@riverpod
class MenuNotifier extends _$MenuNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  MenuRepository get _repo => ref.read(menuRepositoryProvider);

  Future<MenuItemModel?> createItem(MenuItemModel item) async {
    state = const AsyncValue.loading();
    MenuItemModel? result;
    state = await AsyncValue.guard(() async {
      result = await _repo.createItem(item);
    });
    return result;
  }

  Future<void> updateItem(MenuItemModel item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateItem(item));
  }

  Future<void> toggleAvailability(MenuItemModel item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repo.setAvailability(item.id, available: !item.isAvailable));
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteItem(itemId));
  }

  void reset() => state = const AsyncValue.data(null);
}
