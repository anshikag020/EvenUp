class PingedSectionModel {
  final String transacID; 
  final String groupName; 
  final String username;
  final int amount;

  PingedSectionModel({
    required this.transacID, 
    required this.groupName, 
    required this.username,
    required this.amount, 
  });

  // ✅ This is what you need
  factory PingedSectionModel.fromJson(Map<String, dynamic> json) {
    return PingedSectionModel(
      transacID: json['trnasacID'] ?? 'XXXXXX' ,
      groupName: json['groupName'] ?? 'unkown' ,
      username: json['username'] ?? '',
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transacID' : transacID,
      'groupName': groupName, 
      'username': username,
      'amount': amount,
    };
  }
}
