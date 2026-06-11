import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider).value;
    final role = staff?.role ?? StaffRole.waiter;
    final location = GoRouterState.of(context).matchedLocation;

    final tabs = _buildTabs(role);
    final currentIndex = _indexFromLocation(location, tabs);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(tabs[i].path),
          items: tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }

  List<_NavTab> _buildTabs(StaffRole role) {
    return [
      const _NavTab(
        path: AppRoutes.tableMap,
        label: 'Tables',
        icon: Icons.table_restaurant_outlined,
      ),
      if (role.canViewKitchen)
        const _NavTab(
          path: AppRoutes.kitchen,
          label: 'Kitchen',
          icon: Icons.restaurant_outlined,
        ),
      if (role.canViewDashboard)
        const _NavTab(
          path: AppRoutes.dashboard,
          label: 'Dashboard',
          icon: Icons.bar_chart_outlined,
        ),
      if (role.canManageMenu)
        const _NavTab(
          path: AppRoutes.menuManagement,
          label: 'Menu',
          icon: Icons.menu_book_outlined,
        ),
    ];
  }

  int _indexFromLocation(String location, List<_NavTab> tabs) {
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }
}

class _NavTab {
  const _NavTab({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}
