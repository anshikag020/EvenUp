import 'package:flutter/material.dart';
import 'package:my_new_app/models/login_response_model.dart';
import 'package:my_new_app/models/signup_response_model.dart';
import 'package:my_new_app/models/user_model.dart';

abstract class AuthService {
  Future<LoginResponse> login(String username, String password);
  Future<User> getUserDetails(BuildContext context);
  Future<void> logout();
  Future<SignUpResponse> signup(SignUpDataModel signUpData);
  Future<bool> forgotPassword(String emailID); 
  Future<String?> otpConfirm(String emailID, String otp); 
  Future<bool> resetConfirm(String emailID, String resetToken, String newPassword); 
}
