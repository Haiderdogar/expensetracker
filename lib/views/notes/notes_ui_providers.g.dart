// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotesSearchQuery)
final notesSearchQueryProvider = NotesSearchQueryProvider._();

final class NotesSearchQueryProvider
    extends $NotifierProvider<NotesSearchQuery, String> {
  NotesSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesSearchQueryHash();

  @$internal
  @override
  NotesSearchQuery create() => NotesSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$notesSearchQueryHash() => r'401ecc130bacd785e89c399c92fede8a5f6fcc2a';

abstract class _$NotesSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NoteEditorDraftNotifier)
final noteEditorDraftProvider = NoteEditorDraftNotifierFamily._();

final class NoteEditorDraftNotifierProvider
    extends $NotifierProvider<NoteEditorDraftNotifier, NoteEditorDraft> {
  NoteEditorDraftNotifierProvider._({
    required NoteEditorDraftNotifierFamily super.from,
    required NoteModel? super.argument,
  }) : super(
         retry: null,
         name: r'noteEditorDraftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteEditorDraftNotifierHash();

  @override
  String toString() {
    return r'noteEditorDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NoteEditorDraftNotifier create() => NoteEditorDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteEditorDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteEditorDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteEditorDraftNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteEditorDraftNotifierHash() =>
    r'edb01c3d335fa9bbb3c27f71c06613f01bd49394';

final class NoteEditorDraftNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          NoteEditorDraftNotifier,
          NoteEditorDraft,
          NoteEditorDraft,
          NoteEditorDraft,
          NoteModel?
        > {
  NoteEditorDraftNotifierFamily._()
    : super(
        retry: null,
        name: r'noteEditorDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NoteEditorDraftNotifierProvider call(NoteModel? note) =>
      NoteEditorDraftNotifierProvider._(argument: note, from: this);

  @override
  String toString() => r'noteEditorDraftProvider';
}

abstract class _$NoteEditorDraftNotifier extends $Notifier<NoteEditorDraft> {
  late final _$args = ref.$arg as NoteModel?;
  NoteModel? get note => _$args;

  NoteEditorDraft build(NoteModel? note);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteEditorDraft, NoteEditorDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteEditorDraft, NoteEditorDraft>,
              NoteEditorDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
