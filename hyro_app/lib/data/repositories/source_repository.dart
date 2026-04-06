import 'package:flutter/material.dart';
import '../local/source_local_ds.dart';
import '../remote/source_remote_ds.dart';
import '../models/tarea_fuente_model.dart';

/// Repository that abstracts local and remote task source operations.
class SourceRepository {
  final SourceLocalDataSource _local;
  final SourceRemoteDataSource _remote;
  final bool Function() _isAuthenticated;
  final String? Function() _getUserId;

  SourceRepository({
    required SourceLocalDataSource local,
    required SourceRemoteDataSource remote,
    required bool Function() isAuthenticated,
    required String? Function() getUserId,
  })  : _local = local,
        _remote = remote,
        _isAuthenticated = isAuthenticated,
        _getUserId = getUserId;

  /// Get all sources for a task from local storage.
  List<TareaFuenteModel> getSourcesForTask(String tareaId) {
    return _local.getSourcesForTask(tareaId);
  }

  /// Pull all sources from Supabase and replace local data.
  Future<void> pullRemoteToLocal() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final maps = await _remote.fetchAllForUser(userId);
      await _local.clearAll();
      for (final map in maps) {
        final fuente = TareaFuenteModel.fromSupabaseJson(map);
        await _local.putSource(fuente);
      }
    } catch (e) {
      debugPrint('⚠️ SourceRepo: Error pulling from remote: $e');
    }
  }

  /// Add a new source — local first, then remote if authenticated.
  Future<void> addSource(TareaFuenteModel fuente) async {
    await _local.putSource(fuente);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.insertSource(fuente.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ SourceRepo: Error syncing new source to remote: $e');
      }
    }
  }

  /// Update a source — local first, then remote if authenticated.
  Future<void> updateSource(TareaFuenteModel fuente) async {
    await _local.putSource(fuente);
    if (_isAuthenticated()) {
      try {
        final userId = _getUserId();
        if (userId != null) {
          await _remote.updateSource(fuente.id, fuente.toSupabaseJson(userId));
        }
      } catch (e) {
        debugPrint('⚠️ SourceRepo: Error syncing source update to remote: $e');
      }
    }
  }

  /// Delete a source — local first, then remote if authenticated.
  Future<void> deleteSource(String id) async {
    await _local.deleteSource(id);
    if (_isAuthenticated()) {
      try {
        await _remote.deleteSource(id);
      } catch (e) {
        debugPrint('⚠️ SourceRepo: Error syncing source deletion to remote: $e');
      }
    }
  }

  /// Delete all sources for a task — local only.
  Future<void> deleteSourcesForTask(String tareaId) async {
    await _local.deleteSourcesForTask(tareaId);
  }
}
