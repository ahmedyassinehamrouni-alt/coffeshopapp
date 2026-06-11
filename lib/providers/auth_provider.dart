import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/errors/app_exception.dart';
import '../models/staff_model.dart';
import '../repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Raw Firebase auth state stream ───────────────────────────────────────────

@riverpod
Stream<User?> authState(Ref ref) =>
  ref.watch(authRepositoryProvider).authStateChanges;

// ── Current Firebase user (nullable) ─────────────────────────────────────────

@riverpod
User? currentUser(Ref ref) =>
  ref.watch(authStateProvider).value;

// ── Live StaffModel for the signed-in user ────────────────────────────────────

@riverpod
Stream<StaffModel?> currentStaff(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(authRepositoryProvider).watchStaff(user.uid);
}

// ── Convenience: current role ─────────────────────────────────────────────────

@riverpod
StaffRole? currentRole(Ref ref) =>
  ref.watch(currentStaffProvider).value?.role;

// ── Sign-in notifier ──────────────────────────────────────────────────────────

@riverpod
class SignInNotifier extends _$SignInNotifier {
  @override
  AsyncValue<StaffModel?> build() => const AsyncValue.data(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      return null;
    });
  }

  void reset() => state = const AsyncValue.data(null);
}

// ── Register notifier (admin only) ───────────────────────────────────────────

@riverpod
class RegisterNotifier extends _$RegisterNotifier {
  @override
  AsyncValue<StaffModel?> build() => const AsyncValue.data(null);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
  }) async {
    // Guard: only admins can create new accounts
    final callerRole = ref.read(currentRoleProvider);
    if (callerRole != StaffRole.admin) {
      state = AsyncValue.error(
        const AuthException(
          message: 'Only administrators can create new staff accounts.',
          code: 'permission-denied',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            role: role,
          );
    });
  }

  void reset() => state = const AsyncValue.data(null);
}

// ── Change password notifier ──────────────────────────────────────────────────

@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(authRepositoryProvider).updatePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            ));
  }

  void reset() => state = const AsyncValue.data(null);
}
