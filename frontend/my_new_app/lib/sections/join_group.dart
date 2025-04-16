import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
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
      backgroundColor: const Color(0xFF1C1C1C),
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(color: Colors.white30),

            const SizedBox(height: 15),
            buildLabel("Invite Code"),
            const SizedBox(height: 8),
            buildInputField(_inviteCodeController),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(
                  "Join",
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(208, 227, 64, 1),
                      Color.fromRGBO(28, 54, 6, 1),
                    ],
                  ),
                  () {
                    // Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        message: 'Are you sure you want to join this group?',
                        onConfirm: () {
                          Navigator.pop(context); // Close the dialog
                          // ✅ Place your group creation logic here
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
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(255, 71, 139, 1),
                      Color.fromRGBO(58, 11, 30, 1),
                    ],
                  ),
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
