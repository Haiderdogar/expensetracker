import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note_model.dart';
import '../notes_ui_providers.dart';
import 'note_editor_input_decoration.dart';

class NoteTitleField extends StatelessWidget {
  const NoteTitleField({super.key, this.note});

  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final title = ref.watch(noteEditorDraftProvider(note).select((draft) => draft.title));
        return TextFormField(
          initialValue: title,
          minLines: 1,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          onChanged: (value) {
            final draft = ref.read(noteEditorDraftProvider(note));
            ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(title: value);
          },
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null,
          decoration: noteEditorInputDecoration(context, hint: 'Title', isTitle: true),
        );
      },
    );
  }
}
