import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../locator.dart';

class AllBalancesScreen extends StatefulWidget {
  final String groupID;

  const AllBalancesScreen({super.key, required this.groupID});

  @override
  State<AllBalancesScreen> createState() => _AllBalancesScreenState();
}

class _AllBalancesScreenState extends State<AllBalancesScreen> {
  Future<List<Balance>>? _balancesFuture;
  late String? username;
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    setState(() {
      username = savedUsername;
      _balancesFuture = locator<BalanceService>().fetchBalances(widget.groupID);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.appBarColorDark
                : AppColors.appBarColorLight,
        title: Text(
          "Balances",
          style: GoogleFonts.poppins(
            fontSize: 22,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDark
                    : AppColors.textLight,
          ),
        ),
        iconTheme: IconThemeData(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textDark
                  : AppColors.textLight,
        ),
      ),
      body: FutureBuilder<List<Balance>>(
        future: _balancesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No balances found.',
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textDark
                          : AppColors.textLight,
                ),
              ),
            );
          } else {
            final balances = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: balances.length,
                itemBuilder: (context, index) {
                  final balance = balances[index];
                  final isUser1 = balance.user1 == username;
                  final isUser2 = balance.user2 == username;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        // color: const Color(0xFF2C2C2C),
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.box2Dark
                                : AppColors.box2Light,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${balance.user1} owes ${balance.user2} ₹${balance.amount}",
                            style: GoogleFonts.poppins(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isUser1)
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => ConfirmationDialog(
                                        message:
                                            'Do you wish to settle up this balance?',
                                        onConfirm: () {
                                          // handle logic here
                                          showCustomSnackBar(
                                            context,
                                            "Balance settled up from your side",
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  58,
                                                  133,
                                                  61,
                                                ),
                                          );
                                        },
                                        onCancel: () {
                                          // Just close the dialog
                                        },
                                      ),
                                );
                                // Settle up logic to be implemented
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  76,
                                  175,
                                  80,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Settle up",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else if (isUser2)
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => ConfirmationDialog(
                                        message:
                                            'Do you wish to send a reminder?',
                                        onConfirm: () {
                                          // handle here

                                          showCustomSnackBar(
                                            context,
                                            "Reminder sent to ${balance.user1} to pay ${balance.user2}",
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  233,
                                                  30,
                                                  99,
                                                ),
                                          );
                                        },
                                        onCancel: () {
                                          // Just close the dialog
                                        },
                                      ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Remind",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
