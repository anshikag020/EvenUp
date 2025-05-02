import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/transaction_history_model.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ApiTransactionService implements TransactionService {
  final String baseUrl;

  ApiTransactionService({required this.baseUrl});

  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    final response = await http.get(
      Uri.parse('$baseUrl/api/get_transaction_history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      // final data = jsonDecode(response.body) as List;
      // return data.map((json) => TransactionModel.fromJson(json)).toList();
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> transactions = json['transactions'] ?? [];
      return transactions.map((e) => TransactionModel.fromJson(e)).toList();
      
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }
}
