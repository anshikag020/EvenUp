class GroupModel {
  final String name;
  final int size;
  final String description;
  final String inviteCode;
  final String groupType;

  GroupModel({
    required this.name,
    required this.size,
    required this.description,
    required this.inviteCode,
    required this.groupType,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      description: json['description'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      groupType: json['groupType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'size': size,
        'description': description,
        'inviteCode': inviteCode,
        'groupType': groupType,
      };
}
