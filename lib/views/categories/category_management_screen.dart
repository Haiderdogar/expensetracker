import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/category_management_body.dart';
import 'widgets/category_management_dialogs.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories'),
            Text(
              'Manage your money, your way',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: context.pop,
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: const _AddCategoryButton(),
      body: const CategoryManagementBody(),
    );
  }
}

class _AddCategoryButton extends ConsumerWidget {
  const _AddCategoryButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => addCategory(context, ref),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Add category'),
    );
  }
}
