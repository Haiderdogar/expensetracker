// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Notes)
final notesProvider = NotesProvider._();

final class NotesProvider
    extends $AsyncNotifierProvider<Notes, List<NoteModel>> {
  NotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesHash();

  @$internal
  @override
  Notes create() => Notes();
}

String _$notesHash() => r'bd8dd9877048d1bce86285fd81e4892e0dbdf844';

abstract class _$Notes extends $AsyncNotifier<List<NoteModel>> {
  FutureOr<List<NoteModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<NoteModel>>, List<NoteModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NoteModel>>, List<NoteModel>>,
              AsyncValue<List<NoteModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
