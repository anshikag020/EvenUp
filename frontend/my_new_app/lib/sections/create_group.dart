import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/create_group_utils.dart';
import 'package:my_new_app/utils/general_utils.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String groupType = 'Normal';

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Create Group",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(color: Colors.white30),

            const SizedBox(height: 12),
            buildLabel("Group Name:"),
            const SizedBox(height: 10),
            buildInputField(_nameController),

            const SizedBox(height: 20),
            buildLabel("Group Type:"),
            const SizedBox(height: 10),
            buildRadio(
              value: "Normal",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
            ),
            buildRadio(
              value: "OTS",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
            ),
            buildRadio(
              value: "Grey",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
            ),

            const SizedBox(height: 20),
            buildLabel("Description:"),
            const SizedBox(height: 10),
            buildDescriptionField(_descController),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(
                  width,
                  "Create",
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(208, 227, 64, 1),
                      Color.fromRGBO(28, 54, 6, 1),
                    ],
                  ),
                  () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => ConfirmationDialog(
                            message:
                                'Are you sure you want to create this group?',
                            onConfirm: () {
                              // handle logic here
                              Navigator.pop(context); // Close the dialog
                              showCustomSnackBar(
                                context,
                                "New group created successfully",
                                backgroundColor: const Color.fromRGBO(6, 131, 81, 1)
                              );
                            },
                            onCancel: () {
                              Navigator.pop(context); // Just close the dialog
                            },
                          ),
                    ); // Call your group creation logic here
                  },
                ),
                buildActionButton(
                  width,
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
