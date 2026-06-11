import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/staff_model.dart';
import '../../../models/table_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/table_provider.dart';
import '../widgets/add_table_sheet.dart';
import '../widgets/table_action_sheet.dart';
import '../widgets/table_card.dart';
import '../widgets/table_status_filter_bar.dart';
import '../widgets/table_summary_bar.dart';

class TableMapScreen extends ConsumerWidget {
  const TableMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider) ?? StaffRole.waiter;
    final tablesAsync = ref.watch(tablesStreamProvider);
    final filteredTables = ref.watch(filteredTablesProvider);
    final isAdmin = role == StaffRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, ref, isAdmin, tablesAsync),
      body: Column(
        children: [
          // ── Summary bar ──────────────────────────────────────────────────
          const TableSummaryBar(),
          const Divider(height: 1),

          // ── Filter chips ─────────────────────────────────────────────────
          const SizedBox(height: 10),
          const TableFilterBar(),
          const SizedBox(height: 10),

          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: tablesAsync.when(
              loading: () => const _LoadingGrid(),
              error: (e, _) => _ErrorView(error: e.toString()),
              data: (_) => filteredTables.isEmpty
                  ? const _EmptyView()
                  : _TableGrid(tables: filteredTables),
            ),
          ),
        ],
      ),
      // Admin-only FAB to add a table
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => showAddTableSheet(context),
              backgroundColor: AppColors.caramel,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Table'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isAdmin,
    AsyncValue<List<TableModel>> tablesAsync,
  ) {
    // Real-time indicator
    final isLive = tablesAsync.hasValue && !tablesAsync.isLoading;

    return AppBar(
      title: Row(
        children: [
          const Text('Tables'),
          const SizedBox(width: 8),
          // Live sync indicator
          AnimatedOpacity(
            opacity: isLive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Grid / List toggle could go here — keeping layout toggle for UX
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
          onPressed: () => _showProfileMenu(context, ref),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final staff = ref.read(currentStaffProvider).value;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (staff != null) ...[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.caramel.withOpacity(0.15),
                child: Text(
                  staff.name.substring(0, 2).toUpperCase(),
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.caramel),
                ),
              ),
              const SizedBox(height: 10),
              Text(staff.name, style: AppTextStyles.titleMedium),
              Text(staff.role.displayName, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Sign Out',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(signInProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table grid ────────────────────────────────────────────────────────────────

class _TableGrid extends StatelessWidget {
  const _TableGrid({required this.tables});
  final List<TableModel> tables;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.caramel,
      // Firestore streams auto-update; this is just a visual affordance
      onRefresh: () => Future.delayed(const Duration(milliseconds: 400)),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: tables.length,
        itemBuilder: (context, i) {
          final table = tables[i];
          return TableCard(
            key: ValueKey(table.id),
            table: table,
            onTap: () => showTableActionSheet(context, table),
            onLongPress: () => showTableActionSheet(context, table),
          );
        },
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    if (width >= 400) return 3;
    return 2;
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No tables found', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Try a different filter, or add a table.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load tables',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
