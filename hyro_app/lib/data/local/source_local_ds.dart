import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/tarea_fuente_model.dart';

/// Fuente de datos local para fuentes de documentos de tareas usando Hive.
class SourceLocalDataSource {
  static const String boxName = 'fuentesBox';

  // Caché en memoria para entorno Web
  static final Map<String, TareaFuenteModel> _webCache = {};

  Box<TareaFuenteModel> get _box => Hive.box<TareaFuenteModel>(boxName);

  /// Obtiene todas las fuentes de una tarea específica.
  List<TareaFuenteModel> getSourcesForTask(String tareaId) {
    if (kIsWeb) {
      return _webCache.values.where((s) => s.tareaId == tareaId).toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    }
    return _box.values.where((s) => s.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Obtiene una fuente por ID.
  TareaFuenteModel? getSource(String id) {
    if (kIsWeb) return _webCache[id];
    return _box.get(id);
  }

  /// Inserta o actualiza una fuente.
  Future<void> putSource(TareaFuenteModel fuente) async {
    if (kIsWeb) {
      _webCache[fuente.id] = fuente;
      return;
    }
    await _box.put(fuente.id, fuente);
  }

  /// Elimina una fuente por ID.
  Future<void> deleteSource(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      return;
    }
    await _box.delete(id);
  }

  /// Elimina todas las fuentes de una tarea.
  Future<void> deleteSourcesForTask(String tareaId) async {
    if (kIsWeb) {
      _webCache.removeWhere((key, value) => value.tareaId == tareaId);
      return;
    }
    final keys = _box.keys.where((key) {
      final src = _box.get(key);
      return src?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Obtiene todas las fuentes que apuntan a archivos locales.
  List<TareaFuenteModel> getLocalFilesForSync() {
    if (kIsWeb) return []; // No hay archivos locales en web
    return _box.values.where((s) => s.isLocal).toList();
  }

  /// Limpia todas las fuentes del almacenamiento local.
  Future<void> clearAll() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }
    await _box.clear();
  }

  /// Obtiene todas las fuentes para sincronización masiva.
  List<TareaFuenteModel> getAllForSync() {
    if (kIsWeb) return _webCache.values.toList();
    return _box.values.toList();
  }
}
