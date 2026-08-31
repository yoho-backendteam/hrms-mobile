class AssetModel {
  final String id;
  final String assetName;
  final String assetTag;
  final String category;
  final String serialNumber;
  final String status;
  final DateTime? assignedDate;

  AssetModel({
    required this.id,
    required this.assetName,
    required this.assetTag,
    required this.category,
    required this.serialNumber,
    this.status = 'ASSIGNED',
    this.assignedDate,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id']?.toString() ?? '',
      assetName: json['name']?.toString() ?? json['asset_name']?.toString() ?? 'Workstation Device',
      assetTag: json['asset_tag']?.toString() ?? json['tag']?.toString() ?? 'AST-1049',
      category: json['category'] is Map ? json['category']['name']?.toString() ?? 'IT Hardware' : json['category']?.toString() ?? 'Hardware',
      serialNumber: json['serial_number']?.toString() ?? 'SN-84920492',
      status: json['status']?.toString() ?? 'ASSIGNED',
      assignedDate: json['assigned_date'] != null ? DateTime.tryParse(json['assigned_date'].toString()) : null,
    );
  }
}
