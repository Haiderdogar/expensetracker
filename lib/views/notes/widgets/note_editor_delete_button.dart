import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/note_model.dart';
import '../../../providers/note_provider.dart';

class NoteEditorDeleteButton extends StatelessWidget {
  const NoteEditorDeleteButton({super.key, required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => IconButton(
        tooltip: 'Delete note',
        icon: const Icon(Icons.delete_outline_rounded),
        color: Theme.of(context).colorScheme.error,
        onPressed: () => _delete(context, ref),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete "${note.title}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text(AppStrings.delete)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(notesProvider.notifier).delete(note.id);
    ref.invalidate(notesProvider);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
