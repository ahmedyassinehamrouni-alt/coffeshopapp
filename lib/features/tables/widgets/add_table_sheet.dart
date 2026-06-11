import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/table_model.dart';
import '../../../providers/table_provider.dart';

/// Admin-only sheet for adding a new table.
void showAddTableSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTableSheet(),
  );
}

class _AddTableSheet extends ConsumerStatefulWidget {
  const _AddTableSheet();

  @override
  ConsumerState<_AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends ConsumerState<_AddTableSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  int _capacity = 4;
  TableSection _section = TableSection.indoor;
  String? _errorMessage;

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(tableNotifierProvider.notifier).createTable(
          number: int.parse(_numberCtrl.text.trim()),
          capacity: _capacity,
          section: _section,
        );

    if (mounted) {
      final state = ref.read(tableNotifierProvider);
      if (state is AsyncError) {
        setState(() => _errorMessage = state.error.toString());
      } else if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table ${result.number} added successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableNotifierProvider);
    final isLoading = state.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.caramel.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_restaurant_outlined,
                      color: AppColors.caramel, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Add New Table', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 20),

            // Error
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error),
                ),
              ),

            // Table number
            TextFormField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Table Number',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Table number is required';
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Capacity stepper
            Text('Capacity', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  enabled: _capacity > 1 && !isLoading,
                  onTap: () => setState(() => _capacity--),
                ),
                const SizedBox(width: 12),
                Text('$_capacity ${_capacity == 1 ? 'seat' : 'seats'}',
                    style: AppTextStyles.titleMedium),
                const SizedBox(width: 12),
                _StepButton(
                  icon: Icons.add,
                  enabled: _capacity < 20 && !isLoading,
                  onTap: () => setState(() => _capacity++),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section selector
            Text('Section', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TableSection.values.map((s) {
                final sel = _section == s;
                return GestureDetector(
                  onTap: isLoading ? null : () => setState(() => _section = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.caramel : AppColors.foam,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              sel ? AppColors.caramel : AppColors.divider),
                    ),
                    child: Text(
                      s.displayName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color:
                            sel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                  : const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.caramel.withOpacity(0.1) : AppColors.foam,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.caramel.withOpacity(0.3) : AppColors.divider,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.caramel : AppColors.textHint,
        ),
      ),
    );
  }
}
