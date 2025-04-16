import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/all_expenses_utils.dart';
import '../sections/expense_detailed_box.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  late final ExpenseService _expenseService;
  final ScrollController _scrollController = ScrollController();

  List<ExpenseModel> allExpenses = [];
  List<ExpenseModel> filteredExpenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _expenseService = locator<ExpenseService>();

    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _expenseService.fetchAllExpenses();
    setState(() {
      allExpenses = expenses;
      filteredExpenses = expenses;
      isLoading = false;
    });
  }

  void _filterExpenses(String query) {
    final results = allExpenses.where((expense) {
      final desc = expense.description.toLowerCase();
      final amount = expense.amount.toLowerCase();
      final searchLower = query.toLowerCase();
      return desc.contains(searchLower) || amount.contains(searchLower);
    }).toList();

    setState(() {
      filteredExpenses = results;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "Expenses",
          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: _filterExpenses,
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.search, color: Colors.yellow),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredExpenses.length,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        itemBuilder: (context, index) {
                          final item = filteredExpenses[index];
                          return ExpenseTile(
                            description: item.description,
                            amount: item.amount,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ExpenseDetailDialog(
                                  expenseID: item.expenseID,
                                  onDelete: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      filteredExpenses.isEmpty
                          ? "No matching expenses found"
                          : "Group has no more expenses",
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
