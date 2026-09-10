import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note_model.dart';
import '../../../providers/note_provider.dart';
import '../notes_ui_providers.dart';

class NoteEditorSaveActions extends StatelessWidget {
  const NoteEditorSaveActions({super.key, required this.note, required this.formKey});

  final NoteModel? note;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isSaving = ref.watch(noteEditorDraftProvider(note).select((draft) => draft.isSaving));
        final colors = Theme.of(context).colorScheme;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: isSaving ? null : () => _save(context, ref),
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(
              isSaving ? 'Saving...' : (note == null ? 'Save Note' : 'Save Changes'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(noteEditorDraftProvider(note));
    if (draft.isSaving || !(formKey.currentState?.validate() ?? false)) return;
    ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(isSaving: true);
    try {
      await ref.read(notesProvider.notifier).save(id: note?.id, title: draft.title.trim(), content: draft.content.trim());
      ref.invalidate(notesProvider);
      if (context.mounted) Navigator.of(context).pop(note == null ? 'created' : 'updated');
    } finally {
      if (context.mounted) {
        ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(isSaving: false);
      }
    }
  }
}
