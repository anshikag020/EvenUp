import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/analysis_model.dart';
import 'package:my_new_app/services/service interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/analysis_section_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ScrollController _scrollController = ScrollController();
  late final GroupService _groupService;
  late final AnalysisService _analysisService;

  // Replace groupOptions with maps and lists
  Map<String, String> groupIdToName = {}; // groupID -> groupName
  List<String> selectedGroupIds = []; // We will send these to the backend

  final List<String> categoryOptions = ['Entertainment', 'Outing', 'Food', 'Travel', 'Others'];
  final List<String> timeOptions = [
    '1 Week',
    '1 Month',
    '3 Months',
    '6 Months',
    '1 Year',
    'All Time'
  ];

  List<String> selectedCategories = [];
  String selectedTime = 'All Time';

  AnalysisData? _analysisData;

  @override
  void initState() {
    super.initState();
    _groupService = locator<GroupService>();
    _analysisService = locator<AnalysisService>();
    loadGroupOptions();
    selectedCategories = categoryOptions.toList();
  }

  Future<void> loadGroupOptions() async {
    final groupData = await _groupService.fetchGroups(context);

    setState(() {
      groupIdToName = {
        for (var group in groupData) group.groupID.toString(): group.name.toString()
      };
      selectedGroupIds = groupIdToName.keys.toList(); // Initially select all
    });
  }

  Future<void> _handleViewAnalysis() async {
    final result = await _analysisService.fetchAnalysis(
      groupIds: selectedGroupIds,
      categories: selectedCategories,
      timeRange: selectedTime,
    );
    setState(() {
      _analysisData = result;
    });
    _scrollToBottom();
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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final poppins = GoogleFonts.poppins;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textcolor = isDark ? AppColors.textDark : AppColors.textLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
        title: Text("Track My Money", style: poppins(color: textcolor)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textcolor),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Filters Section
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis Options', style: poppins(fontSize: 18, color: textcolor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Divider(color: isDark ? AppColors.textDark2 : AppColors.textLight),
                  const SizedBox(height: 24),

                  AnalysisWidgets.buildMultiSelect(
                    context: context,
                    label: "Selected Groups",
                    items: groupIdToName.values.toList(), // Display group names
                    initialValue: selectedGroupIds.map((id) => groupIdToName[id]!).toList(), // Map IDs to names for initial selection
                    onConfirm: (selectedNames) {
                      setState(() {
                        selectedGroupIds = groupIdToName.entries
                            .where((entry) => selectedNames.contains(entry.value))
                            .map((entry) => entry.key)
                            .toList();
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  AnalysisWidgets.buildMultiSelect(
                    context: context,
                    label: "Selected Categories",
                    items: categoryOptions,
                    initialValue: selectedCategories,
                    onConfirm: (values) => setState(() => selectedCategories = values),
                  ),
                  const SizedBox(height: 20),

                  AnalysisWidgets.buildDropdown(
                    label: "Selected Time",
                    items: timeOptions,
                    value: selectedTime,
                    onChanged: (val) => setState(() => selectedTime = val!),
                    context: context,
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: _handleViewAnalysis,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        fixedSize: Size(width * 0.4, width * 0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: isDark ? AppColors.greenButtondarktheme : AppColors.greenButtonwhitetheme,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "View Analysis",
                            style: TextStyle(color: Colors.white, fontSize: width * 0.045),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),

            /// Graph Section
            if (_analysisData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Spent: ₹${_analysisData!.totalAmountSpent.toStringAsFixed(2)}",
                        style: poppins(color: textcolor, fontSize: 16)),
                    const SizedBox(height: 20),
                    Text("By Category", style: poppins(fontSize: 16, color: textcolor)),
                    const SizedBox(height: 12),
                    SizedBox(height: 300, child: _buildPieChart(_analysisData!.perCategoryBreakdown)),
                    const SizedBox(height: 20),
                    Text("By Group", style: poppins(fontSize: 16, color: textcolor)),
                    const SizedBox(height: 12),
                    SizedBox(height: 350, child: _buildPieChart(_analysisData!.perGroupBreakdown)),
                    const SizedBox(height: 12),
                    Text("By Category - Bar Chart", style: poppins(fontSize: 16, color: textcolor)),
                    const SizedBox(height: 12),
                    SizedBox(height: 200, child: _buildBarChart(_analysisData!.perCategoryBreakdown)),

                  ],
                ),
              ),

            if (_analysisData == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
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


int _touchedIndex = -1;

Widget _buildPieChart(Map<String, double> dataMap) {
  if (dataMap.isEmpty) {
    return const Center(child: Text("No data"));
  }

  final total = dataMap.values.fold(0.0, (a, b) => a + b);
  final entries = dataMap.entries.toList();
  final groupNames = entries.map((e) => groupIdToName[e.key] ?? e.key).toList();
  final colors = [
    const Color(0xFF4C72B0), const Color(0xFF55A868), const Color(0xFFC44E52),
    const Color(0xFF8172B2), const Color(0xFFCCB974), const Color(0xFF64B5CD),
    const Color(0xFF8C8C8C),
  ];

  return SingleChildScrollView(
    child: Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                  } else {
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  }
                },
              ),
              startDegreeOffset: -90,
              centerSpaceRadius: 40,
              sectionsSpace: 3,
              sections: List.generate(entries.length, (i) {
                final label = groupNames[i];
                final value = entries[i].value;
                final percentage = (value / total) * 100;
                final isTouched = i == _touchedIndex;
                final double radius = isTouched ? 75 : 65;

                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: value,
                  radius: radius,
                  title: '${label.split(' ').first}\n₹${value.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.65,
                );
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 300), // smooth animation
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: List.generate(entries.length, (i) {
            final label = groupNames[i];
            final color = colors[i % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 13)),
              ],
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}





Widget _buildBarChart(Map<String, double> dataMap) {
  if (dataMap.isEmpty) {
    return const Center(child: Text("No data"));
  }

  final items = dataMap.entries.toList();
  final maxY = dataMap.values.reduce((a, b) => a > b ? a : b);

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY + 10,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            getTitlesWidget: (value, meta) => Text('₹${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, meta) {
              if (value.toInt() >= items.length) return const SizedBox.shrink();
              return Text(items[value.toInt()].key, style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
      barGroups: items.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              gradient: const LinearGradient(
                colors: [Colors.greenAccent, Colors.blueAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(6),
              width: 18,
            ),
          ],
        );
      }).toList(),
    ),
  );
}



}
