import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/pinged_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PingedSectionServiceImpl implements PingedSectionService {
  final String baseUrl;

  PingedSectionServiceImpl({required this.baseUrl});

  @override
  Future<List<PingedSectionModel>> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/get_in_transit_transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      // final data = jsonDecode(response.body) as List;
      // return data.map((json) => PingedSectionModel.fromJson(json)).toList() ;


      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> transactions = json['transactions'] ?? [];
      return transactions.map((e) => PingedSectionModel.fromJson(e)).toList();
      
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }

}



class HandlePingedSectionImpl implements HandlePingedSectionService {
  final String baseUrl;

  HandlePingedSectionImpl({required this.baseUrl});
  
  @override
  Future<bool> acceptPingedTransaction( String expenseId ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/in_transit_accept'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'transaction_id': expenseId}),
    );

    if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['status'] == true) {
        return true;
      } else {
        return false; 
      }
    } else {
      throw Exception('Failed to accept the transaction: ${response.statusCode}');
    }

  }



  @override
  Future<bool> rejectPingedTransaction( String expenseId ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.put(
      Uri.parse('$baseUrl/api/in_transit_reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'transaction_id': expenseId}),
    );

    if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['status'] == true) {
        return true;
      } else {
        return false; 
      }
    } else {
      throw Exception('Failed to reject the transaction: ${response.statusCode}');
    }

  }
}
