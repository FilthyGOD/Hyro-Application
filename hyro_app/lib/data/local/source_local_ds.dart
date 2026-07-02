import 'package:hive/hive.dart';
import '../models/tarea_fuente_model.dart';

/// Fuente de datos local para fuentes de documentos de tareas usando Hive.
class SourceLocalDataSource {
  static const String boxName = 'fuentesBox';

  Box<TareaFuenteModel> get _box => Hive.box<TareaFuenteModel>(boxName);

  /// Obtiene todas las fuentes de una tarea espec\u00edfica.
  List<TareaFuenteModel> getSourcesForTask(String tareaId) {
    return _box.values.where((s) => s.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Obtiene una fuente por ID.
  TareaFuenteModel? getSource(String id) {
    return _box.get(id);
  }

  /// Inserta o actualiza una fuente.
  Future<void> putSource(TareaFuenteModel fuente) async {
    await _box.put(fuente.id, fuente);
  }

  /// Elimina una fuente por ID.
  Future<void> deleteSource(String id) async {
    await _box.delete(id);
  }

  /// Elimina todas las fuentes de una tarea.
  Future<void> deleteSourcesForTask(String tareaId) async {
    final keys = _box.keys.where((key) {
      final src = _box.get(key);
      return src?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Obtiene todas las fuentes que apuntan a archivos locales (para subir PDFs durante la sincronizaci\u00f3n).
  List<TareaFuenteModel> getLocalFilesForSync() {
    return _box.values.where((s) => s.isLocal).toList();
  }

  /// Limpia todas las fuentes del almacenamiento local.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Obtiene todas las fuentes para sincronizaci\u00f3n masiva.
  List<TareaFuenteModel> getAllForSync() {
    return _box.values.toList();
  }
}
