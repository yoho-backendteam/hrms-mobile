import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/bottom_sheet_container.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/leave_repository.dart';

class ApplyLeaveBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const ApplyLeaveBottomSheet({super.key, required this.onSuccess});

  static Future<void> show(BuildContext context, {required VoidCallback onSuccess}) {
    return BottomSheetContainer.show(
      context: context,
      title: 'Apply for Leave',
      child: ApplyLeaveBottomSheet(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<ApplyLeaveBottomSheet> createState() =>
      _ApplyLeaveBottomSheetState();
}

class _ApplyLeaveBottomSheetState extends ConsumerState<ApplyLeaveBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Casual Leave';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(leaveRepositoryProvider);
      final ok = await repository.applyLeave(
        leaveType: _selectedType,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          Navigator.of(context).pop();
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Leave application submitted for approval.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: 'Leave Type'),
            items: ['Casual Leave', 'Sick Leave', 'Annual Privilege', 'Compensatory Off']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Start Date'),
                    child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'End Date'),
                    child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          CustomTextField(
            controller: _reasonController,
            label: 'Reason for Leave',
            hint: 'Brief explanation for management review',
            maxLines: 3,
            validator: (v) => v == null || v.isEmpty ? 'Reason is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          PrimaryButton(
            text: 'Submit Application',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
