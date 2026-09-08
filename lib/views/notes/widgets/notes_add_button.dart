import 'package:flutter/material.dart';

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
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const NoteEditorScreen()));
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
    }
  }
}
