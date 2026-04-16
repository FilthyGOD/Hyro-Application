import 'package:flutter/material.dart';
import '../local/task_local_ds.dart';
import '../local/category_local_ds.dart';
import '../local/note_local_ds.dart';
import '../local/source_local_ds.dart';
import '../local/card_local_ds.dart';
import '../remote/task_remote_ds.dart';
import '../remote/category_remote_ds.dart';
import '../remote/note_remote_ds.dart';
import '../remote/source_remote_ds.dart';
import '../remote/card_remote_ds.dart';
import '../remote/file_storage_service.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/tarea_nota_model.dart';
import '../models/tarea_fuente_model.dart';
import '../models/tarea_card_model.dart';
import '../models/daily_stats.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_status.dart';

/// Orchestrates the one-time migration of ALL local data to Supabase
/// when a guest user creates an account.
///
/// SYNC ORDER (respects foreign key constraints):
/// 1. Categorías (no FK dependencies)
/// 2. Tareas (depends on categorías)
/// 3. Notas (depends on tareas)
/// 4. Fuentes/PDFs (depends on tareas + file upload)
/// 5. Flashcards (depends on tareas)
class SyncService {
  final CategoryLocalDataSource _categoryLocal;
  final TaskLocalDataSource _taskLocal;
  final NoteLocalDataSource _noteLocal;
  final SourceLocalDataSource _sourceLocal;
  final CardLocalDataSource _cardLocal;

  final CategoryRemoteDataSource _categoryRemote;
  final TaskRemoteDataSource _taskRemote;
  final NoteRemoteDataSource _noteRemote;
  final SourceRemoteDataSource _sourceRemote;
  final CardRemoteDataSource _cardRemote;

  final FileStorageService _fileStorage;

  SyncService({
    required CategoryLocalDataSource categoryLocal,
    required TaskLocalDataSource taskLocal,
    required NoteLocalDataSource noteLocal,
    required SourceLocalDataSource sourceLocal,
    required CardLocalDataSource cardLocal,
    required CategoryRemoteDataSource categoryRemote,
    required TaskRemoteDataSource taskRemote,
    required NoteRemoteDataSource noteRemote,
    required SourceRemoteDataSource sourceRemote,
    required CardRemoteDataSource cardRemote,
    required FileStorageService fileStorage,
  })  : _categoryLocal = categoryLocal,
        _taskLocal = taskLocal,
        _noteLocal = noteLocal,
        _sourceLocal = sourceLocal,
        _cardLocal = cardLocal,
        _categoryRemote = categoryRemote,
        _taskRemote = taskRemote,
        _noteRemote = noteRemote,
        _sourceRemote = sourceRemote,
        _cardRemote = cardRemote,
        _fileStorage = fileStorage;

  /// Executes the full migration of local data to Supabase.
  ///
  /// [userId] is the Supabase `auth.uid()` from the newly created account.
  /// This replaces any local guest UUID with the real user ID.
  Future<SyncResult> syncAllToRemote(String userId) async {
    final result = SyncResult();

    try {
      // ─── STEP 1: Categorías ─────────────────────────────────
      debugPrint('🔄 Sync Step 1/5: Subiendo categorías...');
      final categorias = _categoryLocal.getAllForSync();
      if (categorias.isNotEmpty) {
        final catMaps = categorias
            .map((c) => c.toSupabaseJson(userId))
            .toList();
        await _categoryRemote.bulkUpsert(catMaps);
        result.categoriasSynced = catMaps.length;
        debugPrint('   ✅ ${catMaps.length} categorías sincronizadas');
      }

      // ─── STEP 2: Tareas ────────────────────────────────────
      debugPrint('🔄 Sync Step 2/5: Subiendo tareas...');
      final tareas = _taskLocal.getAllForSync();
      if (tareas.isNotEmpty) {
        final taskMaps = tareas
            .map((t) => t.toSupabaseJson(userId))
            .toList();
        await _taskRemote.bulkUpsert(taskMaps);
        result.tareasSynced = taskMaps.length;
        debugPrint('   ✅ ${taskMaps.length} tareas sincronizadas');
      }

      // ─── STEP 3: Notas ─────────────────────────────────────
      debugPrint('🔄 Sync Step 3/5: Subiendo notas...');
      final notas = _noteLocal.getAllForSync();
      if (notas.isNotEmpty) {
        final notaMaps = notas
            .map((n) => n.toSupabaseJson(userId))
            .toList();
        await _noteRemote.bulkUpsert(notaMaps);
        result.notasSynced = notaMaps.length;
        debugPrint('   ✅ ${notaMaps.length} notas sincronizadas');
      }

      // ─── STEP 4: Fuentes / PDFs ────────────────────────────
      debugPrint('🔄 Sync Step 4/5: Subiendo archivos PDF...');
      final fuentes = _sourceLocal.getAllForSync();
      for (final fuente in fuentes) {
        try {
          String rutaFinal = fuente.rutaArchivo;

          // If the file is local, upload to Supabase Storage
          if (fuente.isLocal) {
            rutaFinal = await _fileStorage.uploadFile(
              localPath: fuente.rutaArchivo,
              userId: userId,
              fileId: fuente.id,
            );

            // Update local record with the public URL
            fuente.rutaArchivo = rutaFinal;
            await _sourceLocal.putSource(fuente);
          }

          // Insert metadata into Supabase DB
          await _sourceRemote.insertSource(fuente.toSupabaseJson(userId)
            ..['ruta_archivo'] = rutaFinal);
          result.archivosSynced++;
        } catch (e) {
          debugPrint('   ⚠️ Error subiendo ${fuente.nombreArchivo}: $e');
          result.errors.add('Archivo: ${fuente.nombreArchivo} - $e');
        }
      }
      debugPrint('   ✅ ${result.archivosSynced} archivos sincronizados');

      // ─── STEP 5: Flashcards ────────────────────────────────
      debugPrint('🔄 Sync Step 5/5: Subiendo flashcards...');
      final cards = _cardLocal.getAllForSync();
      if (cards.isNotEmpty) {
        final cardMaps = cards
            .map((c) => c.toSupabaseJson())
            .toList();
        await _cardRemote.bulkUpsert(cardMaps);
        result.cardsSynced = cardMaps.length;
        debugPrint('   ✅ ${cardMaps.length} flashcards sincronizadas');
      }

      result.success = true;
      debugPrint('✅ Sincronización completa: $result');
    } catch (e) {
      result.success = false;
      result.errors.add('Error general de sincronización: $e');
      debugPrint('❌ Error en sincronización: $e');
    }

    return result;
  }

  /// Downloads ALL user data from Supabase and replaces local Hive data.
  ///
  /// PULL ORDER (respects FK constraints):
  /// 1. Categorías (no FK dependencies)
  /// 2. Tareas (depends on categorías)
  /// 3. Notas (depends on tareas)
  /// 4. Fuentes (depends on tareas)
  /// 5. Flashcards (depends on tareas)
  Future<SyncResult> pullFromRemote(String userId) async {
    final result = SyncResult();

    try {
      // ─── STEP 1: Categorías ─────────────────────────────────
      debugPrint('⬇️ Pull Step 1/5: Descargando categorías...');
      final catMaps = await _categoryRemote.fetchAllForUser(userId);
      await _categoryLocal.clearAll();
      for (final map in catMaps) {
        final cat = CategoryModel.fromSupabaseJson(map);
        await _categoryLocal.putCategory(cat);
        result.categoriasSynced++;
      }
      debugPrint('   ✅ ${result.categoriasSynced} categorías descargadas');

      // ─── STEP 2: Tareas ────────────────────────────────────
      debugPrint('⬇️ Pull Step 2/5: Descargando tareas...');
      final taskMaps = await _taskRemote.fetchAllForUser(userId);
      await _taskLocal.clearAll();
      final taskIds = <String>[];
      for (final map in taskMaps) {
        final task = TaskModel.fromSupabaseJson(map);
        // Resolve category name from local cache
        if (task.categoryId != null) {
          final cat = _categoryLocal.getCategory(task.categoryId!);
          if (cat != null) task.category = cat.name;
        }
        await _taskLocal.putTask(task);
        taskIds.add(task.id);
        result.tareasSynced++;
      }
      debugPrint('   ✅ ${result.tareasSynced} tareas descargadas');

      // ─── STEP 3: Notas ─────────────────────────────────────
      debugPrint('⬇️ Pull Step 3/5: Descargando notas...');
      final notaMaps = await _noteRemote.fetchAllForUser(userId);
      await _noteLocal.clearAll();
      for (final map in notaMaps) {
        final nota = TareaNotaModel.fromSupabaseJson(map);
        await _noteLocal.putNote(nota);
        result.notasSynced++;
      }
      debugPrint('   ✅ ${result.notasSynced} notas descargadas');

      // ─── STEP 4: Fuentes ───────────────────────────────────
      debugPrint('⬇️ Pull Step 4/5: Descargando fuentes...');
      final fuenteMaps = await _sourceRemote.fetchAllForUser(userId);
      await _sourceLocal.clearAll();
      for (final map in fuenteMaps) {
        final fuente = TareaFuenteModel.fromSupabaseJson(map);
        await _sourceLocal.putSource(fuente);
        result.archivosSynced++;
      }
      debugPrint('   ✅ ${result.archivosSynced} fuentes descargadas');

      // ─── STEP 5: Flashcards ────────────────────────────────
      debugPrint('⬇️ Pull Step 5/5: Descargando flashcards...');
      await _cardLocal.clearAll();
      if (taskIds.isNotEmpty) {
        final cardMaps = await _cardRemote.fetchAllByTaskIds(taskIds);
        for (final map in cardMaps) {
          final card = TareaCardModel.fromSupabaseJson(map);
          await _cardLocal.putCard(card);
          result.cardsSynced++;
        }
      }
      debugPrint('   ✅ ${result.cardsSynced} flashcards descargadas');

      result.success = true;
      debugPrint('✅ Pull completo: $result');

      // ─── STEP 6: Estadísticas / Sesiones de Enfoque ────────────────
      debugPrint('⬇️ Pull Step 6/6: Descargando sesiones de enfoque (Stats)...');
      try {
        final supabaseClient = Supabase.instance.client;
        final sesionesMaps = await supabaseClient
            .from('sesiones_enfoque')
            .select('duracion_minutos, completada_en')
            .eq('usuario_id', userId);
            
        final statsMap = <String, DailyStats>{};
        for (final map in sesionesMaps) {
          final completadaEnStr = map['completada_en'] as String?;
          if (completadaEnStr == null) continue;
          final completadaEn = DateTime.parse(completadaEnStr).toLocal();
          final dateKey = '${completadaEn.year}-${completadaEn.month.toString().padLeft(2, '0')}-${completadaEn.day.toString().padLeft(2, '0')}';
          final duracion = (map['duracion_minutos'] as num?)?.toInt() ?? 0;
          
          if (!statsMap.containsKey(dateKey)) {
            statsMap[dateKey] = DailyStats(date: dateKey);
          }
          statsMap[dateKey]!.focusSessions += 1;
          statsMap[dateKey]!.focusMinutes += duracion;
        }
        
        if (Hive.isBoxOpen('statsBox')) {
          final statsBox = Hive.box<DailyStats>('statsBox');
          await statsBox.clear();
          for (final stat in statsMap.values) {
            await statsBox.put(stat.date, stat);
          }
        }
        debugPrint('   ✅ ${statsMap.length} días de estadísticas guardados localmente');
      } catch (e) {
        debugPrint('   ⚠️ Error descargando estadísticas: $e');
      }
    } catch (e) {
      result.success = false;
      result.errors.add('Error descargando datos: $e');
      debugPrint('❌ Error en pull: $e');
    }

    return result;
  }
}
