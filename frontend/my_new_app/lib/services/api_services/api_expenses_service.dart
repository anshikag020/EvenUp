import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/add_expense_model.dart';
import 'package:my_new_app/services/service%20interfaces/expense_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddExpenseServiceImpl extends AddExpenseService {
  final String baseUrl;

  AddExpenseServiceImpl(this.baseUrl);
  // final String baseUrl = "https://your-backend-url.com/api"; // Replace this

  @override
  Future<void> sendExpense(
    AddExpenseModel newExpense,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = newExpense.toJson();

    final response = await http.post(
      Uri.parse('$baseUrl/api/add_expense'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        showCustomSnackBar(
          context,
          "New expense addded successfully",
          backgroundColor: const Color.fromRGBO(6, 131, 81, 1),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense addition failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception('Failed to add Expense: ${response.statusCode}');
    }
  }

  @override
  Future<bool> deleteExpense(BuildContext context, String expenseID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/delete_expense'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'expense_id': expenseID}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        showCustomSnackBar(
          context,
          "Expense deleted successfully",
          backgroundColor: const Color.fromRGBO(6, 131, 81, 1),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense deletion failed'),
            backgroundColor: Colors.red,
          ),
        );
        return false; 
      }
    } else {
      throw Exception('Failed to delete Expense: ${response.statusCode}');
    }
  }


  @override
  Future<void> updateExpense(
    EditExpenseModel newExpense,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = newExpense.toJson();

    final response = await http.put(
      Uri.parse('$baseUrl/api/edit_expense'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        showCustomSnackBar(
          context,
          "New expense addded successfully",
          backgroundColor: const Color.fromRGBO(6, 131, 81, 1),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense addition failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception('Failed to add Expense: ${response.statusCode}');
    }
  }

}


class BalanceSettleServiceImpl extends SettleService {
    final String baseUrl;

    BalanceSettleServiceImpl(this.baseUrl);

    @override
    Future<bool> settleBalance(String groupId, String receiver) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');

      final response = await http.put(
        Uri.parse('$baseUrl/api/settle_balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'group_id': groupId, 'receiver': receiver}),
      );

      if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
          return true;
        } else {
          return false; 
        }
      } else {
        throw Exception('Failed to settle the Balance: ${response.statusCode}');
      }

    }


    @override
    Future<bool> remindBalance(String groupId, String receiver) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');

      final response = await http.post(
        Uri.parse('$baseUrl/api/remind_user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'group_id': groupId, 'receiver_username': receiver}),
      );

      if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
          return true;
        } else {
          return false; 
        }
      } else {
        throw Exception('Failed to settle the Balance: ${response.statusCode}');
      }

    }



}



