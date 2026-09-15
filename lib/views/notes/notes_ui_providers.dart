import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/note_model.dart';

part 'notes_ui_providers.g.dart';

@riverpod
class NotesSearchQuery extends _$NotesSearchQuery {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

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

@riverpod
class NoteEditorDraftNotifier extends _$NoteEditorDraftNotifier {
  @override
  NoteEditorDraft build(NoteModel? note) => NoteEditorDraft.fromNote(note);

  @override
  set state(NoteEditorDraft value) => super.state = value;
}
