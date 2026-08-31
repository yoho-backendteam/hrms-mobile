import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/features/attendance/domain/models/attendance_model.dart';
import 'package:hrms_mobile/features/attendance/domain/models/face_profile_model.dart';

void main() {
  group('Attendance State Machine Tests', () {
    test('Attendance state correctly transitions based on clock in/out & breaks', () {
      // 1. Not started
      final notStarted = AttendanceModel(
        id: 'att-1',
        employeeId: 'emp-1',
        date: '2026-08-29',
      );
      expect(notStarted.state, AttendanceState.notStarted);

      // 2. Clocked In
      final clockedIn = AttendanceModel(
        id: 'att-2',
        employeeId: 'emp-1',
        date: '2026-08-29',
        clockIn: DateTime.parse('2026-08-29 09:00:00'),
      );
      expect(clockedIn.state, AttendanceState.clockedIn);

      // 3. On Break
      final onBreak = AttendanceModel(
        id: 'att-3',
        employeeId: 'emp-1',
        date: '2026-08-29',
        clockIn: DateTime.parse('2026-08-29 09:00:00'),
        breaks: [
          AttendanceBreak(
            id: 'brk-1',
            breakIn: DateTime.parse('2026-08-29 13:00:00'),
            breakOut: null,
          ),
        ],
      );
      expect(onBreak.state, AttendanceState.onBreak);

      // 4. Clocked Out
      final clockedOut = AttendanceModel(
        id: 'att-4',
        employeeId: 'emp-1',
        date: '2026-08-29',
        clockIn: DateTime.parse('2026-08-29 09:00:00'),
        clockOut: DateTime.parse('2026-08-29 18:00:00'),
      );
      expect(clockedOut.state, AttendanceState.clockedOut);
    });

    test('FaceProfileStatusModel correctly parses registration metadata', () {
      final json = {
        'isEnrolled': true,
        'status': 'ACTIVE',
        'enrolledAt': '2026-08-28T10:00:00Z',
        'lastVerifiedAt': '2026-08-29T09:05:00Z',
        'modelName': 'mediapipe-tasks-vision',
      };

      final face = FaceProfileStatusModel.fromJson(json);

      expect(face.isEnrolled, true);
      expect(face.status, 'ACTIVE');
      expect(face.modelName, 'mediapipe-tasks-vision');
      expect(face.enrolledAt, isNotNull);
      expect(face.lastVerifiedAt, isNotNull);
    });
  });
}
