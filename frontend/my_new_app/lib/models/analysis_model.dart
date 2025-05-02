class AnalysisData {
  final bool status;
  final double totalAmountSpent;
  final Map<String, double> perGroupBreakdown;
  final Map<String, double> perCategoryBreakdown;

  AnalysisData({
    required this.status,
    required this.totalAmountSpent,
    required this.perGroupBreakdown,
    required this.perCategoryBreakdown,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(
      status: json['status'],
      totalAmountSpent: (json['total_amount_spent'] as num).toDouble(),
      perGroupBreakdown: Map<String, double>.from(
        (json['per_group_breakdown'] as Map).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      perCategoryBreakdown: Map<String, double>.from(
        (json['per_category_breakdown'] as Map).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }
}
