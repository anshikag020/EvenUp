import 'package:my_new_app/models/groups_section_model.dart';

abstract class GroupService {
  Future<List<GroupModel>> fetchGroups();
}
