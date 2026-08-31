class ShiftModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String? description;
  final bool isDefault;

  ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.description,
    this.isDefault = false,
  });

  String get timeRange => '$startTime - $endTime';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General Shift',
      startTime: json['start_time']?.toString() ?? json['startTime']?.toString() ?? '09:00 AM',
      endTime: json['end_time']?.toString() ?? json['endTime']?.toString() ?? '06:00 PM',
      description: json['description']?.toString(),
      isDefault: json['is_default'] == true,
    );
  }
}
