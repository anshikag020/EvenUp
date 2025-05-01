import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';

class MockGroupService implements GroupService {
  @override
  Future<List<GroupModel>> fetchGroups(BuildContext context) async {
    final String response = await rootBundle.loadString(
      'lib/data/groups_section_data.json',
    );
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => GroupModel.fromJson(json)).toList();
  }
}


class MockGroupMemberService implements GroupMemberService {
  @override
  Future<List<GroupMemberModel>> fetchMembersForGroup(String groupId) async {
    final path = 'lib/data/${groupId}_members_data.json';

    try {
      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = jsonDecode(response);
      return data.map((e) => GroupMemberModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ Error loading file for $groupId: $e");
      return [];
    }
  }
}

class MockExpenseService implements ExpenseService {
  @override
  Future<List<ExpenseModel>> fetchAllExpenses(String groupID) async {
    final String response = await rootBundle.loadString('lib/data/expenses_data.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((e) => ExpenseModel.fromJson(e)).toList();
  }
}


class MockDetailedExpenseService implements DetailedExpenseService {
  @override
  Future<DetailedExpenseModel> fetchExpenseById(String id) 
  async {
    final String response = await rootBundle.loadString('lib/data/detailed_expense_data.json');
    final dynamic data = jsonDecode(response);

    return DetailedExpenseModel.fromJson(data);
  }
}


class MockBalanceService implements BalanceService {
  @override
  Future<List<Balance>> fetchBalances(String groupID) async {
    final String response = await rootBundle.loadString('lib/data/all_balances_data.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => Balance.fromJson(json)).toList();
  }
}


