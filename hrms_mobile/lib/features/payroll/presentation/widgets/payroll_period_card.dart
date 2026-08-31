import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/payroll_model.dart';
import '../screens/payslip_details_view.dart';

class PayrollPeriodCard extends StatelessWidget {
  final PayslipModel payslip;

  const PayrollPeriodCard({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PayslipDetailsView(payslip: payslip),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Payroll Period',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                StatusBadge.fromStatus(payslip.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Date Range
            Text(
              payslip.formattedPeriodRange,
              style: AppTextStyles.h2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Net Pay Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Net Salary', style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(payslip.netSalary),
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
