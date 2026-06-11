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

/// Offline drop-in for [FirebaseAuthRepository]. Uses hardcoded test accounts.
/// Toggle via [kOfflineMode] in dev_config.dart.
///
/// ⚠️  NEVER ship a release build with kOfflineMode = true.
class OfflineAuthRepository implements AuthRepository {
  OfflineAuthRepository() {
    print('⚠️  BrewDesk: running in OFFLINE / TEST mode — no Firebase auth.');
  }

  // We stream String? (uid) internally and expose a User?-typed stream
  // by wrapping the uid in a minimal UserInfo-compatible object via
  // FirebaseAuth's anonymous sign-in alternative — but since we have no
  // network, we use a StreamController<User?> and emit null for sign-out.
  // For sign-in we emit a cached FirebaseAuth.instance.currentUser after
  // a fake anonymous sign-in, OR simply keep a separate uid stream.
  //
  // Simplest safe approach: keep the uid in memory; expose a stream that
  // emits null (signed out) or a recycled User object via a completer-based
  // bridge. Since only user.uid is accessed by consumers, we proxy via
  // a StreamController<User?> that emits null on sign-out and re-uses a
  // previously fetched real anonymous User on sign-in... but that needs
  // network.
  //
  // Final approach: use a StreamController<User?> and create a minimal
  // User-like wrapper. Dart allows `implements` + `noSuchMethod` on
  // non-sealed classes, which User is not sealed in firebase_auth.
  final _authController = StreamController<User?>.broadcast();
  _SignedInUser? _currentFakeUser;

  @override
  Stream<User?> get authStateChanges => _authController.stream;

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
    _currentFakeUser = _SignedInUser(user.uid, user.email);
    _authController.add(_currentFakeUser);
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
    _currentFakeUser = null;
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
    return Stream.value(
      _kOfflineUsers
          .where((u) => u.uid == uid)
          .map((u) => u.toStaffModel())
          .firstOrNull,
    );
  }
}

// ── Minimal User stub ─────────────────────────────────────────────────────────

/// A minimal [User]-compatible object. Only [uid] and [email] are used by
/// this app's auth flow. All other getters throw if accidentally accessed.
class _SignedInUser extends User {
  _SignedInUser(this._uid, this._email);

  final String _uid;
  final String _email;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  String? get displayName => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo> get providerData => const [];

  @override
  String? get tenantId => null;

  @override
  UserMetadata get metadata => throw UnimplementedError('offline mode');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '_SignedInUser.${invocation.memberName} not implemented in offline mode.',
      );
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
