import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note_model.dart';
import '../notes_ui_providers.dart';

class NoteContentField extends StatelessWidget {
  const NoteContentField({super.key, this.note});

  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final content = ref.watch(noteEditorDraftProvider(note).select((draft) => draft.content));
        final colors = Theme.of(context).colorScheme;
        return TextFormField(
          initialValue: content,
          expands: true,
          maxLines: null,
          minLines: null,
          textCapitalization: TextCapitalization.sentences,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colors.onSurface,
          ),
          onChanged: (value) {
            final draft = ref.read(noteEditorDraftProvider(note));
            ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(content: value);
          },
          validator: (value) => value == null || value.trim().isEmpty ? 'Please write some note content' : null,
          decoration: InputDecoration(
            hintText: 'Write your note here...',
            hintStyle: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
          ),
        );
      },
    );
  }
}
