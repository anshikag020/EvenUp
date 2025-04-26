import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/sections/main_page.dart';
import 'package:my_new_app/sections/reset_password_page.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Username", _usernameController),
                  const SizedBox(height: 10),
                  _buildPasswordField("Password", _passwordController),
                  
                  // forgot password
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),



                  const SizedBox(height: 20),   
                  _buildGradientButton("Login", () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final authService = locator<AuthService>();
                        final loginResponse = await authService.login(
                          _usernameController.text.trim(),
                          _passwordController.text.trim(),
                        );

                        if (loginResponse.success) {
                          // Save the token is already done inside ApiAuthService.login()

                          // Navigate to Main Page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => MainPage()),
                          );
                        } else {
                          // Show error if login failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loginResponse.message ?? "Login failed")),
                          );
                        }
                      } catch (e) {
                        // Handle unexpected errors (server down, network error etc.)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('An error occurred: $e')),
                        );
                      }
                    }
                  }),




                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController _controller) {
    return TextFormField(
      controller: _controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      validator:
          (value) =>
              value == null || value.isEmpty ? '$label cannot be empty' : null,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController _controller ) {
    return TextFormField(
      controller: _controller,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty ? '$label cannot be empty' : null,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
