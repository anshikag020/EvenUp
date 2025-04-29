import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/dashboard_section_models.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
// import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/utils/join_group_utils.dart';

class CreatePrivateSplit extends StatefulWidget {
  const CreatePrivateSplit({super.key});

  @override
  State<CreatePrivateSplit> createState() => _CreatePrivateSplitState();
}

class _CreatePrivateSplitState extends State<CreatePrivateSplit> {
  final TextEditingController _splitNameController = TextEditingController();

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
              "Create Private Split",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Divider(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),

            const SizedBox(height: 12),
            buildLabel("Enter UserID", Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight ),
            const SizedBox(height: 8),
            buildInputField(_splitNameController, Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton("Create", Theme.of(context).brightness ==  Brightness.dark ? AppColors.greenButtondarktheme : AppColors.greenButtonwhitetheme, () {
                  // Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                      message: 'Are you sure you want to create this private-split?',
                      onConfirm: () async {
                        // handle logic here

                                final newSplit = CreatePrivateSplitModel(
                                  otheruser: _splitNameController.text.trim() 
                                );

                                final CreatePrivateSplitService splitService =
                                    locator<CreatePrivateSplitService>();
                                await splitService.createNewPrivateSplit(
                                  newSplit,
                                  context,
                                );

                        Navigator.pop(context); // Close the dialog
                        // showCustomSnackBar(
                        //         context,
                        //         "New private-split created successfully",
                        //         backgroundColor: const Color.fromRGBO(15, 111, 179, 1)
                        //       );
                      },
                      onCancel: () {
                        Navigator.pop(context); // Just close the dialog
                      },
                    ),
                  ); 
                  // Handle create logic here
                }),
                buildActionButton("Cancel", Theme.of(context).brightness ==  Brightness.dark ? AppColors.redbuttondarktheme : AppColors.redbuttonwhitetheme, () {
                  Navigator.pop(context);
                }),
              ],
            )
          ],
        ),
      ),
    );
  }
}
