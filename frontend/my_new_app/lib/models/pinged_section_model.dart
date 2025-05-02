// class PingedSectionModel {
//   final String transacID;
//   final String groupName;
//   final String username;
//   final int amount;

//   PingedSectionModel({
//     required this.transacID,
//     required this.groupName,
//     required this.username,
//     required this.amount,
//   });

//   // ✅ This is what you need
//   factory PingedSectionModel.fromJson(Map<String, dynamic> json) {
//     return PingedSectionModel(
//       transacID: json['trnasacID'] ?? 'XXXXXX',
//       groupName: json['groupName'] ?? 'unkown',
//       username: json['username'] ?? '',
//       amount: json['amount'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'transacID': transacID,
//       'groupName': groupName,
//       'username': username,
//       'amount': amount,
//     };
//   }
// }

class PingedSectionModel {
  final String transacID;
  final String groupName;
  final String otherMember;
  final bool isSender; 
  final double amount;

  PingedSectionModel({
    required this.transacID,
    required this.groupName,
    required this.otherMember,
    required this.isSender, 
    required this.amount,
  });

  factory PingedSectionModel.fromJson(Map<String, dynamic> json) {
    return PingedSectionModel(
      transacID: json['transaction_id'] ?? 'XXXXXX',
      groupName: json['group_name'] ?? 'unkown',
      otherMember: json['other_member'] ?? '',
      isSender: json['is_sender'] ?? 'false',
      amount: json['amount'].toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transacID,
      'group_name': groupName,
      'other_member': otherMember,
      'is_sender': isSender, 
      'amount': amount,
    };
  }
}
