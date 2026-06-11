import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum PasswordStrength { empty, weak, fair, strong, veryStrong }

extension PasswordStrengthX on PasswordStrength {
  String get label => switch (this) {
    PasswordStrength.empty => '',
    PasswordStrength.weak => 'Weak',
    PasswordStrength.fair => 'Fair',
    PasswordStrength.strong => 'Strong',
    PasswordStrength.veryStrong => 'Very strong',
  };

  Color get color => switch (this) {
    PasswordStrength.empty => Colors.transparent,
    PasswordStrength.weak => AppColors.error,
    PasswordStrength.fair => AppColors.warning,
    PasswordStrength.strong => AppColors.info,
    PasswordStrength.veryStrong => AppColors.success,
  };

  double get fraction => switch (this) {
    PasswordStrength.empty => 0,
    PasswordStrength.weak => 0.25,
    PasswordStrength.fair => 0.5,
    PasswordStrength.strong => 0.75,
    PasswordStrength.veryStrong => 1,
  };
}

PasswordStrength evaluateStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]'))) score++;

  return switch (score) {
    0 || 1 => PasswordStrength.weak,
    2 => PasswordStrength.fair,
    3 => PasswordStrength.strong,
    _ => PasswordStrength.veryStrong,
  };
}

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = evaluateStrength(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength.fraction,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(strength.color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Password strength: ',
              style: AppTextStyles.labelSmall,
            ),
            Text(
              strength.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: strength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (strength == PasswordStrength.weak || strength == PasswordStrength.fair)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Try adding uppercase letters, numbers, or symbols.',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
            ),
          ),
      ],
    );
  }
}
