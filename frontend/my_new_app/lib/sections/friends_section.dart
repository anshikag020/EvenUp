import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/models/friends_model.dart';
import 'package:my_new_app/services/service%20interfaces/friends_section_api_interface_service.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../locator.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<List<Friend>>? _friendsFuture;
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
      _friendsFuture = locator<FriendsService>().fetchFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark
                ? const Color.fromARGB(255, 18, 18, 18)
                : AppColors.appBarColorLight,
        title: Text(
          "Friends",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDark
                    : AppColors.textLight,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Friend>>(
        future: _friendsFuture,
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
                'No friends found.',
                style: TextStyle(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            );
          } else {
            final friends = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isUserPaying = friend.sender == username;
                  final friendName =
                      isUserPaying ? friend.receiver : friend.sender;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.box2Dark : AppColors.box2Light,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${friend.sender} owes ${friend.receiver} ₹${friend.balance.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color:
                                  isDark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => ConfirmationDialog(
                                      message:
                                          isUserPaying
                                              ? 'Do you wish to settle up this balance?'
                                              : 'Do you wish to send a reminder?',
                                      onConfirm: () async {
                                        final FriendsService service =
                                            locator<FriendsService>();
                                        bool success = false;
                                        if (isUserPaying) {
                                          success = await service.settleFriend(
                                            friendName,
                                          );
                                        } else {
                                          success = await service.remindFriend(
                                            friendName,
                                          );
                                        }

                                        if (success) {
                                          showCustomSnackBar(
                                            context,
                                            isUserPaying
                                                ? "Settlement initiated"
                                                : "Reminder sent to $friendName",
                                            backgroundColor:
                                                isUserPaying
                                                    ? const Color.fromARGB(
                                                      255,
                                                      58,
                                                      133,
                                                      61,
                                                    )
                                                    : const Color.fromARGB(
                                                      255,
                                                      233,
                                                      30,
                                                      99,
                                                    ),
                                          );
                                          await _initData();
                                        } else {
                                          showCustomSnackBar(
                                            context,
                                            "Action failed, try again later!",
                                            backgroundColor: Colors.red,
                                          );
                                        }
                                      },
                                      onCancel: () {},
                                    ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isUserPaying
                                      ? const Color.fromARGB(255, 76, 175, 80)
                                      : const Color(0xFFE91E63),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              isUserPaying ? "Settle up" : "Remind",
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
