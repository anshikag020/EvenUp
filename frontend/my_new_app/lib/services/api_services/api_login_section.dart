import 'package:flutter/material.dart';
import 'package:my_new_app/models/login_response_model.dart';
import 'package:my_new_app/models/signup_response_model.dart';
import 'package:my_new_app/models/user_model.dart';
import 'package:my_new_app/services/api_services/utility_check_invalid_token.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiAuthService implements AuthService {
  final String baseUrl;

  ApiAuthService({required this.baseUrl});

  @override
  Future<SignUpResponse> signup(SignUpDataModel signUpData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signUpData),
    );

    final data = jsonDecode(response.body);
    if (data['status']) {
      return SignUpResponse.fromJson(data);
    } else {
      return SignUpResponse(success: false, message: data['message']);
    }
  }

  @override
  Future<LoginResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (data['status']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwtToken', data['token']);
      await prefs.setString('username', username.trim());

      return LoginResponse.fromJson(data);
    } else {
      return LoginResponse(success: false, message: data['message']);
    }
  }

  @override
  Future<User> getUserDetails(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      redirectToLoginPage(context);
    }
    final data = jsonDecode(response.body);
    // await prefs.setString('jwtToken', data['username']);
    return User.fromJson(data);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
  }
}
