class User {
  final String id;
  final String email;
  final String? fullName;

  const User({required this.id, required this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        fullName: json['fullName']?.toString() ?? json['name']?.toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'fullName': fullName};

  User copyWith({String? id, String? email, String? fullName}) =>
      User(id: id ?? this.id, email: email ?? this.email, fullName: fullName ?? this.fullName);
}
