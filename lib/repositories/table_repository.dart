import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/table_model.dart';

part 'table_repository.g.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class TableRepository {
  /// Real-time stream of all non-deleted tables, ordered by number.
  Stream<List<TableModel>> watchAllTables();

  /// Real-time stream of tables in a specific section.
  Stream<List<TableModel>> watchTablesBySection(TableSection section);

  /// Fetch a single table by ID (one-shot).
  Future<TableModel?> fetchTable(String tableId);

  /// Real-time stream of a single table.
  Stream<TableModel?> watchTable(String tableId);

  /// Create a new table document.
  Future<TableModel> createTable({
    required int number,
    required int capacity,
    required TableSection section,
  });

  /// Update a table's status. Optionally attach/clear an orderId.
  Future<void> updateStatus({
    required String tableId,
    required TableStatus status,
    String? currentOrderId,
  });

  /// Update table metadata (capacity, section).
  Future<void> updateTable({
    required String tableId,
    int? capacity,
    TableSection? section,
    int? number,
  });

  /// Soft-delete a table (sets isDeleted = true).
  Future<void> deleteTable(String tableId);

  /// Attach an order to a table and set it to occupied.
  Future<void> attachOrder({
    required String tableId,
    required String orderId,
  });

  /// Detach the current order from a table (after payment).
  Future<void> detachOrder(String tableId);
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseTableRepository implements TableRepository {
  FirebaseTableRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.tables);

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _firestore.doc(FirestorePaths.tableDoc(id));

  // ── Streams ───────────────────────────────────────────────────────────────

  @override
  Stream<List<TableModel>> watchAllTables() {
    return _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('number')
        .snapshots()
        .map((snap) => snap.docs.map(TableModel.fromFirestore).toList())
        .handleError(_handleError);
  }

  @override
  Stream<List<TableModel>> watchTablesBySection(TableSection section) {
    return _col
        .where('isDeleted', isEqualTo: false)
        .where('section', isEqualTo: section.name)
        .orderBy('number')
        .snapshots()
        .map((snap) => snap.docs.map(TableModel.fromFirestore).toList())
        .handleError(_handleError);
  }

  @override
  Stream<TableModel?> watchTable(String tableId) {
    return _doc(tableId)
        .snapshots()
        .map((snap) => snap.exists ? TableModel.fromFirestore(snap) : null)
        .handleError(_handleError);
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<TableModel?> fetchTable(String tableId) async {
    try {
      final snap = await _doc(tableId).get();
      return snap.exists ? TableModel.fromFirestore(snap) : null;
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<TableModel> createTable({
    required int number,
    required int capacity,
    required TableSection section,
  }) async {
    try {
      // Check for duplicate table numbers
      final existing = await _col
          .where('number', isEqualTo: number)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw ValidationException(
          message: 'Table $number already exists.',
        );
      }

      final ref = _col.doc(); // auto-ID
      final table = TableModel(
        id: ref.id,
        number: number,
        capacity: capacity,
        status: TableStatus.available,
        section: section,
      );

      await ref.set(table.toFirestore());
      return table;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update status ─────────────────────────────────────────────────────────

  @override
  Future<void> updateStatus({
    required String tableId,
    required TableStatus status,
    String? currentOrderId,
  }) async {
    try {
      await _doc(tableId).update({
        'status': status.name,
        'currentOrderId': currentOrderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update metadata ───────────────────────────────────────────────────────

  @override
  Future<void> updateTable({
    required String tableId,
    int? capacity,
    TableSection? section,
    int? number,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (capacity != null) updates['capacity'] = capacity;
      if (section != null) updates['section'] = section.name;
      if (number != null) updates['number'] = number;
      await _doc(tableId).update(updates);
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Soft delete ───────────────────────────────────────────────────────────

  @override
  Future<void> deleteTable(String tableId) async {
    try {
      await _doc(tableId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Order attachment ──────────────────────────────────────────────────────

  @override
  Future<void> attachOrder({
    required String tableId,
    required String orderId,
  }) async {
    try {
      await _doc(tableId).update({
        'status': TableStatus.occupied.name,
        'currentOrderId': orderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> detachOrder(String tableId) async {
    try {
      await _doc(tableId).update({
        'status': TableStatus.cleaning.name,
        'currentOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  AppException _mapError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return FirestoreException.permissionDenied();
    }
    if (e.code == 'not-found') {
      return FirestoreException.notFound('Table');
    }
    return FirestoreException(
      message: e.message ?? 'Firestore error',
      code: e.code,
    );
  }

  void _handleError(Object error, StackTrace stack) {
    if (error is FirebaseException) throw _mapError(error);
    throw error;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

@riverpod
TableRepository tableRepository(Ref ref) =>
  FirebaseTableRepository();
