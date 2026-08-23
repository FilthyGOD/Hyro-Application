import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/tarea_card_model.dart';

/// Fuente de datos local para flashcards usando Hive.
class CardLocalDataSource {
  static const String boxName = 'cardsBox';

  // Caché en memoria para entorno Web
  static final Map<String, TareaCardModel> _webCache = {};

  Box<TareaCardModel> get _box => Hive.box<TareaCardModel>(boxName);

  /// Obtiene todas las flashcards de una tarea específica.
  List<TareaCardModel> getCardsForTask(String tareaId) {
    if (kIsWeb) {
      return _webCache.values.where((c) => c.tareaId == tareaId).toList()
        ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    }
    return _box.values.where((c) => c.tareaId == tareaId).toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
  }

  /// Obtiene una flashcard por ID.
  TareaCardModel? getCard(String id) {
    if (kIsWeb) return _webCache[id];
    return _box.get(id);
  }

  /// Inserta o actualiza una flashcard.
  Future<void> putCard(TareaCardModel card) async {
    if (kIsWeb) {
      _webCache[card.id] = card;
      return;
    }
    await _box.put(card.id, card);
  }

  /// Elimina una flashcard por ID.
  Future<void> deleteCard(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      return;
    }
    await _box.delete(id);
  }

  /// Elimina todas las flashcards de una tarea.
  Future<void> deleteCardsForTask(String tareaId) async {
    if (kIsWeb) {
      _webCache.removeWhere((key, value) => value.tareaId == tareaId);
      return;
    }
    final keys = _box.keys.where((key) {
      final card = _box.get(key);
      return card?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Limpia todas las flashcards del almacenamiento local.
  Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    await _box.clear();
  }

  /// Obtiene todas las flashcards para sincronización masiva.
  List<TareaCardModel> getAllForSync() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }
}
