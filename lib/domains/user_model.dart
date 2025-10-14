class UserModel {
  final String id;
  final String name;
  final String username; // 👈 added
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
    required this.username, // 👈 added
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
      'username': username, // 👈 added
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
      username: map['username'] ?? '', // 👈 added
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      stallName: map['stall_name'] ?? '',
      region: map['region'] ?? '',
      contact: map['contact'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
