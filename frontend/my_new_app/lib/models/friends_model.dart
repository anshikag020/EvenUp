class Friend {
  final String sender;
  final String receiver;
  final String name;
  final double balance;

  Friend({
    required this.sender,
    required this.receiver,
    required this.name,
    required this.balance,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      sender: json['sender'],
      receiver: json['receiver'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
