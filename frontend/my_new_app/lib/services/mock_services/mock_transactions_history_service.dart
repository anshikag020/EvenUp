import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_new_app/models/transaction_history_model.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';

class MockTransactionService implements TransactionService {
  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final String response = await rootBundle.loadString('lib/data/transactions_history_data.json');
    final List<dynamic> data = jsonDecode(response);

    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }
}
