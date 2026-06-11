import 'package:equatable/equatable.dart';

/// Base exception for all app-level errors.
abstract class AppException extends Equatable implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

// ── Auth ──────────────────────────────────────────────────────────────────────

class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  factory AuthException.fromFirebaseCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return const AuthException(
          message: 'Invalid email or password.',
          code: 'invalid-credentials',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many attempts. Try again later.',
          code: 'too-many-requests',
        );
      default:
        return AuthException(
          message: 'Authentication failed: $code',
          code: code,
        );
    }
  }
}

// ── Firestore ─────────────────────────────────────────────────────────────────

class FirestoreException extends AppException {
  const FirestoreException({required super.message, super.code});

  factory FirestoreException.permissionDenied() => const FirestoreException(
        message: 'You do not have permission to perform this action.',
        code: 'permission-denied',
      );

  factory FirestoreException.notFound(String resource) => FirestoreException(
        message: '$resource not found.',
        code: 'not-found',
      );
}

// ── Network ───────────────────────────────────────────────────────────────────

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Check your internet connection.',
    super.code = 'network-error',
  });
}

// ── Validation ────────────────────────────────────────────────────────────────

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code = 'validation'});
}

// ── Unknown ───────────────────────────────────────────────────────────────────

class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.code = 'unknown',
  });
}
