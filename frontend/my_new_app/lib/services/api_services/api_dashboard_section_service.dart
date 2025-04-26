import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/dashboard_section_models.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupServiceImpl implements CreateGroupService {
  final String baseUrl;

  CreateGroupServiceImpl(this.baseUrl);

  @override
  Future<void> createNewGroup(CreateGroupModel newGroup, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = newGroup.toJson();

    final response = await http.put(
      Uri.parse('$baseUrl/api/create_group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
         showCustomSnackBar(
            context,
            "New group created successfully",
            backgroundColor: const Color.fromRGBO(6, 131, 81, 1)
          );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group creation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception('Failed to create group: ${response.statusCode}');
    }
  }
}





class JoinGroupImpl implements JoinGroupService {
  final String baseUrl;

  JoinGroupImpl(this.baseUrl);

  @override
  Future<void> joinGroupByCode(JoinGroupModel joinModel, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = joinModel.toJson();

    final response = await http.put(
      Uri.parse('$baseUrl/api/join_group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
          showCustomSnackBar(
            context,
            "Joined new group successfully",
            backgroundColor: const Color.fromARGB(255, 175, 155, 39)
          );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group Joining failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception('Failed to join group: ${response.statusCode}');
    }
  }
}
