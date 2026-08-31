import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  late final TextEditingController _searchController;

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref, {
    NoteModel? note,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        data: (notes) {
          final query = _searchController.text.trim().toLowerCase();
          final filteredNotes = notes.where((note) {
            if (query.isEmpty) return true;
            return note.title.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(notesProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  const _NotesMessage(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${filteredNotes.length} ${filteredNotes.length == 1 ? 'note' : 'notes'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...filteredNotes.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NoteCard(
                        note: entry.value,
                        accent: _noteAccents[entry.key % _noteAccents.length],
                        onTap: () => _editNote(context, ref, note: entry.value),
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
  }
}

const _noteAccents = [
  AppColors.primaryEmerald,
  Color(0xFF6366F1),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
];

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.accent,
    required this.onTap,
  });

  final NoteModel note;
  final Color accent;
  final VoidCallback onTap;

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
                      maxLines: 5,
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Updated ${months[local.month - 1]} ${local.day}, ${local.year}';
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  final NoteModel? note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final ScrollController _contentScrollController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _contentScrollController = ScrollController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete "${widget.note!.title}" permanently?'),
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

    if (confirmed != true) return;

    await ref.read(notesProvider.notifier).delete(widget.note!.id);
    if (!mounted) return;
    ref.invalidate(notesProvider);
    Navigator.of(context).pop(true);
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
      ref.invalidate(notesProvider);
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.primaryEmerald,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Note' : 'Create New Note',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: _isEditing
            ? [
                IconButton(
                  tooltip: 'Delete note',
                  onPressed: _deleteNote,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 18,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryEmerald,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Scrollbar(
                        controller: _contentScrollController,
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(999),
                        child: SingleChildScrollView(
                          controller: _contentScrollController,
                          padding: EdgeInsets.zero,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 4,
                                margin: const EdgeInsets.only(top: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _contentController,
                                  minLines: 5,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Write your note here...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 16,
                                    ),
                                    alignLabelWithHint: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryEmerald,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty
                                      ? 'Enter some text'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: buttonStyle,
                        child: Text(
                          _saving ? 'Saving...' : AppStrings.save,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
