class LoginResponse {
  final bool success;
  final String? message;
  final String? token;

  LoginResponse({
    required this.success,
    this.message,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['status'] ?? false,
      message: json['message'],
      token: json['token'],
    );
  }
}
