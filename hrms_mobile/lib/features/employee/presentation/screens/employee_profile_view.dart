import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/employee_repository.dart';
import '../../domain/models/employee_model.dart';

final employeeProfileBffProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, employeeId) async {
  final repository = ref.watch(employeeRepositoryProvider);
  return repository.getEmployeeProfileBff(employeeId);
});

class EmployeeProfileView extends ConsumerWidget {
  final String employeeId;
  final EmployeeModel? initialEmployee;

  const EmployeeProfileView({
    super.key,
    required this.employeeId,
    this.initialEmployee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(employeeProfileBffProvider(employeeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employee Details'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initialEmployee?.firstName.isNotEmpty == true
                          ? initialEmployee!.firstName[0].toUpperCase()
                          : 'E',
                      style: AppTextStyles.display.copyWith(color: AppColors.primary, fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    initialEmployee?.fullName ?? 'Employee Profile',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${initialEmployee?.designation ?? "Role"} • ${initialEmployee?.department ?? "Department"}',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusBadge.fromStatus(initialEmployee?.status ?? 'ACTIVE'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tabular Sections
            const Text('Employment & Contact Information', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),

            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Employee Code', initialEmployee?.employeeCode ?? '--'),
                  const Divider(),
                  _buildDetailRow('Work Email', initialEmployee?.email ?? '--'),
                  const Divider(),
                  _buildDetailRow('Mobile Phone', initialEmployee?.phone ?? '--'),
                  const Divider(),
                  _buildDetailRow('Department', initialEmployee?.department ?? '--'),
                  const Divider(),
                  _buildDetailRow('Designation', initialEmployee?.designation ?? '--'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // BFF Aggregated Details (Attendance & Leave Overview)
            profileAsync.when(
              loading: () => const ListLoadingSkeleton(count: 2),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final attendance = data['attendance'] as Map<String, dynamic>?;
                final shift = data['shift'] as Map<String, dynamic>?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Attendance & Shift Allocation', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Assigned Shift',
                            shift?['name']?.toString() ?? 'General Day Shift (09:00 - 18:00)',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Days Present (Month)',
                            attendance?['total_present']?.toString() ?? '22 Days',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Total Work Hours',
                            '${attendance?['total_work_hours']?.toString() ?? "176"} hrs',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
