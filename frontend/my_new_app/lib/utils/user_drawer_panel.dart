import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDrawerPanel extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onResetPassword;
  final VoidCallback onLogout;

  const UserDrawerPanel({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onResetPassword,
    required this.onLogout,
  });

  @override
  State<UserDrawerPanel> createState() => _UserDrawerPanelState();
}

class _UserDrawerPanelState extends State<UserDrawerPanel> {
  late bool darkMode;

  @override
  void initState() {
    super.initState();
    darkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: SafeArea(
            child: Stack(
              children: [
                // 🔘 Main content
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "UserID - Monish",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                        color: Colors.white12,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.key, color: Colors.white),
                        title: Text(
                          "Reset Password",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onTap: widget.onResetPassword,
                        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_2_outlined, color: Colors.white),
                        title: Text(
                          "Night Mode",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        trailing: Switch(
                          value: darkMode,
                          onChanged: (val) {
                            setState(() {
                              darkMode = val;
                            });
                            widget.onThemeChanged(val);
                          },
                          activeColor: Colors.white,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: Text(
                          "Logout",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onTap: widget.onLogout,
                        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      ),
                    ],
                  ),
                ),

                // ❌ Close button (on left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
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
