import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/friends_model.dart';
import 'package:my_new_app/services/service%20interfaces/friends_section_api_interface_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiFriendsService implements FriendsService {
  final String baseUrl;

  ApiFriendsService({required this.baseUrl});

  @override
  Future<List<Friend>> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/get_friends_page_records'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> friends = json['friends'] ?? [];
      return friends.map((e) => Friend.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load friends');
    }
  }

  @override
  Future<bool> settleFriend(String friendUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/settle_up_friends_page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'friend_name': friendUsername}),
    );
    
    return response.statusCode == 200;
  }

  @override
  Future<bool> remindFriend(String friendUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/remind_friends_page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'friend_name': friendUsername}),
    );

    return response.statusCode == 200;
  }
}
