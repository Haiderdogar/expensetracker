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
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final headerColor = isLight ? const Color(0xFF192A56) : colors.onSurface;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Small text title above the title input field
          Text(
            'Title',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: headerColor,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          NoteTitleField(note: note, textColor: headerColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          // Details section header
          Text(
            'Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: headerColor,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: NoteContentField(note: note),
          ),
          const SizedBox(height: 16),
          NoteEditorSaveActions(note: note, formKey: _formKey),
        ],
      ),
    );
  }
}
