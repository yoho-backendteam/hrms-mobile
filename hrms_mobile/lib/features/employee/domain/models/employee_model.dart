class EmployeeModel {
  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? department;
  final String? designation;
  final String? avatarUrl;
  final String status;
  final DateTime? joiningDate;

  EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.department,
    this.designation,
    this.avatarUrl,
    this.status = 'ACTIVE',
    this.joiningDate,
  });

  String get fullName => '$firstName $lastName';

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? json['employeeCode']?.toString() ?? 'EMP-${json['id']?.toString().substring(0, 4)}',
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
      department: json['department'] is Map
          ? json['department']['name']?.toString()
          : json['department']?.toString(),
      designation: json['designation'] is Map
          ? json['designation']['name']?.toString()
          : json['designation']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['profile_picture']?.toString(),
      status: json['status']?.toString() ?? (json['is_active'] == true ? 'ACTIVE' : 'INACTIVE'),
      joiningDate: json['joining_date'] != null
          ? DateTime.tryParse(json['joining_date'].toString())
          : null,
    );
  }
}
