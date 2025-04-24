import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/utils/join_group_utils.dart';

class JoinGroupDialog extends StatefulWidget {
  const JoinGroupDialog({super.key});

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Join Group",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Divider(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),

            const SizedBox(height: 15),
            buildLabel("Invite Code", Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
            const SizedBox(height: 8),
            buildInputField(_inviteCodeController, Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(
                  "Join",
                  Theme.of(context).brightness ==  Brightness.dark ? AppColors.greenButtondarktheme : AppColors.greenButtonwhitetheme,
                  () {
                    // Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        message: 'Are you sure you want to join this group?',
                        onConfirm: () {
                          //  handle logic here
                          Navigator.pop(context); // Close the dialog
                          showCustomSnackBar(
                                context,
                                "Joined new group successfully",
                                backgroundColor: const Color.fromARGB(255, 175, 155, 39)
                              );
                        },
                        onCancel: () {
                          Navigator.pop(context); // Just close the dialog
                        },
                      ),
                    ); 
                    // Handle join logic here
                  },
                ),
                buildActionButton(
                  "Cancel",
                  Theme.of(context).brightness ==  Brightness.dark ? AppColors.redbuttondarktheme : AppColors.redbuttonwhitetheme,
                  () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
