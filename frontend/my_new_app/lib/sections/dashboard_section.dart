import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/sections/analysis_section.dart';
import 'package:my_new_app/sections/create_group.dart';
import 'package:my_new_app/sections/create_private_split.dart';
import 'package:my_new_app/sections/join_group.dart';
import 'package:my_new_app/sections/transactions_history.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/dashboard_utils.dart';
import 'package:my_new_app/utils/user_drawer_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String? username;
  String? email; 

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  void loadUserName() async {
    final api = locator<AuthService>();
    final user = await api.getUserDetails(context);
    setState(() {
      username = user.name;
      email = user.email; 
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width ;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight ,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 15, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username != null ? "Hi, $username" : "Loading...",
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70: AppColors.textLight,
                            fontSize: width*0.047, 
                            // fontSize: 20,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        Text(
                          "Welcome back",
                          style: GoogleFonts.poppins(
                            color:  Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textLight,
                            fontSize: width*0.07,
                            // fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.circleAvatarColorDark: AppColors.circleAvatarColorWhite,
                      radius: width*0.07,
                      // radius: 25,
                      child: IconButton(
                        icon: Icon(Icons.person, color: Colors.white, 
                            size: width*0.07,
                          // size: 30
                        ),
                        onPressed: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.black54,
                            barrierLabel: "User Panel",
                            transitionDuration: const Duration(milliseconds: 200),
                            pageBuilder: (_, __, ___) {
                              return UserDrawerPanel(
                                isDarkMode: true,
                                onThemeChanged: (val) {},
                                onResetPassword: () {},
                                onLogout: () {},
                                username: username, 
                                email: email,
                              );
                            },
                            transitionBuilder: (_, anim, __, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        
                const SizedBox(height: 50),
        
                // Top Row Buttons
                Row(
                  children: [
                    Expanded(
                      child: DashboardTileVer(
                        title: "Create\nGroup",
                        icon: Icons.add_circle_outline,
                        gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.greenTileDark: AppColors.greenTileWhite,
                        onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const CreateGroupDialog(),
                                    );
                                  }
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardTileVer(
                        title: "Create\nPrivate Split",
                        icon: Icons.add_circle_outline,
                        gradient:  Theme.of(context).brightness == Brightness.dark ? AppColors.blueTileDark: AppColors.blueTileWhite , 
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "Create Private Split",
                            barrierColor: const Color(0x99000000), // ~60% black
                            transitionDuration: const Duration(milliseconds: 200),
                            pageBuilder: (_, __, ___) {
                              return const CreatePrivateSplit();
                            },
                            transitionBuilder: (_, anim, __, child) {
                              return BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // Blur effect
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
        
                      ),
                    ),
                  ],
                ),
        
                const SizedBox(height: 16),
        
                // Next Buttons
                DashboardTileHor(
                  height: 100,
                  title: "Join Group",
                  icon: Icons.group_add,
                  gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.yelloweTileDark : AppColors.yellowTileWhite, 
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: "Join Group",
                      barrierColor: const Color(0x99000000), // ~60% black
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (_, __, ___) {
                        return const JoinGroupDialog();
                      },
                      transitionBuilder: (_, anim, __, child) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // Blur effect
                          child: FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                DashboardTileHor(
                  height: 100,
                  title: "Transactions History",
                  icon: Icons.history,
                  gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.orangeTileDark : AppColors.orangeTileWhite ,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionsHistoryScreen()
                      ),
                    );
                  },
        
                ),
                const SizedBox(height: 16),
                DashboardTileHor(
                  height: 150,
                  title: "Track My\nMoney",
                  icon: Icons.show_chart,
                  gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.purplrTileDark : AppColors.purplrTileWhite,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalysisScreen()
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
