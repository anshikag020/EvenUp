import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';

class PingCard extends StatelessWidget {
  final String transacID;
  final String otherMember;
  final double amount;
  final String groupName;
  final bool isSender;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const PingCard({
    Key? key,
    required this.transacID,
    required this.otherMember,
    required this.isSender,
    required this.amount,
    required this.groupName,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.searchBoxDark
          : AppColors.searchBoxLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Group: $groupName',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color.fromARGB(255, 151, 151, 151)
                      : const Color.fromARGB(255, 80, 79, 79),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  otherMember,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textDark
                        : AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  amount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textDark
                        : AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isSender) 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: width * 0.25,
                    height: width * 0.1,
                    child: Material(
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.greenButtondarktheme
                              : AppColors.greenButtonwhitetheme,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmationDialog(
                                message: 'Are you sure you want to accept this transaction?',
                                onConfirm: onAccept,
                                onCancel: () {},
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Center(
                            child: Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.038,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: width * 0.25,
                    height: width * 0.1,
                    child: Material(
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.redbuttondarktheme
                              : AppColors.redbuttonwhitetheme,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmationDialog(
                                message: 'Are you sure you want to reject this transaction?',
                                onConfirm: onReject,
                                onCancel: () {},
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Center(
                            child: Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.038,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
