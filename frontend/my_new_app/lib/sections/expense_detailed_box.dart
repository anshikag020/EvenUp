import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';


class ExpenseDetailDialog extends StatelessWidget {
  final String expenseID;
  final VoidCallback onDelete;

  ExpenseDetailDialog({
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
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(width*0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Paid by:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: expense.paidBy.length > 4 ? maxListHeight : double.infinity,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: expense.paidBy.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.white, size: 12),
                                  const SizedBox(width: 8),
                                  Text(
                                    expense.paidBy[index],
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Owed by:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: expense.owedBy.length > 4 ? maxListHeight : double.infinity,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: expense.owedBy.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.white, size: 12),
                                  const SizedBox(width: 8),
                                  Text(
                                    expense.owedBy[index],
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Last Updated by: ${expense.lastUpdatedBy}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount: ₹${expense.amount}',
                      style: TextStyle(
                        color: Color(0xFFCBFF41),
                        fontSize: width *0.04,
                        // fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10,), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmationDialog(
                                message: 'Are you sure you want to edit this expense?',
                                onConfirm: () {
                                  Navigator.pop(context); // Close the dialog
                                  // ✅ Place your group creation logic here
                                },
                                onCancel: () {
                                  Navigator.pop(context); // Just close the dialog
                                },
                              ),
                            ); 
                          },
                          icon: Icon(Icons.edit, color: Color.fromARGB(255, 248, 251, 58), size: width*0.04,),
                          label: Text(
                            'Edit',
                            style: TextStyle( fontSize: width*0.04,color: Color.fromARGB(255, 248, 251, 58)),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmationDialog(
                                message: 'Are you sure you want to delete this expense?',
                                onConfirm: () {
                                  Navigator.pop(context); // Close the dialog
                                  // ✅ Place your group creation logic here
                                },
                                onCancel: () {
                                  Navigator.pop(context); // Just close the dialog
                                },
                              ),
                            ); 
                          },
                          icon: Icon(Icons.delete, color: Colors.redAccent, size: width*0.04,),
                          label: Text(
                            'Delete',
                            style: TextStyle(fontSize:width*0.04  ,color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                    
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
