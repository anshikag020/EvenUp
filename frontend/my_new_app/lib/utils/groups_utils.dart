import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/sections/group_detailed_page.dart'; // Adjust import path as needed

class GroupTile extends StatelessWidget {
  final String name;
  final int size;
  final String description; 
  final String inviteCode; 
  final String groupType; 

  const GroupTile({
    required this.name,
    required this.size,
    required this.description,
    required this.inviteCode,
    required this.groupType, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              groupName: name,
              groupType: groupType, // Use dynamic value when backend is integrated
              inviteCode: inviteCode, // Placeholder for now
              description: description, // Placeholder
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(27, 27, 27, 1),
              Color.fromRGBO(53, 53, 53, 1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Group:\n',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Text(
              "Size\n$size",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
