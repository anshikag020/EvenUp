import 'package:flutter/material.dart';
import 'package:my_new_app/models/exit_group_models.dart';
import 'package:my_new_app/models/groups_section_model.dart';

abstract class GroupService {
  Future<List<GroupModel>> fetchGroups(BuildContext context);
}


abstract class ConfirmOTS {
  Future<void> confirmOTS(BuildContext context, String groupId); 
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
  Future<ExitGroupResponse> exitGroup(String groupId);
  Future<SelectAdminResponse> selectAnotherAdmin(String groupId, String newAdmin);
  Future<bool> deleteGroup(String groupId, BuildContext context); 
}

