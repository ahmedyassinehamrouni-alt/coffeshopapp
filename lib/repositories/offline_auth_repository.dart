// ignore_for_file: avoid_print
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/staff_model.dart';
import 'auth_repository.dart';

// ── Hardcoded test users ──────────────────────────────────────────────────────

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

/// Offline drop-in for [FirebaseAuthRepository].
/// Toggle via [kOfflineMode] in dev_config.dart.
/// ⚠️  NEVER ship a release build with kOfflineMode = true.
class OfflineAuthRepository implements AuthRepository {
  OfflineAuthRepository() {
    print('⚠️  BrewDesk: running in OFFLINE / TEST mode — no Firebase auth.');
  }

  // We keep a separate uid stream (String?) and bridge to User? by watching
  // FirebaseAuth anonymous sign-ins — but since we have no network in offline
  // mode, we instead keep the signed-in user as a StaffModel and expose
  // authStateChanges as a stream that emits a sentinel non-null User when
  // signed in and null when signed out.
  //
  // The only field ever accessed on the User object is .uid (see auth_provider.dart).
  // We use FirebaseAuth.instance.signInAnonymously() as a real User source,
  // OR simply never emit a real User and instead override watchStaff to use
  // our internal uid directly.
  //
  // Chosen approach: internal uid-based stream; override watchStaff and
  // currentStaff to bypass User entirely by watching the uid stream.

  final _uidController = StreamController<String?>.broadcast();
  String? _currentUid;

  /// Exposes a fake User?-typed stream by mapping our internal uid stream.
  /// Emits null when signed out. When signed in, emits a FirebaseAuth
  /// anonymous User (requires no network — uses cached credential).
  ///
  /// Since User cannot be instantiated directly, we store the uid separately
  /// and make watchStaff/fetchStaff work off our uid, not the User object.
  /// The authStateChanges stream simply emits null (signed-out sentinel) and
  /// a non-null cached User for signed-in state via anonymous auth.
  @override
  Stream<User?> get authStateChanges => _uidController.stream.asyncMap(
        (uid) async {
          if (uid == null) return null;
          // Return a cached anonymous Firebase user just as a non-null sentinel.
          // Only .uid is read downstream, and we intercept watchStaff by uid.
          try {
            final cred =
                await FirebaseAuth.instance.signInAnonymously();
            return cred.user;
          } catch (_) {
            // If Firebase is unreachable (pure offline), return null.
            // The app will stay on the login screen.
            return null;
          }
        },
      );

  @override
  Future<StaffModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final matches = _kOfflineUsers.where(
      (u) =>
          u.email.toLowerCase() == email.trim().toLowerCase() &&
          u.password == password,
    );

    if (matches.isEmpty) {
      throw const AuthException(
        message: 'Invalid email or password.',
        code: 'wrong-password',
      );
    }

    final user = matches.first;
    _currentUid = user.uid;
    _uidController.add(user.uid);
    return user.toStaffModel();
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
    _currentUid = null;
    _uidController.add(null);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthException(
      message: 'Password reset not available in offline / test mode.',
      code: 'offline-mode',
    );
  }

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw const AuthException(
      message: 'Password change not available in offline / test mode.',
      code: 'offline-mode',
    );
  }

  @override
  Future<StaffModel?> fetchStaff(String uid) async {
    // uid may be the offline uid OR an anonymous Firebase uid — check both
    final byOfflineUid = _kOfflineUsers.where((u) => u.uid == uid);
    if (byOfflineUid.isNotEmpty) return byOfflineUid.first.toStaffModel();
    // Fall back to current session uid
    if (_currentUid != null) {
      final byCurrent = _kOfflineUsers.where((u) => u.uid == _currentUid);
      if (byCurrent.isNotEmpty) return byCurrent.first.toStaffModel();
    }
    return null;
  }

  @override
  Stream<StaffModel?> watchStaff(String uid) {
    // Same uid resolution as fetchStaff
    final byOfflineUid =
        _kOfflineUsers.where((u) => u.uid == uid).map((u) => u.toStaffModel());
    if (byOfflineUid.isNotEmpty) return Stream.value(byOfflineUid.first);
    if (_currentUid != null) {
      final byCurrent = _kOfflineUsers
          .where((u) => u.uid == _currentUid)
          .map((u) => u.toStaffModel());
      if (byCurrent.isNotEmpty) return Stream.value(byCurrent.first);
    }
    return const Stream.empty();
  }
}

// ── Public credential list (for quick-fill UI) ────────────────────────────────

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
