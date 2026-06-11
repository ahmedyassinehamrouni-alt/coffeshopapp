import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/staff_model.dart';

/// Tappable role selection cards — used on the register screen.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availableRoles = const [StaffRole.waiter, StaffRole.admin],
  });

  final StaffRole selected;
  final ValueChanged<StaffRole> onChanged;
  final List<StaffRole> availableRoles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Row(
          children: availableRoles.map((role) {
            final isSelected = selected == role;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: role != availableRoles.last ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.caramel : AppColors.foam,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.caramel : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconFor(role),
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role.displayName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconFor(StaffRole role) => switch (role) {
    StaffRole.admin => Icons.admin_panel_settings_outlined,
    StaffRole.waiter => Icons.room_service_outlined,
    StaffRole.cashier => Icons.point_of_sale_outlined,
    StaffRole.kitchen => Icons.restaurant_outlined,
  };
}
