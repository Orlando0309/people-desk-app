class User {
  final String id;
  final String email;
  final String? fullName;
  final String? employeeId; // Required for API calls scoped to employee
  final String? role; // For role-based UI
  final String? avatarUrl; // Profile picture URL
  final String? phone; // Contact phone number
  final String? department; // Department name
  final String? position; // Job position/title

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.employeeId,
    this.role,
    this.avatarUrl,
    this.phone,
    this.department,
    this.position,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? json['name']?.toString(),
        employeeId: json['employee_id']?.toString(),
        role: json['role']?.toString(),
        avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
        phone: json['phone']?.toString() ?? json['phone_number']?.toString(),
        department: json['department']?.toString() ?? json['department_name']?.toString(),
        position: json['position']?.toString() ?? json['job_title']?.toString() ?? json['title']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'employee_id': employeeId,
        'role': role,
        'avatar_url': avatarUrl,
        'phone': phone,
        'department': department,
        'position': position,
      };

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? employeeId,
    String? role,
    String? avatarUrl,
    String? phone,
    String? department,
    String? position,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        employeeId: employeeId ?? this.employeeId,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        position: position ?? this.position,
      );
}