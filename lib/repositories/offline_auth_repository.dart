// ignore_for_file: avoid_print
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/staff_model.dart';
import 'auth_repository.dart';

// ── Hardcoded test users ──────────────────────────────────────────────────────

/// All offline test accounts. Email is also the key used for lookup.
const _kOfflineUsers = [
  _OfflineUser(
    uid: 'offline-admin-001',
    name: 'Admin User',
    email: 'admin@brewdesk.test',
    password: 'admin123',
    role: StaffRole.admin,
  ),
  _OfflineUser(
    uid: 'offline-cashier-002',
    name: 'Cashier User',
    email: 'cashier@brewdesk.test',
    password: 'cashier123',
    role: StaffRole.cashier,
  ),
  _OfflineUser(
    uid: 'offline-waiter-003',
    name: 'Waiter User',
    email: 'waiter@brewdesk.test',
    password: 'waiter123',
    role: StaffRole.waiter,
  ),
  _OfflineUser(
    uid: 'offline-kitchen-004',
    name: 'Kitchen User',
    email: 'kitchen@brewdesk.test',
    password: 'kitchen123',
    role: StaffRole.kitchen,
  ),
];

class _OfflineUser {
  const _OfflineUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String password;
  final StaffRole role;

  StaffModel toStaffModel() => StaffModel(
        id: uid,
        name: name,
        email: email,
        role: role,
        isActive: true,
      );
}

// ── Repository ────────────────────────────────────────────────────────────────

/// A fully-offline [AuthRepository] that uses [_kOfflineUsers] instead of
/// Firebase. Drop-in for [FirebaseAuthRepository] during development.
class OfflineAuthRepository implements AuthRepository {
  OfflineAuthRepository() {
    print('⚠️  BrewDesk: running in OFFLINE / TEST mode — no Firebase auth.');
  }

  final _authController = StreamController<User?>.broadcast();
  StaffModel? _currentStaff;

  // The offline repo never produces real Firebase [User] objects.
  // Instead it just emits `null` (signed out) or keeps a fake uid in memory.
  // Consumers that only need the uid can call [fetchStaff] directly.
  @override
  Stream<User?> get authStateChanges => _authController.stream;

  @override
  Future<StaffModel> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate a tiny network delay so loading states are visible
    await Future.delayed(const Duration(milliseconds: 400));

    final match = _kOfflineUsers.where(
      (u) =>
          u.email.toLowerCase() == email.trim().toLowerCase() &&
          u.password == password,
    );

    if (match.isEmpty) {
      throw const AuthException(
        message: 'Invalid email or password.',
        code: 'wrong-password',
      );
    }

    _currentStaff = match.first.toStaffModel();
    // Emit a fake non-null signal on the stream so consumers know someone
    // signed in. We reuse the uid string as a placeholder.
    _authController.add(_FakeUser(match.first.uid));
    return _currentStaff!;
  }

  @override
  Future<StaffModel> register({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
  }) async {
    throw const AuthException(
      message: 'Registration is disabled in offline / test mode.',
      code: 'offline-mode',
    );
  }

  @override
  Future<void> signOut() async {
    _currentStaff = null;
    _authController.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthException(
      message: 'Password reset is not available in offline / test mode.',
      code: 'offline-mode',
    );
  }

  @override
  Future<void> updateDisplayName(String name) async {
    // No-op in offline mode
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw const AuthException(
      message: 'Password change is not available in offline / test mode.',
      code: 'offline-mode',
    );
  }

  @override
  Future<StaffModel?> fetchStaff(String uid) async {
    final match = _kOfflineUsers.where((u) => u.uid == uid);
    return match.isEmpty ? null : match.first.toStaffModel();
  }

  @override
  Stream<StaffModel?> watchStaff(String uid) {
    // Return a one-shot stream with the staff model (no live updates needed)
    return Stream.value(
      _kOfflineUsers.where((u) => u.uid == uid).map((u) => u.toStaffModel()).firstOrNull,
    );
  }
}

// ── Fake Firebase User stub ───────────────────────────────────────────────────

/// Minimal stub that satisfies [User?] stream consumers needing only [uid].
class _FakeUser implements User {
  const _FakeUser(this.uid);

  @override
  final String uid;

  // All other members are unused by this app — throw to surface accidental use.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '_FakeUser: ${invocation.memberName} is not implemented in offline mode.',
      );
}

// ── Public accessor for test credentials ─────────────────────────────────────

/// Exposes the list of offline test accounts so the UI can render quick-fill
/// buttons without duplicating the credential list.
List<OfflineTestCredential> get offlineTestCredentials => _kOfflineUsers
    .map((u) => OfflineTestCredential(
          email: u.email,
          password: u.password,
          role: u.role,
          displayName: u.name,
        ))
    .toList();

class OfflineTestCredential {
  const OfflineTestCredential({
    required this.email,
    required this.password,
    required this.role,
    required this.displayName,
  });

  final String email;
  final String password;
  final StaffRole role;
  final String displayName;
}
