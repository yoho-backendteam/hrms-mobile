class FaceProfileStatusModel {
  final bool isEnrolled;
  final String status;
  final DateTime? enrolledAt;
  final DateTime? lastVerifiedAt;
  final String? modelName;

  FaceProfileStatusModel({
    required this.isEnrolled,
    required this.status,
    this.enrolledAt,
    this.lastVerifiedAt,
    this.modelName,
  });

  factory FaceProfileStatusModel.fromJson(Map<String, dynamic> json) {
    return FaceProfileStatusModel(
      isEnrolled: json['isEnrolled'] == true || json['registered'] == true,
      status: json['status']?.toString() ?? 'NOT_REGISTERED',
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.tryParse(json['enrolledAt'].toString())
          : null,
      lastVerifiedAt: json['lastVerifiedAt'] != null
          ? DateTime.tryParse(json['lastVerifiedAt'].toString())
          : null,
      modelName: json['modelName']?.toString() ?? 'mediapipe-tasks-vision',
    );
  }
}
