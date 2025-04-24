import 'package:flutter/material.dart';
import './login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
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
                  _buildTextField("Name", false),
                  const SizedBox(height: 10),
                  _buildTextField("Username", false),
                  const SizedBox(height: 10),
                  _buildTextField("Email", false, isEmail: true),
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
                  _buildGradientButton("Sign Up", () {
                    if (_formKey.currentState!.validate()) {
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
    bool obscureText, {
    bool isEmail = false,
  }) {
    return TextFormField(
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
