import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/kitchen/screens/kitchen_display_screen.dart';
import '../../features/menu_management/screens/menu_management_screen.dart';
import '../../features/orders/screens/menu_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/tables/screens/table_map_screen.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import '../utils/shell_scaffold.dart';

part 'app_router.g.dart';

// ── Route name constants ──────────────────────────────────────────────────────

abstract class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/admin/staff/new';
  static const profile = '/profile';
  static const changePassword = '/change-password';

  // Main shell
  static const tableMap = '/tables';
  static const kitchen = '/kitchen';
  static const dashboard = '/dashboard';
  static const menuManagement = '/admin/menu';

  // Order flow
  static const newOrder = '/tables/:tableId/order';
  static const orderDetail = '/orders/:orderId';
  static const payment = '/orders/:orderId/payment';
  static const menu = '/tables/:tableId/order/menu';
}

// ── Router provider ───────────────────────────────────────────────────────────

@riverpod
GoRouter appRouter(Ref ref) {
  final authStream = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final isLoading = authStream.isLoading;
      final isLoggedIn = authStream.value != null;
      final loc = state.matchedLocation;

      // Still resolving — stay on splash
      if (isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoginPage = loc == AppRoutes.login;
      final isSplash = loc == AppRoutes.splash;

      if (!isLoggedIn && !isLoginPage) return AppRoutes.login;
      if (isLoggedIn && (isLoginPage || isSplash)) return AppRoutes.tableMap;
      return null;
    },

    refreshListenable: _RouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),

    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth (no bottom nav) ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (_, __) => const ChangePasswordScreen(),
      ),

      // ── Shell (persistent bottom nav) ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tableMap,
            name: 'tableMap',
            builder: (_, __) => const TableMapScreen(),
          ),
          GoRoute(
            path: AppRoutes.kitchen,
            name: 'kitchen',
            builder: (_, __) => const KitchenDisplayScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.menuManagement,
            name: 'menuManagement',
            builder: (_, __) => const MenuManagementScreen(),
          ),
        ],
      ),

      // ── Order flow ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.newOrder,
        name: 'newOrder',
        builder: (_, state) => OrderScreen(
          tableId: state.pathParameters['tableId']!,
        ),
        routes: [
          GoRoute(
            path: 'menu',
            name: 'menu',
            builder: (_, state) => MenuScreen(
              tableId: state.pathParameters['tableId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        name: 'orderDetail',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        builder: (_, state) => PaymentScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            TextButton(
              onPressed: () => context.go(AppRoutes.tableMap),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Role-based navigation extension ──────────────────────────────────────────

extension RoleGuard on StaffRole {
  bool get canViewDashboard => this == StaffRole.admin;
  bool get canManageMenu => this == StaffRole.admin;
  bool get canManageStaff => this == StaffRole.admin;
  bool get canProcessPayments =>
      this == StaffRole.admin || this == StaffRole.cashier;
  bool get canViewKitchen =>
      this == StaffRole.admin || this == StaffRole.kitchen;
}

// ── Stream → Listenable adapter ───────────────────────────────────────────────

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
