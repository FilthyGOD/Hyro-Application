import 'package:hive/hive.dart';
import '../models/tarea_card_model.dart';

/// Local data source for flashcards using Hive.
class CardLocalDataSource {
  static const String boxName = 'cardsBox';

  Box<TareaCardModel> get _box => Hive.box<TareaCardModel>(boxName);

  /// Get all flashcards for a specific task.
  List<TareaCardModel> getCardsForTask(String tareaId) {
    return _box.values.where((c) => c.tareaId == tareaId).toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
  }

  /// Get a single card by ID.
  TareaCardModel? getCard(String id) {
    return _box.get(id);
  }

  /// Insert or update a card.
  Future<void> putCard(TareaCardModel card) async {
    await _box.put(card.id, card);
  }

  /// Delete a card by ID.
  Future<void> deleteCard(String id) async {
    await _box.delete(id);
  }

  /// Delete all cards for a task.
  Future<void> deleteCardsForTask(String tareaId) async {
    final keys = _box.keys.where((key) {
      final card = _box.get(key);
      return card?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Clear all cards from local storage.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get all cards for bulk sync.
  List<TareaCardModel> getAllForSync() {
    return _box.values.toList();
  }
}
