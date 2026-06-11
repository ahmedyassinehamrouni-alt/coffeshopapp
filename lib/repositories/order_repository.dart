import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';

part 'order_repository.g.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class OrderRepository {
  /// Live stream of all orders for a table (active + history).
  Stream<List<OrderModel>> watchOrdersByTable(String tableId);

  /// Live stream of the active (non-paid, non-cancelled) order for a table.
  Stream<OrderModel?> watchActiveOrderForTable(String tableId);

  /// Live stream of a single order.
  Stream<OrderModel?> watchOrder(String orderId);

  /// Live stream of all orders with active statuses (for kitchen / dashboard).
  Stream<List<OrderModel>> watchActiveOrders();

  /// One-shot fetch.
  Future<OrderModel?> fetchOrder(String orderId);

  /// Create a new order and atomically attach it to the table.
  Future<OrderModel> createOrder({
    required String tableId,
    required int tableNumber,
    required String staffId,
    required String staffName,
    required List<OrderItem> items,
    required String notes,
  });

  /// Replace the items list and recalculate totals.
  Future<void> updateItems({
    required String orderId,
    required List<OrderItem> items,
    String? notes,
  });

  /// Transition the order to a new status.
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  });

  /// Add a single item or increment its quantity if already present.
  Future<void> addItem({
    required String orderId,
    required OrderItem item,
  });

  /// Remove an item entirely.
  Future<void> removeItem({
    required String orderId,
    required String menuItemId,
  });

  /// Change the quantity of one item.
  Future<void> setItemQuantity({
    required String orderId,
    required String menuItemId,
    required int quantity,
  });

  /// Update the per-item note.
  Future<void> setItemNote({
    required String orderId,
    required String menuItemId,
    required String note,
  });

  /// Update the order-level note.
  Future<void> setOrderNote({
    required String orderId,
    required String note,
  });

  /// Cancel and clean up (detach from table).
  Future<void> cancelOrder(String orderId);
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseOrderRepository implements OrderRepository {
  FirebaseOrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.orders);

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _db.doc(FirestorePaths.orderDoc(id));

  DocumentReference<Map<String, dynamic>> _tableDoc(String id) =>
      _db.doc(FirestorePaths.tableDoc(id));

  // ── Streams ───────────────────────────────────────────────────────────────

  @override
  Stream<List<OrderModel>> watchOrdersByTable(String tableId) => _col
      .where('tableId', isEqualTo: tableId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList())
      .handleError(_handle);

  @override
  Stream<OrderModel?> watchActiveOrderForTable(String tableId) => _col
      .where('tableId', isEqualTo: tableId)
      .where('status', whereIn: [
        OrderStatus.pending.name,
        OrderStatus.preparing.name,
        OrderStatus.ready.name,
        OrderStatus.served.name,
        OrderStatus.draft.name,
      ])
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : OrderModel.fromFirestore(s.docs.first))
      .handleError(_handle);

  @override
  Stream<OrderModel?> watchOrder(String orderId) => _doc(orderId)
      .snapshots()
      .map((s) => s.exists ? OrderModel.fromFirestore(s) : null)
      .handleError(_handle);

  @override
  Stream<List<OrderModel>> watchActiveOrders() => _col
      .where('status', whereIn: [
        OrderStatus.pending.name,
        OrderStatus.preparing.name,
        OrderStatus.ready.name,
      ])
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList())
      .handleError(_handle);

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<OrderModel?> fetchOrder(String orderId) async {
    try {
      final doc = await _doc(orderId).get();
      return doc.exists ? OrderModel.fromFirestore(doc) : null;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<OrderModel> createOrder({
    required String tableId,
    required int tableNumber,
    required String staffId,
    required String staffName,
    required List<OrderItem> items,
    required String notes,
  }) async {
    try {
      final orderRef = _col.doc();

      // Compute totals
      final sub = items.fold(0.0, (s, i) => s + i.lineTotal);
      final tax = sub * kTaxRate;

      final order = OrderModel(
        id: orderRef.id,
        tableId: tableId,
        tableNumber: tableNumber,
        staffId: staffId,
        staffName: staffName,
        status: OrderStatus.pending,
        items: items,
        subtotal: sub,
        tax: tax,
        total: sub + tax,
        notes: notes,
        createdAt: DateTime.now(),
      );

      // Batch: write order + update table atomically
      final batch = _db.batch();
      batch.set(orderRef, order.toFirestore());
      batch.update(_tableDoc(tableId), {
        'status': TableStatus.occupied.name,
        'currentOrderId': orderRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      return order;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Update items ──────────────────────────────────────────────────────────

  @override
  Future<void> updateItems({
    required String orderId,
    required List<OrderItem> items,
    String? notes,
  }) async {
    try {
      final sub = items.fold(0.0, (s, i) => s + i.lineTotal);
      final tax = sub * kTaxRate;
      final updates = <String, dynamic>{
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': sub,
        'tax': tax,
        'total': sub + tax,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (notes != null) updates['notes'] = notes;
      await _doc(orderId).update(updates);
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Status ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await _doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Item-level mutations (read-modify-write with transaction) ─────────────

  @override
  Future<void> addItem({
    required String orderId,
    required OrderItem item,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_doc(orderId));
        if (!snap.exists) throw FirestoreException.notFound('Order');

        final order = OrderModel.fromFirestore(snap);
        final idx = order.items.indexWhere((i) => i.menuItemId == item.menuItemId);
        List<OrderItem> updated;
        if (idx >= 0) {
          updated = List.of(order.items);
          updated[idx] = updated[idx].copyWith(
            quantity: updated[idx].quantity + item.quantity,
          );
        } else {
          updated = [...order.items, item];
        }

        final sub = updated.fold(0.0, (s, i) => s + i.lineTotal);
        final tax = sub * kTaxRate;
        tx.update(_doc(orderId), {
          'items': updated.map((i) => i.toMap()).toList(),
          'subtotal': sub,
          'tax': tax,
          'total': sub + tax,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> removeItem({
    required String orderId,
    required String menuItemId,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_doc(orderId));
        if (!snap.exists) throw FirestoreException.notFound('Order');

        final order = OrderModel.fromFirestore(snap);
        final updated = order.items.where((i) => i.menuItemId != menuItemId).toList();

        final sub = updated.fold(0.0, (s, i) => s + i.lineTotal);
        final tax = sub * kTaxRate;
        tx.update(_doc(orderId), {
          'items': updated.map((i) => i.toMap()).toList(),
          'subtotal': sub,
          'tax': tax,
          'total': sub + tax,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> setItemQuantity({
    required String orderId,
    required String menuItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return removeItem(orderId: orderId, menuItemId: menuItemId);
    }
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_doc(orderId));
        if (!snap.exists) throw FirestoreException.notFound('Order');

        final order = OrderModel.fromFirestore(snap);
        final updated = order.items.map((i) {
          return i.menuItemId == menuItemId ? i.copyWith(quantity: quantity) : i;
        }).toList();

        final sub = updated.fold(0.0, (s, i) => s + i.lineTotal);
        final tax = sub * kTaxRate;
        tx.update(_doc(orderId), {
          'items': updated.map((i) => i.toMap()).toList(),
          'subtotal': sub,
          'tax': tax,
          'total': sub + tax,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> setItemNote({
    required String orderId,
    required String menuItemId,
    required String note,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_doc(orderId));
        if (!snap.exists) throw FirestoreException.notFound('Order');

        final order = OrderModel.fromFirestore(snap);
        final updated = order.items.map((i) {
          return i.menuItemId == menuItemId ? i.copyWith(notes: note) : i;
        }).toList();

        tx.update(_doc(orderId), {
          'items': updated.map((i) => i.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> setOrderNote({
    required String orderId,
    required String note,
  }) async {
    try {
      await _doc(orderId).update({
        'notes': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      final snap = await _doc(orderId).get();
      if (!snap.exists) return;
      final order = OrderModel.fromFirestore(snap);

      final batch = _db.batch();
      batch.update(_doc(orderId), {
        'status': OrderStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Free the table
      batch.update(_tableDoc(order.tableId), {
        'status': TableStatus.available.name,
        'currentOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  AppException _map(FirebaseException e) {
    if (e.code == 'permission-denied') return FirestoreException.permissionDenied();
    if (e.code == 'not-found') return FirestoreException.notFound('Order');
    return FirestoreException(message: e.message ?? 'Firestore error', code: e.code);
  }

  void _handle(Object err, StackTrace st) {
    if (err is FirebaseException) throw _map(err);
    throw err;
  }
}

@riverpod
OrderRepository orderRepository(Ref ref) =>
  FirebaseOrderRepository();
