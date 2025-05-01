import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/add_expense_model.dart';
import 'package:my_new_app/services/service%20interfaces/expense_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddExpenseServiceImpl extends AddExpenseService{

  final String baseUrl;

  AddExpenseServiceImpl(this.baseUrl);
  // final String baseUrl = "https://your-backend-url.com/api"; // Replace this

  @override
  Future<void> sendExpense( AddExpenseModel newExpense, BuildContext context) async {
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
}





// class ApiGroupService implements GroupService {
//   final String baseUrl;

//   ApiGroupService({required this.baseUrl});

//   @override
//   Future<List<GroupModel>> fetchGroups(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('jwtToken');

//     final response = await http.get(
//       Uri.parse('$baseUrl/api/get_groups'),
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     // print(response.statusCode);
//     if (response.statusCode == 401) {
//       redirectToLoginPage(context);
//     }

//     final data = jsonDecode(response.body);
//     final List<dynamic> groupList = data['groups'];

//     List<GroupModel> groups =
//         groupList.map((groupJson) => GroupModel.fromJson(groupJson)).toList();

//     return groups;
//   }
// }


