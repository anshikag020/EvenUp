import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/utils/analysis_section_utils.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ScrollController _scrollController = ScrollController();

  List<String> groupOptions = ['Family', 'Friends', 'Work', 'Demo Group 1', 'Demo Group 2', 'Demo Group 3', 'Demo Group 4'];
  final List<String> categoryOptions = ['Food', 'Travel', 'Shopping', 'Bills'];
  final List<String> timeOptions = [
    '1 Week',
    '1 Month',
    '3 Months',
    '6 Months',
    '1 Year',
    'All Time'
  ];

  late final GroupService _groupService;
  List<String> selectedGroups = [];
  List<String> selectedCategories = [];
  String selectedTime = 'All Time';
  String selectedType = 'Spent';

Future<void> loadGroupOptions() async {
  final groupData = await _groupService.fetchGroups(); // assuming it returns List<Map<String, dynamic>>

  setState(() {
    groupOptions = groupData
        .map<String>((group) => group.name.toString())
        .toList();

    selectedGroups = groupOptions.toList();
  });
}


  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _groupService = locator<GroupService>();
    loadGroupOptions();
    // groupOptions1['name']; 
    // selectedGroups = groupOptions.toList();
    selectedCategories = categoryOptions.toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width; 
    final poppins = GoogleFonts.poppins;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Track My Money", style: poppins(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
  children: [
    Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Options',
            style: poppins(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.grey),
          const SizedBox(height: 24),

          /// Groups
          AnalysisWidgets.buildMultiSelect(
            context: context,
            label: "Selected Groups",
            items: groupOptions,
            initialValue: selectedGroups,
            onConfirm: (values) {
              setState(() {
                selectedGroups = values;
              });
            },
          ),
          const SizedBox(height: 20),

          /// Categories
          AnalysisWidgets.buildMultiSelect(
            context: context,
            label: "Selected Categories",
            items: categoryOptions,
            initialValue: selectedCategories,
            onConfirm: (values) {
              setState(() {
                selectedCategories = values;
              });
            },
          ),
          const SizedBox(height: 20),

          /// Time
          AnalysisWidgets.buildDropdown(
            label: "Selected Time",
            items: timeOptions,
            value: selectedTime,
            onChanged: (val) {
              setState(() {
                selectedTime = val!;
              });
            },
          ),
          const SizedBox(height: 20),

          /// Type
          Text("Type:", style: poppins(color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            children: [
              AnalysisWidgets.buildRadio(
                title: "Spent",
                groupValue: selectedType,
                onChanged: (val) => setState(() => selectedType = val),
              ),
              const SizedBox(width: 16),
              AnalysisWidgets.buildRadio(
                title: "Received",
                groupValue: selectedType,
                onChanged: (val) => setState(() => selectedType = val),
              ),
            ],
          ),
          const SizedBox(height: 30),

          /// View Button
          Center(
            child: ElevatedButton(
                    onPressed: () {
                                      // handle this function
                                  },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      fixedSize: Size(width*0.4, width*0.12),
                      // fixedSize: Size(100, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color.fromRGBO(208, 227, 64, 1), Color.fromRGBO(28, 54, 6, 1)],
                                  ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "View Analysis",
                          style: TextStyle(color: Colors.white, fontSize: width*0.045),
                        ),
                      ),
                    ),
                  ),
          )
        ],
      ),
    ),
    const SizedBox(height: 40),

    /// Result
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'You can see the analysis here',
        style: poppins(color: Colors.white70, fontSize: 16),
      ),
    ),
    const SizedBox(height: 60),
  ],
),
      ),
    );
  }
}
