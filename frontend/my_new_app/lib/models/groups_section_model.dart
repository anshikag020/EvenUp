class GroupModel {
  final String groupID; 
  final String name;
  final int size;
  final String description;
  final String inviteCode;
  final String groupType;

  GroupModel({
    required this.groupID,
    required this.name,
    required this.size,
    required this.description,
    required this.inviteCode,
    required this.groupType,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      groupID: json['groupID'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      description: json['description'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      groupType: json['groupType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'groupID': groupID, 
        'name': name,
        'size': size,
        'description': description,
        'inviteCode': inviteCode,
        'groupType': groupType,
      };
}

class GroupMemberModel {
  final String name;

  GroupMemberModel({required this.name});

  factory GroupMemberModel.fromJson(dynamic value) {
    return GroupMemberModel(name: value.toString());
  }
}


// lib/models/expense_model.dart

class ExpenseModel {
  final String expenseID; 
  final String description;
  final int amount;

  ExpenseModel({
    required this.expenseID, 
    required this.description,
    required this.amount,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expenseID: json['expense_id'],
      description: json['description'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseID,
      'description': description,
      'amount': amount,
    };
  }
}


class DetailedExpenseModel {
  final String description;
  final String amount;
  final String tag; 
  final List<String> paidBy;
  final List<String> owedBy;
  final String lastUpdatedBy;

  DetailedExpenseModel({
    required this.description,
    required this.amount,
    required this.tag,
    required this.paidBy,
    required this.owedBy,
    required this.lastUpdatedBy,
  });

  factory DetailedExpenseModel.fromJson(Map<String, dynamic> json) {
  return DetailedExpenseModel(
    description: json['description'] ?? '',
    amount: json['amount'].toString(),
    tag: json['tag'] ?? '', 
    paidBy: (json['paid_by'] as Map<String, dynamic>).keys.toList(),
    owedBy: (json['owed_by'] as Map<String, dynamic>).keys.toList(),
    lastUpdatedBy: json['last_modified'] ?? '',
  );
}


  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'tag': tag,
      'paid_by': paidBy,
      'owed_by': owedBy,
      'last_modified': lastUpdatedBy,
    };
  }
}




class Balance {

  final String user1;
  final String user2;
  final int amount;

  Balance({
    required this.user1,
    required this.user2,
    required this.amount,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      user1: json['sender'],
      user2: json['receiver'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': user1,
      'receiver': user2,
      'amount': amount,
    };
  }
}

class ExpenseTileModel {
  final String name;

  ExpenseTileModel({required this.name});

  factory ExpenseTileModel.fromJson(dynamic value) {
    return ExpenseTileModel(name: value.toString());
  }
}