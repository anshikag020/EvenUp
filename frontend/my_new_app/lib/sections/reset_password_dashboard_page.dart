import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'login_page.dart';

class PanelResetPasswordPage extends StatefulWidget {
  const PanelResetPasswordPage({super.key});

  @override
  State<PanelResetPasswordPage> createState() => _PanelResetPasswordPageState();
}

class _PanelResetPasswordPageState extends State<PanelResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

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
                    "Reset Password",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    label: "Old Password",
                    controller: _oldPasswordController,
                    obscure: _obscureOldPassword,
                    onToggleVisibility: () {
                      setState(
                        () => _obscureOldPassword = !_obscureOldPassword,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    label: "New Password",
                    controller: _newPasswordController,
                    obscure: _obscureNewPassword,
                    onToggleVisibility: () {
                      setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    label: "Confirm New Password",
                    controller: _confirmNewPasswordController,
                    obscure: _obscureConfirmPassword,
                    onToggleVisibility: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    isConfirm: true,
                  ),
                  const SizedBox(height: 20),
                  _buildGradientButton("Reset Password", () async {
                    if (_formKey.currentState!.validate()) {
                      final ResetPasswordFlowService resetService =
                          locator<ResetPasswordFlowService>();
                      final success = await resetService.resetPassword(
                        _oldPasswordController.text.trim(),
                        _newPasswordController.text.trim(),
                      );

                      if (success) {
                        showCustomSnackBar(
                          context,
                          'Password changed successfully!',
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      } else {
                        showCustomSnackBar(context, 'Password change Failed!');
                      }
                    }
                  }),
                  TextButton(
                    onPressed: () {
                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(builder: (_) => const LoginPage()),
                      // );
                      Navigator.pop(context);
                    },
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
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleVisibility,
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label cannot be empty';
        if (isConfirm && value != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
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
