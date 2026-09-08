import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
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
        return Container(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: colors.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: isSaving ? null : () => _save(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isSaving ? 'Saving...' : AppStrings.save, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
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
      if (context.mounted) Navigator.of(context).pop(true);
    } finally {
      if (context.mounted) {
        ref.read(noteEditorDraftProvider(note).notifier).state = draft.copyWith(isSaving: false);
      }
    }
  }
}
