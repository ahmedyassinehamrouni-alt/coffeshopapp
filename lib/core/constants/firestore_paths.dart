/// Centralised Firestore collection/document path constants.
/// Never use raw strings for Firestore paths — always reference this class.
abstract class FirestorePaths {
  // ── Collections ──────────────────────────────────────────────────────────
  static const String tables = 'tables';
  static const String orders = 'orders';
  static const String menuItems = 'menuItems';
  static const String payments = 'payments';
  static const String staff = 'staff';

  // ── Document helpers ──────────────────────────────────────────────────────
  static String tableDoc(String tableId) => '$tables/$tableId';
  static String orderDoc(String orderId) => '$orders/$orderId';
  static String menuItemDoc(String itemId) => '$menuItems/$itemId';
  static String paymentDoc(String paymentId) => '$payments/$paymentId';
  static String staffDoc(String staffId) => '$staff/$staffId';
}
