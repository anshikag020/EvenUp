import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';

class MockGroupService implements GroupService {
  @override
  Future<List<GroupModel>> fetchGroups() async {
    final String response = await rootBundle.loadString('lib/data/groups_section_data.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => GroupModel.fromJson(json)).toList();
  }
}
