enum AttendanceState {
  notStarted,
  clockedIn,
  onBreak,
  clockedOut,
}

class AttendanceBreak {
  final String id;
  final DateTime? breakIn;
  final DateTime? breakOut;
  final String? breakType;
  final int? durationMinutes;

  AttendanceBreak({
    required this.id,
    this.breakIn,
    this.breakOut,
    this.breakType,
    this.durationMinutes,
  });

  factory AttendanceBreak.fromJson(Map<String, dynamic> json) {
    final rawIn = json['break_in'] ?? json['breakIn'] ?? json['start_time'] ?? json['startTime'];
    final rawOut = json['break_out'] ?? json['breakOut'] ?? json['end_time'] ?? json['endTime'];

    return AttendanceBreak(
      id: json['id']?.toString() ?? '',
      breakIn: rawIn != null ? DateTime.tryParse(rawIn.toString()) : null,
      breakOut: rawOut != null ? DateTime.tryParse(rawOut.toString()) : null,
      breakType: json['break_type']?.toString() ?? json['breakType']?.toString() ?? 'lunch',
      durationMinutes: int.tryParse(
        json['duration_minutes']?.toString() ??
        json['durationMinutes']?.toString() ??
        json['durations']?.toString() ??
        '',
      ),
    );
  }
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final String date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String status;
  final String? attendanceState;
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final List<AttendanceBreak> breaks;
  final bool isRegularized;
  final dynamic location;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status = 'PRESENT',
    this.attendanceState,
    this.totalWorkMinutes = 0,
    this.totalBreakMinutes = 0,
    this.breaks = const [],
    this.isRegularized = false,
    this.location,
  });

  AttendanceState get state {
    if (clockIn == null) return AttendanceState.notStarted;
    if (clockOut != null) return AttendanceState.clockedOut;
    final hasActiveBreak = breaks.any((b) => b.breakIn != null && b.breakOut == null);
    if (hasActiveBreak || attendanceState == 'ON_BREAK' || attendanceState == 'on_break') {
      return AttendanceState.onBreak;
    }
    return AttendanceState.clockedIn;
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    List<AttendanceBreak> parsedBreaks = [];
    final rawBreaks = json['breaks'];
    if (rawBreaks is List) {
      parsedBreaks = rawBreaks
          .map((b) => AttendanceBreak.fromJson(b is Map<String, dynamic> ? b : {}))
          .toList();
    }

    final rawClockIn = json['clock_in'] ?? json['clockIn'] ?? json['check_in'] ?? json['checkIn'];
    final rawClockOut = json['clock_out'] ?? json['clockOut'] ?? json['check_out'] ?? json['checkOut'];

    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? '',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().split('T').first,
      clockIn: rawClockIn != null ? DateTime.tryParse(rawClockIn.toString()) : null,
      clockOut: rawClockOut != null ? DateTime.tryParse(rawClockOut.toString()) : null,
      status: json['status']?.toString() ?? 'PRESENT',
      attendanceState: json['attendance_state']?.toString() ?? json['attendanceState']?.toString() ?? json['state']?.toString(),
      totalWorkMinutes: int.tryParse(
        json['total_work_minutes']?.toString() ?? json['totalWorkMinutes']?.toString() ?? '',
      ) ?? 0,
      totalBreakMinutes: int.tryParse(
        json['total_break_minutes']?.toString() ?? json['totalBreakMinutes']?.toString() ?? '',
      ) ?? 0,
      breaks: parsedBreaks,
      isRegularized: json['is_regularized'] == true || json['isRegularized'] == true,
      location: json['location'],
    );
  }
}
