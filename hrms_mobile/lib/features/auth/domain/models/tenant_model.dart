class TenantModel {
  final String id;
  final String name;
  final String subdomain;
  final String? logoUrl;
  final String? subscriptionPlan;

  TenantModel({
    required this.id,
    required this.name,
    required this.subdomain,
    this.logoUrl,
    this.subscriptionPlan,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['company_name']?.toString() ?? 'HRMS Workspace',
      subdomain: json['subdomain']?.toString() ?? json['subDomain']?.toString() ?? json['domain']?.toString() ?? json['tenant_code']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
      subscriptionPlan: json['subscriptionPlan']?.toString() ?? json['plan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subdomain': subdomain,
        'logoUrl': logoUrl,
        'subscriptionPlan': subscriptionPlan,
      };
}
