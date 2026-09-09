import 'package:flutter/material.dart';

import '../../../core/utils/app_snackbars.dart';
import '../note_editor_screen.dart';

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
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const NoteEditorScreen()));
    if (result == 'created' && context.mounted) {
      showSuccessSnackBar(context, 'Note added successfully');
    }
  }
}
