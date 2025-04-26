class User {
  final String username;
  final String name;
  final String email;
  final bool darkMode;

  User({
    required this.username,
    required this.name,
    required this.email,
    required this.darkMode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      name: json['name'],
      email: json['email'],
      darkMode: json['dark_mode'] ?? false,
    );
  }
}
