import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/order_repository.dart';
import '../repositories/table_repository.dart';

part 'order_provider.g.dart';

// ── Live streams ──────────────────────────────────────────────────────────────

@riverpod
Stream<List<OrderModel>> ordersByTable(
  OrdersByTableRef ref,
  String tableId,
) =>
    ref.watch(orderRepositoryProvider).watchOrdersByTable(tableId);

@riverpod
Stream<OrderModel?> activeOrderForTable(
  ActiveOrderForTableRef ref,
  String tableId,
) =>
    ref.watch(orderRepositoryProvider).watchActiveOrderForTable(tableId);

@riverpod
Stream<OrderModel?> orderStream(
  OrderStreamRef ref,
  String orderId,
) =>
    ref.watch(orderRepositoryProvider).watchOrder(orderId);

@riverpod
Stream<List<OrderModel>> activeOrdersStream(ActiveOrdersStreamRef ref) =>
    ref.watch(orderRepositoryProvider).watchActiveOrders();

// ── Draft cart state ─────────────────────────────────────────────────────────
//
// The cart is a LOCAL list of OrderItems built before the order is committed
// to Firestore.  When the user taps "Place Order" the cart is flushed into
// createOrder() and cleared.

@riverpod
class OrderDraft extends _$OrderDraft {
  @override
  ({List<OrderItem> items, String note}) build(String tableId) =>
      (items: [], note: '');

  // ── Item mutations ─────────────────────────────────────────────────────────

  void addItem(MenuItemModel menuItem) {
    final items = List<OrderItem>.from(state.items);
    final idx = items.indexWhere((i) => i.menuItemId == menuItem.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(OrderItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        unitPrice: menuItem.price,
        quantity: 1,
      ));
    }
    state = (items: items, note: state.note);
  }

  void removeItem(String menuItemId) {
    final items = state.items.where((i) => i.menuItemId != menuItemId).toList();
    state = (items: items, note: state.note);
  }

  void setQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    final items = state.items.map((i) {
      return i.menuItemId == menuItemId ? i.copyWith(quantity: quantity) : i;
    }).toList();
    state = (items: items, note: state.note);
  }

  void setItemNote(String menuItemId, String note) {
    final items = state.items.map((i) {
      return i.menuItemId == menuItemId ? i.copyWith(notes: note) : i;
    }).toList();
    state = (items: items, note: state.note);
  }

  void setOrderNote(String note) {
    state = (items: state.items, note: note);
  }

  void clear() => state = (items: [], note: '');

  // ── Derived helpers ────────────────────────────────────────────────────────

  int quantityOf(String menuItemId) {
    final match = state.items.where((i) => i.menuItemId == menuItemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  double get subtotal =>
      state.items.fold(0.0, (s, i) => s + i.lineTotal);

  double get tax => subtotal * kTaxRate;
  double get total => subtotal + tax;
  int get totalItems => state.items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => state.items.isEmpty;
}

// ── Order CRUD notifier ───────────────────────────────────────────────────────

@riverpod
class OrderNotifier extends _$OrderNotifier {
  @override
  AsyncValue<OrderModel?> build() => const AsyncValue.data(null);

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  // ── Place order (commit draft) ─────────────────────────────────────────────

  Future<OrderModel?> placeOrder({
    required String tableId,
    required int tableNumber,
    required List<OrderItem> items,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    OrderModel? result;

    final staff = ref.read(currentStaffProvider).valueOrNull;
    if (staff == null) {
      state = AsyncValue.error(
          Exception('Not signed in'), StackTrace.current);
      return null;
    }

    state = await AsyncValue.guard(() async {
      result = await _repo.createOrder(
        tableId: tableId,
        tableNumber: tableNumber,
        staffId: staff.id,
        staffName: staff.name,
        items: items,
        notes: notes,
      );
      // Clear the local draft for this table
      ref.read(orderDraftProvider(tableId).notifier).clear();
      return result;
    });
    return result;
  }

  // ── Item-level mutations on an existing order ─────────────────────────────

  Future<void> addItem({
    required String orderId,
    required OrderItem item,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.addItem(orderId: orderId, item: item).then((_) => null));
  }

  Future<void> removeItem({
    required String orderId,
    required String menuItemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repo.removeItem(orderId: orderId, menuItemId: menuItemId).then((_) => null));
  }

  Future<void> setQuantity({
    required String orderId,
    required String menuItemId,
    required int quantity,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo
        .setItemQuantity(
            orderId: orderId, menuItemId: menuItemId, quantity: quantity)
        .then((_) => null));
  }

  Future<void> setItemNote({
    required String orderId,
    required String menuItemId,
    required String note,
  }) async {
    state = await AsyncValue.guard(() =>
        _repo.setItemNote(orderId: orderId, menuItemId: menuItemId, note: note)
            .then((_) => null));
  }

  Future<void> setOrderNote({
    required String orderId,
    required String note,
  }) async {
    state = await AsyncValue.guard(
        () => _repo.setOrderNote(orderId: orderId, note: note).then((_) => null));
  }

  // ── Status transitions ─────────────────────────────────────────────────────

  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _repo.updateStatus(orderId: orderId, status: status).then((_) => null));
  }

  Future<void> cancelOrder(String orderId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.cancelOrder(orderId).then((_) => null));
  }

  void reset() => state = const AsyncValue.data(null);
}
