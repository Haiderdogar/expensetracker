import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/category_management_body.dart';
import 'widgets/category_management_dialogs.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Manage categories'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, _) => FloatingActionButton.extended(
            onPressed: () => addCategory(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New category'),
          ),
        ),
        body: const CategoryManagementBody(),
      );
}
