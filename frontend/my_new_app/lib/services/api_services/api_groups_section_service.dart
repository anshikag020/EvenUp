import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';

class ApiGroupService implements GroupService {
  final String baseUrl;

  ApiGroupService({required this.baseUrl});

  @override
  Future<List<GroupModel>> fetchGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/groups'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load group data');
    }
  }
}


class ApiGroupMemberService implements GroupMemberService {
  final String baseUrl;

  ApiGroupMemberService({required this.baseUrl});

  @override
  Future<List<GroupMemberModel>> fetchMembersForGroup(String groupId) async {
    final response = await http.get(Uri.parse('$baseUrl/groups/$groupId/members'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => GroupMemberModel.fromJson(e)).toList();
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

