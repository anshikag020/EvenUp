import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/exit_group_models.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/api_services/utility_check_invalid_token.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
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
    final List<dynamic> groupList = data['groups'] ?? [];

    List<GroupModel> groups =
        groupList.map((groupJson) => GroupModel.fromJson(groupJson)).toList();

    return groups;
  }
}

class ConfirmOTSImpl implements ConfirmOTS {
  final String baseUrl;

  ConfirmOTSImpl({required this.baseUrl});

  @override
  Future<void> confirmOTS(BuildContext context, String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/ots/confirm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupId}),
    );

    // print(response.statusCode);
    if (response.statusCode == 401) {
      redirectToLoginPage(context);
    }

    // print(response.statusCode);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showCustomSnackBar(
        context,
        data['message'],
        backgroundColor: Color.fromRGBO(156, 13, 40, 1),
      );
    } else {
      throw Exception("Failed to confirm OTS button");
    }
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
      return members
          .map((e) => GroupMemberModel.fromJson(e['username']))
          .toList();
    } else {
      throw Exception("Failed to load group members");
    }
  }
}

class GroupUserPanelImpl implements GroupUserPanelService {
  final String baseUrl;

  GroupUserPanelImpl({required this.baseUrl});

  @override
  Future<ExitGroupResponse> exitGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/exit_group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupId}),
    );

    if (response.statusCode == 200) {
      return ExitGroupResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to exit group: ${response.body}');
    }
  }

  @override
  Future<SelectAdminResponse> selectAnotherAdmin(
    String groupId,
    String newAdmin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/select_another_admin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupId, 'new_admin': newAdmin}),
    );

    if (response.statusCode == 200) {
      return SelectAdminResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to select another admin: ${response.body}');
    }
  }

  @override
  Future<bool> deleteGroup(String groupId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/delete_group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return true;
      } else {
        showCustomSnackBar(context, data['message']);
        return false;
      }
    } else {
      throw Exception('Failed to select another admin: ${response.body}');
    }
  }
}

class ApiExpenseService implements ExpenseService {
  final String baseUrl;

  ApiExpenseService({required this.baseUrl});

  @override
  Future<List<ExpenseModel>> fetchAllExpenses(String groupID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.post(
      Uri.parse('$baseUrl/api/get_expenses'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupID}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> expenses = json['expenses'] ?? [];
      return expenses.map((e) => ExpenseModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load expenses: ${response.statusCode}');
    }
  }
}

class ApiBalanceService implements BalanceService {
  final String baseUrl;

  ApiBalanceService({required this.baseUrl});

  @override
  Future<List<Balance>> fetchBalances(String groupID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.post(
      Uri.parse('$baseUrl/api/get_balances'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'group_id': groupID}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> balances = json['balances'] ?? [];
      // print(balances); 
      // print( balances );
      return balances.map((e) => Balance.fromJson(e)).toList();

      // final List<dynamic> data = json.decode(response.body);
      // return data.map((json) => Balance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load balances');
    }
  }
}

class ApiDetailedExpenseService implements DetailedExpenseService {
  final String baseUrl;

  ApiDetailedExpenseService({required this.baseUrl});

  @override
  Future<DetailedExpenseModel> fetchExpenseById(String expenseID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.post(
      Uri.parse('$baseUrl/api/get_expense_details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'expense_id': expenseID}),
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data['status'] != true) {
        throw Exception('Failed to fetch expense');
      }
      return DetailedExpenseModel.fromJson(data);
    } else {
      throw Exception("Failed to load group members");
    }
  }
}
