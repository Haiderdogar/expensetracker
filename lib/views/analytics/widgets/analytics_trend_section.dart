import 'package:flutter/material.dart';

import 'spending_bar_chart.dart';

class AnalyticsTrendSection extends StatelessWidget {
  const AnalyticsTrendSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SpendingBarChart(),
      ),
    );
  }
}
