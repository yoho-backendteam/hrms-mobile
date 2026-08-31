class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final String? assigneeName;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.dueDate,
    this.assigneeName,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString(),
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'PENDING',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      assigneeName: json['assignee'] is Map
          ? '${json['assignee']['first_name']} ${json['assignee']['last_name']}'
          : json['assignee_name']?.toString(),
    );
  }
}
