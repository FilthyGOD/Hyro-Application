import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local/note_local_ds.dart';
import '../remote/note_remote_ds.dart';
import '../models/tarea_nota_model.dart';

/// Repositorio que abstrae las operaciones locales y remotas de notas de tareas.
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

  /// Obtiene todas las notas de una tarea desde el almacenamiento local.
  List<TareaNotaModel> getNotesForTask(String tareaId) {
    return _local.getNotesForTask(tareaId);
  }

  /// Descarga todas las notas de Supabase y reemplaza los datos locales.
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
