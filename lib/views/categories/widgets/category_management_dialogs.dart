import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/category_provider.dart';

Future<void> addCategory(BuildContext context, WidgetRef ref) async {
  final type = await showModalBottomSheet<String>(context: context, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.trending_up_rounded), title: const Text('Income category'), onTap: () => Navigator.pop(sheet, 'income')), ListTile(leading: const Icon(Icons.trending_down_rounded), title: const Text('Expense category'), onTap: () => Navigator.pop(sheet, 'expense'))])));
  if (type == null || !context.mounted) return;
  final input = await showCategoryInput(context);
  if (input == null || !context.mounted) return;
  try {
    await ref.read(categoriesProvider.notifier).createWithSubcategory(name: input.name, subcategoryName: input.subcategory, type: type, icon: type == 'income' ? 'work' : 'shopping_bag', color: type == 'income' ? '#22C55E' : '#EF4444');
    if (context.mounted) showSuccessSnackBar(context, 'Category added successfully');
  } catch (error) { if (context.mounted) showError(context, error); }
}

class CategoryInput { const CategoryInput(this.name, this.subcategory); final String name; final String subcategory; }

Future<CategoryInput?> showCategoryInput(BuildContext context) {
  final category = TextEditingController();
  final subcategory = TextEditingController();
  return showDialog<CategoryInput>(context: context, builder: (dialog) => AlertDialog(title: const Text('New category'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: category, autofocus: true, decoration: const InputDecoration(labelText: 'Category name')), const SizedBox(height: 12), TextField(controller: subcategory, decoration: const InputDecoration(labelText: 'First subcategory'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')), FilledButton(onPressed: () { final name = category.text.trim(); final sub = subcategory.text.trim(); if (name.isNotEmpty && sub.isNotEmpty) Navigator.pop(dialog, CategoryInput(name, sub)); }, child: const Text('Save'))]));
}

Future<String?> showNameDialog(BuildContext context, String title, {String? initialName}) {
  final controller = TextEditingController(text: initialName ?? '');
  return showDialog<String>(context: context, builder: (dialog) => AlertDialog(title: Text(title), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Name')), actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')), FilledButton(onPressed: () { final name = controller.text.trim(); if (name.isNotEmpty) Navigator.pop(dialog, name); }, child: const Text('Save'))]));
}

Future<bool> confirmDelete(BuildContext context, String title, String message) async => await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete'))])) ?? false;
void showError(BuildContext context, Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.message(error))));
