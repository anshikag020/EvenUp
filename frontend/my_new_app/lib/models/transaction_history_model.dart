class TransactionModel {
  final String name;
  final String amount;

  TransactionModel({
    required this.name,
    required this.amount,
  });

  // ✅ This is what you need
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}
