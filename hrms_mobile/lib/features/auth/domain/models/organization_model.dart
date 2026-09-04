class OrganizationModel {
  final String id;
  final String code;
  final String name;
  final String? domain;
  final String? role;

  OrganizationModel({
    required this.id,
    required this.code,
    required this.name,
    this.domain,
    this.role,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? json['tenant_code']?.toString() ?? json['domain']?.toString() ?? '',
      name: json['name']?.toString() ?? json['company_name']?.toString() ?? json['tenant_name']?.toString() ?? 'Organization',
      domain: json['domain']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'domain': domain,
        'role': role,
      };
}
