import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About HRMS Enterprise'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Icon(Icons.business_center_rounded, size: 42, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('HRMS Enterprise Mobile', style: AppTextStyles.h1),
            const SizedBox(height: 2),
            const Text('Version 1.0.0 (Build 1)', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xxl),

            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Architecture', style: AppTextStyles.bodyBold),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Unified Multi-Tenant Gateway & BFF Integration\n'
                    '• MediaPipe AI Face Biometrics & Geofenced Attendance\n'
                    '• End-to-End Enterprise Encryption with Secure Hardware KeyStore\n'
                    '• Modern Flutter + Riverpod + Clean Architecture',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('© 2026 HRMS Platform Inc. All rights reserved.', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
