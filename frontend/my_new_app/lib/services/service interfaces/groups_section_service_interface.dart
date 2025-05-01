import 'package:flutter/material.dart';
import 'package:my_new_app/models/groups_section_model.dart';

abstract class GroupService {
  Future<List<GroupModel>> fetchGroups(BuildContext context);
}

abstract class GroupMemberService {
  Future<List<GroupMemberModel>> fetchMembersForGroup(String groupId);
}

abstract class ExpenseService {
  Future<List<ExpenseModel>> fetchAllExpenses(String groupID);
}

abstract class DetailedExpenseService {
  Future<DetailedExpenseModel> fetchExpenseById(String expenseID);
}

abstract class BalanceService {
  Future<List<Balance>> fetchBalances(String groupId);
}

abstract class GroupUserPanelService {
  Future<void> exitGroup(String groupId);
  // Future<void> deleteGroup(String groupId); 
}

