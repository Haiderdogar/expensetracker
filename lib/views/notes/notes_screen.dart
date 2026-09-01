import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/constants/app_strings.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import 'note_editor_screen.dart';
import 'widgets/note_list_widgets.dart';

final notesSearchQueryProvider = StateProvider<String>((ref) => '');

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notesAsync = ref.watch(notesProvider);
        final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();

        return Scaffold(
          appBar: AppBar(
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : null,
            title: const Text(AppStrings.notes),
            actions: [
              IconButton(
                tooltip: 'Refresh notes',
                onPressed: () => ref.read(notesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editNote(context, ref),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('New note'),
          ),
          body: notesAsync.when(
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
            data: (notes) {
              final filteredNotes = notes
                  .where(
                    (note) =>
                        query.isEmpty ||
                        note.title.toLowerCase().contains(query),
                  )
                  .toList();

              return RefreshIndicator(
                onRefresh: () => ref.read(notesProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) =>
                          ref.read(notesSearchQueryProvider.notifier).state =
                              value,
                      decoration: InputDecoration(
                        hintText: 'Search notes',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (filteredNotes.isEmpty)
                      const NotesMessage(
                        icon: Icons.auto_awesome_rounded,
                        title: 'No matching notes',
                        message:
                            'Try a different title to find the note you are looking for.',
                      )
                    else ...[
                      Row(
                        children: [
                          Text(
                            'Recent notes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredNotes.length} ${filteredNotes.length == 1 ? 'note' : 'notes'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...filteredNotes.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NoteCard(
                            note: entry.value,
                            accent:
                                noteAccents[entry.key % noteAccents.length],
                            onTap: () =>
                                _editNote(context, ref, note: entry.value),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref, {
    NoteModel? note,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved')));
    }
  }
}
