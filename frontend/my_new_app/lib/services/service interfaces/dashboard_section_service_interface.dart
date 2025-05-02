// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:my_new_app/models/dashboard_section_models.dart';

abstract class CreateGroupService {
  Future<void> createNewGroup(CreateGroupModel groupModel, BuildContext context);
}

abstract class CreatePrivateSplitService {
  Future<void> createNewPrivateSplit(CreatePrivateSplitModel privateSplitModel, BuildContext context);
}

abstract class JoinGroupService {
  Future<void> joinGroupByCode(JoinGroupModel joinModel, BuildContext context);
}

abstract class ResetPasswordFlowService {
  Future<bool> resetPassword(String oldPassword, String newPassword);
}
 