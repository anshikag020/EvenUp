import '../../models/transaction_history_model.dart';

abstract class TransactionService {
  Future<List<TransactionModel>> fetchTransactions();
}
