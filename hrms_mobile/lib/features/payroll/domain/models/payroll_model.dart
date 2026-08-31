import 'package:intl/intl.dart';

class PayslipModel {
  final String id;
  final String month;
  final String year;
  final String? startDate;
  final String? endDate;
  final String? payslipNumber;
  final String? employeeName;
  final String? employeeCode;
  final String? department;
  final String? designation;
  final double basicSalary;
  final double hra;
  final double allowances;
  final double bonuses;
  final double overtime;
  final double otherEarnings;
  final double grossSalary;
  final double incomeTax;
  final double providentFund;
  final double insurance;
  final double loanDeduction;
  final double lopDeduction;
  final double otherDeductions;
  final double deductions;
  final double netSalary;
  final int attendanceDays;
  final int workingDays;
  final int lopDays;
  final String status;
  final DateTime? paymentDate;
  final Map<String, dynamic>? attendanceSnapshot;

  PayslipModel({
    required this.id,
    required this.month,
    required this.year,
    this.startDate,
    this.endDate,
    this.payslipNumber,
    this.employeeName,
    this.employeeCode,
    this.department,
    this.designation,
    required this.basicSalary,
    this.hra = 0,
    required this.allowances,
    this.bonuses = 0,
    this.overtime = 0,
    this.otherEarnings = 0,
    double? grossSalary,
    this.incomeTax = 0,
    this.providentFund = 0,
    this.insurance = 0,
    this.loanDeduction = 0,
    this.lopDeduction = 0,
    this.otherDeductions = 0,
    required this.deductions,
    required this.netSalary,
    this.attendanceDays = 30,
    this.workingDays = 30,
    this.lopDays = 0,
    this.status = 'PAID',
    this.paymentDate,
    this.attendanceSnapshot,
  }) : grossSalary = grossSalary ?? (basicSalary + hra + allowances + bonuses + overtime + otherEarnings);

  String get periodFormatted => '$month $year';

  String get formattedPeriodRange {
    if (startDate != null && endDate != null && startDate!.isNotEmpty && endDate!.isNotEmpty) {
      try {
        final sDate = DateTime.tryParse(startDate!);
        final eDate = DateTime.tryParse(endDate!);
        if (sDate != null && eDate != null) {
          return '${DateFormat('MMM d').format(sDate)} - ${DateFormat('MMM d, yyyy').format(eDate)}';
        }
      } catch (_) {}
    }
    return '$month $year';
  }

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    final basic = double.tryParse(json['basic_salary']?.toString() ?? json['basic']?.toString() ?? '50000') ?? 50000;
    final hraVal = double.tryParse(json['hra']?.toString() ?? '10000') ?? 10000;
    final allow = double.tryParse(json['allowances']?.toString() ?? json['total_allowances']?.toString() ?? '5000') ?? 5000;
    final bonus = double.tryParse(json['bonuses']?.toString() ?? '0') ?? 0;
    final ot = double.tryParse(json['overtime']?.toString() ?? '0') ?? 0;
    final otherEarn = double.tryParse(json['other_earnings']?.toString() ?? '0') ?? 0;

    final tax = double.tryParse(json['income_tax']?.toString() ?? '2500') ?? 2500;
    final pf = double.tryParse(json['provident_fund']?.toString() ?? '1800') ?? 1800;
    final ins = double.tryParse(json['insurance']?.toString() ?? '700') ?? 700;
    final loan = double.tryParse(json['loan_deduction']?.toString() ?? '0') ?? 0;
    final lop = double.tryParse(json['lop_deduction']?.toString() ?? '0') ?? 0;
    final otherDed = double.tryParse(json['other_deductions']?.toString() ?? '0') ?? 0;

    final totalDed = double.tryParse(json['total_deductions']?.toString() ?? '') ?? (tax + pf + ins + loan + lop + otherDed);
    final gross = double.tryParse(json['gross_salary']?.toString() ?? json['total_earnings']?.toString() ?? '') ?? (basic + hraVal + allow + bonus + ot + otherEarn);
    final net = double.tryParse(json['net_salary']?.toString() ?? json['net']?.toString() ?? '') ?? (gross - totalDed);

    return PayslipModel(
      id: json['id']?.toString() ?? '',
      month: json['month']?.toString() ?? 'January',
      year: json['year']?.toString() ?? '2026',
      startDate: json['start_date']?.toString() ?? '2026-01-26',
      endDate: json['end_date']?.toString() ?? '2026-02-25',
      payslipNumber: json['payslip_number']?.toString() ?? 'PS-202601',
      employeeName: json['employee_name']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      department: json['department']?.toString(),
      designation: json['designation']?.toString(),
      basicSalary: basic,
      hra: hraVal,
      allowances: allow,
      bonuses: bonus,
      overtime: ot,
      otherEarnings: otherEarn,
      grossSalary: gross,
      incomeTax: tax,
      providentFund: pf,
      insurance: ins,
      loanDeduction: loan,
      lopDeduction: lop,
      otherDeductions: otherDed,
      deductions: totalDed,
      netSalary: net,
      attendanceDays: int.tryParse(json['attendance_days']?.toString() ?? '30') ?? 30,
      workingDays: int.tryParse(json['working_days']?.toString() ?? '30') ?? 30,
      lopDays: int.tryParse(json['lop_days']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'PAID',
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString())
          : null,
      attendanceSnapshot: json['attendance_snapshot'] is Map<String, dynamic>
          ? json['attendance_snapshot'] as Map<String, dynamic>
          : null,
    );
  }
}
