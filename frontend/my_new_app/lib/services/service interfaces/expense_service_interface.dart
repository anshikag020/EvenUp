import 'package:flutter/material.dart';
import 'package:my_new_app/models/add_expense_model.dart';

abstract class AddExpenseService {
  Future<void> sendExpense(AddExpenseModel newExpense, BuildContext context);
  Future<bool> deleteExpense(BuildContext context, String expenseID);
  Future<void> updateExpense(EditExpenseModel newExpense, BuildContext context);
}

abstract class SettleService {
  Future<bool> settleBalance(String groupId, String receiverId);
  Future<bool> remindBalance(String groupId, String receiverId);
}
