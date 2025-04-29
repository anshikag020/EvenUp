import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/api_services/utility_check_invalid_token.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiGroupService implements GroupService {
  final String baseUrl;

  ApiGroupService({required this.baseUrl});

  @override
  // Future<List<GroupModel>> fetchGroups() async {
  //   final response = await http.get(Uri.parse('$baseUrl/groups'));
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = jsonDecode(response.body);
  //     return data.map((json) => GroupModel.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load group data');
  //   }
  // }
  Future<List<GroupModel>> fetchGroups(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/get_groups'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // print(response.statusCode);
    if (response.statusCode == 401) {
      redirectToLoginPage(context);
    }

    final data = jsonDecode(response.body);
    final List<dynamic> groupList = data['groups'];

    List<GroupModel> groups =
        groupList.map((groupJson) => GroupModel.fromJson(groupJson)).toList();

    return groups;
  }
}

class ApiGroupMemberService implements GroupMemberService {
  final String baseUrl;

  ApiGroupMemberService({required this.baseUrl});

  @override
  Future<List<GroupMemberModel>> fetchMembersForGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/get_members?group_id=$groupId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // final List<dynamic> data = jsonDecode(response.body);
      // final List<dynamic> data = jsonDecode(response.body);
      // return data.map((e) => GroupMemberModel.fromJson(e)).toList();

      final Map<String, dynamic> json = jsonDecode(response.body);
      List<dynamic> members = json['members'];
      return members.map((e) => GroupMemberModel.fromJson(e['username'])).toList() ; 
    } else {
      throw Exception("Failed to load group members");
    }
  }
}

class ApiExpenseService implements ExpenseService {
  final String baseUrl;

  ApiExpenseService({required this.baseUrl});

  @override
  Future<List<ExpenseModel>> fetchAllExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ExpenseModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }
}

class ApiDetailedExpenseService implements DetailedExpenseService {
  final String baseUrl;

  ApiDetailedExpenseService({required this.baseUrl});

  @override
  Future<DetailedExpenseModel> fetchExpenseById(String expenseID) async {
    final response = await http.get(Uri.parse('$baseUrl/$expenseID'));

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      return DetailedExpenseModel.fromJson(data);
    } else {
      throw Exception("Failed to load group members");
    }
  }
}

class ApiBalanceService implements BalanceService {
  final String baseUrl;

  ApiBalanceService({required this.baseUrl});

  @override
  Future<List<Balance>> fetchBalances() async {
    final response = await http.get(Uri.parse('$baseUrl/balances'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Balance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load balances');
    }
  }
}
