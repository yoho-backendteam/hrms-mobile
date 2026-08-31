class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final List<String> roles;
  final List<String> permissions;
  final String? tenantId;
  final String? tenantName;
  final String? employeeId;
  final String? employeeCode;
  final String? avatarUrl;
  final String? department;
  final String? designation;
  final String? phone;
  final String? location;
  final String? joiningDate;
  final String? status;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.roles = const [],
    this.permissions = const [],
    this.tenantId,
    this.tenantName,
    this.employeeId,
    this.employeeCode,
    this.avatarUrl,
    this.department,
    this.designation,
    this.phone,
    this.location,
    this.joiningDate,
    this.status,
  });

  String get fullName {
    if (firstName != null && lastName != null && firstName!.isNotEmpty && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return email.split('@').first;
  }

  String get displayCompanyName {
    if (tenantName != null && tenantName!.isNotEmpty) {
      return tenantName!;
    }
    return 'CSK Technologies';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = [];
    if (json['permissions'] is List) {
      parsedPermissions = (json['permissions'] as List)
          .map((p) => p is Map ? (p['code'] ?? p['name'] ?? '').toString() : p.toString())
          .where((p) => p.isNotEmpty)
          .toList();
    }

    List<String> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List)
          .map((r) => r is Map ? (r['name'] ?? '').toString() : r.toString())
          .where((r) => r.isNotEmpty)
          .toList();
    }

    String? tName = json['tenantName']?.toString() ??
        json['tenant_name']?.toString() ??
        json['company_name']?.toString() ??
        json['companyName']?.toString();

    if (tName == null && json['tenant'] is Map) {
      tName = json['tenant']['name']?.toString() ??
          json['tenant']['company_name']?.toString() ??
          json['tenant']['tenant_name']?.toString();
    }

    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? json['sub']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? json['first_name']?.toString(),
      lastName: json['lastName']?.toString() ?? json['last_name']?.toString(),
      role: json['role']?.toString() ?? (parsedRoles.isNotEmpty ? parsedRoles.first : 'EMPLOYEE'),
      roles: parsedRoles,
      permissions: parsedPermissions,
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString(),
      tenantName: tName,
      employeeId: json['employeeId']?.toString() ?? json['employee_id']?.toString() ?? json['id']?.toString(),
      employeeCode: json['employee_code']?.toString() ?? json['employeeCode']?.toString() ?? 'EMP-01',
      avatarUrl: json['avatarUrl']?.toString() ?? json['profile_picture']?.toString() ?? json['avatar']?.toString(),
      department: json['department']?.toString() ?? 'Engineering',
      designation: json['designation']?.toString() ?? 'Software Engineer',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '+91 98765 43210',
      location: json['location']?.toString() ?? json['work_location']?.toString() ?? 'Chennai HQ',
      joiningDate: json['joiningDate']?.toString() ?? json['joining_date']?.toString() ?? '2024-01-15',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    List<String>? roles,
    List<String>? permissions,
    String? tenantId,
    String? tenantName,
    String? employeeId,
    String? employeeCode,
    String? avatarUrl,
    bool clearAvatar = false,
    String? department,
    String? designation,
    String? phone,
    String? location,
    String? joiningDate,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      department: department ?? this.department,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'roles': roles,
        'permissions': permissions,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'employeeId': employeeId,
        'employeeCode': employeeCode,
        'avatarUrl': avatarUrl,
        'department': department,
        'designation': designation,
        'phone': phone,
        'location': location,
        'joiningDate': joiningDate,
        'status': status,
      };
}
