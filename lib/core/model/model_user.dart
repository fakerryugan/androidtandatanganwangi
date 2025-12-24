class User {
  final String id;
  final String username;
  final String name;
  final String nim;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.nim,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      nim: json['nim'] ?? '',
      token: token,
    );
  }
}
