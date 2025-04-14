import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/utils/all_expenses_utils.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  List<Map<String, dynamic>> allExpenses = [
    {
      "description": "This group is just made for testing the app.",
      "amount": "500",
    },
    {"description": "Dinner with friends.", "amount": "1200"},
    {
      "description": "Snacks for group meeting. herer is moerew to this",
      "amount": "350",
    },
    {
      "description":
          "Subscription for shared tools that we all use to collaborate on projects. I am just testing this if this text gets cut in between, cause this text is more than 2 lines so it should end with ellipses.",
      "amount": "999",
    },
  ];

  List<Map<String, dynamic>> filteredExpenses = [];

  @override
  void initState() {
    super.initState();
    filteredExpenses = List.from(allExpenses);
  }

  void _filterExpenses(String query) {
    final results =
        allExpenses.where((expense) {
          final desc = expense['description'].toLowerCase();
          final amount = expense['amount'].toLowerCase();
          final searchLower = query.toLowerCase();
          return desc.contains(searchLower) || amount.contains(searchLower);
        }).toList();

    setState(() {
      filteredExpenses = results;
    });
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
        child: Column(
          children: [
            // Search Box
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

            // Expense Tiles
            Expanded(
              child: ListView.builder(
                itemCount: filteredExpenses.length,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemBuilder: (context, index) {
                  final item = filteredExpenses[index];
                  return ExpenseTile(
                    description: item['description'],
                    amount: item['amount'],
                    onTap: () {},
                  );
                },
              ),
            ),

            // Bottom Text
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

// ✅ Reusable Expense Tile Widget
