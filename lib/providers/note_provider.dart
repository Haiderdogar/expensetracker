import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/error_handler.dart';
import '../models/note_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'wallet_provider.dart';

part 'note_provider.g.dart';

@Riverpod(keepAlive: true)
class Notes extends _$Notes {
  @override
  Future<List<NoteModel>> build() => _fetchAll();

  Future<List<NoteModel>> _fetchAll() async {
    try {
      ref.watch(localDataEpochProvider);
      final userId = ref.watch(currentUserIdProvider);
      final walletId = ref.watch(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      return await syncRepo.getNotes(userId, walletId: walletId);
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<void> save({
    String? id,
    required String title,
    required String content,
  }) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final walletId = ref.read(activeWalletIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      final now = DateTime.now();
      final existing = id == null
          ? null
          : await syncRepo.getNote(id, userId, walletId: walletId);

      final note = NoteModel(
        id: id ?? const Uuid().v4(),
        userId: userId,
        walletId: walletId ?? '',
        title: title,
        content: content,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isSynced: false,
      );

      await syncRepo.saveNote(note);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.deleteNote(id, userId);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}
