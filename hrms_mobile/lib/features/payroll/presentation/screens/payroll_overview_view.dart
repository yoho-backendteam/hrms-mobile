import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../data/payroll_repository.dart';
import '../../domain/models/payroll_model.dart';
import '../widgets/payroll_period_card.dart';

final payslipsListProvider =
    FutureProvider.autoDispose<List<PayslipModel>>((ref) async {
  final repository = ref.watch(payrollRepositoryProvider);
  return repository.getPayslips();
});

class PayrollOverviewView extends ConsumerStatefulWidget {
  const PayrollOverviewView({super.key});

  @override
  ConsumerState<PayrollOverviewView> createState() => _PayrollOverviewViewState();
}

class _PayrollOverviewViewState extends ConsumerState<PayrollOverviewView> {
  String _selectedMonth = 'All';
  String _selectedYear = '2026';

  final List<String> _months = [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _years = ['2026', '2025', '2024'];

  @override
  Widget build(BuildContext context) {
    final payslipsAsync = ref.watch(payslipsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payroll & Compensation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(payslipsListProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month & Year Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Filter:', style: AppTextStyles.captionBold),
                  const SizedBox(width: AppSpacing.md),

                  // Month Dropdown
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.textPrimary),
                        items: _months.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(height: 20, width: 1, color: AppColors.border),
                  const SizedBox(width: AppSpacing.sm),

                  // Year Dropdown
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: AppColors.textPrimary),
                      items: _years.map((y) {
                        return DropdownMenuItem(value: y, child: Text(y));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payroll Periods', style: AppTextStyles.h2),
                Text(
                  'Showing $_selectedMonth $_selectedYear',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Payslips / Periods List
            payslipsAsync.when(
              loading: () => const ListLoadingSkeleton(count: 3),
              error: (err, _) => Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text('Unable to load payroll runs: $err', style: AppTextStyles.caption),
              ),
              data: (payslips) {
                final filtered = payslips.where((p) {
                  final matchesMonth = _selectedMonth == 'All' ||
                      p.month.toLowerCase() == _selectedMonth.toLowerCase() ||
                      (p.startDate != null && p.startDate!.contains(_selectedMonth.substring(0, 3)));
                  final matchesYear = p.year == _selectedYear ||
                      (p.startDate != null && p.startDate!.startsWith(_selectedYear));
                  return matchesMonth && matchesYear;
                }).toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Payroll Records',
                      description: 'No compensation statements found for the selected period.',
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return PayrollPeriodCard(payslip: item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
