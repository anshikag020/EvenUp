import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/transaction_history_model.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/transaction_tile.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TransactionService _transactionService;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _transactionService = locator<TransactionService>();
    _fetchTransactions();
    _searchController.addListener(_searchTransaction);
  }
 
  Future<void> _fetchTransactions() async {
    final data = await _transactionService.fetchTransactions();
    setState(() {
      _allTransactions = data;
      _filteredTransactions = data;
    });
  }

  void _searchTransaction() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactions = _allTransactions
          .where((txn) => txn.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Transactions History",
          style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
        ),
        backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
        iconTheme: IconThemeData(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                  filled: true,
                  fillColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.searchBoxDark : AppColors.searchBoxLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredTransactions.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (_, index) {
                        final txn = _filteredTransactions[index];
                        return FancyTransactionTile(
                                groupName: txn.groupName, 
                                name: txn.name, 
                                amount: txn.amount,
                                type: txn.type
                              );
                      },
                    )
                  : Center(
                      child: Text(
                        "No transactions found",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
