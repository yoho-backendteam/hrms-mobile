import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/features/auth/domain/models/tenant_model.dart';
import 'package:hrms_mobile/features/auth/domain/models/user_model.dart';

void main() {
  group('Auth & UserModel Unit Tests', () {
    test('UserModel parse json with roles and permissions correctly', () {
      final json = {
        'id': 'usr-123',
        'email': 'admin@csktech.com',
        'firstName': 'Sujith',
        'lastName': 'Kumar',
        'role': 'HR',
        'roles': ['HR', 'EMPLOYEE'],
        'permissions': [
          {'code': 'attendance.create'},
          {'code': 'employee.read'},
          'payroll.read',
        ],
        'tenantId': 'ten-456',
        'employeeId': 'emp-789',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr-123');
      expect(user.email, 'admin@csktech.com');
      expect(user.fullName, 'Sujith Kumar');
      expect(user.role, 'HR');
      expect(user.roles, contains('HR'));
      expect(user.permissions, contains('attendance.create'));
      expect(user.permissions, contains('employee.read'));
      expect(user.permissions, contains('payroll.read'));
      expect(user.tenantId, 'ten-456');
    });

    test('TenantModel parses organization information', () {
      final json = {
        'id': 'ten-101',
        'name': 'CSK Technologies',
        'subdomain': 'csktech',
      };

      final tenant = TenantModel.fromJson(json);

      expect(tenant.id, 'ten-101');
      expect(tenant.name, 'CSK Technologies');
      expect(tenant.subdomain, 'csktech');
    });
  });
}
