import 'package:my_new_app/models/groups_section_model.dart';

abstract class GroupService {
  Future<List<GroupModel>> fetchGroups();
}

abstract class GroupMemberService {
  Future<List<GroupMemberModel>> fetchMembersForGroup(String groupId);
}

abstract class ExpenseService {
  Future<List<ExpenseModel>> fetchAllExpenses();
}

abstract class DetailedExpenseService {
  Future<DetailedExpenseModel> fetchExpenseById(String expenseID);
}

abstract class BalanceService {
  Future<List<Balance>> fetchBalances();
}
