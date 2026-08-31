import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/core/network/api_endpoints.dart';
import 'package:hrms_mobile/core/network/api_exception.dart';

void main() {
  group('ApiClient & Endpoints Unit Tests', () {
    test('ApiEndpoints paths match microservice proxy contracts', () {
      expect(ApiEndpoints.login, '/api/auth/tenant/login');
      expect(ApiEndpoints.attendanceClockIn, '/api/attendance/clock-in');
      expect(ApiEndpoints.faceRegister, '/api/attendance/face/register');
      expect(ApiEndpoints.faceVerify, '/api/attendance/face/verify');
      expect(ApiEndpoints.employeeProfileBff('emp-100'), '/api/bff/employee-profile/emp-100');
      expect(ApiEndpoints.payslips, '/api/payroll/payslips');
    });

    test('ApiException formatting', () {
      final exception = ApiException(
        message: 'Tenant authorization expired',
        statusCode: 401,
      );

      expect(exception.statusCode, 401);
      expect(exception.toString(), 'Tenant authorization expired');
    });
  });
}
