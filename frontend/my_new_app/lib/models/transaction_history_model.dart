class TransactionModel {
  final String transactionId;
  final String groupName; 
  final String name;
  final int amount;
  final bool type; 
  final String timestamp; 

  TransactionModel({
    required this.transactionId,
    required this.groupName, 
    required this.name,
    required this.amount,
    required this.type, 
    required this.timestamp
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id'] ?? 'unkown',
      groupName: json['group_name'] ?? 'unkown' ,
      name: json['other_user'] ?? '',
      amount: json['amount'] ?? 0,
      type: json['is_sender'] ?? true, 
      timestamp: json['timestamp'] ?? 'unknown', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId, 
      'groupName': groupName, 
      'name': name,
      'amount': amount,
      'type': type, 
      'timestamp': timestamp
    };
  }
}
