import 'package:hive/hive.dart';
import '../models/tarea_fuente_model.dart';

/// Local data source for task document sources using Hive.
class SourceLocalDataSource {
  static const String boxName = 'fuentesBox';

  Box<TareaFuenteModel> get _box => Hive.box<TareaFuenteModel>(boxName);

  /// Get all sources for a specific task.
  List<TareaFuenteModel> getSourcesForTask(String tareaId) {
    return _box.values.where((s) => s.tareaId == tareaId).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /// Get a single source by ID.
  TareaFuenteModel? getSource(String id) {
    return _box.get(id);
  }

  /// Insert or update a source.
  Future<void> putSource(TareaFuenteModel fuente) async {
    await _box.put(fuente.id, fuente);
  }

  /// Delete a source by ID.
  Future<void> deleteSource(String id) async {
    await _box.delete(id);
  }

  /// Delete all sources for a task.
  Future<void> deleteSourcesForTask(String tareaId) async {
    final keys = _box.keys.where((key) {
      final src = _box.get(key);
      return src?.tareaId == tareaId;
    }).toList();
    await _box.deleteAll(keys);
  }

  /// Get all sources that point to local files (for PDF upload during sync).
  List<TareaFuenteModel> getLocalFilesForSync() {
    return _box.values.where((s) => s.isLocal).toList();
  }

  /// Clear all sources from local storage.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get all sources for bulk sync.
  List<TareaFuenteModel> getAllForSync() {
    return _box.values.toList();
  }
}
