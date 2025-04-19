import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/sections/analysis_section.dart';
import 'package:my_new_app/sections/create_group.dart';
import 'package:my_new_app/sections/create_private_split.dart';
import 'package:my_new_app/sections/join_group.dart';
import 'package:my_new_app/sections/transactions_history.dart';
import 'package:my_new_app/utils/dashboard_utils.dart';
import 'package:my_new_app/utils/user_drawer_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width ;

    return Scaffold(
      backgroundColor: Colors.black,
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
                          "Hi Monish",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: width*0.047, 
                            // fontSize: 20,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        Text(
                          "Welcome back",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: width*0.07,
                            // fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white12,
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromRGBO(6, 131, 81, 1), Color.fromRGBO(0, 31, 18, 1)],
                        ),
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromRGBO(15, 111, 179, 1), Color.fromRGBO(0, 11, 31, 1)],
                        ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromRGBO(237, 202, 3, 1), Color.fromRGBO(41, 43, 0, 1)],
                  ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromRGBO(226, 93, 22, 1), Color.fromRGBO(44, 28, 1, 1)],
                  ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromRGBO(106, 23, 169, 1), Color.fromRGBO(34, 2, 61, 1)],
                  ),
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
