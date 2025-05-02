import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/models/add_expense_model.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/expense_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/add_expense_utils.dart';
import 'package:my_new_app/utils/create_group_utils.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:my_new_app/locator.dart';

class EditExpenseDialog extends StatefulWidget {
  final String groupID;
  final String expenseID;
  final String initialDescription;
  final double initialAmount;
  final Map<String, double> initialPaidBy;
  final List<String> initialSplitBetween;
  final Map<String, double> initialSplitDetails;
  final String initialSplitType;
  final String initialExpenseType;
  final BuildContext parentContext;

  EditExpenseDialog({
    Key? key,
    required this.groupID,
    required this.expenseID,
    required this.initialDescription,
    required this.initialAmount,
    required this.initialPaidBy,
    required this.initialSplitBetween,
    required this.initialSplitDetails,
    required this.initialSplitType,
    required this.initialExpenseType,
    required this.parentContext,
  }) : super(key: key);

  @override
  _EditExpenseDialogState createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  late TextEditingController descriptionController;
  late double totalAmount;
  late Map<String, double> paidBy;
  late List<String> splitBetween;
  late Map<String, double> splitDetails;
  late String splitType;
  late String selectedExpenseType;

  late GroupMemberService memberService;
  late List<GroupMemberModel> members = [];

  final List<String> expenseTypes = [
    "Entertainment",
    "Outing",
    "Food",
    "Travel",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    totalAmount = widget.initialAmount;
    paidBy = Map<String, double>.from(widget.initialPaidBy);
    splitBetween = List<String>.from(widget.initialSplitBetween);
    splitDetails = Map<String, double>.from(widget.initialSplitDetails);
    splitType = widget.initialSplitType;
    // selectedExpenseType = widget.initialExpenseType;
    selectedExpenseType = expenseTypes.firstWhere(
      (type) => type.toLowerCase() == widget.initialExpenseType.toLowerCase(),
      orElse: () => expenseTypes[0],
    );

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
      builder: (_) => PaidByDialog(members: members, initialPaidBy: paidBy),
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
      builder:
          (_) => SplitBetweenDialog(
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

  void _selectSplitType(BuildContext context) async {
    if (splitBetween.isEmpty || totalAmount == 0.0) {
      showOverlayNotification(
        widget.parentContext,
        "Select paid by and split between members first",
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (_) => SplitTypeDialog(
            members: members,
            selectedMembers: splitBetween,
            totalAmount: totalAmount,
            initialSplitType: splitType,
            initialSplitDetails: splitDetails,
            parentContext: widget.parentContext,
          ),
    );

    if (result != null) {
      setState(() {
        splitType = result['type'];
        splitDetails = Map<String, double>.from(result['details']);
      });
    }
  }

  void _confirmEdit(BuildContext context) {
    if (descriptionController.text.trim().isEmpty ||
        paidBy.isEmpty ||
        splitBetween.isEmpty ||
        splitDetails.isEmpty ||
        splitType.isEmpty) {
      showOverlayNotification(
        widget.parentContext,
        "Please fill in all required details",
      );
      return;
    }

    final model = EditExpenseModel(
      expenseID: widget.expenseID,
      description: descriptionController.text.trim(),
      amount: totalAmount,
      tag: selectedExpenseType,
      splitBetween: splitDetails,
      paidBy: paidBy,
    );

    final AddExpenseService expenseService = locator<AddExpenseService>();
    expenseService.updateExpense(model, context);

    Navigator.of(context).pop({
      'description': model.description,
      'paidBy': model.paidBy,
      'amount': model.amount,
      'splitBetween': model.splitBetween.keys.toList(),
      'splitType': splitType,
      'splitDetails': model.splitBetween,
      'expenseType': model.tag,
    });
    Navigator.pop(context);
  }

  Widget buildLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildAmountLine(
    String label,
    String value,
    VoidCallback onTap,
    Color color,
  ) {
    return ListTile(
      title: Text(label, style: TextStyle(color: color)),
      trailing: ElevatedButton(onPressed: onTap, child: Text("Select")),
    );
  }

  // Widget buildActionButton(
  //   double width,
  //   String label,
  //   Color color,
  //   VoidCallback onPressed,
  // ) {
  //   return ElevatedButton(
  //     onPressed: onPressed,
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: color,
  //       padding: EdgeInsets.symmetric(horizontal: width * 0.1, vertical: 12),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //     ),
  //     child: Text(label),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 193, 249, 39), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.searchBoxDark
                    : AppColors.searchBoxLight,
          ),
          padding: EdgeInsets.all(width * 0.025),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Expense",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textDark
                            : AppColors.textLight,
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
                buildLabel(
                  "Description:",
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textDark
                            : AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter the description",
                    hintStyle: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white38
                              : AppColors.textLight2,
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildLabel(
                  "Expense Type:",
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedExpenseType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  dropdownColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.searchBoxDark
                          : AppColors.searchBoxLight,
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textDark
                            : AppColors.textLight,
                  ),
                  items:
                      expenseTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedExpenseType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                buildAmountLine(
                  'Paid By',
                  'Select',
                  _selectPaidBy,
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                ListTile(
                  title: Text(
                    "Amount",
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textDark
                              : AppColors.textLight,
                    ),
                  ),
                  trailing: Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : AppColors.textLight,
                      fontSize: width * 0.045,
                    ),
                  ),
                ),
                buildAmountLine(
                  'Split Between',
                  'Select',
                  _selectSplitBetween,
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                buildAmountLine(
                  'Split Type',
                  'Select',
                  () => _selectSplitType(context),
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildActionButton(
                      width,
                      "Save",
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.greenButtondarktheme
                          : AppColors.greenButtonwhitetheme,
                      () => _confirmEdit(context),
                    ),
                    buildActionButton(
                      width,
                      "Cancel",
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.redbuttondarktheme
                          : AppColors.redbuttonwhitetheme,
                      () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
