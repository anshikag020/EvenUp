class SignUpDataModel {
  final String name;
  final String username;
  final String email;
  final String password; 

  SignUpDataModel({
    required this.name,
    required this.username,
    required this.email, 
    required this.password 
  });

  factory SignUpDataModel.fromJson(Map<String, dynamic> json) {
    return SignUpDataModel(
      name: json['name'],
      username: json['username'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username, 
      'email': email,
      'password': password 
    };
  }
}


class SignUpResponse {
  final bool success;
  final String? message;

  SignUpResponse({
    required this.success,
    this.message,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      success: json['status'] ?? false,
      message: json['message'],
    );
  }
}
