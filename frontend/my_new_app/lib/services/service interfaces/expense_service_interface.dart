import 'package:flutter/material.dart';
import 'package:my_new_app/models/add_expense_model.dart';

abstract class AddExpenseService {
  Future<void> sendExpense(AddExpenseModel newExpense, BuildContext context);
}