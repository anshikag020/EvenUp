// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/all_expenses_utils.dart';
import '../sections/expense_detailed_box.dart';

class AllExpensesScreen extends StatefulWidget {
  String groupID; 
  AllExpensesScreen({super.key, required this.groupID});

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
    final expenses = await _expenseService.fetchAllExpenses(widget.groupID); 
    setState(() {
      allExpenses = expenses;
      filteredExpenses = expenses;
      isLoading = false;
    });
  }

  void _filterExpenses(String query) {
    final results = allExpenses.where((expense) {
      final desc = expense.description.toLowerCase();
      // final amount = expense.amount;
      final searchLower = query.toLowerCase();
      return desc.contains(searchLower) ;
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Expenses",
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textDark
                : AppColors.textLight,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.appBarColorDark
            : AppColors.appBarColorLight,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textDark
              : AppColors.textLight,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.searchBoxDark
                            : AppColors.searchBoxLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: _filterExpenses,
                        decoration: InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textDark2
                                : AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.yellow
                                : const Color.fromARGB(255, 201, 255, 7),
                          ),
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
                        itemCount: filteredExpenses.isEmpty
                            ? 1 
                            : filteredExpenses.length + 1,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        itemBuilder: (context, index) {
                          if (filteredExpenses.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Text(
                                  "No matching expenses found",
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.textDark
                                        : AppColors.textLight,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (index == filteredExpenses.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "Group has no more expenses",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                ),
                              ),
                            );
                          }

                          final item = filteredExpenses[index];
                          return ExpenseTile(
                            description: item.description,
                            amount: item.amount.toString(),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ExpenseDetailDialog(
                                  groupID: widget.groupID, 
                                  expenseID: item.expenseID,
                                  onDeleteSuccessCall: _loadExpenses
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
