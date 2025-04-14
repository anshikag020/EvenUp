import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/sections/all_expenses.dart';
import 'package:my_new_app/utils/group_detailed_page_utils.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupName;
  final String groupType;
  final String inviteCode;
  final String description;

  const GroupDetailScreen({
    Key? key,
    required this.groupName,
    required this.groupType,
    required this.inviteCode,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          '$groupName: $groupType',
          style: GoogleFonts.poppins(fontSize: 25, color: Colors.white),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Color.fromARGB(255, 255, 255, 255)),
                title: Text("Exit Group", style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.white),
                title: Text("Delete group", style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Invite Code: $inviteCode",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  buildActionBox(
                    label: "All\nExpenses",
                    icon: Icons.receipt_long,
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.fromRGBO(6, 131, 81, 1), Color.fromRGBO(0, 31, 18, 1)],
                      ),
                    // onTap: () {},
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AllExpensesScreen()),
                      );
                    },

                  ),
                  const SizedBox(width: 12),
                  buildActionBox(
                    label: "All\nBalances",
                    icon: Icons.menu_book,
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.fromRGBO(15, 111, 179, 1), Color.fromRGBO(0, 11, 31, 1)],
                      ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.fromRGBO(106, 23, 169, 1), Color.fromRGBO(34, 2, 61, 1)],
                ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "View Group Members",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 21),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                "Description:",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 21),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description.isNotEmpty ? description : "No description provided.",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

