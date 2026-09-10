import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note_model.dart';
import '../notes_ui_providers.dart';

class NoteTitleField extends StatelessWidget {
  const NoteTitleField({super.key, this.note, this.textColor});

  final NoteModel? note;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final title = ref.watch(noteEditorDraftProvider(note).select((draft) => draft.title));
        final colors = Theme.of(context).colorScheme;
        final color = textColor ??
            (Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF192A56)
                : colors.onSurface);

        return TextFormField(
          initialValue: title,
          maxLines: null,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
          onChanged: (value) {
            final draft = ref.read(noteEditorDraftProvider(note));
            ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(title: value);
          },
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
          decoration: InputDecoration(
            hintText: 'Add a Title',
            hintStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              fontSize: 20,
              letterSpacing: -0.3,
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
