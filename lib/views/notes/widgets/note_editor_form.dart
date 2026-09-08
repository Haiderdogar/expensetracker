import 'package:flutter/material.dart';

import '../../../models/note_model.dart';
import 'note_content_field.dart';
import 'note_editor_actions.dart';
import 'note_title_field.dart';

class NoteEditorForm extends StatelessWidget {
  NoteEditorForm({super.key, this.note});

  final NoteModel? note;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                NoteTitleField(note: note),
                const SizedBox(height: 16),
                NoteContentField(note: note),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        NoteEditorSaveActions(note: note, formKey: _formKey),
      ],
    );
  }
}
