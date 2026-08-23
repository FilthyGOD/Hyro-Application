import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/tarea_nota_model.dart';

/// Fuente de datos local para notas de tareas usando Hive.
class NoteLocalDataSource {
  static const String boxName = 'notasBox';

  // Caché en memoria para entorno Web
  static final Map<String, TareaNotaModel> _webCache = {};

  Box<TareaNotaModel> get _box => Hive.box<TareaNotaModel>(boxName);

  /// Obtiene todas las notas de una tarea específica.
  List<TareaNotaModel> getNotesForTask(String tareaId) {
    if (kIsWeb) {
      return _webCache.values.where((n) => n.tareaId == tareaId).toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    }
    return _box.values.where((n) => n.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Obtiene una nota por ID.
  TareaNotaModel? getNote(String id) {
    if (kIsWeb) return _webCache[id];
    return _box.get(id);
  }

  /// Inserta o actualiza una nota.
  Future<void> putNote(TareaNotaModel nota) async {
    if (kIsWeb) {
      _webCache[nota.id] = nota;
      return;
    }
    await _box.put(nota.id, nota);
  }

  /// Elimina una nota por ID.
  Future<void> deleteNote(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      return;
    }
    await _box.delete(id);
  }

  /// Elimina todas las notas de una tarea.
  Future<void> deleteNotesForTask(String tareaId) async {
    if (kIsWeb) {
      _webCache.removeWhere((key, value) => value.tareaId == tareaId);
      return;
    }
    final keys = _box.keys.where((key) {
      final nota = _box.get(key);
      return nota?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Limpia todas las notas del almacenamiento local.
  Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    await _box.clear();
  }

  /// Obtiene todas las notas para sincronización masiva.
  List<TareaNotaModel> getAllForSync() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }
}
