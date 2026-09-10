import 'package:flutter/material.dart';

import '../../models/note_model.dart';
import 'widgets/note_editor_delete_button.dart';
import 'widgets/note_editor_form.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key, this.note});

  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              note == null ? Icons.note_add_outlined : Icons.edit_note_rounded,
              size: 22,
              color: colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              note == null ? 'Add Note' : 'Edit Note',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
            ),
          ],
        ),
        actions: note == null ? null : [NoteEditorDeleteButton(note: note!)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: NoteEditorForm(note: note),
        ),
      ),
    );
  }
}
