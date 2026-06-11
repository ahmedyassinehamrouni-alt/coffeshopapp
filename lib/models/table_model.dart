import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/theme/app_theme.dart';

part 'table_model.freezed.dart';
part 'table_model.g.dart';

// ── Status enum ───────────────────────────────────────────────────────────────

enum TableStatus {
  available,
  occupied,
  reserved,
  cleaning;

  static TableStatus fromString(String value) => TableStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TableStatus.available,
      );

  String get displayName => switch (this) {
        TableStatus.available => 'Available',
        TableStatus.occupied => 'Occupied',
        TableStatus.reserved => 'Reserved',
        TableStatus.cleaning => 'Cleaning',
      };

  Color get color => switch (this) {
        TableStatus.available => AppColors.available,
        TableStatus.occupied => AppColors.occupied,
        TableStatus.reserved => AppColors.reserved,
        TableStatus.cleaning => AppColors.cleaning,
      };

  Color get lightColor => switch (this) {
        TableStatus.available => const Color(0xFFE8F5E9),
        TableStatus.occupied => const Color(0xFFFFEBEE),
        TableStatus.reserved => const Color(0xFFFFFDE7),
        TableStatus.cleaning => const Color(0xFFE3F2FD),
      };

  IconData get icon => switch (this) {
        TableStatus.available => Icons.check_circle_outline,
        TableStatus.occupied => Icons.people_outline,
        TableStatus.reserved => Icons.event_available_outlined,
        TableStatus.cleaning => Icons.cleaning_services_outlined,
      };

  /// Which statuses this status can transition to.
  List<TableStatus> get allowedTransitions => switch (this) {
        TableStatus.available => [TableStatus.occupied, TableStatus.reserved],
        TableStatus.occupied => [TableStatus.cleaning, TableStatus.available],
        TableStatus.reserved => [TableStatus.occupied, TableStatus.available],
        TableStatus.cleaning => [TableStatus.available],
      };
}

// ── Section enum ──────────────────────────────────────────────────────────────

enum TableSection {
  indoor,
  outdoor,
  bar,
  private;

  String get displayName => switch (this) {
        TableSection.indoor => 'Indoor',
        TableSection.outdoor => 'Outdoor',
        TableSection.bar => 'Bar',
        TableSection.private => 'Private',
      };

  static TableSection fromString(String v) => TableSection.values.firstWhere(
        (e) => e.name == v,
        orElse: () => TableSection.indoor,
      );
}

// ── Model ─────────────────────────────────────────────────────────────────────

@freezed
abstract class TableModel with _$TableModel {
  const factory TableModel({
    required String id,
    required int number,
    required int capacity,
    required TableStatus status,
    required TableSection section,
    String? currentOrderId,
    @Default(false) bool isDeleted,
    DateTime? updatedAt,
  }) = _TableModel;

  factory TableModel.fromJson(Map<String, dynamic> json) =>
      _$TableModelFromJson(json);

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      number: (data['number'] as num).toInt(),
      capacity: (data['capacity'] as num).toInt(),
      status: TableStatus.fromString(data['status'] as String),
      section: TableSection.fromString(data['section'] as String? ?? 'indoor'),
      currentOrderId: data['currentOrderId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

extension TableModelX on TableModel {
  Map<String, dynamic> toFirestore() => {
        'number': number,
        'capacity': capacity,
        'status': status.name,
        'section': section.name,
        'currentOrderId': currentOrderId,
        'isDeleted': isDeleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;

  String get displayName => 'Table $number';

  /// Short capacity label e.g. "4 seats"
  String get capacityLabel => '$capacity ${capacity == 1 ? 'seat' : 'seats'}';
}
