import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/router/app_router.dart';

class NotesAddButton extends StatelessWidget {
  const NotesAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openEditor(context),
      icon: const Icon(Icons.edit_rounded),
      label: const Text('New note'),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final result = await context.push<String>(AppRoutes.noteEditor);
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(context, 'Note added successfully');
    }
  }
}
