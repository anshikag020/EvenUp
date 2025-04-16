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
  final String amount;

  ExpenseModel({
    required this.expenseID, 
    required this.description,
    required this.amount,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expenseID: json['expenseID'],
      description: json['description'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseID': expenseID,
      'description': description,
      'amount': amount,
    };
  }
}


class DetailedExpenseModel {
  final String id;
  final String description;
  final String amount;
  final List<String> paidBy;
  final List<String> owedBy;
  final String lastUpdatedBy;

  DetailedExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.owedBy,
    required this.lastUpdatedBy,
  });

  factory DetailedExpenseModel.fromJson(Map<String, dynamic> json) {
    return DetailedExpenseModel(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
      paidBy: List<String>.from(json['paidBy']),
      owedBy: List<String>.from(json['owedBy']),
      lastUpdatedBy: json['lastUpdatedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'owedBy': owedBy,
      'lastUpdatedBy': lastUpdatedBy,
    };
  }
}



class Balance {
  final String balanceID;
  final String user1;
  final String user2;
  final int amount;

  Balance({
    required this.balanceID,
    required this.user1,
    required this.user2,
    required this.amount,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      balanceID: json['balanceID'],
      user1: json['user1'],
      user2: json['user2'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balanceID': balanceID,
      'user1': user1,
      'user2': user2,
      'amount': amount,
    };
  }
}


