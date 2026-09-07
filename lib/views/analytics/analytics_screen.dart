import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import 'widgets/analytics_category_section.dart';
import 'widgets/analytics_trend_section.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.analytics),
      ),
      body:  ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          AnalyticsCategorySection(),
          SizedBox(height: 24),
          AnalyticsTrendSection(),
        ],
      ),
    );
  }
}
