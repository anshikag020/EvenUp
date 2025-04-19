import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/add_expense_utils.dart';
import 'package:my_new_app/utils/create_group_utils.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/locator.dart';


class AddExpenseDialog extends StatefulWidget {
  final String groupID;

  const AddExpenseDialog({super.key, required this.groupID});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController descriptionController = TextEditingController();
  double totalAmount = 0.0;
  Map<String, double> paidBy = {};
  List<String> splitBetween = [];
  Map<String, double> splitDetails = {};
  String splitType = "";

  late GroupMemberService memberService;
  late List<GroupMemberModel> members = [];

  @override
  void initState() {
    super.initState();
    memberService = locator<GroupMemberService>();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final data = await memberService.fetchMembersForGroup(widget.groupID);
    setState(() {
      members = data;
    });
  }
 
  void _selectPaidBy() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) => PaidByDialog(members: members),
    );
    if (result != null) {
      setState(() {
        paidBy = result;
        totalAmount = paidBy.values.fold(0, (sum, item) => sum + item);
      });
    }
  }

  void _selectSplitBetween() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => SplitBetweenDialog(
        members: members,
        selectedMembers: splitBetween,
      ),
    );
    if (result != null) {
      setState(() {
        splitBetween = result;
        splitDetails = {};
      });
    }
  }

  void _selectSplitType() async {
    if (splitBetween.isEmpty || totalAmount == 0.0) {
      showCustomSnackBar(context, "Select paid by and split between members first");
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SplitTypeDialog(
        members: members,
        selectedMembers: splitBetween,
        totalAmount: totalAmount,
        initialSplitType: splitType,
        initialSplitDetails: splitDetails,
      ),
    );

    if (result != null) {
      setState(() {
        splitType = result['type'];
        splitDetails = Map<String, double>.from(result['details']);
      });
    }
  }

  void _confirmExpense() {
    if (descriptionController.text.trim().isEmpty ||
        paidBy.isEmpty ||
        splitBetween.isEmpty ||
        splitDetails.isEmpty ||
        splitType.isEmpty) {
      showCustomSnackBar(context, "Please fill in all required details");
      return;
    }

    Navigator.of(context).pop({
      'description': descriptionController.text.trim(),
      'paidBy': paidBy,
      'amount': totalAmount,
      'splitBetween': splitBetween,
      'splitType': splitType,
      'splitDetails': splitDetails,
    });
  }

  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildAmountLine(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Colors.white)),
      trailing: ElevatedButton(
        onPressed: onTap,
        child: Text("Select"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Add Expense",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),

            buildLabel("Description:"),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter the description",
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 16),
            buildAmountLine('Paid By', 'Select', _selectPaidBy),
            ListTile(
              title: Text("Amount", style: TextStyle(color: Colors.white)),
              trailing: Text('₹${totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white70, fontSize: width*0.045)),
            ),
            buildAmountLine('Split Between', 'Select', _selectSplitBetween),
            buildAmountLine('Split Type', 'Select', _selectSplitType),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(
                  width,
                  "Add Expense",
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(208, 227, 64, 1),
                      Color.fromRGBO(28, 54, 6, 1),
                    ],
                  ),
                  _confirmExpense,
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
                  () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
