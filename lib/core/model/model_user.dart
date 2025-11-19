class User {
  final int id;
  final String name;
  final String email;
  final String nip;
  final String roleAktif;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.nip,
    required this.roleAktif,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nip: json['nip'] ?? '',
      roleAktif: json['role_aktif'] ?? '',
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nip': nip,
      'role_aktif': roleAktif,
      'token': token,
    };
  }
}
