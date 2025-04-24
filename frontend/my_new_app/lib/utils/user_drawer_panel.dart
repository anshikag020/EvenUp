import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/sections/login_page.dart';
import 'package:my_new_app/sections/reset_password_page.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/utils/toggle_theme_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,

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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.circleAvatarColorDark
                                : AppColors.circleAvatarColorWhite,

                        //  Colors.white12,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "UserID - Monish",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.backgroundLight
                                  : AppColors.backgroundDark,
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
                        leading: Icon(
                          Icons.key,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.backgroundLight
                                  : AppColors.backgroundDark,
                        ),
                        title: Text(
                          "Reset Password",
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.backgroundLight
                                    : AppColors.backgroundDark,
                          ),
                        ),
                        onTap: (){
                          widget.onResetPassword;
                          
                          //  write the logic correctly 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResetPasswordPage(),
                            ),
                          );
                          
                        },
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          15,
                          20,
                          15,
                        ),
                      ),
                      ThemeToggleTile(),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.backgroundLight
                                  : AppColors.backgroundDark,
                        ),
                        title: Text(
                          "Logout",
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.backgroundLight
                                    : AppColors.backgroundDark,
                          ),
                        ),
                        onTap: () {
                          widget.onLogout;
                          showDialog(
                            context: context,
                            builder:
                                (context) => ConfirmationDialog(
                                  message: 'Are you sure you want to logout?',
                                  onConfirm: () async {
                                    // handle logic here
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool('isLoggedIn', false);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoginPage(),
                                      ),
                                    );
                                    // Navigator.pop(context);
                                    showCustomSnackBar(
                                      context,
                                      "Logged out successfully",
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        129,
                                        171,
                                        13,
                                      ),
                                    );
                                  },
                                  onCancel: () => Navigator.pop(context),
                                ),
                          );
                        },

                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          15,
                          20,
                          15,
                        ),
                      ),
                    ],
                  ),
                ),

                // ❌ Close button (on left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.backgroundLight
                              : AppColors.backgroundDark,
                    ),
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
