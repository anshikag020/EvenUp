import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';

class ApiGroupService implements GroupService {
  final String baseUrl;

  ApiGroupService({required this.baseUrl});

  @override
  Future<List<GroupModel>> fetchGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/groups'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load group data');
    }
  }
}
