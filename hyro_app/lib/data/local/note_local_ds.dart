import 'package:hive/hive.dart';
import '../models/tarea_nota_model.dart';

/// Fuente de datos local para notas de tareas usando Hive.
class NoteLocalDataSource {
  static const String boxName = 'notasBox';

  Box<TareaNotaModel> get _box => Hive.box<TareaNotaModel>(boxName);

  /// Obtiene todas las notas de una tarea espec\u00edfica.
  List<TareaNotaModel> getNotesForTask(String tareaId) {
    return _box.values.where((n) => n.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Obtiene una nota por ID.
  TareaNotaModel? getNote(String id) {
    return _box.get(id);
  }

  /// Inserta o actualiza una nota.
  Future<void> putNote(TareaNotaModel nota) async {
    await _box.put(nota.id, nota);
  }

  /// Elimina una nota por ID.
  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  /// Elimina todas las notas de una tarea.
  Future<void> deleteNotesForTask(String tareaId) async {
    final keys = _box.keys.where((key) {
      final nota = _box.get(key);
      return nota?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Limpia todas las notas del almacenamiento local.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Obtiene todas las notas para sincronizaci\u00f3n masiva.
  List<TareaNotaModel> getAllForSync() {
    return _box.values.toList();
  }
}
