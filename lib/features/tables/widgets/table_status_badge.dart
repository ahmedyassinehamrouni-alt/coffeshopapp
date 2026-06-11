import 'package:flutter/material.dart';

import '../../../models/table_model.dart';
import '../../../core/theme/app_theme.dart';

/// Compact animated status badge.
/// Occupied tables show a subtle pulse on their dot.
class TableStatusBadge extends StatefulWidget {
  const TableStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final TableStatus status;

  /// When true, shows only the colored dot (no label text).
  final bool compact;

  @override
  State<TableStatusBadge> createState() => _TableStatusBadgeState();
}

class _TableStatusBadgeState extends State<TableStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.status == TableStatus.occupied) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TableStatusBadge old) {
    super.didUpdateWidget(old);
    if (widget.status == TableStatus.occupied) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.status.color;

    final dot = widget.status == TableStatus.occupied
        ? ScaleTransition(
            scale: _pulse,
            child: _dot(color),
          )
        : _dot(color);

    if (widget.compact) return dot;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.status.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 5),
          Text(
            widget.status.displayName,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
