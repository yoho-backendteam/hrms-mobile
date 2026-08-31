import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/bottom_sheet_container.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/helpdesk_repository.dart';

class CreateTicketModal extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const CreateTicketModal({super.key, this.onSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return BottomSheetContainer.show(
      context: context,
      title: 'Submit Support Ticket',
      child: CreateTicketModal(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<CreateTicketModal> createState() => _CreateTicketModalState();
}

class _CreateTicketModalState extends ConsumerState<CreateTicketModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'IT & Workstation Hardware';
  String _selectedPriority = 'MEDIUM';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'IT & Workstation Hardware',
    'Software & Access Permissions',
    'Payroll & Compensation Inquiry',
    'Leave & Attendance Adjustment',
    'HR Policies & Employee Relations',
    'Office Facilities & Workplace',
  ];

  final List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(helpdeskRepositoryProvider);
      await repo.createTicket(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Support ticket submitted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Selector
          const Text('Category', style: AppTextStyles.captionBold),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat, style: AppTextStyles.body));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Priority Selector
          const Text('Priority Level', style: AppTextStyles.captionBold),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: _priorities.map((p) {
              final isSelected = _selectedPriority == p;
              Color color;
              if (p == 'URGENT' || p == 'HIGH') {
                color = AppColors.error;
              } else if (p == 'MEDIUM') {
                color = AppColors.warning;
              } else {
                color = AppColors.info;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPriority = p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Text(
                      p,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionBold.copyWith(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Subject / Title
          CustomTextField(
            label: 'Subject / Title',
            hint: 'Brief summary of the issue...',
            controller: _titleController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter ticket subject' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Detailed Description
          CustomTextField(
            label: 'Detailed Description',
            hint: 'Explain what happened and what assistance is needed...',
            controller: _descController,
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please provide a detailed description' : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          PrimaryButton(
            text: _isSubmitting ? 'Submitting Ticket...' : 'Submit Support Ticket',
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            isLoading: _isSubmitting,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
