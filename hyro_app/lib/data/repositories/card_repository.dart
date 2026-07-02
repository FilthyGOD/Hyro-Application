import 'package:flutter/material.dart';
import '../local/card_local_ds.dart';
import '../local/task_local_ds.dart';
import '../remote/card_remote_ds.dart';
import '../models/tarea_card_model.dart';

/// Repositorio que abstrae las operaciones locales y remotas de flashcards.
class CardRepository {
  final CardLocalDataSource _local;
  final CardRemoteDataSource _remote;
  final bool Function() _isAuthenticated;

  CardRepository({
    required CardLocalDataSource local,
    required CardRemoteDataSource remote,
    required bool Function() isAuthenticated,
  })  : _local = local,
        _remote = remote,
        _isAuthenticated = isAuthenticated;

  /// Obtiene todas las flashcards de una tarea desde el almacenamiento local.
  List<TareaCardModel> getCardsForTask(String tareaId) {
    return _local.getCardsForTask(tareaId);
  }

  /// Descarga todas las flashcards de Supabase y reemplaza los datos locales.
  /// Las flashcards se obtienen por IDs de tarea (no tienen usuario_id).
  Future<void> pullRemoteToLocal() async {
    try {
      final taskLocal = TaskLocalDataSource();
      final taskIds = taskLocal.getAllTasks().map((t) => t.id).toList();
      if (taskIds.isEmpty) return;
      final maps = await _remote.fetchAllByTaskIds(taskIds);
      await _local.clearAll();
      for (final map in maps) {
        final card = TareaCardModel.fromSupabaseJson(map);
        await _local.putCard(card);
      }
    } catch (e) {
      debugPrint('⚠️ CardRepo: Error pulling from remote: $e');
    }
  }

  /// Add a new flashcard — local first, then remote if authenticated.
  Future<void> addCard(TareaCardModel card) async {
    await _local.putCard(card);
    if (_isAuthenticated()) {
      try {
        await _remote.insertCard(card.toSupabaseJson());
      } catch (e) {
        debugPrint('⚠️ CardRepo: Error syncing new card to remote: $e');
      }
    }
  }

  /// Update a flashcard — local first, then remote if authenticated.
  Future<void> updateCard(TareaCardModel card) async {
    await _local.putCard(card);
    if (_isAuthenticated()) {
      try {
        await _remote.updateCard(card.id, card.toSupabaseJson());
      } catch (e) {
        debugPrint('⚠️ CardRepo: Error syncing card update to remote: $e');
      }
    }
  }

  /// Delete a flashcard — local first, then remote if authenticated.
  Future<void> deleteCard(String id) async {
    await _local.deleteCard(id);
    if (_isAuthenticated()) {
      try {
        await _remote.deleteCard(id);
      } catch (e) {
        debugPrint('⚠️ CardRepo: Error syncing card deletion to remote: $e');
      }
    }
  }

  /// Delete all cards for a task — local only.
  Future<void> deleteCardsForTask(String tareaId) async {
    await _local.deleteCardsForTask(tareaId);
  }
}
