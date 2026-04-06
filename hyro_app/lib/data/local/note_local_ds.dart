import 'package:hive/hive.dart';
import '../models/tarea_nota_model.dart';

/// Local data source for task notes using Hive.
class NoteLocalDataSource {
  static const String boxName = 'notasBox';

  Box<TareaNotaModel> get _box => Hive.box<TareaNotaModel>(boxName);

  /// Get all notes for a specific task.
  List<TareaNotaModel> getNotesForTask(String tareaId) {
    return _box.values.where((n) => n.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Get a single note by ID.
  TareaNotaModel? getNote(String id) {
    return _box.get(id);
  }

  /// Insert or update a note.
  Future<void> putNote(TareaNotaModel nota) async {
    await _box.put(nota.id, nota);
  }

  /// Delete a note by ID.
  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  /// Delete all notes for a task.
  Future<void> deleteNotesForTask(String tareaId) async {
    final keys = _box.keys.where((key) {
      final nota = _box.get(key);
      return nota?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Clear all notes from local storage.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get all notes for bulk sync.
  List<TareaNotaModel> getAllForSync() {
    return _box.values.toList();
  }
}
