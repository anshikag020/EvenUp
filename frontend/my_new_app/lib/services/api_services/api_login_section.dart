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

  @override
  Future<bool> forgotPassword(String emailID) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/forgot_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailID}),
    );


    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return true; 
      } else {
        return false; 
      }
    } else {
      throw Exception("Empty or invalid response from server");
    }
  }

  @override
  Future<String?> otpConfirm(String emailID, String otp) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/confirm_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailID, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true && data.containsKey('reset_token')) {
      return data['reset_token']; // return the token to be used for password reset
    } else {
      return null; // OTP invalid or expired
    }
  }

  @override
  Future<bool> resetConfirm(String emailID, String resetToken, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/forgot_reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailID, 'reset_token': resetToken, 'new_password': newPassword}),
    );

    final data = jsonDecode(response.body);

    if (data['status']) {
      return true; 
    } else {
      return false; 
    }
  }
  
}
