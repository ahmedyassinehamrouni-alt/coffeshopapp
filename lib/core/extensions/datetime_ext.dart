import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  /// e.g. "14 Jun 2025"
  String get formattedDate => DateFormat('dd MMM yyyy').format(this);

  /// e.g. "14:30"
  String get formattedTime => DateFormat('HH:mm').format(this);

  /// e.g. "14 Jun 2025 · 14:30"
  String get formattedDateTime => '$formattedDate · $formattedTime';

  /// e.g. "2 hours ago" / "just now"
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return formattedDate;
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

extension CurrencyFormatting on num {
  /// e.g. "$12.50"
  String get asCurrency => NumberFormat.currency(symbol: '\$').format(this);

  /// e.g. "12.50"
  String get asDecimal => NumberFormat('#,##0.00').format(this);
}
