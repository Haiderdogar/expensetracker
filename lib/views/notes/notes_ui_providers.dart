import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/note_model.dart';

final notesSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class NoteEditorDraft {
  const NoteEditorDraft({required this.title, required this.content, this.isSaving = false});

  factory NoteEditorDraft.fromNote(NoteModel? note) {
    return NoteEditorDraft(title: note?.title ?? '', content: note?.content ?? '');
  }

  final String title;
  final String content;
  final bool isSaving;

  NoteEditorDraft copyWith({String? title, String? content, bool? isSaving}) {
    return NoteEditorDraft(
      title: title ?? this.title,
      content: content ?? this.content,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final noteEditorDraftProvider = StateProvider.autoDispose.family<NoteEditorDraft, NoteModel?>(
  (ref, note) => NoteEditorDraft.fromNote(note),
);
