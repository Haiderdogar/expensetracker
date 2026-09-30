import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/error_handler.dart';
import '../models/note_model.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';

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
      
      final current = state.value ?? [];
      final existing = id == null
          ? null
          : current.where((n) => n.id == id).firstOrNull;

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

      // ── Step 1: Write to SQLite instantly.
      await syncRepo.saveNoteLocalOnly(note);

      // ── Step 2: Optimistic UI update.
      if (existing != null) {
        state = AsyncData(current.map((n) => n.id == note.id ? note : n).toList());
      } else {
        state = AsyncData([note, ...current]);
      }

      // ── Step 3: Push to Firestore in the background.
      unawaited(syncRepo.pushNoteRemote(note));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      final syncRepo = ref.read(syncRepositoryProvider);

      final current = state.value ?? [];
      final old = current.where((n) => n.id == id).firstOrNull;
      if (old == null) return;

      // ── Step 1: Soft-delete locally (instant).
      await syncRepo.deleteNoteLocalOnly(id, userId);

      // ── Step 2: Optimistic UI update.
      state = AsyncData(current.where((n) => n.id != id).toList());

      // ── Step 3: Push soft-delete to Firestore in the background.
      unawaited(syncRepo.pushDeleteRemote(
        table: 'notes',
        userId: userId,
        id: id,
        walletId: old.walletId,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ));
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}
