import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/core/permissions/permission_gate.dart';
import 'package:hrms_mobile/features/auth/domain/models/user_model.dart';
import 'package:hrms_mobile/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('PermissionGate Widget Tests', () {
    testWidgets('Renders child when user has required permission', (tester) async {
      final user = UserModel(
        id: 'usr-1',
        email: 'hr@csktech.com',
        permissions: ['employee.read', 'attendance.create'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => FakeAuthController(user)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: 'employee.read',
                fallback: Text('Access Denied'),
                child: Text('Authorized Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Authorized Content'), findsOneWidget);
      expect(find.text('Access Denied'), findsNothing);
    });

    testWidgets('Renders fallback when user lacks required permission', (tester) async {
      final user = UserModel(
        id: 'usr-2',
        email: 'emp@csktech.com',
        permissions: ['attendance.create'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => FakeAuthController(user)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: 'employee.delete',
                fallback: Text('Access Denied'),
                child: Text('Authorized Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Authorized Content'), findsNothing);
    });
  });
}

class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController(UserModel user)
      : super(AuthState(status: AuthStatus.authenticated, user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
