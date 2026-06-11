import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/errors/app_exception.dart';
import '../models/table_model.dart';
import '../repositories/table_repository.dart';

part 'table_provider.g.dart';

// ── Live stream of all tables ─────────────────────────────────────────────────

@riverpod
Stream<List<TableModel>> tablesStream(Ref ref) =>
  ref.watch(tableRepositoryProvider).watchAllTables();

// ── Live stream filtered by section ──────────────────────────────────────────

@riverpod
Stream<List<TableModel>> tablesBySection(
  Ref ref,
  TableSection section,
) =>
    ref.watch(tableRepositoryProvider).watchTablesBySection(section);

// ── Live stream of one table ──────────────────────────────────────────────────

@riverpod
Stream<TableModel?> tableStream(
  Ref ref,
  String tableId,
) =>
    ref.watch(tableRepositoryProvider).watchTable(tableId);

// ── Derived: counts per status ────────────────────────────────────────────────

@riverpod
Map<TableStatus, int> tableStatusCounts(Ref ref) {
  final tables = ref.watch(tablesStreamProvider).value ?? [];
  final counts = <TableStatus, int>{for (final s in TableStatus.values) s: 0};
  for (final t in tables) {
    counts[t.status] = (counts[t.status] ?? 0) + 1;
  }
  return counts;
}

// ── Selected section filter (UI state) ───────────────────────────────────────

@riverpod
class SelectedSectionFilter extends _$SelectedSectionFilter {
  @override
  TableSection? build() => null; // null = show all

  void select(TableSection? section) => state = section;
}

// ── Filtered tables (applies section + optional status filter) ────────────────

@riverpod
List<TableModel> filteredTables(Ref ref) {
  final all = ref.watch(tablesStreamProvider).value ?? [];
  final section = ref.watch(selectedSectionFilterProvider);
  final statusFilter = ref.watch(tableStatusFilterProvider);

  var result = all;
  if (section != null) {
    result = result.where((t) => t.section == section).toList();
  }
  if (statusFilter != null) {
    result = result.where((t) => t.status == statusFilter).toList();
  }
  return result;
}

// ── Status filter (UI state) ──────────────────────────────────────────────────

@riverpod
class TableStatusFilter extends _$TableStatusFilter {
  @override
  TableStatus? build() => null; // null = show all statuses

  void select(TableStatus? status) => state = status;
}

// ── CRUD notifier ─────────────────────────────────────────────────────────────

@riverpod
class TableNotifier extends _$TableNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  TableRepository get _repo => ref.read(tableRepositoryProvider);

  // ── Status update ─────────────────────────────────────────────────────────

  Future<void> updateStatus({
    required String tableId,
    required TableStatus status,
    String? currentOrderId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateStatus(
          tableId: tableId,
          status: status,
          currentOrderId: currentOrderId,
        ));
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<TableModel?> createTable({
    required int number,
    required int capacity,
    required TableSection section,
  }) async {
    state = const AsyncValue.loading();
    TableModel? result;
    state = await AsyncValue.guard(() async {
      result = await _repo.createTable(
        number: number,
        capacity: capacity,
        section: section,
      );
    });
    return result;
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  Future<void> editTable({
    required String tableId,
    int? capacity,
    TableSection? section,
    int? number,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateTable(
          tableId: tableId,
          capacity: capacity,
          section: section,
          number: number,
        ));
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteTable(String tableId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteTable(tableId));
  }

  void reset() => state = const AsyncValue.data(null);
}
