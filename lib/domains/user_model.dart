class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String role;
  final String stallName;
  final String region;
  final String contact;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.stallName,
    required this.region,
    required this.contact,
    required this.createdAt,
  });

  // Convert model to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'stall_name': stallName,
      'region': region,
      'contact': contact,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create model from Firestore document
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      stallName: map['stall_name'] ?? '',
      region: map['region'] ?? '',
      contact: map['contact'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // ✅ copyWith method (works even with non-nullable fields)
  UserModel copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? role,
    String? stallName,
    String? region,
    String? contact,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      stallName: stallName ?? this.stallName,
      region: region ?? this.region,
      contact: contact ?? this.contact,
      createdAt: createdAt,
    );
  }
}
