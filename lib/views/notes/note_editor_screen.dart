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
        title: Text(
          note == null ? 'Create New Note' : 'Edit Note',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: note == null ? null : [NoteEditorDeleteButton(note: note!)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: NoteEditorForm(note: note),
        ),
      ),
    );
  }
}
