import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/versus_models.dart';
import '../../../data/repositories/versus_repository.dart';

/// Estado reactivo para el sistema Versus (Duelos entre usuarios).
/// Gestiona batallas activas en tiempo real, creación de retos,
/// carga de preguntas y envío de respuestas a Supabase.
///
/// Sigue el mismo patrón que [FriendsProvider]:
/// - Se registra en MultiProvider de app.dart.
/// - Se consume vía context.watch/read desde la UI.
class VersusProvider extends ChangeNotifier {
  final VersusRepository _repo = VersusRepository();
  final _supabase = Supabase.instance.client;

  // ── Estado observable ──
  List<VersusMatch> activeBattles = [];
  List<VersusQuestion> currentQuestions = [];
  bool isLoading = false;
  bool isCreating = false;
  String? error;
  String? actionMessage;

  // ── Suscripción al stream de Supabase Realtime ──
  StreamSubscription<List<Map<String, dynamic>>>? _battlesSub;
  String? _currentUserId;

  // ── Cache de perfiles para evitar queries repetidos ──
  final Map<String, VersusPlayer> _profileCache = {};

  // ── Cache de nombres de categorías para optimizar realtime ──
  final Map<String, String> _categoryCache = {};
  // ── Cache de nombres de tareas para optimizar realtime ──
  final Map<String, String> _taskCache = {};
  // ── Cache de colores de categorías ──
  final Map<String, Color> _categoryColorCache = {};

  // ═══════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN Y STREAM EN TIEMPO REAL
  // ═══════════════════════════════════════════════════════════════════════

  /// Inicia la suscripción al stream de batallas activas.
  /// Debe llamarse una vez al cargar la app con el userId actual.
  void initStream(String userId) {
    // Evitar múltiples suscripciones al mismo usuario
    if (_currentUserId == userId && _battlesSub != null) return;

    _currentUserId = userId;
    _battlesSub?.cancel();

    isLoading = true;
    Future.microtask(() => notifyListeners());

    _battlesSub = _repo.getBatallasActivasStream(userId).listen(
      (rows) async {
        try {
          activeBattles = await _mapRowsToMatches(rows, userId);
          error = null;
        } catch (e) {
          debugPrint('❌ [VersusProvider] Error mapeando batallas: $e');
          error = 'Error cargando batallas: $e';
        } finally {
          isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('❌ [VersusProvider] Error en stream de batallas: $e');
        error = 'Error en la conexión: $e';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Carga puntual de batallas (para pull-to-refresh).
  Future<void> refreshBattles(String userId) async {
    isLoading = true;
    error = null;
    Future.microtask(() => notifyListeners());

    try {
      final rows = await _repo.getBatallasActivas(userId);
      activeBattles = await _mapRowsToMatches(rows, userId);
    } catch (e) {
      error = 'Error actualizando batallas: $e';
      debugPrint('❌ [VersusProvider] $error');
    } finally {
      isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CREAR BATALLA (Retador lanza reto)
  // ═══════════════════════════════════════════════════════════════════════

  /// Crea una nueva batalla y notifica a la UI.
  /// Retorna true si se creó exitosamente, false si hubo error.
  Future<bool> crearBatalla({
    required String oponenteId,
    required String modoBatalla,
    required String tareaRetadorId,
    required String? categoriaRetadorId,
    required int apuestaMonedas,
  }) async {
    isCreating = true;
    actionMessage = null;
    notifyListeners();

    try {
      await _repo.crearBatalla(
        oponenteId: oponenteId,
        modoBatalla: modoBatalla,
        tareaRetadorId: tareaRetadorId,
        categoriaRetadorId: categoriaRetadorId,
        apuestaMonedas: apuestaMonedas,
      );

      actionMessage = '¡Reto enviado exitosamente!';
      return true;
    } on VersusException catch (e) {
      actionMessage = e.message;
      return false;
    } catch (e) {
      actionMessage = 'Error inesperado al crear el reto: $e';
      return false;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACEPTAR / RECHAZAR BATALLA
  // ═══════════════════════════════════════════════════════════════════════

  /// Acepta una batalla pendiente. Para modo 'cruzado',
  /// el oponente debe elegir su tarea.
  Future<bool> aceptarBatalla({
    required String batallaId,
    String? tareaOponenteId,
    String? categoriaOponenteId,
  }) async {
    try {
      await _repo.aceptarBatalla(
        batallaId: batallaId,
        tareaOponenteId: tareaOponenteId,
        categoriaOponenteId: categoriaOponenteId,
      );
      actionMessage = '¡Batalla aceptada!';
      notifyListeners();
      return true;
    } on VersusException catch (e) {
      actionMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Rechaza/cancela una batalla pendiente.
  Future<bool> rechazarBatalla(String batallaId) async {
    try {
      await _repo.rechazarBatalla(batallaId);
      actionMessage = 'Batalla rechazada';
      notifyListeners();
      return true;
    } on VersusException catch (e) {
      actionMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PREGUNTAS POR RONDA
  // ═══════════════════════════════════════════════════════════════════════

  /// Carga las preguntas de una ronda específica.
  /// Almacena el resultado en [currentQuestions].
  Future<List<VersusQuestion>> cargarPreguntasRonda({
    required String batallaId,
    required int ronda,
  }) async {
    try {
      currentQuestions = await _repo.obtenerPreguntasPorRonda(
        batallaId: batallaId,
        ronda: ronda,
      );
      notifyListeners();
      return currentQuestions;
    } on VersusException catch (e) {
      debugPrint('❌ [VersusProvider] Error cargando preguntas: ${e.message}');
      currentQuestions = [];
      notifyListeners();
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GUARDAR RESPUESTA
  // ═══════════════════════════════════════════════════════════════════════

  /// Guarda la respuesta del usuario en Supabase.
  Future<void> guardarRespuesta({
    required String preguntaId,
    required String batallaId,
    required String jugadorId,
    required String respuestaDada,
    required bool esCorrecta,
    required int tiempoRespuestaMs,
  }) async {
    try {
      await _repo.guardarRespuesta(
        preguntaId: preguntaId,
        batallaId: batallaId,
        jugadorId: jugadorId,
        respuestaDada: respuestaDada,
        esCorrecta: esCorrecta,
        tiempoRespuestaMs: tiempoRespuestaMs,
      );
    } on VersusException catch (e) {
      debugPrint('❌ [VersusProvider] Error guardando respuesta: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTUALIZAR MARCADOR & REFRESCO REALTIME
  // ═══════════════════════════════════════════════════════════════════════

  /// Actualiza el marcador de rondas ganadas al finalizar una ronda.
  Future<void> actualizarMarcador({
    required String batallaId,
    required int rondasRetador,
    required int rondasOponente,
  }) async {
    try {
      await _repo.actualizarMarcador(
        batallaId: batallaId,
        rondasRetador: rondasRetador,
        rondasOponente: rondasOponente,
      );
    } on VersusException catch (e) {
      debugPrint('❌ [VersusProvider] Error actualizando marcador: ${e.message}');
    }
  }

  /// Gatilla una actualización en la base de datos para notificar al stream Realtime.
  Future<void> touchBatalla(String batallaId) async {
    try {
      await _repo.touchBatalla(batallaId);
    } catch (e) {
      debugPrint('❌ [VersusProvider] Error al tocar batalla: $e');
    }
  }

  /// Finaliza el turno del jugador actual y pasa el turno al oponente
  /// (o marca la ronda como lista para evaluación).
  Future<void> finalizarTurno({
    required String batallaId,
    required String jugadorActualId,
    required String oponenteId,
    required bool isChallenger,
    required int rondaActual,
  }) async {
    try {
      await _repo.finalizarTurno(
        batallaId: batallaId,
        jugadorActualId: jugadorActualId,
        oponenteId: oponenteId,
        isChallenger: isChallenger,
        rondaActual: rondaActual,
      );
    } on VersusException catch (e) {
      debugPrint('❌ [VersusProvider] Error finalizando turno: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UTILIDADES INTERNAS
  // ═══════════════════════════════════════════════════════════════════════

  /// Convierte filas crudas de `batallas_versus` en objetos [VersusMatch],
  /// resolviendo los perfiles del retador y oponente desde Supabase.
  Future<List<VersusMatch>> _mapRowsToMatches(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    final matches = <VersusMatch>[];

    for (final row in rows) {
      try {
        final retadorId = row['retador_id'] as String;
        final oponenteId = row['oponente_id'] as String;
        final isRetador = retadorId == currentUserId;

        final localId = isRetador ? retadorId : oponenteId;
        final opponentId = isRetador ? oponenteId : retadorId;

        // Resolver perfiles (con cache para evitar queries repetidos)
        final localPlayer = await _resolvePlayer(localId);
        final opponentPlayer = await _resolvePlayer(opponentId);

        // Resolver nombre del tema del duelo (titulo de la tarea del retador)
        final tareaId = row['tarea_retador_id']?.toString();
        final categoriaId = row['categoria_retador_id']?.toString();
        String subjectName = 'Sin tarea';

        if (tareaId != null) {
          subjectName = await _resolveTaskName(tareaId);
        } else if (categoriaId != null) {
          subjectName = await _resolveCategoryName(categoriaId);
        }

        // Resolver color de la categoría de la tarea
        Color subjectColor = const Color(0xFF00F2FF);
        if (categoriaId != null) {
          subjectColor = await _resolveCategoryColor(categoriaId);
        }

        matches.add(VersusMatch.fromSupabase(
          row: row,
          currentUserId: currentUserId,
          localPlayer: localPlayer,
          opponentPlayer: opponentPlayer,
          subjectName: subjectName,
          subjectColor: subjectColor,
        ));
      } catch (e) {
        debugPrint('⚠️ [VersusProvider] Error mapeando fila: $e');
        // Continuar con las demás filas sin romper
      }
    }

    return matches;
  }

  /// Resuelve un perfil de usuario desde cache o Supabase.
  Future<VersusPlayer> _resolvePlayer(String userId) async {
    // Retornar desde cache si ya lo tenemos
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId]!;
    }

    try {
      final response = await _supabase
          .from('perfiles')
          .select(
            'id, nombre_usuario, nivel, '
            'mascota_cosmeticos(sombrero, cara, traje)',
          )
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final player = VersusPlayer.fromProfileData(response);
        _profileCache[userId] = player;
        return player;
      }
    } catch (e) {
      debugPrint('⚠️ [VersusProvider] Error resolviendo perfil $userId: $e');
    }

    // Fallback con datos mínimos
    return VersusPlayer(
      id: userId,
      username: 'Usuario',
      sombreroId: 100,
      cosmeticoId: 200,
      trajeId: 300,
      level: 1,
    );
  }

  /// Resuelve el nombre de una categoría por su ID.
  Future<String> _resolveCategoryName(String categoryId) async {
    if (_categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId]!;
    }
    try {
      final response = await _supabase
          .from('categorias')
          .select('nombre')
          .eq('id', categoryId)
          .maybeSingle();

      final name = response?['nombre'] as String? ?? 'Sin materia';
      _categoryCache[categoryId] = name;
      return name;
    } catch (e) {
      debugPrint('⚠️ [VersusProvider] Error resolviendo categoría: $e');
      return 'Sin materia';
    }
  }

  /// Resuelve el título de una tarea por su ID.
  Future<String> _resolveTaskName(String taskId) async {
    if (_taskCache.containsKey(taskId)) {
      return _taskCache[taskId]!;
    }
    try {
      final response = await _supabase
          .from('tareas')
          .select('titulo')
          .eq('id', taskId)
          .maybeSingle();

      final title = response?['titulo'] as String? ?? 'Sin tarea';
      _taskCache[taskId] = title;
      return title;
    } catch (e) {
      debugPrint('⚠️ [VersusProvider] Error resolviendo tarea $taskId: $e');
      return 'Sin tarea';
    }
  }

  /// Resuelve el color de una categoría por su ID.
  Future<Color> _resolveCategoryColor(String categoryId) async {
    if (_categoryColorCache.containsKey(categoryId)) {
      return _categoryColorCache[categoryId]!;
    }
    try {
      final response = await _supabase
          .from('categorias')
          .select('color')
          .eq('id', categoryId)
          .maybeSingle();

      final colorHex = response?['color'] as String?;
      int val = 0xFF22C55E; // default color
      if (colorHex != null && colorHex.isNotEmpty) {
        final clean = colorHex.replaceAll('#', '');
        val = int.tryParse(clean, radix: 16) ?? 0xFF22C55E;
      }
      if (val <= 0xFFFFFF) {
        val = 0xFF000000 | val; // Asegurar canal alfa
      }
      final color = Color(val);
      _categoryColorCache[categoryId] = color;
      return color;
    } catch (e) {
      debugPrint('⚠️ [VersusProvider] Error resolviendo color de categoría $categoryId: $e');
      return const Color(0xFF00F2FF);
    }
  }

  /// Reclama el premio de una batalla ganada
  Future<void> reclamarPremio(String batallaId) async {
    await _repo.reclamarPremio(batallaId);
    notifyListeners();
  }

  /// Archiva la batalla actualizándola a estado 'reclamada' en Supabase y ocultándola para el jugador.
  Future<void> archivarBatalla(String batallaId, bool isChallenger) async {
    await _repo.archivarBatalla(batallaId, isChallenger);
    notifyListeners();
  }

  /// Limpia el mensaje de acción temporal.
  void clearActionMessage() {
    actionMessage = null;
    notifyListeners();
  }

  /// Limpia la cache de perfiles (útil al cambiar de usuario).
  void clearCache() {
    _profileCache.clear();
    _categoryCache.clear();
    _taskCache.clear();
    _categoryColorCache.clear();
  }

  @override
  void dispose() {
    _battlesSub?.cancel();
    super.dispose();
  }
}
