import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/bottom_sheet_container.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/leave_model.dart';

class LeaveRequestDetailModal extends StatelessWidget {
  final LeaveRequestModel request;

  const LeaveRequestDetailModal({super.key, required this.request});

  static Future<void> show({
    required BuildContext context,
    required LeaveRequestModel request,
  }) {
    return BottomSheetContainer.show(
      context: context,
      title: 'Leave Request Details',
      child: LeaveRequestDetailModal(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final startDateStr = dateFormat.format(request.startDate);
    final endDateStr = dateFormat.format(request.endDate);
    final requestedOnStr = dateFormat.format(request.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Status Card
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                request.leaveType,
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${request.totalDays.toInt()} ${request.totalDays == 1 ? "Day" : "Days"} Total Duration',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(height: AppSpacing.sm),
              StatusBadge.fromStatus(request.status),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Timeline & Date Schedule
        const Text('Schedule & Timeline', style: AppTextStyles.h3),
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
              _buildRow('From Date', startDateStr, icon: Icons.calendar_today_outlined),
              const Divider(height: AppSpacing.lg),
              _buildRow('To Date', endDateStr, icon: Icons.event_available_outlined),
              const Divider(height: AppSpacing.lg),
              _buildRow('Requested On', requestedOnStr, icon: Icons.access_time_rounded),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Request Details
        const Text('Details & Justification', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason for Leave', style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(
                request.reason.isNotEmpty ? request.reason : 'General personal time off request.',
                style: AppTextStyles.body,
              ),
              const Divider(height: AppSpacing.lg),
              _buildRow('Applicant', request.employeeName, icon: Icons.person_outline_rounded),
              if (request.status == 'APPROVED') ...[
                const Divider(height: AppSpacing.lg),
                _buildRow('Approved By', 'HR Approver', icon: Icons.verified_user_outlined),
              ] else if (request.status == 'REJECTED') ...[
                const Divider(height: AppSpacing.lg),
                _buildRow('Review Note', 'Insufficient department coverage for requested dates', icon: Icons.info_outline),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyBold),
      ],
    );
  }
}
