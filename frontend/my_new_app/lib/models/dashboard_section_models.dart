class CreateGroupModel {
  final String groupName; 
  final String groupDescription;
  final String groupType;

  CreateGroupModel({
    required this.groupName,
    required this.groupDescription,
    required this.groupType,
  });

  factory CreateGroupModel.fromJson(Map<String, dynamic> json) {
    return CreateGroupModel(
      groupName: json['group_name'],
      groupDescription: json['group_description'],
      groupType: json['group_type']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_name': groupName,
      'group_description': groupDescription,
      'group_type': groupType,
    };
  }
}




class CreatePrivateSplitModel {
  final String otheruser; 

  CreatePrivateSplitModel({
    required this.otheruser,
  });

  factory CreatePrivateSplitModel.fromJson(Map<String, dynamic> json) {
    return CreatePrivateSplitModel(
      otheruser: json['username_2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username_2': otheruser,
    };
  }
}




class JoinGroupModel {
  final String inviteCode; 

  JoinGroupModel({
    required this.inviteCode,
  });

  factory JoinGroupModel.fromJson(Map<String, dynamic> json) {
    return JoinGroupModel(
      inviteCode: json['inviteCode']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invite_Code': inviteCode
    };
  }
}
