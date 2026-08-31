import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum StatusBadgeType {
  success,
  warning,
  error,
  info,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  factory StatusBadge.fromStatus(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('approved') || s.contains('present') || s.contains('active') || s.contains('clocked_in') || s.contains('completed')) {
      return StatusBadge(label: status ?? 'Active', type: StatusBadgeType.success);
    } else if (s.contains('pending') || s.contains('break') || s.contains('review') || s.contains('late')) {
      return StatusBadge(label: status ?? 'Pending', type: StatusBadgeType.warning);
    } else if (s.contains('rejected') || s.contains('absent') || s.contains('revoked') || s.contains('failed')) {
      return StatusBadge(label: status ?? 'Rejected', type: StatusBadgeType.error);
    }
    return StatusBadge(label: status ?? 'None', type: StatusBadgeType.neutral);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    switch (type) {
      case StatusBadgeType.success:
        bg = AppColors.successLight;
        text = AppColors.success;
        border = AppColors.successBorder;
        break;
      case StatusBadgeType.warning:
        bg = AppColors.warningLight;
        text = AppColors.warning;
        border = AppColors.warningBorder;
        break;
      case StatusBadgeType.error:
        bg = AppColors.errorLight;
        text = AppColors.error;
        border = AppColors.errorBorder;
        break;
      case StatusBadgeType.info:
        bg = AppColors.infoLight;
        text = AppColors.info;
        border = AppColors.infoBorder;
        break;
      case StatusBadgeType.neutral:
        bg = AppColors.surfaceMuted;
        text = AppColors.textSecondary;
        border = AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: text),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: text, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
