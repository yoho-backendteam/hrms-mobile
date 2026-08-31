String _extractLeaveTypeName(dynamic raw) {
  if (raw == null) return 'Casual Leave';
  if (raw is Map) {
    return raw['name']?.toString() ??
        raw['leave_type_name']?.toString() ??
        raw['type']?.toString() ??
        raw['code']?.toString() ??
        'Casual Leave';
  }
  final str = raw.toString().trim();
  if (str.isEmpty) return 'Casual Leave';
  // If it's a stringified map representation like "{id: ..., name: Sick Leave}"
  if (str.startsWith('{') && str.contains('name:')) {
    final match = RegExp(r'name:\s*([^,}]+)').firstMatch(str);
    if (match != null) return match.group(1)?.trim() ?? 'Casual Leave';
  }
  // If it's a raw UUID string, fallback to readable title
  if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(str)) {
    return 'Leave Request';
  }
  return str;
}

class LeaveBalanceModel {
  final String leaveType;
  final double totalAllocated;
  final double used;
  final double remaining;

  LeaveBalanceModel({
    required this.leaveType,
    required this.totalAllocated,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['leave_type'] ??
        json['leave_type_name'] ??
        json['name'] ??
        json['type'];

    return LeaveBalanceModel(
      leaveType: _extractLeaveTypeName(rawType),
      totalAllocated: double.tryParse(json['total']?.toString() ?? json['allocated']?.toString() ?? json['total_days']?.toString() ?? '12') ?? 12,
      used: double.tryParse(json['used']?.toString() ?? json['used_days']?.toString() ?? '0') ?? 0,
      remaining: double.tryParse(json['remaining']?.toString() ?? json['balance']?.toString() ?? json['remaining_days']?.toString() ?? '10') ?? 10,
    );
  }
}

class LeaveRequestModel {
  final String id;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String reason;
  final String status;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['leave_type'] ??
        json['leave_type_name'] ??
        json['name'] ??
        json['type'];

    return LeaveRequestModel(
      id: json['id']?.toString() ?? '',
      employeeName: json['employee'] is Map
          ? '${json['employee']['first_name']} ${json['employee']['last_name']}'
          : json['employee_name']?.toString() ?? 'Self',
      leaveType: _extractLeaveTypeName(rawType),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : (json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now()),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : (json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now() : DateTime.now()),
      totalDays: double.tryParse(json['total_days']?.toString() ?? json['totalDays']?.toString() ?? '1') ?? 1,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }
}

class HolidayModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isRecurring;
  final bool isActive;

  HolidayModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    this.isRecurring = false,
    this.isActive = true,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Public Holiday',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : (json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now()),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : (json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now() : DateTime.now()),
      description: json['description']?.toString(),
      isRecurring: json['is_recurring'] == true || json['isRecurring'] == true,
      isActive: json['is_active'] != false && json['isActive'] != false,
    );
  }
}

