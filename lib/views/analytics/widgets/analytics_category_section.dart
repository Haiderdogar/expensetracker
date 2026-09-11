import 'package:flutter/material.dart';

import 'expense_pie_chart.dart';

class AnalyticsCategorySection extends StatelessWidget {
  const AnalyticsCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: ExpensePieChart(),
      ),
    );
  }
}
