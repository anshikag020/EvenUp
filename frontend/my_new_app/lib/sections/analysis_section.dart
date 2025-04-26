import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/analysis_section_utils.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}
 
class _AnalysisScreenState extends State<AnalysisScreen> {
  final ScrollController _scrollController = ScrollController();
  late final GroupService _groupService;

  List<String> groupOptions = [];  
  final List<String> categoryOptions = ['Food', 'Travel', 'Shopping', 'Bills'];
  final List<String> timeOptions = [
    '1 Week',
    '1 Month',
    '3 Months',
    '6 Months',
    '1 Year',
    'All Time'
  ];

  List<String> selectedGroups = [];
  List<String> selectedCategories = [];
  String selectedTime = 'All Time';
  String selectedType = 'Spent';

Future<void> loadGroupOptions() async {
  final groupData = await _groupService.fetchGroups(context); // assuming it returns List<Map<String, dynamic>>

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
    Color textcolor = Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight; 

    return Scaffold(
      backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
        title: Text("Track My Money", style: poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
  children: [
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
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
              color: textcolor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
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
            context: context, 
          ),
          const SizedBox(height: 20),

          /// Type
          Text("Type:", style: poppins(color: textcolor)),
          const SizedBox(height: 10),
          Row(
            children: [
              AnalysisWidgets.buildRadio(
                title: "Spent",
                groupValue: selectedType,
                onChanged: (val) => setState(() => selectedType = val),
                selectColor:   Theme.of(context).brightness ==  Brightness.dark ? Colors.greenAccent :  Color.fromARGB(255, 5, 129, 36),
                textcolor:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight

              ),
              const SizedBox(width: 16),
              AnalysisWidgets.buildRadio(
                title: "Received",
                groupValue: selectedType,
                onChanged: (val) => setState(() => selectedType = val),
                selectColor: Theme.of(context).brightness ==  Brightness.dark ? Colors.greenAccent : Color.fromARGB(255, 5, 129, 36),
                textcolor:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight

              ),
            ],
          ),
          const SizedBox(height: 30),

          /// View Button
          Center(
            child: ElevatedButton(
                    onPressed: () {
                                      // handle this function
                    _scrollToBottom(); 
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
                                    gradient:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.greenButtondarktheme : AppColors.greenButtonwhitetheme,
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
        color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'You can see the analysis here',
        style: poppins(color: textcolor, fontSize: 16),
      ),
    ),
    const SizedBox(height: 60),
  ],
),
      ),
    );
  }
}
