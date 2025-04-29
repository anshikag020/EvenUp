class AddExpenseModel {
  final String groupId;
  final String description;
  final double amount;
  final String tag;
  final Map<String, double> splitBetween;
  final Map<String, double> paidBy;

  AddExpenseModel({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.tag,
    required this.splitBetween,
    required this.paidBy,
  });

  Map<String, dynamic> toJson() => {
        "group_id": groupId,
        "description": description,
        "amount": amount,
        "tag": tag,
        "split_between": splitBetween,
        "paid_by": paidBy,
      };
}