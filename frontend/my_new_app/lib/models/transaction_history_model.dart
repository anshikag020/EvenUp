class TransactionModel {
  final String groupName; 
  final String name;
  final String amount;
  final String type; 

  TransactionModel({
    required this.groupName, 
    required this.name,
    required this.amount,
    required this.type, 
  });

  // ✅ This is what you need
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      groupName: json['groupName'] ?? 'unkown' ,
      name: json['name'] ?? '',
      amount: json['amount'] ?? '0',
      type: json['type'] ?? '1', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName, 
      'name': name,
      'amount': amount,
      'type': type, 
    };
  }
}
