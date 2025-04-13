import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF1C1C1C),
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(color: Colors.white30),

            const SizedBox(height: 12),
            buildLabel("Enter UserID"),
            const SizedBox(height: 8),
            buildInputField(_splitNameController),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton("Create", const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.fromRGBO(208, 227, 64, 1), Color.fromRGBO(28, 54, 6, 1)],
                      ), () {
                  Navigator.pop(context);
                  // Handle create logic here
                }),
                buildActionButton("Cancel", const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.fromRGBO(255, 71, 139, 1), Color.fromRGBO(58, 11, 30, 1)],
                ), () {
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
