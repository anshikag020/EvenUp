import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/sections/login_page.dart';
import 'package:my_new_app/sections/otp_verification_page.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';

class EmailOtpPage extends StatefulWidget {
  const EmailOtpPage({super.key});

  @override
  State<EmailOtpPage> createState() => _EmailOtpPageState();
}

class _EmailOtpPageState extends State<EmailOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      // ✅ Call backend to send OTP to email

      // Logic handling remains
      final String emailID = _emailController.text.trim(); 
      final AuthService otpService = locator<AuthService>();
      final success = await otpService.forgotPassword(emailID);

      if (success) {
        showCustomSnackBar(context, "Otp sent to your email!");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyPage(email: emailID),
          ),
        );
      } else {
        showCustomSnackBar(context, "Error occured, try again later!");
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Forgot Password",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Email cannot be empty'
                              : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text("Send OTP"),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
