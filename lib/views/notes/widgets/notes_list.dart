import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../models/note_model.dart';
import '../../../providers/note_provider.dart';
import '../note_editor_screen.dart';
import '../notes_ui_providers.dart';
import 'note_list_widgets.dart';

class NotesList extends StatelessWidget {
  const NotesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final notes = ref.watch(notesProvider);
        final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();
        return notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => NotesMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Notes are unavailable',
            message: error.toString(),
            action: TextButton.icon(
              onPressed: () => ref.read(notesProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
          data: (items) => _NotesContent(notes: _filter(items, query)),
        );
      },
    );
  }

  List<NoteModel> _filter(List<NoteModel> notes, String query) {
    if (query.isEmpty) return notes;
    return notes.where((note) => note.title.toLowerCase().contains(query)).toList();
  }
}

class _NotesContent extends StatelessWidget {
  const _NotesContent({required this.notes});

  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        final container = ProviderScope.containerOf(context);
        return container.read(notesProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
        children: [
          if (notes.isEmpty)
            const NotesMessage(
              icon: Icons.auto_awesome_rounded,
              title: 'No matching notes',
              message: 'Try a different title to find the note you are looking for.',
            )
          else ...[
            Row(
              children: [
                Text('Recent notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(
                  '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoteCard(
                  note: entry.value,
                  accent: noteAccents[entry.key % noteAccents.length],
                  onTap: () => _openEditor(context, entry.value),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, NoteModel note) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (result == 'updated' && context.mounted) {
      showSuccessSnackBar(context, 'Note updated successfully');
    }
  }
}
