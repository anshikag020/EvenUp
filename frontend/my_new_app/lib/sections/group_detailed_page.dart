import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/sections/add_expense.dart';
import 'package:my_new_app/sections/all_expenses.dart';
import 'package:my_new_app/sections/show_balances.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/utils/group_detailed_page_utils.dart';
import 'package:my_new_app/utils/view_all_members_utils.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupID;
  final String groupName;
  final String groupType;
  final String inviteCode;
  final String description;

  const GroupDetailScreen({
    Key? key,
    required this.groupID,
    required this.groupName,
    required this.groupType,
    required this.inviteCode,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
        title: Text(
          '$groupName: $groupType',
          style: GoogleFonts.poppins(fontSize: 25, color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
        ),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.menu, color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
        ],
        iconTheme: IconThemeData(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,),
      ),
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.exit_to_app,
                  color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                ),
                title: Text(
                  "Exit Group",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                title: Text(
                  "Delete group",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.box2Dark : AppColors.box2Light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Invite Code: $inviteCode",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  buildActionBox(
                    label: "All\nExpenses",
                    icon: Icons.receipt_long,
                    gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.greenTileDark : AppColors.greenTileWhite, 
                    // onTap: () {},
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AllExpensesScreen(groupID: groupID,)),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  buildActionBox(
                    label: "All\nBalances",
                    icon: Icons.menu_book,
                    gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.blueTileDark : AppColors.blueTileWhite,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllBalancesScreen(groupID: groupID,),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  
                showDialog(
                  context: context,
                  builder: (_) => AddExpenseDialog(groupID: groupID,parentContext: context,),
                );

                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromRGBO(191, 191, 5, 1),
                        Color.fromRGBO(2, 61, 59, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "Add New Expense",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: () {
                  GroupUtils.showGroupMembersDialog(
                    context: context, 
                    groupId: groupID,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:Theme.of(context).brightness ==  Brightness.dark ? AppColors.purplrTileDark : AppColors.purplrTileWhite,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "View Group Members",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 21,
                    ),
                  ),
                ),
              ),

              if (groupType == "OTS")
                Column(
                  children: [
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                                context: context,
                                builder: (context) => ConfirmationDialog(
                                  message: 'Are you sure you want to use Confirm feature of OTS group?',
                                  onConfirm: () {
                                    // handle here
                                    showCustomSnackBar(context, "You confirmed on this OTS group", backgroundColor: Color.fromRGBO(156, 13, 40, 1)); 
                                  },
                                  onCancel: () {},
                                ),
                              );
                        // GroupUtils.showGroupMembersDialog(
                        //   context: context,
                        //   groupId: groupID,
                        // );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.redTileDark : AppColors.redTileLight,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Confirm",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 21,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '( Confirm that you added all expenses )',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 34),
              Text(
                "Description:",
                style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 21),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.box2Dark : AppColors.box2Light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description.isNotEmpty
                      ? description
                      : "No description provided.",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
