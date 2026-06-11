import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/staff_model.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (staff) => staff == null
            ? const Center(child: Text('Profile not found.'))
            : _ProfileBody(staff: staff),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(signInNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.staff});
  final StaffModel staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Avatar + name ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.caramel.withOpacity(0.15),
            child: Text(
              _initials(staff.name),
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.caramel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(staff.name, style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          _RoleBadge(role: staff.role),
          const SizedBox(height: 4),
          Text(staff.email, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 28),

          // ── Info card ─────────────────────────────────────────────────────
          _InfoCard(
            items: [
              _InfoRow(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Role',
                value: staff.role.displayName,
              ),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: staff.email,
              ),
              _InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Status',
                value: staff.isActive ? 'Active' : 'Inactive',
                valueColor: staff.isActive ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Permissions card ──────────────────────────────────────────────
          _InfoCard(
            title: 'Access Permissions',
            items: _permissionRows(staff.role),
          ),
          const SizedBox(height: 24),

          // ── Change password ───────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => context.push('/change-password'),
            icon: const Icon(Icons.lock_reset_outlined),
            label: const Text('Change Password'),
          ),
          const SizedBox(height: 12),

          // ── Sign out ──────────────────────────────────────────────────────
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  List<_InfoRow> _permissionRows(StaffRole role) {
    final all = <String, bool>{
      'View Tables': true,
      'Create Orders': role != StaffRole.kitchen,
      'Process Payments': role == StaffRole.admin || role == StaffRole.cashier,
      'Kitchen Display': role == StaffRole.admin || role == StaffRole.kitchen,
      'Admin Dashboard': role == StaffRole.admin,
      'Manage Menu': role == StaffRole.admin,
      'Manage Staff': role == StaffRole.admin,
    };
    return all.entries
        .map((e) => _InfoRow(
              icon: e.value ? Icons.check_circle_outline : Icons.cancel_outlined,
              label: e.key,
              value: e.value ? 'Allowed' : 'No access',
              valueColor: e.value ? AppColors.success : AppColors.textHint,
            ))
        .toList();
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(signInNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.caramel.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.caramel.withOpacity(0.3)),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.caramel,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items, this.title});
  final List<_InfoRow> items;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
          ],
          ...items.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(row.icon,
                        size: 18,
                        color: row.valueColor ?? AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(row.label, style: AppTextStyles.bodyMedium),
                    const Spacer(),
                    Text(
                      row.value,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: row.valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}
