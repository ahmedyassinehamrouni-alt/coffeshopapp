import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

// ── Order status ──────────────────────────────────────────────────────────────

enum OrderStatus {
  draft,      // being built locally, not yet sent to kitchen
  pending,    // submitted, awaiting kitchen
  preparing,  // kitchen is working on it
  ready,      // kitchen done, awaiting service
  served,     // delivered to table
  paid,       // payment complete
  cancelled;

  String get displayName => switch (this) {
        OrderStatus.draft => 'Draft',
        OrderStatus.pending => 'Pending',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.served => 'Served',
        OrderStatus.paid => 'Paid',
        OrderStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        OrderStatus.draft => const Color(0xFFB0A090),
        OrderStatus.pending => const Color(0xFFFFB74D),
        OrderStatus.preparing => const Color(0xFF29B6F6),
        OrderStatus.ready => const Color(0xFF66BB6A),
        OrderStatus.served => const Color(0xFF9E9E9E),
        OrderStatus.paid => const Color(0xFF4CAF50),
        OrderStatus.cancelled => const Color(0xFFE53935),
      };

  Color get lightColor => switch (this) {
        OrderStatus.draft => const Color(0xFFF5F0EB),
        OrderStatus.pending => const Color(0xFFFFF8E1),
        OrderStatus.preparing => const Color(0xFFE3F2FD),
        OrderStatus.ready => const Color(0xFFE8F5E9),
        OrderStatus.served => const Color(0xFFF5F5F5),
        OrderStatus.paid => const Color(0xFFE8F5E9),
        OrderStatus.cancelled => const Color(0xFFFFEBEE),
      };

  IconData get icon => switch (this) {
        OrderStatus.draft => Icons.edit_note_outlined,
        OrderStatus.pending => Icons.schedule_outlined,
        OrderStatus.preparing => Icons.restaurant_outlined,
        OrderStatus.ready => Icons.check_circle_outline,
        OrderStatus.served => Icons.room_service_outlined,
        OrderStatus.paid => Icons.payment_outlined,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready;

  bool get isEditable =>
      this == OrderStatus.draft || this == OrderStatus.pending;

  static OrderStatus fromString(String v) => OrderStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => OrderStatus.pending,
      );
}

// ── Order item ────────────────────────────────────────────────────────────────

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String menuItemId,
    required String name,         // denormalised — snapshot of menu item name
    required double unitPrice,    // denormalised — snapshot at time of order
    required int quantity,
    @Default('') String notes,    // per-item note (e.g. "no sugar")
    @Default('pending') String itemStatus, // pending | preparing | ready
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

extension OrderItemX on OrderItem {
  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'notes': notes,
        'itemStatus': itemStatus,
      };

  static OrderItem fromMap(Map<String, dynamic> m) => OrderItem(
        menuItemId: m['menuItemId'] as String,
        name: m['name'] as String,
        unitPrice: (m['unitPrice'] as num).toDouble(),
        quantity: (m['quantity'] as num).toInt(),
        notes: m['notes'] as String? ?? '',
        itemStatus: m['itemStatus'] as String? ?? 'pending',
      );
}

// ── Order model ───────────────────────────────────────────────────────────────

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    required String tableId,
    required int tableNumber,        // denormalised for quick display
    required String staffId,
    required String staffName,       // denormalised
    required OrderStatus status,
    required List<OrderItem> items,
    @Default(0.0) double subtotal,
    @Default(0.0) double tax,
    @Default(0.0) double total,
    @Default('') String notes,       // order-level note
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawItems = (d['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemX.fromMap(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: doc.id,
      tableId: d['tableId'] as String,
      tableNumber: (d['tableNumber'] as num).toInt(),
      staffId: d['staffId'] as String,
      staffName: d['staffName'] as String? ?? '',
      status: OrderStatus.fromString(d['status'] as String),
      items: rawItems,
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (d['tax'] as num?)?.toDouble() ?? 0.0,
      total: (d['total'] as num?)?.toDouble() ?? 0.0,
      notes: d['notes'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ── Tax rate constant ─────────────────────────────────────────────────────────

const double kTaxRate = 0.08; // 8%

extension OrderModelX on OrderModel {
  Map<String, dynamic> toFirestore() => {
        'tableId': tableId,
        'tableNumber': tableNumber,
        'staffId': staffId,
        'staffName': staffName,
        'status': status.name,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  int get totalItemCount => items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => items.isEmpty;
  bool get hasItems => items.isNotEmpty;

  /// Recompute subtotal/tax/total from current items.
  OrderModel withRecalculatedTotals() {
    final sub = items.fold(0.0, (s, i) => s + i.lineTotal);
    final t = sub * kTaxRate;
    return copyWith(subtotal: sub, tax: t, total: sub + t);
  }
}
