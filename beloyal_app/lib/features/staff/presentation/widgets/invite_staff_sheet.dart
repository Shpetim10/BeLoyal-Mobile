import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/staff_controller.dart';
import 'package:intl/intl.dart';

/// Bottom sheet to invite a new staff member.
class InviteStaffSheet extends ConsumerStatefulWidget {
  const InviteStaffSheet({super.key});

  @override
  ConsumerState<InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends ConsumerState<InviteStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await ref
        .read(staffControllerProvider.notifier)
        .inviteStaff(email: _emailCtrl.text.trim(), hireDate: _selectedDate);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite sent successfully.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context); // Close sheet
    } else {
      setState(() => _error = error);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invite Staff',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the email address of the staff member you want to invite. If they already have a BesaHub account, use their existing email.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.errorLight,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email Field
            TextFormField(
              controller: _emailCtrl,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                hintText: 'e.g. staff@restaurant.com',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceDark.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Optional Hire Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Hire Date (Optional)'
                            : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.textMuted
                              : AppColors.textOnDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We’ll send a secure invite link to set a password.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send Invite',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
