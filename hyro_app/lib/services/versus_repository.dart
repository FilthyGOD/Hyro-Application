import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/versus/models/versus_models.dart';

/// Excepción personalizada para errores del módulo Versus.
class VersusException implements Exception {
  final String message;
  final String? code;
  const VersusException(this.message, {this.code});

  @override
  String toString() => 'VersusException($code): $message';
}

/// Repositorio centralizado para operaciones de Supabase relacionadas
/// con el modo Versus (duelos entre usuarios).
///
/// Tablas involucradas:
/// - `batallas_versus`: Datos de la partida.
/// - `batalla_preguntas`: Preguntas pre-generadas por ronda.
/// - `batalla_respuestas`: Respuestas individuales de cada jugador.
class VersusRepository {
  final _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════
  // 1. CREAR BATALLA (Retador inicia el duelo)
  // ═══════════════════════════════════════════════════════════════════════

  /// Crea una nueva batalla Versus e inserta el registro en `batallas_versus`.
  ///
  /// Parámetros:
  /// - [retadorId]: ID del usuario que lanza el reto.
  /// - [oponenteId]: ID del amigo desafiado.
  /// - [modoBatalla]: 'misma_materia' o 'cruzado'.
  /// - [categoriaRetadorId]: ID de la categoría/materia elegida por el retador.
  /// - [apuestaMonedas]: Cantidad apostada (20, 50 o 100).
  ///
  /// Retorna el mapa completo de la batalla recién insertada.
  ///
  /// ⚠️ IMPORTANTE — Seguridad del cobro de monedas:
  /// En producción, el cobro de monedas NO debe hacerse desde el cliente.
  /// Se recomienda llamar a una Supabase Edge Function (RPC) que:
  /// 1. Verifique que el retador tenga saldo suficiente.
  /// 2. Descuente las monedas atómicamente (transacción).
  /// 3. Cree el registro en `batallas_versus`.
  /// 4. Llame a la IA para pre-generar las preguntas de la Ronda 1.
  ///
  /// Ejemplo de llamada RPC alternativa:
  /// ```dart
  /// final result = await _supabase.rpc('crear_batalla_versus', params: { ... });
  /// ```
  Future<Map<String, dynamic>> crearBatalla({
    required String retadorId,
    required String oponenteId,
    required String modoBatalla,
    required String categoriaRetadorId,
    required int apuestaMonedas,
  }) async {
    try {
      // Validación básica en el cliente
      if (![20, 50, 100].contains(apuestaMonedas)) {
        throw const VersusException(
          'La apuesta debe ser 20, 50 o 100 monedas.',
          code: 'INVALID_BET',
        );
      }

      if (!['misma_materia', 'cruzado'].contains(modoBatalla)) {
        throw const VersusException(
          'Modo de batalla inválido.',
          code: 'INVALID_MODE',
        );
      }

      final response = await _supabase
          .from('batallas_versus')
          .insert({
            'retador_id': retadorId,
            'oponente_id': oponenteId,
            'modo_batalla': modoBatalla,
            'categoria_retador_id': categoriaRetadorId,
            // En modo 'misma_materia', ambos usan la misma categoría.
            // En modo 'cruzado', `categoria_oponente_id` se define al aceptar.
            'categoria_oponente_id': modoBatalla == 'misma_materia'
                ? categoriaRetadorId
                : null,
            'estado': 'pendiente',
            'apuesta_monedas': apuestaMonedas,
            'rondas_ganadas_retador': 0,
            'rondas_ganadas_oponente': 0,
          })
          .select()
          .single();

      debugPrint('⚔️ [VersusRepo] Batalla creada: ${response['id']}');
      return response;
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error Postgrest al crear batalla: ${e.message}');
      throw VersusException(
        'No se pudo crear la batalla: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (e is VersusException) rethrow;
      debugPrint('❌ [VersusRepo] Error inesperado al crear batalla: $e');
      throw VersusException('Error inesperado al crear la batalla: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 2. STREAM DE BATALLAS ACTIVAS (para la pestaña Amigos)
  // ═══════════════════════════════════════════════════════════════════════

  /// Retorna un `Stream` reactivo de batallas donde el usuario participa
  /// (como retador u oponente) y cuyo estado sea 'pendiente' o 'activa'.
  ///
  /// Alimenta el listado horizontal de combates en proceso en FriendsScreen.
  ///
  /// Supabase Realtime escucha cambios en la tabla `batallas_versus` y
  /// emite automáticamente cada vez que se inserta, actualiza o elimina
  /// una fila que coincida con el filtro del usuario.
  Stream<List<Map<String, dynamic>>> getBatallasActivasStream(String userId) {
    // Usamos .stream() de Supabase Realtime para escuchar cambios en tiempo real.
    // El filtro se aplica en el cliente porque Supabase Realtime no soporta
    // filtros OR complejos nativamente en el stream. Filtramos en el .map().
    return _supabase
        .from('batallas_versus')
        .stream(primaryKey: ['id'])
        .map((rows) {
          return rows.where((row) {
            final esRetador = row['retador_id'] == userId;
            final esOponente = row['oponente_id'] == userId;
            final estadoValido =
                row['estado'] == 'pendiente' || row['estado'] == 'activa';
            return (esRetador || esOponente) && estadoValido;
          }).toList();
        });
  }

  /// Alternativa con query puntual (no reactiva) para cargar las batallas
  /// activas una vez, útil para RefreshIndicator o pull-to-refresh.
  Future<List<Map<String, dynamic>>> getBatallasActivas(String userId) async {
    try {
      final response = await _supabase
              .from('batallas_versus')
              .select()
              .or('retador_id.eq.$userId,oponente_id.eq.$userId')
              .inFilter('estado', ['pendiente', 'activa'])
              .order('created_at', ascending: false)
          as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al obtener batallas activas: ${e.message}');
      throw VersusException(
        'No se pudieron cargar las batallas activas: ${e.message}',
        code: e.code,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 3. ACEPTAR BATALLA (Oponente acepta el reto)
  // ═══════════════════════════════════════════════════════════════════════

  /// Acepta una batalla pendiente, actualizando su estado a 'activa'.
  ///
  /// Si el modo de batalla es 'cruzado', el oponente debe seleccionar su
  /// propia categoría, la cual se guarda en `categoria_oponente_id`.
  ///
  /// ⚠️ IMPORTANTE — Seguridad del cobro al oponente:
  /// Al igual que al crear, el cobro de monedas al oponente debe hacerse
  /// a través de una Edge Function (RPC) que:
  /// 1. Verifique el saldo del oponente.
  /// 2. Descuente las monedas atómicamente.
  /// 3. Actualice el estado de la batalla.
  /// 4. Genere las preguntas de la Ronda 1 si aún no existen
  ///    (llamando a la IA con los apuntes de ambos jugadores).
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await _supabase.rpc('aceptar_batalla_versus', params: {
  ///   'batalla_id': batallaId,
  ///   'categoria_oponente_id': categoriaOponenteId,
  /// });
  /// ```
  Future<Map<String, dynamic>> aceptarBatalla({
    required String batallaId,
    String? categoriaOponenteId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'estado': 'activa',
      };

      // En modo 'cruzado', el oponente elige su materia al aceptar.
      if (categoriaOponenteId != null) {
        updates['categoria_oponente_id'] = categoriaOponenteId;
      }

      final response = await _supabase
          .from('batallas_versus')
          .update(updates)
          .eq('id', batallaId)
          .eq('estado', 'pendiente') // Solo actualiza si sigue pendiente (idempotencia)
          .select()
          .single();

      debugPrint('✅ [VersusRepo] Batalla aceptada: $batallaId');
      return response;
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al aceptar batalla: ${e.message}');
      throw VersusException(
        'No se pudo aceptar la batalla: ${e.message}',
        code: e.code,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 4. OBTENER PREGUNTAS POR RONDA
  // ═══════════════════════════════════════════════════════════════════════

  /// Descarga las preguntas de una ronda específica desde `batalla_preguntas`.
  ///
  /// Mapea el campo JSONB `datos_extra` al modelo [VersusQuestion] de Dart.
  /// El campo `datos_extra` contiene datos específicos del tipo de pregunta,
  /// por ejemplo, para opción múltiple:
  /// ```json
  /// { "options": ["Opción A", "Opción B", "Opción C", "Opción D"] }
  /// ```
  ///
  /// ⚠️ Las preguntas deben haber sido generadas previamente por una
  /// Edge Function al crear o aceptar la batalla (o al iniciar una nueva ronda).
  Future<List<VersusQuestion>> obtenerPreguntasPorRonda({
    required String batallaId,
    required int ronda,
  }) async {
    try {
      final response = await _supabase
              .from('batalla_preguntas')
              .select()
              .eq('batalla_id', batallaId)
              .eq('ronda', ronda)
              .order('indice', ascending: true)
          as List<dynamic>;

      return response.map((row) {
        final datosExtra = row['datos_extra'] as Map<String, dynamic>? ?? {};

        // Mapeo del JSONB `datos_extra` según el tipo de pregunta:
        // - 'multiple_choice': { "options": [...] }
        // - 'true_false': {} (sin datos extra, la respuesta es "true"/"false")
        // - 'fill_in_blank': { "segmented_text": [...], "correct_blanks": [...] }
        // - 'drag_drop': { "pairs": [{ "item": "...", "group": "..." }] }
        final options = (datosExtra['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Encontrar el índice de la respuesta correcta dentro de las opciones
        final correctAnswer = row['respuesta_correcta'] as String;
        int correctIndex = options.indexOf(correctAnswer);
        if (correctIndex == -1 && options.isNotEmpty) correctIndex = 0;

        return VersusQuestion(
          id: row['id'].toString(),
          questionText: row['pregunta_texto'] as String,
          options: options,
          correctOptionIndex: correctIndex,
          authorName: datosExtra['author_name'] as String?,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al obtener preguntas: ${e.message}');
      throw VersusException(
        'No se pudieron cargar las preguntas de la ronda $ronda: ${e.message}',
        code: e.code,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 5. GUARDAR RESPUESTA DEL USUARIO
  // ═══════════════════════════════════════════════════════════════════════

  /// Inserta la respuesta de un jugador en `batalla_respuestas`.
  ///
  /// Parámetros:
  /// - [preguntaId]: ID de la pregunta contestada.
  /// - [batallaId]: ID de la batalla.
  /// - [jugadorId]: ID del usuario que responde.
  /// - [respuestaDada]: Texto de la respuesta elegida.
  /// - [esCorrecta]: true si acertó, false si falló.
  /// - [tiempoRespuestaMs]: Tiempo de respuesta en milisegundos.
  Future<void> guardarRespuesta({
    required String preguntaId,
    required String batallaId,
    required String jugadorId,
    required String respuestaDada,
    required bool esCorrecta,
    required int tiempoRespuestaMs,
  }) async {
    try {
      await _supabase.from('batalla_respuestas').insert({
        'pregunta_id': preguntaId,
        'batalla_id': batallaId,
        'jugador_id': jugadorId,
        'respuesta_dada': respuestaDada,
        'es_correcta': esCorrecta,
        'tiempo_respuesta_ms': tiempoRespuestaMs,
      });

      debugPrint(
        '📝 [VersusRepo] Respuesta guardada — '
        'Pregunta: $preguntaId | '
        'Correcta: $esCorrecta | '
        'Tiempo: ${tiempoRespuestaMs}ms',
      );
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al guardar respuesta: ${e.message}');
      throw VersusException(
        'No se pudo guardar la respuesta: ${e.message}',
        code: e.code,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UTILIDADES AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════

  /// Actualiza el marcador de rondas ganadas de una batalla.
  /// Llamado al finalizar cada ronda para reflejar el resultado.
  Future<void> actualizarMarcador({
    required String batallaId,
    required int rondasRetador,
    required int rondasOponente,
  }) async {
    try {
      final updates = <String, dynamic>{
        'rondas_ganadas_retador': rondasRetador,
        'rondas_ganadas_oponente': rondasOponente,
      };

      // Si alguno ganó 2 rondas, la batalla se completa.
      if (rondasRetador >= 2 || rondasOponente >= 2) {
        updates['estado'] = 'completada';
        // ⚠️ En producción, el reparto de monedas del pozo al ganador
        // debe hacerse en una Edge Function para evitar manipulación:
        // await _supabase.rpc('finalizar_batalla_versus', params: {
        //   'batalla_id': batallaId,
        // });
      }

      await _supabase
          .from('batallas_versus')
          .update(updates)
          .eq('id', batallaId);

      debugPrint('🏆 [VersusRepo] Marcador actualizado: $rondasRetador - $rondasOponente');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al actualizar marcador: ${e.message}');
      throw VersusException(
        'No se pudo actualizar el marcador: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Rechaza o cancela una batalla pendiente.
  Future<void> rechazarBatalla(String batallaId) async {
    try {
      await _supabase
          .from('batallas_versus')
          .update({'estado': 'cancelada'})
          .eq('id', batallaId)
          .eq('estado', 'pendiente');

      debugPrint('🚫 [VersusRepo] Batalla rechazada: $batallaId');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al rechazar batalla: ${e.message}');
      throw VersusException(
        'No se pudo rechazar la batalla: ${e.message}',
        code: e.code,
      );
    }
  }
}
