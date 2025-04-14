import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/transaction_history_model.dart';
import '../service interfaces/transaction_history_service_interface.dart';

class ApiTransactionService implements TransactionService {
  final String baseUrl;

  ApiTransactionService({required this.baseUrl});

  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }
}
