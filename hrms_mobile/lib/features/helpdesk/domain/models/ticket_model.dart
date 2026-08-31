import 'package:intl/intl.dart';

class TicketCommentModel {
  final String id;
  final String ticketId;
  final String authorName;
  final String? authorRole;
  final String message;
  final bool isInternal;
  final DateTime createdAt;

  TicketCommentModel({
    required this.id,
    required this.ticketId,
    required this.authorName,
    this.authorRole,
    required this.message,
    this.isInternal = false,
    required this.createdAt,
  });

  factory TicketCommentModel.fromJson(Map<String, dynamic> json) {
    return TicketCommentModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? json['ticket_id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? json['author_name']?.toString() ?? json['userName']?.toString() ?? 'Support Staff',
      authorRole: json['authorRole']?.toString() ?? json['author_role']?.toString() ?? json['role']?.toString(),
      message: json['message']?.toString() ?? json['comment']?.toString() ?? '',
      isInternal: json['isInternal'] == true || json['is_internal'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }
}

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? employeeName;
  final String? employeeCode;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<TicketCommentModel> comments;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    this.priority = 'MEDIUM',
    this.status = 'OPEN',
    this.employeeName,
    this.employeeCode,
    this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
    this.comments = const [],
  });

  String get formattedCreatedDate => DateFormat('MMM d, yyyy').format(createdAt);

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    List<TicketCommentModel> parsedComments = [];
    if (json['comments'] is List) {
      parsedComments = (json['comments'] as List)
          .map((c) => TicketCommentModel.fromJson(c is Map<String, dynamic> ? c : {}))
          .toList();
    }

    return TicketModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? json['ticket_number']?.toString() ?? '#HD-${json['id']?.toString().substring(0, 5) ?? "1001"}',
      title: json['title']?.toString() ?? json['subject']?.toString() ?? 'Support Ticket',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? json['category_name']?.toString() ?? 'General IT & Operations',
      priority: json['priority']?.toString().toUpperCase() ?? 'MEDIUM',
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      employeeName: json['employeeName']?.toString() ?? json['employee_name']?.toString(),
      employeeCode: json['employeeCode']?.toString() ?? json['employee_code']?.toString(),
      assignedTo: json['assignedTo']?.toString() ?? json['assigned_to']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : (json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null),
      comments: parsedComments,
    );
  }
}
