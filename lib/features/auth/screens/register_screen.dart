import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/role_selector.dart';

/// Admin-only screen for creating new staff accounts.
/// Accessible via Admin Dashboard → Staff Management.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  StaffRole _selectedRole = StaffRole.waiter;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _success = false;
    });
    if (!_formKey.currentState!.validate()) return;

    await ref.read(registerProvider.notifier).register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          role: _selectedRole,
        );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _confirmCtrl.clear();
    setState(() {
      _selectedRole = StaffRole.waiter;
      _errorMessage = null;
      _success = false;
    });
    ref.read(registerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerProvider);
    final isLoading = state.isLoading;

    ref.listen(registerProvider, (_, next) {
      if (next is AsyncError) {
        setState(() {
          _errorMessage = next.error is AppException
              ? (next.error as AppException).message
              : 'Failed to create account. Please try again.';
          _success = false;
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() => _success = true);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Staff Account'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _success
            ? _SuccessBanner(
                name: _nameCtrl.text,
                role: _selectedRole,
                onCreateAnother: _resetForm,
                onDone: () => Navigator.of(context).pop(),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header info ───────────────────────────────────────────
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.caramel.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_add_outlined,
                                    color: AppColors.caramel, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('New Staff Member',
                                        style: AppTextStyles.titleMedium),
                                    Text(
                                      'An email invitation will be sent automatically.',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Personal info ─────────────────────────────────────────
                    _SectionCard(
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          AuthErrorBanner(message: _errorMessage),
                          AuthTextField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            prefixIcon: Icons.badge_outlined,
                            enabled: !isLoading,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (v.trim().split(' ').length < 2) {
                                return 'Please enter first and last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isLoading,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Role ──────────────────────────────────────────────────
                    _SectionCard(
                      title: 'Role & Permissions',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoleSelector(
                            selected: _selectedRole,
                            onChanged: (r) => setState(() => _selectedRole = r),
                          ),
                          const SizedBox(height: 14),
                          _RolePermissionChips(role: _selectedRole),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password ──────────────────────────────────────────────
                    _SectionCard(
                      title: 'Temporary Password',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The staff member should change this on first login.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          ValueListenableBuilder(
                            valueListenable: _passwordCtrl,
                            builder: (_, __, ___) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AuthTextField(
                                  controller: _passwordCtrl,
                                  label: 'Temporary Password',
                                  prefixIcon: Icons.lock_outlined,
                                  isPassword: true,
                                  enabled: !isLoading,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (v.length < 8) {
                                      return 'Minimum 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                PasswordStrengthIndicator(
                                    password: _passwordCtrl.text),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _confirmCtrl,
                            label: 'Confirm Password',
                            prefixIcon: Icons.lock_outlined,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v != _passwordCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Submit ────────────────────────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Create Staff Account'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Role permission chips ─────────────────────────────────────────────────────

class _RolePermissionChips extends StatelessWidget {
  const _RolePermissionChips({required this.role});
  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final permissions = _permissionsFor(role);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: permissions.map((p) => Chip(
        label: Text(p),
        labelStyle: AppTextStyles.labelSmall,
        backgroundColor: AppColors.caramel.withOpacity(0.08),
        side: BorderSide(color: AppColors.caramel.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )).toList(),
    );
  }

  List<String> _permissionsFor(StaffRole role) => switch (role) {
    StaffRole.admin => [
        'Tables', 'Orders', 'Payments', 'Kitchen', 'Dashboard', 'Menu Mgmt', 'Staff Mgmt',
      ],
    StaffRole.cashier => ['Tables', 'Orders', 'Payments'],
    StaffRole.waiter => ['Tables', 'Orders'],
    StaffRole.kitchen => ['Kitchen Display'],
  };
}

// ── Reusable section card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.titleMedium),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({
    required this.name,
    required this.role,
    required this.onCreateAnother,
    required this.onDone,
  });

  final String name;
  final StaffRole role;
  final VoidCallback onCreateAnother;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 20),
        Text('Account Created!', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '$name has been added as ${role.displayName}.\nA confirmation email has been sent.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: onCreateAnother,
          child: const Text('Add Another Staff Member'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
