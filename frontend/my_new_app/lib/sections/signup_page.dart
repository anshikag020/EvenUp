import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/signup_response_model.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import './login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                    "Sign Up",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Name", false, _nameController),
                  const SizedBox(height: 10),
                  _buildTextField("Username", false, _usernameController),
                  const SizedBox(height: 10),
                  _buildTextField("Email", false, _emailController, isEmail: true),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    "Password",
                    _passwordController,
                    isConfirm: false,
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    "Confirm Password",
                    null,
                    isConfirm: true,
                  ),
                  const SizedBox(height: 20),
                  _buildGradientButton("Sign Up", () async {
                    if (_formKey.currentState!.validate()) {

                      try {
                        final authService = locator<AuthService>();
                        final signUpData = SignUpDataModel(
                          name: _nameController.text,
                          username: _usernameController.text,
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                        final loginResponse = await authService.signup(
                          signUpData
                        );

                        print( loginResponse.message ); 

                        if (loginResponse.success) {
                          // Save the token is already done inside ApiAuthService.login()
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("User Account Created")),
                          );
                          // Navigate to Main Page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        } else {
                          // Show error if login failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loginResponse.message ?? "Sign Up failed")),
                          );
                        }
                      } catch (e) {
                        // Handle unexpected errors (server down, network error etc.)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('An error occurred: $e')),
                        );
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  }),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
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

  Widget _buildTextField(
    String label,
    bool obscureText,
    TextEditingController myController,
    {
    bool isEmail = false,
    }
  ) {
    return TextFormField(
      controller: myController,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(label),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label cannot be empty';
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
          return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController? controller, {
    required bool isConfirm,
  }) {
    return TextFormField(
      controller: isConfirm ? null : controller,
      obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isConfirm
                ? (_obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off)
                : (_obscurePassword ? Icons.visibility : Icons.visibility_off),
            color: Colors.white54,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label cannot be empty';
        if (isConfirm && value != _passwordController.text)
          return 'Passwords do not match';
        return null;
      },
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
