/// Standard HRMS Permission Codes matching backend auth-service and web frontend
class AppPermissions {
  AppPermissions._();

  // Wildcard
  static const String all = '*';

  // Dashboards
  static const String dashboardGeneralRead = 'dashboard.general.read';
  static const String dashboardEmployeeRead = 'dashboard.employee.read';
  static const String dashboardHrRead = 'dashboard.hr.read';
  static const String dashboardManagerRead = 'dashboard.manager.read';
  static const String dashboardPayrollRead = 'dashboard.payroll.read';
  static const String dashboardOrganizationRead = 'dashboard.organization.read';

  // Employee Management
  static const String employeeRead = 'employee.read';
  static const String employeeCreate = 'employee.create';
  static const String employeeUpdate = 'employee.update';
  static const String employeeDelete = 'employee.delete';
  static const String employeeViewPersonal = 'employee.view_personal';
  static const String employeeViewDocuments = 'employee.view_documents';
  static const String employeeViewSalary = 'employee.view_salary';
  static const String employeeViewBankDetails = 'employee.view_bank_details';
  static const String employeeExport = 'employee.export';

  // Department & Designation & Location
  static const String departmentRead = 'department.read';
  static const String designationRead = 'designation.read';
  static const String locationRead = 'location.read';

  // Attendance
  static const String attendanceRead = 'attendance.read';
  static const String attendanceCreate = 'attendance.create';
  static const String attendanceBreakIn = 'attendance.break.in';
  static const String attendanceBreakOut = 'attendance.break.out';
  static const String attendanceUpdate = 'attendance.update';
  static const String attendanceDelete = 'attendance.delete';
  static const String attendanceApprove = 'attendance.approve';
  static const String attendanceLogRead = 'attendance_log.read';
  static const String attendanceRequestRead = 'attendance_request.read';
  static const String attendanceRequestCreate = 'attendance_request.create';
  static const String attendanceRequestApprove = 'attendance_request.approve';
  static const String attendanceRequestReject = 'attendance_request.reject';
  static const String attendanceRegularizationRead = 'attendance_regularization.read';
  static const String attendanceRegularizationCreate = 'attendance_regularization.create';
  static const String attendanceRegularizationApprove = 'attendance_regularization.approve';
  static const String attendanceRegularizationReject = 'attendance_regularization.reject';
  static const String attendanceConfigRead = 'attendance_config.read';
  static const String attendanceDashboardRead = 'attendance_dashboard.read';

  // Leave Management
  static const String leaveRead = 'leave.read';
  static const String leaveCreate = 'leave.create';
  static const String leaveApply = 'leave.apply';
  static const String leaveCancel = 'leave.cancel';
  static const String leaveApprove = 'leave.approve';
  static const String leaveReject = 'leave.reject';
  static const String leaveBalanceRead = 'leave_balance.read';
  static const String holidayRead = 'holiday.read';
  static const String restrictedLeaveRead = 'restricted_leave.read';
  static const String leaveTypeRead = 'leave_type.read';

  // Payroll & Payslips
  static const String payrollRead = 'payroll.read';
  static const String payrollCreate = 'payroll.create';
  static const String payrollUpdate = 'payroll.update';
  static const String payrollProcess = 'payroll.process';
  static const String payrollApprove = 'payroll.approve';
  static const String payrollDetailsRead = 'payroll.details.read';
  static const String payslipRead = 'payslip.read';
  static const String payslipDownload = 'payslip.download';
  static const String payslipCreate = 'payslip.create';
  static const String payslipGenerate = 'payslip.generate';
  static const String loanRead = 'loan.read';
  static const String loanCreate = 'loan.create';
  static const String loanApprove = 'loan.approve';
  static const String reimbursementRead = 'reimbursement.read';
  static const String reimbursementCreate = 'reimbursement.create';
  static const String reimbursementApprove = 'reimbursement.approve';

  // Shift Management
  static const String shiftRead = 'shift.read';
  static const String shiftCreate = 'shift.create';
  static const String shiftUpdate = 'shift.update';
  static const String shiftAssign = 'shift.assign';
  static const String shiftRosterRead = 'shift_roster.read';
  static const String shiftRequestRead = 'shift_request.read';
  static const String shiftRequestCreate = 'shift_request.create';
  static const String shiftRequestApprove = 'shift_request.approve';
  static const String shiftSwapRead = 'shift_swap.read';
  static const String shiftSwapCreate = 'shift_swap.create';
  static const String shiftSwapApprove = 'shift_swap.approve';
  static const String shiftComplianceRead = 'shift_compliance.read';

  // Helpdesk & Support Tickets
  static const String helpdeskRead = 'helpdesk.read';
  static const String helpdeskCreate = 'helpdesk.create';
  static const String helpdeskUpdate = 'helpdesk.update';
  static const String helpdeskDelete = 'helpdesk.delete';
  static const String helpdeskResolve = 'helpdesk.resolve';
  static const String helpdeskAssign = 'helpdesk.assign';
  static const String helpdeskComment = 'helpdesk.comment';

  // Asset Management
  static const String assetRead = 'asset.read';
  static const String assetCreate = 'asset.create';
  static const String assetUpdate = 'asset.update';
  static const String assetRequestCreate = 'asset_request.create';
  static const String assetRequestRead = 'asset_request.read';
  static const String assetCategoryRead = 'asset_category.read';

  // Recruitment & Documents & Policies
  static const String recruitmentRead = 'recruitment.read';
  static const String onboardingRead = 'onboarding.read';
  static const String documentRead = 'document.read';
  static const String employeeDocumentRead = 'employee_document.read';
  static const String policyRead = 'policy.read';
  static const String exitRead = 'exit.read';
  static const String referralRead = 'referral.read';
  static const String referralCreate = 'referral.create';

  // Notifications
  static const String notificationRead = 'notification.read';
  static const String notificationUpdate = 'notification.update';
  static const String notificationCreate = 'notification.create';
  static const String notificationSend = 'notification.send';

  // Settings & Roles
  static const String settingsRead = 'settings.read';
  static const String settingsUpdate = 'settings.update';
  static const String settingsAboutRead = 'settings.about.read';
  static const String settingsPrivacyPolicyRead = 'settings.privacy_policy.read';
  static const String roleRead = 'role.read';
  static const String roleCreate = 'role.create';
}
