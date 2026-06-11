import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/menu_item_model.dart';

part 'menu_repository.g.dart';

abstract class MenuRepository {
  Stream<List<MenuItemModel>> watchAllItems();
  Stream<List<MenuItemModel>> watchAvailableItems();
  Stream<List<MenuItemModel>> watchByCategory(MenuCategory category);
  Future<MenuItemModel?> fetchItem(String itemId);
  Future<MenuItemModel> createItem(MenuItemModel item);
  Future<void> updateItem(MenuItemModel item);
  Future<void> setAvailability(String itemId, {required bool available});
  Future<void> deleteItem(String itemId);
}

class FirebaseMenuRepository implements MenuRepository {
  FirebaseMenuRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.menuItems);

  // ── Streams ───────────────────────────────────────────────────────────────

  @override
  Stream<List<MenuItemModel>> watchAllItems() => _col
      .orderBy('category')
      .snapshots()
      .map((s) => s.docs.map(MenuItemModel.fromFirestore).toList())
      .handleError(_handle);

  @override
  Stream<List<MenuItemModel>> watchAvailableItems() => _col
      .where('isAvailable', isEqualTo: true)
      .orderBy('category')
      .snapshots()
      .map((s) => s.docs.map(MenuItemModel.fromFirestore).toList())
      .handleError(_handle);

  @override
  Stream<List<MenuItemModel>> watchByCategory(MenuCategory category) => _col
      .where('category', isEqualTo: category.name)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(MenuItemModel.fromFirestore).toList())
      .handleError(_handle);

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<MenuItemModel?> fetchItem(String itemId) async {
    try {
      final doc = await _db.doc(FirestorePaths.menuItemDoc(itemId)).get();
      return doc.exists ? MenuItemModel.fromFirestore(doc) : null;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<MenuItemModel> createItem(MenuItemModel item) async {
    try {
      final ref = _col.doc();
      final toSave = item.copyWith(id: ref.id);
      await ref.set(toSave.toFirestore());
      return toSave;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateItem(MenuItemModel item) async {
    try {
      await _db
          .doc(FirestorePaths.menuItemDoc(item.id))
          .update(item.toFirestore());
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> setAvailability(String itemId, {required bool available}) async {
    try {
      await _db
          .doc(FirestorePaths.menuItemDoc(itemId))
          .update({'isAvailable': available});
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      await _db.doc(FirestorePaths.menuItemDoc(itemId)).delete();
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  AppException _map(FirebaseException e) {
    if (e.code == 'permission-denied') return FirestoreException.permissionDenied();
    if (e.code == 'not-found') return FirestoreException.notFound('Menu item');
    return FirestoreException(message: e.message ?? 'Firestore error', code: e.code);
  }

  void _handle(Object err, StackTrace st) {
    if (err is FirebaseException) throw _map(err);
    throw err;
  }
}

@riverpod
MenuRepository menuRepository(Ref ref) =>
  FirebaseMenuRepository();
