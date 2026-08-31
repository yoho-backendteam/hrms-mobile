import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

final availableFeaturesProvider = Provider<List<String>>((ref) {
  // Can be populated from tenant subscription endpoint
  return [
    'ATTENDANCE_TRACKING',
    'FACE_RECOGNITION_ATTENDANCE',
    'LEAVE_MANAGEMENT',
    'PAYROLL_MANAGEMENT',
    'SHIFT_SCHEDULING',
    'TASK_MANAGEMENT',
    'ASSET_TRACKING',
    'NOTIFICATIONS',
  ];
});

class SubscriptionGuard extends ConsumerWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;

  const SubscriptionGuard({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(availableFeaturesProvider);
    final isEnabled = features.contains(featureKey);

    if (isEnabled) {
      return child;
    }

    return fallback ??
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.warningBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'This feature is not included in your organization subscription plan.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        );
  }
}
