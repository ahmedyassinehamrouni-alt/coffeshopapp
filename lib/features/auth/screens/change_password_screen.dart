import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    await ref.read(changePasswordNotifierProvider.notifier).changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordNotifierProvider);
    final isLoading = state.isLoading;

    ref.listen(changePasswordNotifierProvider, (_, next) {
      if (next is AsyncError) {
        setState(() {
          _errorMessage = next.error is AppException
              ? (next.error as AppException).message
              : 'Failed to update password.';
        });
      } else if (next is AsyncData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthErrorBanner(message: _errorMessage),

                    AuthTextField(
                      controller: _currentCtrl,
                      label: 'Current Password',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Current password required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    ValueListenableBuilder(
                      valueListenable: _newCtrl,
                      builder: (_, __, ___) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            controller: _newCtrl,
                            label: 'New Password',
                            prefixIcon: Icons.lock_reset_outlined,
                            isPassword: true,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'New password required';
                              if (v.length < 8) return 'Minimum 8 characters';
                              if (v == _currentCtrl.text) {
                                return 'New password must differ from current';
                              }
                              return null;
                            },
                          ),
                          PasswordStrengthIndicator(password: _newCtrl.text),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      controller: _confirmCtrl,
                      label: 'Confirm New Password',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v != _newCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
