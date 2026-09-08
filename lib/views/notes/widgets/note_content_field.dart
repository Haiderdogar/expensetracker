import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note_model.dart';
import '../notes_ui_providers.dart';
import 'note_editor_input_decoration.dart';

class NoteContentField extends StatelessWidget {
  const NoteContentField({super.key, this.note});

  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final content = ref.watch(noteEditorDraftProvider(note).select((draft) => draft.content));
        return TextFormField(
          initialValue: content,
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textAlignVertical: TextAlignVertical.top,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          onChanged: (value) {
            final draft = ref.read(noteEditorDraftProvider(note));
            ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(content: value);
          },
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter some text' : null,
          decoration: noteEditorInputDecoration(context, hint: 'Write your note here...'),
        );
      },
    );
  }
}
