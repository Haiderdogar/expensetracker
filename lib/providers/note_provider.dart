import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database_tables.dart';
import '../core/utils/error_handler.dart';
import '../models/note_model.dart';
import 'database_provider.dart';

part 'note_provider.g.dart';

@Riverpod(keepAlive: true)
class Notes extends _$Notes {
  @override
  Future<List<NoteModel>> build() => _fetchAll();

  Future<List<NoteModel>> _fetchAll() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final rows = await db.query(
        DatabaseTables.notes,
        orderBy: 'updated_at DESC',
      );
      return rows.map(NoteModel.fromMap).toList();
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
      final db = await ref.read(databaseProvider.future);
      final now = DateTime.now();
      if (id == null) {
        await db.insert(DatabaseTables.notes, NoteModel(
          id: const Uuid().v4(),
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
        ).toMap());
      } else {
        await db.update(
          DatabaseTables.notes,
          {'title': title, 'content': content, 'updated_at': now.toUtc().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      state = const AsyncData([]);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete(DatabaseTables.notes, where: 'id = ?', whereArgs: [id]);
      state = const AsyncData([]);
      await refresh();
    } catch (e) {
      throw ErrorHandler.from(e);
    }
  }
}
