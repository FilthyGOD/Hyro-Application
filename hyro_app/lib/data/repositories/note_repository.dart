import 'package:flutter/material.dart';
import '../local/note_local_ds.dart';
import '../remote/note_remote_ds.dart';
import '../models/tarea_nota_model.dart';

/// Repository that abstracts local and remote task note operations.
class NoteRepository {
  final NoteLocalDataSource _local;
  final NoteRemoteDataSource _remote;
  final bool Function() _isAuthenticated;
  final String? Function() _getUserId;

  NoteRepository({
    required NoteLocalDataSource local,
    required NoteRemoteDataSource remote,
    required bool Function() isAuthenticated,
    required String? Function() getUserId,
  })  : _local = local,
        _remote = remote,
        _isAuthenticated = isAuthenticated,
        _getUserId = getUserId;

  /// Get all notes for a task from local storage.
  List<TareaNotaModel> getNotesForTask(String tareaId) {
    return _local.getNotesForTask(tareaId);
  }

  /// Pull all notes from Supabase and replace local data.
  Future<void> pullRemoteToLocal() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final maps = await _remote.fetchAllForUser(userId);
      await _local.clearAll();
      for (final map in maps) {
        final nota = TareaNotaModel.fromSupabaseJson(map);
        await _local.putNote(nota);
      }
    } catch (e) {
      debugPrint('⚠️ NoteRepo: Error pulling from remote: $e');
    }
  }

  /// Add a new note — local first, then remote if authenticated.
  Future<void> addNote(TareaNotaModel nota) async {
    await _local.putNote(nota);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.insertNote(nota.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ NoteRepo: Error syncing new note to remote: $e');
      }
    }
  }

  /// Update a note — local first, then remote if authenticated.
  Future<void> updateNote(TareaNotaModel nota) async {
    await _local.putNote(nota);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.updateNote(nota.id, nota.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ NoteRepo: Error syncing note update to remote: $e');
      }
    }
  }

  /// Delete a note — local first, then remote if authenticated.
  Future<void> deleteNote(String id) async {
    await _local.deleteNote(id);
    if (_isAuthenticated()) {
      try {
        await _remote.deleteNote(id);
      } catch (e) {
        debugPrint('⚠️ NoteRepo: Error syncing note deletion to remote: $e');
      }
    }
  }

  /// Delete all notes for a task — local only (remote cascade handled by task deletion).
  Future<void> deleteNotesForTask(String tareaId) async {
    await _local.deleteNotesForTask(tareaId);
  }
}
