import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref, {
    NoteModel? note,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteEditorSheet(note: note),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved')));
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    NoteModel note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete "${note.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notesProvider.notifier).delete(note.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
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
        error: (error, _) => _NotesMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Notes are unavailable',
          message: error.toString(),
          action: TextButton.icon(
            onPressed: () => ref.read(notesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
        data: (notes) => RefreshIndicator(
          onRefresh: () => ref.read(notesProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              _NotesHeader(
                count: notes.length,
                onCreate: () => _editNote(context, ref),
              ),
              const SizedBox(height: 24),
              if (notes.isEmpty)
                const _NotesMessage(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Your thoughts belong here',
                  message:
                      'Save ideas, reminders, and important details in one calm space.',
                )
              else ...[
                Row(
                  children: [
                    Text(
                      'Recent notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...notes.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NoteCard(
                      note: entry.value,
                      accent: _noteAccents[entry.key % _noteAccents.length],
                      onTap: () =>
                          _editNote(context, ref, note: entry.value),
                      onDelete: () =>
                          _deleteNote(context, ref, entry.value),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _noteAccents = [
  AppColors.primaryEmerald,
  Color(0xFF6366F1),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
];

class _NotesHeader extends StatelessWidget {
  const _NotesHeader({required this.count, required this.onCreate});

  final int count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepForest, Color(0xFF0B8060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -28,
            child: Icon(
              Icons.sticky_note_2_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.mintAccent),
                  const SizedBox(width: 8),
                  Text(
                    'A space for what matters',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Keep your\nthoughts close.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '$count ${count == 1 ? 'note' : 'notes'} saved',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  final NoteModel note;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 76,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _noteDate(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete note',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesMessage extends StatelessWidget {
  const _NotesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

String _noteDate(DateTime date) {
  final local = date.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'Updated ${months[local.month - 1]} ${local.day}, ${local.year}';
}

class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({super.key, this.note});

  final NoteModel? note;

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(notesProvider.notifier)
          .save(
            id: widget.note?.id,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.note == null ? 'New note' : 'Edit note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter some text'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
