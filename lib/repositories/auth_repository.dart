import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/staff_model.dart';

part 'auth_repository.g.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class AuthRepository {
  /// Sign in with email + password. Returns the resulting [StaffModel].
  Future<StaffModel> signIn({
    required String email,
    required String password,
  });

  /// Register a new staff member. Only callable by admins.
  /// Creates a Firebase Auth user and a Firestore staff document atomically.
  Future<StaffModel> register({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password-reset email.
  Future<void> sendPasswordReset(String email);

  /// Update the display name of the currently signed-in user.
  Future<void> updateDisplayName(String name);

  /// Update password for currently signed-in user (requires recent login).
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Stream of the currently signed-in Firebase user.
  Stream<User?> get authStateChanges;

  /// Fetch the [StaffModel] for [uid] from Firestore.
  Future<StaffModel?> fetchStaff(String uid);

  /// Live stream of the [StaffModel] for [uid].
  Stream<StaffModel?> watchStaff(String uid);
}

// ── Firebase implementation ───────────────────────────────────────────────────

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── Auth state ──────────────────────────────────────────────────────────────

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign in ─────────────────────────────────────────────────────────────────

  @override
  Future<StaffModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final staff = await fetchStaff(credential.user!.uid);

      if (staff == null) {
        await _auth.signOut();
        throw const FirestoreException(
          message: 'Staff profile not found. Contact your administrator.',
          code: 'staff-not-found',
        );
      }

      if (!staff.isActive) {
        await _auth.signOut();
        throw const AuthException(
          message: 'Your account has been deactivated. Contact your administrator.',
          code: 'account-deactivated',
        );
      }

      return staff;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    }
  }

  // ── Register ────────────────────────────────────────────────────────────────

  @override
  Future<StaffModel> register({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user!.updateDisplayName(name.trim());

      // Build the Firestore staff document
      final staff = StaffModel(
        id: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        isActive: true,
      );

      // Write to Firestore
      await _firestore
          .doc(FirestorePaths.staffDoc(staff.id))
          .set(staff.toFirestore());

      return staff;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    }
  }

  // ── Password reset ───────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    }
  }

  // ── Update display name ──────────────────────────────────────────────────────

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(message: 'Not signed in.', code: 'not-signed-in');
    try {
      await user.updateDisplayName(name.trim());
      await _firestore
          .doc(FirestorePaths.staffDoc(user.uid))
          .update({'name': name.trim()});
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    }
  }

  // ── Update password ──────────────────────────────────────────────────────────

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(message: 'Not signed in.', code: 'not-signed-in');
    try {
      // Re-authenticate before sensitive change
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code);
    }
  }

  // ── Firestore helpers ────────────────────────────────────────────────────────

  @override
  Future<StaffModel?> fetchStaff(String uid) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.staffDoc(uid)).get();
      if (!doc.exists) return null;
      return StaffModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirestoreException.permissionDenied();
      }
      throw FirestoreException(message: e.message ?? 'Firestore error', code: e.code);
    }
  }

  @override
  Stream<StaffModel?> watchStaff(String uid) {
    return _firestore
        .doc(FirestorePaths.staffDoc(uid))
        .snapshots()
        .map((snap) => snap.exists ? StaffModel.fromFirestore(snap) : null);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) =>
    FirebaseAuthRepository();
