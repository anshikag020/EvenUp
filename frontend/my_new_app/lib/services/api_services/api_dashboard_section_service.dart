import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/analysis_model.dart';
import 'package:my_new_app/models/dashboard_section_models.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/utils/general_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupServiceImpl implements CreateGroupService {
  final String baseUrl; 

  CreateGroupServiceImpl(this.baseUrl);

  @override
  Future<void> createNewGroup(
    CreateGroupModel newGroup,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = newGroup.toJson();

    final response = await http.post(
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
          backgroundColor: const Color.fromRGBO(6, 131, 81, 1),
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

class CreatePrivateSplitServiceImpl implements CreatePrivateSplitService {
  final String baseUrl;

  CreatePrivateSplitServiceImpl(this.baseUrl);

  @override
  Future<void> createNewPrivateSplit(
    CreatePrivateSplitModel newPrivateSplit,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = newPrivateSplit.toJson();

    final response = await http.post(
      Uri.parse('$baseUrl/api/create_private_split'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print(data);

      if (data['status'] == true) {
        showCustomSnackBar(
          context,
          "New split created successfully",
          backgroundColor: const Color.fromARGB(255, 6, 79, 131),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Split creation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception('Failed to create Split: ${response.statusCode}');
    }
  }
}

class JoinGroupImpl implements JoinGroupService {
  final String baseUrl;

  JoinGroupImpl(this.baseUrl);

  @override
  Future<void> joinGroupByCode(
    JoinGroupModel joinModel,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final body = joinModel.toJson();

    final response = await http.post(
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
          backgroundColor: const Color.fromARGB(255, 175, 155, 39),
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

class ResetPasswordFlowImpl implements ResetPasswordFlowService {
  final String baseUrl;

  ResetPasswordFlowImpl(this.baseUrl);

  @override
  Future<bool> resetPassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.post(
      Uri.parse('$baseUrl/api/reset_password'), 
      headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',},      
      body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
    );
    

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return true; 
      } else {
        return false; 
      }
    } else {
      throw Exception("Empty or invalid response from server");
    }
  }
}



class ApiAnalysisService implements AnalysisService {
  final String baseUrl;

  ApiAnalysisService({required this.baseUrl});

  @override
  Future<AnalysisData> fetchAnalysis({
    required List<String> groupIds,
    required List<String> categories,
    required String timeRange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.post(
      Uri.parse('$baseUrl/api/get_analysis'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "group_ids": groupIds,
        "categories": categories,
        "time_range": timeRange,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AnalysisData.fromJson(data);
    } else {
      throw Exception('Failed to load analysis');
    }
  }
}