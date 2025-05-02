class ExitGroupResponse {
  final bool status;
  final String message;
  final bool? isAdmin;
  final List<Member>? membersList;

  ExitGroupResponse({
    required this.status,
    required this.message,
    this.isAdmin,
    this.membersList,
  });

  factory ExitGroupResponse.fromJson(Map<String, dynamic> json) {
    return ExitGroupResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      isAdmin: json['is_admin'],
      membersList: json['members_list'] != null
          ? (json['members_list'] as List)
              .map((e) => Member.fromJson(e))
              .toList()
          : null,
    );
  }
}

class Member {
  final String username;
  final String name;

  Member({required this.username, required this.name});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      username: json['username'],
      name: json['name'],
    );
  }
}


class SelectAdminResponse {
  final bool status;
  final String message;

  SelectAdminResponse({required this.status, required this.message});

  factory SelectAdminResponse.fromJson(Map<String, dynamic> json) {
    return SelectAdminResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}
