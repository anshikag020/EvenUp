import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';
import 'package:my_new_app/utils/general_utils.dart';

class ExpenseDetailDialog extends StatelessWidget {
  final String expenseID;
  final VoidCallback onDelete;

  const ExpenseDetailDialog({
    Key? key,
    required this.expenseID,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    const double maxListHeight = 100.0;
    final service = GetIt.instance<DetailedExpenseService>();

    return FutureBuilder<DetailedExpenseModel>(
      future: service.fetchExpenseById(expenseID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Dialog(
            backgroundColor: Color(0xFF1E1E1E),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        final expense = snapshot.data!;
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
              // boxShadow: [
              //   BoxShadow(
              //     color:  Color(0xFFCBFF41).withOpacity(0.6),
              //     spreadRadius:1,
              //     blurRadius: 15,
              //   ),
              // ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color:  Color(0xFF1E1E1E).withOpacity(0.95),
              ),
              padding: EdgeInsets.all(width * 0.045),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildLabel('Description:'),
                          buildText(expense.description),
                          const SizedBox(height: 16),
                          buildLabel('Paid by:'),
                          buildList(expense.paidBy, maxListHeight),
                          const SizedBox(height: 16),
                          buildLabel('Owed by:'),
                          buildList(expense.owedBy, maxListHeight),
                          const SizedBox(height: 24),
                          Text(
                            'Last Updated by: ${expense.lastUpdatedBy}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Text(
                        'Amount: ₹${expense.amount}',
                        style: TextStyle(
                          color: const Color(0xFFCBFF41),
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color:  Color(0xFFCBFF41).withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildActionButton(
                            context,
                            icon: Icons.edit,
                            label: 'Edit',
                            color: const Color.fromARGB(255, 203, 255, 65),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmationDialog(
                                  message: 'Are you sure you want to edit this expense?',
                                  onConfirm: () {
                                    // handle logic here 
                                    Navigator.pop(context);
                                    showCustomSnackBar(
                                      context,
                                      "Expense edited successfully",
                                      backgroundColor: const Color.fromARGB(255, 129, 171, 13)
                                    );
                                  },
                                  onCancel: () => Navigator.pop(context),
                                ),
                              );
                            },
                          ),
                          buildActionButton(
                            context,
                            icon: Icons.delete,
                            label: 'Delete',
                            color: const Color.fromARGB(255, 255, 82, 82),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmationDialog(
                                  message: 'Are you sure you want to delete this expense?',
                                  onConfirm: () {
                                    onDelete(); // <-- callback trigger
                                    showCustomSnackBar(
                                      context,
                                      "Expense deleted successfully",
                                      backgroundColor: const Color.fromARGB(255, 189, 48, 48)
                                    );
                                  },
                                  onCancel: () => Navigator.pop(context),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Widget buildList(List<String> data, double maxHeight) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: data.length > 4 ? maxHeight : double.infinity,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: data.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.white, size: 10),
              const SizedBox(width: 8),
              Text(data[index], style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    double width = MediaQuery.of(context).size.width;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: width * 0.045),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: width * 0.043,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
