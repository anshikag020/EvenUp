import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/dashboard_section_models.dart';
// import 'package:my_new_app/services/api_services/api_dashboard_section_service.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/create_group_utils.dart';

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
    Color textcolor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.textDark
            : AppColors.textLight;

    double width = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
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
                color: textcolor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Divider(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white30
                      : AppColors.textLight,
            ),

            const SizedBox(height: 12),
            buildLabel("Group Name:", context),
            const SizedBox(height: 10),
            buildInputField(_nameController, context),

            const SizedBox(height: 20),
            buildLabel("Group Type:", context),
            const SizedBox(height: 10),
            buildRadio(
              value: "Normal",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
              context: context,
            ),
            buildRadio(
              value: "OTS",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
              context: context,
            ),
            buildRadio(
              value: "Grey",
              groupValue: groupType,
              onChanged: (val) => setState(() => groupType = val),
              context: context,
            ),

            const SizedBox(height: 20),
            buildLabel("Description:", context),
            const SizedBox(height: 10),
            buildDescriptionField(_descController, context),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(
                  width,
                  "Create",

                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.greenButtondarktheme
                      : AppColors.greenButtonwhitetheme,
                  () {
                    final groupName = _nameController.text.trim();
                    final groupDesc = _descController.text.trim();

                    if (groupName.isEmpty || groupDesc.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Missing Information"),
                          content: const Text("Please fill in all fields before proceeding."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        message: 'Are you sure you want to create this group?',
                        onConfirm: () async {
                          Navigator.pop(context); // Close confirmation dialog

                          final type = groupType;

                          final newGroup = CreateGroupModel(
                            groupName: groupName,
                            groupDescription: groupDesc,
                            groupType: "$type Group",
                          );

                          final CreateGroupService groupService = locator<CreateGroupService>();
                          await groupService.createNewGroup(newGroup, context);
                        },
                        onCancel: () {
                          Navigator.pop(context); // Just close the dialog
                        },
                      ),
                    );
                  }

                ),
                buildActionButton(
                  width,
                  "Cancel",
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.redbuttondarktheme
                      : AppColors.redbuttonwhitetheme,
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
