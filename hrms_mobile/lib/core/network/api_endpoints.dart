/// API Endpoints corresponding to API Gateway & BFF Microservices routing
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication & Tenant
  static const String login = '/api/auth/tenant/login';
  static const String refreshToken = '/api/auth/tenant/refresh';
  static const String verifySessionOtp = '/api/auth/tenant/verify-session-otp';
  static const String resendSessionOtp = '/api/auth/tenant/resend-session-otp';
  static const String resolveTenant = '/api/auth/tenant/resolve';
  static const String currentUser = '/api/auth/tenant/me';
  static const String userAuthorization = '/api/auth/tenant/authorization';
  static const String permissions = '/api/auth/tenant/permission';
  static const String selectTenant = '/api/auth/tenant/select-tenant';
  static const String switchTenant = '/api/auth/tenant/switch-tenant';
  static const String userOrganizations = '/api/auth/tenant/user-organizations';

  // Attendance & Biometrics
  static const String attendanceToday = '/api/attendance/today';
  static const String attendanceClockIn = '/api/attendance/clock-in';
  static const String attendanceClockOut = '/api/attendance/clock-out';
  static const String attendanceBreakIn = '/api/attendance/break-in';
  static const String attendanceBreakOut = '/api/attendance/break-out';
  static const String attendanceMyLogs = '/api/attendance/my-logs';
  static const String attendanceDashboard = '/api/attendance/dashboard';
  static const String attendanceRegularization = '/api/attendance/regularization';
  
  // Face Recognition
  static const String faceRegister = '/api/attendance/face/register';
  static const String faceEnroll = '/api/attendance/face/enroll';
  static const String faceStatus = '/api/attendance/face/status';
  static const String faceVerify = '/api/attendance/face/verify';
  static const String faceRevoke = '/api/attendance/face/revoke';

  // BFF Aggregated Employee Profile
  static String employeeProfileBff(String employeeId) => '/api/bff/employee-profile/$employeeId';

  // Employee Directory
  static const String employeeList = '/api/employee/get-all';
  static const String departmentList = '/api/employee/department';
  static const String designationList = '/api/employee/designation';

  // Leave Management
  static const String leaveRequests = '/api/leave/requests';
  static const String leaveMyRequests = '/api/leave/my-requests';
  static const String leaveApply = '/api/leave/apply';
  static const String leaveBalances = '/api/leave/balances';
  static const String leaveTypes = '/api/leave/types';
  static const String leaveHolidays = '/api/leave/holidays';
  static const String leaveStats = '/api/leave/stats';
  static String leaveApprove(String id) => '/api/leave/requests/$id/approve';
  static String leaveReject(String id) => '/api/leave/requests/$id/reject';
  static String leaveCancel(String id) => '/api/leave/requests/$id/cancel';

  // Payroll
  static const String payrollDashboard = '/api/payroll/dashboard';
  static const String payslips = '/api/payroll/payslips';
  static String payslipDetail(String id) => '/api/payroll/payslips/$id';
  static String payslipDownload(String id) => '/api/payroll/payslips/$id/download';

  // Shift & Rostering
  static const String shiftAssigned = '/api/shift/assigned-shifts';
  static const String shiftToday = '/api/shift/today-shifts';
  static const String shiftRequests = '/api/shift/shift-request';

  // Helpdesk & Support Tickets
  static const String ticketDashboard = '/api/ticket/dashboard';
  static const String ticketList = '/api/ticket/list';
  static String ticketDetail(String id) => '/api/ticket/detail/$id';
  static const String ticketCreate = '/api/ticket/create';
  static String ticketUpdate(String id) => '/api/ticket/update/$id';
  static String ticketComments(String ticketId) => '/api/ticket/comments/$ticketId';
  static const String ticketFaqs = '/api/ticket/faqs';

  // Tasks & Assets
  static const String taskList = '/api/task';
  static const String assetList = '/api/asset/assets';
  static const String assetMy = '/api/asset/my-assets';
  static const String assetRequests = '/api/asset/requests';

  // Notifications
  static const String notifications = '/api/notification';
  static const String notificationsUnread = '/api/notification/unread';
  static String notificationMarkRead(String id) => '/api/notification/$id/read';
  static const String notificationMarkAllRead = '/api/notification/mark-all-read';

  // Dashboard Aggregations
  static const String dashboardEmployee = '/api/dashboard/employee';
  static const String dashboardGeneral = '/api/dashboard/general';
}
