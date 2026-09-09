import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../models/subcategory_model.dart';
import '../../../providers/subcategory_provider.dart';
import 'category_management_dialogs.dart';

class SubcategoryTile extends StatelessWidget {
  const SubcategoryTile({super.key, required this.subcategory});
  final SubcategoryModel subcategory;
  @override
  Widget build(BuildContext context) => Consumer(builder: (context, ref, _) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.subdirectory_arrow_right_rounded), title: Text(subcategory.name), trailing: PopupMenuButton<String>(onSelected: (action) => _action(context, ref, action), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))])));
  Future<void> _action(BuildContext context, WidgetRef ref, String action) async { if (action == 'edit') { final name = await showNameDialog(context, 'Edit subcategory', initialName: subcategory.name); if (name == null || !context.mounted) return; await updateSubcategory(ref, subcategory: subcategory, name: name); if (context.mounted) showSuccessSnackBar(context, 'Subcategory updated successfully'); return; } final ok = await confirmDelete(context, 'Delete ${subcategory.name}?', 'A category must keep at least one subcategory.'); if (ok && context.mounted) { try { await deleteSubcategory(ref, subcategory); if (context.mounted) showSuccessSnackBar(context, 'Subcategory deleted successfully'); } catch (error) { if (context.mounted) showError(context, error); } } }
}
