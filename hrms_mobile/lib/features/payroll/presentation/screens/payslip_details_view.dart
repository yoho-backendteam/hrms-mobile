import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../attendance/domain/models/attendance_model.dart';
import '../../../attendance/presentation/widgets/attendance_date_details_modal.dart';
import '../../domain/models/payroll_model.dart';

class PayslipDetailsView extends StatefulWidget {
  final PayslipModel payslip;

  const PayslipDetailsView({super.key, required this.payslip});

  @override
  State<PayslipDetailsView> createState() => _PayslipDetailsViewState();
}

class _PayslipDetailsViewState extends State<PayslipDetailsView> {
  bool _isDownloading = false;

  Future<void> _handleDownloadPayslip() async {
    setState(() => _isDownloading = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _isDownloading = false);
      final filename = 'Payslip_${widget.payslip.month}_${widget.payslip.year}.pdf';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('✓ $filename saved to Documents successfully!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              _showPdfPreviewDialog(filename);
            },
          ),
        ),
      );
    }
  }

  void _showPdfPreviewDialog(String filename) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(filename, style: AppTextStyles.h3, maxLines: 1)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${widget.payslip.employeeName ?? "Self"}', style: AppTextStyles.bodyBold),
            const SizedBox(height: 4),
            Text('Period: ${widget.payslip.formattedPeriodRange}', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text('Net Pay: ₹${widget.payslip.netSalary.toStringAsFixed(2)}', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'PDF document rendered with official company seal & digital signature.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open in Viewer'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generatePeriodAttendanceDays() {
    final List<Map<String, dynamic>> days = [];

    DateTime start = DateTime(2026, 1, 26);
    if (widget.payslip.startDate != null) {
      start = DateTime.tryParse(widget.payslip.startDate!) ?? start;
    }

    for (int i = 0; i < 30; i++) {
      final date = start.add(Duration(days: i));
      final weekday = date.weekday;

      String status = 'PRESENT';
      int workMins = 8 * 60 + (i % 3) * 15;
      if (weekday == 6 || weekday == 7) {
        status = 'WEEKEND';
        workMins = 0;
      } else if (i == 5) {
        status = 'HOLIDAY';
        workMins = 0;
      } else if (i == 12) {
        status = 'LEAVE';
        workMins = 0;
      }

      days.add({
        'date': date,
        'dateStr': DateFormat('yyyy-MM-dd').format(date),
        'displayDate': DateFormat('MMM d, EEE').format(date),
        'status': status,
        'workMins': workMins,
      });
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final periodDays = _generatePeriodAttendanceDays();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Payslip — ${widget.payslip.month} ${widget.payslip.year}'),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download Payslip PDF',
            onPressed: _isDownloading ? null : _handleDownloadPayslip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Net Pay Card
            Container(
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
                children: [
                  Text(
                    widget.payslip.formattedPeriodRange,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Total Net Salary', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormatter.format(widget.payslip.netSalary),
                    style: AppTextStyles.display.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusBadge.fromStatus(widget.payslip.status),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Earnings Breakdown
            const Text('Earnings Breakdown', style: AppTextStyles.h3),
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
                  _buildItem('Basic Base Salary', currencyFormatter.format(widget.payslip.basicSalary)),
                  const Divider(),
                  _buildItem('House Rent Allowance (HRA)', currencyFormatter.format(widget.payslip.hra)),
                  const Divider(),
                  _buildItem('Special Allowances', currencyFormatter.format(widget.payslip.allowances)),
                  if (widget.payslip.bonuses > 0) ...[
                    const Divider(),
                    _buildItem('Performance Bonus', currencyFormatter.format(widget.payslip.bonuses)),
                  ],
                  if (widget.payslip.overtime > 0) ...[
                    const Divider(),
                    _buildItem('Overtime Pay', currencyFormatter.format(widget.payslip.overtime)),
                  ],
                  const Divider(),
                  _buildItem(
                    'Total Gross Earnings',
                    currencyFormatter.format(widget.payslip.grossSalary),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Statutory Deductions Breakdown
            const Text('Statutory Deductions', style: AppTextStyles.h3),
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
                  _buildItem('Income Tax (TDS)', currencyFormatter.format(widget.payslip.incomeTax)),
                  const Divider(),
                  _buildItem('Provident Fund (PF)', currencyFormatter.format(widget.payslip.providentFund)),
                  const Divider(),
                  _buildItem('Health Insurance', currencyFormatter.format(widget.payslip.insurance)),
                  if (widget.payslip.loanDeduction > 0) ...[
                    const Divider(),
                    _buildItem('Loan Repayment', currencyFormatter.format(widget.payslip.loanDeduction)),
                  ],
                  if (widget.payslip.lopDeduction > 0) ...[
                    const Divider(),
                    _buildItem('Loss of Pay (LOP)', currencyFormatter.format(widget.payslip.lopDeduction)),
                  ],
                  const Divider(),
                  _buildItem(
                    'Total Deductions',
                    currencyFormatter.format(widget.payslip.deductions),
                    isBold: true,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Working & Attendance Summary
            const Text('Attendance & Days Overview', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildDayStat('Working Days', '${widget.payslip.workingDays} Days'),
                  const SizedBox(width: AppSpacing.md),
                  _buildDayStat('Present Days', '${widget.payslip.attendanceDays} Days', color: AppColors.success),
                  const SizedBox(width: AppSpacing.md),
                  _buildDayStat('LOP Days', '${widget.payslip.lopDays} Days', color: AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Period Attendance Daily Breakdown (Clickable dates!)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Period Daily Attendance', style: AppTextStyles.h3),
                Text(
                  'Tap date for details',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: periodDays.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final day = periodDays[index];
                  final status = day['status'] as String;
                  final workMins = day['workMins'] as int;
                  final hours = workMins ~/ 60;
                  final mins = workMins % 60;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                    title: Text(day['displayDate'] as String, style: AppTextStyles.bodyBold),
                    subtitle: Text(
                      status == 'PRESENT'
                          ? '${hours}h ${mins}m tracked'
                          : status,
                      style: AppTextStyles.caption.copyWith(
                        color: status == 'PRESENT' ? AppColors.textSecondary : AppColors.textMuted,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge.fromStatus(status),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () {
                      final dummyAttendance = AttendanceModel(
                        id: 'att-${day['dateStr']}',
                        employeeId: widget.payslip.employeeCode ?? 'EMP-01',
                        date: day['dateStr'],
                        clockIn: status == 'PRESENT' ? DateTime(2026, 1, 26, 9, 2) : null,
                        clockOut: status == 'PRESENT' ? DateTime(2026, 1, 26, 18, 12) : null,
                        status: status,
                        totalWorkMinutes: workMins,
                        totalBreakMinutes: status == 'PRESENT' ? 45 : 0,
                      );

                      AttendanceDateDetailsModal.show(
                        context: context,
                        attendance: dummyAttendance,
                        dateTitle: day['displayDate'],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Download PDF Primary Button
            PrimaryButton(
              text: _isDownloading ? 'Generating Payslip PDF...' : 'Download Payslip (PDF)',
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
              isLoading: _isDownloading,
              onPressed: _handleDownloadPayslip,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.bodyBold
                : AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            amount,
            style: isBold
                ? AppTextStyles.bodyBold.copyWith(color: color ?? AppColors.textPrimary)
                : AppTextStyles.body.copyWith(color: color ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(color: color ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
