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
    required String oponenteId,
    required String modoBatalla,
    required String tareaRetadorId,
    required String? categoriaRetadorId,
    required int apuestaMonedas,
  }) async {
    try {
      // Validación básica en el cliente (UX rápida antes de llamar al RPC)
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

      // ── RPC: Crear batalla (cobra monedas + crea registro atómicamente) ──
      final response = await _supabase.rpc('crear_batalla_versus', params: {
        'p_oponente_id': oponenteId,
        'p_modo_batalla': modoBatalla,
        'p_categoria_retador_id': categoriaRetadorId,
        'p_apuesta': apuestaMonedas,
        'p_tarea_retador_id': tareaRetadorId,
      });

      // La RPC retorna el ID de la batalla creada o el registro completo
      final batallaId = response is Map
          ? response['id']?.toString() ?? response.toString()
          : response.toString();

      // Generar y guardar las preguntas en la tabla batalla_preguntas
      await _generarPreguntasParaBatalla(
        batallaId: batallaId,
        tareaRetadorId: tareaRetadorId,
      );

      debugPrint('⚔️ [VersusRepo] Batalla creada via RPC con preguntas: $batallaId');
      return response is Map<String, dynamic>
          ? response
          : {'id': batallaId};
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error RPC al crear batalla: ${e.message}');
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

  /// Genera 16 preguntas para la batalla basadas en las flashcards y notas de la tarea y las guarda en batalla_preguntas.
  Future<void> _generarPreguntasParaBatalla({
    required String batallaId,
    required String tareaRetadorId,
  }) async {
    try {
      final cardsResponse = await _supabase
          .from('tarea_cards')
          .select()
          .eq('tarea_id', tareaRetadorId) as List<dynamic>;

      final notasResponse = await _supabase
          .from('tarea_notas')
          .select()
          .eq('tarea_id', tareaRetadorId) as List<dynamic>;

      final questionsToInsert = <Map<String, dynamic>>[];
      final totalQuestions = 16; // 5 en ronda 1, 5 en ronda 2, 6 en ronda 3 (desempate)

      if (cardsResponse.isEmpty && notasResponse.isEmpty) {
        // Fallback: Si no hay flashcards ni notas, generar preguntas genéricas de estudio
        for (int i = 0; i < totalQuestions; i++) {
          final ronda = i < 5 ? 1 : (i < 10 ? 2 : 3);
          final indice = i < 5 ? i : (i < 10 ? i - 5 : i - 10);
          final options = ['Opción A', 'Opción B', 'Opción C', 'Opción D'];
          questionsToInsert.add({
            'batalla_id': batallaId,
            'ronda': ronda,
            'indice': indice,
            'tipo_pregunta': 'multiple_choice',
            'pregunta_texto': 'Pregunta de estudio #${i + 1} sobre tu tarea',
            'respuesta_correcta': 'Opción A',
            'datos_extra': {
              'options': options..shuffle(),
            },
          });
        }
      } else {
        // Combinar generación de flashcards (multiple_choice, true_false) y notas (drag_drop)
        for (int i = 0; i < totalQuestions; i++) {
          final ronda = i < 5 ? 1 : (i < 10 ? 2 : 3);
          final indice = i < 5 ? i : (i < 10 ? i - 5 : i - 10);
          
          final availableTypes = <String>[];
          if (cardsResponse.isNotEmpty) {
            availableTypes.add('multiple_choice');
            availableTypes.add('true_false');
          }
          if (notasResponse.isNotEmpty) {
            availableTypes.add('drag_drop');
          }
          
          availableTypes.shuffle();
          final type = availableTypes.first;
          
          if (type == 'multiple_choice' || type == 'true_false') {
            final card = cardsResponse[(i) % cardsResponse.length] as Map<String, dynamic>;
            final askFront = (i % 2 == 0);
            final questionText = askFront ? (card['frente'] as String) : (card['reverso'] as String);
            final correctAnswer = askFront ? (card['reverso'] as String) : (card['frente'] as String);
            
            if (type == 'multiple_choice') {
              final distractors = <String>[];
              for (final otherCard in cardsResponse) {
                final val = askFront ? (otherCard['reverso'] as String) : (otherCard['frente'] as String);
                if (val != correctAnswer && !distractors.contains(val)) distractors.add(val);
                if (distractors.length >= 3) break;
              }
              final padList = ['No aplica', 'Ninguna de las anteriores', 'Opción incorrecta', 'No es correcto'];
              int padIndex = 0;
              while (distractors.length < 3) {
                final padVal = padList[padIndex % padList.length];
                if (!distractors.contains(padVal) && padVal != correctAnswer) distractors.add(padVal);
                padIndex++;
              }
              final options = [correctAnswer, ...distractors]..shuffle();
              questionsToInsert.add({
                'batalla_id': batallaId, 'ronda': ronda, 'indice': indice,
                'tipo_pregunta': 'multiple_choice', 'pregunta_texto': questionText,
                'respuesta_correcta': correctAnswer, 'datos_extra': {'options': options},
              });
            } else { // true_false
              final isTrue = (i % 3 != 0); // 2/3 chance of being true
              String statement = correctAnswer;
              if (!isTrue && cardsResponse.length > 1) {
                final otherCard = cardsResponse[(i + 1) % cardsResponse.length] as Map<String, dynamic>;
                statement = askFront ? (otherCard['reverso'] as String) : (otherCard['frente'] as String);
              }
              final options = ['Verdadero', 'Falso'];
              final answer = isTrue ? 'Verdadero' : 'Falso';
              questionsToInsert.add({
                'batalla_id': batallaId, 'ronda': ronda, 'indice': indice,
                'tipo_pregunta': 'true_false', 'pregunta_texto': '¿$questionText es "$statement"?',
                'respuesta_correcta': answer, 'datos_extra': {'options': options},
              });
            }
          } else { // drag_drop
            final nota = notasResponse[(i) % notasResponse.length] as Map<String, dynamic>;
            final originalText = nota['contenido'] as String;
            final words = originalText.split(RegExp(r'\s+'));
            var candidates = words.where((w) => w.length > 3 && w.contains(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]'))).toSet().toList();
            if (candidates.isEmpty) {
              candidates = words.where((w) => w.length > 1).toSet().toList();
            }
            if (candidates.isEmpty) {
              candidates = words.toSet().toList();
            }
            candidates.shuffle();
            
            final count = candidates.length > 3 ? 3 : candidates.length;
            final selectedForBlank = candidates.take(count).toList();
            
            final toReplace = List<String>.from(selectedForBlank);
            final orderedBlanks = <String>[];
            final newWords = <String>[];
            
            for (var w in words) {
              if (toReplace.contains(w)) {
                orderedBlanks.add(w);
                newWords.add('{{BLANK}}');
                toReplace.remove(w);
              } else {
                newWords.add(w);
              }
            }
            
            final text = newWords.join(' ');
            
            final distractorPool = candidates.where((w) => !selectedForBlank.contains(w)).toList()..shuffle();
            final availableWords = List<String>.from(orderedBlanks);
            availableWords.addAll(distractorPool.take(2));
            availableWords.shuffle();
            
            questionsToInsert.add({
              'batalla_id': batallaId, 'ronda': ronda, 'indice': indice,
              'tipo_pregunta': 'drag_drop', 'pregunta_texto': text,
              'respuesta_correcta': orderedBlanks.join(', '), 
              'datos_extra': {'blanks': orderedBlanks, 'available_words': availableWords},
            });
          }
        }
      }

      await _supabase.from('batalla_preguntas').insert(questionsToInsert);
      debugPrint('⚡ [VersusRepo] $totalQuestions preguntas generadas y guardadas para la batalla: $batallaId');
    } catch (e) {
      debugPrint('❌ [VersusRepo] Error generando preguntas para batalla: $e');
      rethrow;
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
            final mostrar = esRetador ? (row['mostrar_retador'] ?? true) == true : (row['mostrar_oponente'] ?? true) == true;
            
            final estadoValido =
                row['estado'] == 'pendiente' || 
                row['estado'] == 'activa' || 
                row['estado'] == 'completada' ||
                row['estado'] == 'reclamada';
                
            return (esRetador || esOponente) && estadoValido && mostrar;
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
              .inFilter('estado', ['pendiente', 'activa', 'completada', 'reclamada'])
              .order('created_at', ascending: false)
          as List<dynamic>;

      final filtered = response.cast<Map<String, dynamic>>().where((row) {
        final esRetador = row['retador_id'] == userId;
        final mostrar = esRetador ? (row['mostrar_retador'] ?? true) == true : (row['mostrar_oponente'] ?? true) == true;
        return mostrar;
      }).toList();

      return filtered;
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
    String? tareaOponenteId,
    String? categoriaOponenteId,
  }) async {
    try {
      // ── RPC: Aceptar reto (cobra monedas, activa batalla, asigna turno) ──
      final response = await _supabase.rpc('aceptar_reto_versus', params: {
        'p_batalla_id': batallaId,
        'p_categoria_oponente_id': categoriaOponenteId,
        'p_tarea_oponente_id': tareaOponenteId,
      });

      debugPrint('✅ [VersusRepo] Batalla aceptada via RPC: $batallaId');
      return response is Map<String, dynamic>
          ? response
          : {'id': batallaId};
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error RPC al aceptar batalla: ${e.message}');
      throw VersusException(
        'No se pudo aceptar la batalla: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Reclama el premio llamando a la RPC
  Future<void> reclamarPremio(String batallaId) async {
    try {
      await _supabase.rpc('reclamar_premio_versus', params: {
        'p_batalla_id': batallaId,
      });
      debugPrint('💰 [VersusRepo] Premio reclamado para la batalla: $batallaId');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al reclamar premio: ${e.message}');
      throw VersusException('No se pudo reclamar el premio: ${e.message}', code: e.code);
    }
  }

  Future<void> archivarBatalla(String batallaId, bool isChallenger) async {
    try {
      final updates = <String, dynamic>{};
      
      if (isChallenger) {
        updates['mostrar_retador'] = false;
      } else {
        updates['mostrar_oponente'] = false;
      }

      await _supabase
          .from('batallas_versus')
          .update(updates)
          .eq('id', batallaId);
      debugPrint('✅ [VersusRepo] Batalla archivada/ocultada: $batallaId');
    } catch (e) {
      debugPrint('❌ [VersusRepo] Error al archivar batalla: $e');
    }
  }

  Future<Map<String, dynamic>> calcularEstadoBatalla({
    required String batallaId,
    required String retadorId,
    required String oponenteId,
    required String estadoDb,
  }) async {
    // Si la batalla está pendiente, no ha sido aceptada, por lo que no realizamos cálculos.
    if (estadoDb == 'pendiente') {
      return {
        'ronda': 1,
        'retador_completado_ronda': false,
        'oponente_completado_ronda': false,
        'rondas_ganadas_retador': 0,
        'rondas_ganadas_oponente': 0,
        'ganador_id': null,
        'estado_calculado': 'pendiente',
      };
    }

    // Si la batalla ya está completada, reclamada o cancelada, no recalculamos
    if (estadoDb == 'completada' || estadoDb == 'reclamada' || estadoDb == 'cancelada') {
      return {
        'ronda': 1,
        'retador_completado_ronda': true,
        'oponente_completado_ronda': true,
        'rondas_ganadas_retador': 0,
        'rondas_ganadas_oponente': 0,
        'ganador_id': null,
        'estado_calculado': estadoDb,
      };
    }

    try {
      // 1. Obtener todas las preguntas de la batalla
      final preguntasRes = await _supabase
          .from('batalla_preguntas')
          .select('id, ronda')
          .eq('batalla_id', batallaId);
      
      final preguntas = preguntasRes as List<dynamic>? ?? [];

      // Agrupar preguntas por ronda
      final preguntasPorRonda = <int, List<String>>{1: [], 2: [], 3: []};
      for (final p in preguntas) {
        final r = (p['ronda'] as num?)?.toInt() ?? 1;
        final id = p['id']?.toString();
        if (id != null) {
          preguntasPorRonda[r] = (preguntasPorRonda[r] ?? [])..add(id);
        }
      }

      // 2. Obtener todas las respuestas de ambos jugadores
      final respuestasRes = await _supabase
          .from('batalla_respuestas')
          .select('pregunta_id, jugador_id, es_correcta, tiempo_respuesta_ms')
          .eq('batalla_id', batallaId);
      
      final respuestas = respuestasRes as List<dynamic>? ?? [];

      final respuestasRetador = respuestas.where((r) => r['jugador_id'] == retadorId).toList();
      final respuestasOponente = respuestas.where((r) => r['jugador_id'] == oponenteId).toList();

      // Comprobar completitud por ronda
      bool retadorCompletado(int ronda) {
        final qIds = preguntasPorRonda[ronda] ?? [];
        if (qIds.isEmpty) return false;
        return qIds.every((qId) => respuestasRetador.any((r) => r['pregunta_id'] == qId));
      }

      bool oponenteCompletado(int ronda) {
        final qIds = preguntasPorRonda[ronda] ?? [];
        if (qIds.isEmpty) return false;
        return qIds.every((qId) => respuestasOponente.any((r) => r['pregunta_id'] == qId));
      }

      // Calcular ganador de una ronda
      String? determinarGanadorRonda(int ronda) {
        final qIds = preguntasPorRonda[ronda] ?? [];
        if (qIds.isEmpty) return null;

        final respR = respuestasRetador.where((r) => qIds.contains(r['pregunta_id'])).toList();
        final respO = respuestasOponente.where((r) => qIds.contains(r['pregunta_id'])).toList();

        if (respR.length < qIds.length || respO.length < qIds.length) return null;

        final aciertosR = respR.where((r) => r['es_correcta'] == true).length;
        final aciertosO = respO.where((r) => r['es_correcta'] == true).length;

        if (aciertosR > aciertosO) {
          return 'retador';
        } else if (aciertosO > aciertosR) {
          return 'oponente';
        } else {
          // Desempate por tiempo total de respuesta
          final tiempoR = respR.fold<int>(0, (sum, r) => sum + ((r['tiempo_respuesta_ms'] as num?)?.toInt() ?? 0));
          final tiempoO = respO.fold<int>(0, (sum, r) => sum + ((r['tiempo_respuesta_ms'] as num?)?.toInt() ?? 0));
          if (tiempoR < tiempoO) return 'retador';
          return 'oponente';
        }
      }

      // Calcular estado ronda por ronda
      int rondaActual = 1;
      int rondasGanadasRetador = 0;
      int rondasGanadasOponente = 0;
      String? ganadorId;
      String estadoFinal = 'activa';

      // Ronda 1
      final r1Retador = retadorCompletado(1);
      final r1Oponente = oponenteCompletado(1);

      if (r1Retador && r1Oponente) {
        final w1 = determinarGanadorRonda(1);
        if (w1 == 'retador') {
          rondasGanadasRetador++;
        } else if (w1 == 'oponente') {
          rondasGanadasOponente++;
        }

        // Pasar a Ronda 2
        rondaActual = 2;
        final r2Retador = retadorCompletado(2);
        final r2Oponente = oponenteCompletado(2);

        if (r2Retador && r2Oponente) {
          final w2 = determinarGanadorRonda(2);
          if (w2 == 'retador') {
            rondasGanadasRetador++;
          } else if (w2 == 'oponente') {
            rondasGanadasOponente++;
          }

          // Comprobar si hay ganador absoluto (2-0 o 0-2)
          if (rondasGanadasRetador >= 2) {
            ganadorId = retadorId;
            estadoFinal = 'completada';
          } else if (rondasGanadasOponente >= 2) {
            ganadorId = oponenteId;
            estadoFinal = 'completada';
          } else {
            // Empate (1-1), pasar a Ronda 3 (Desempate)
            rondaActual = 3;
            final r3Retador = retadorCompletado(3);
            final r3Oponente = oponenteCompletado(3);

            if (r3Retador && r3Oponente) {
              final w3 = determinarGanadorRonda(3);
              if (w3 == 'retador') {
                rondasGanadasRetador++;
                ganadorId = retadorId;
              } else {
                rondasGanadasOponente++;
                ganadorId = oponenteId;
              }
              estadoFinal = 'completada';
            }
          }
        }
      }

      // Si ha cambiado el estado a completada, actualizarlo en Supabase
      if (estadoFinal == 'completada' && estadoDb != 'completada') {
        await _supabase
            .from('batallas_versus')
            .update({
              'estado': 'completada',
              'ganador_id': ganadorId,
              'rondas_ganadas_retador': rondasGanadasRetador,
              'rondas_ganadas_oponente': rondasGanadasOponente,
              'finalizado_en': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', batallaId);
      }

      return {
        'ronda': rondaActual,
        'retador_completado_ronda': r1Retador ? retadorCompletado(rondaActual) : false,
        'oponente_completado_ronda': r1Oponente ? oponenteCompletado(rondaActual) : false,
        'rondas_ganadas_retador': rondasGanadasRetador,
        'rondas_ganadas_oponente': rondasGanadasOponente,
        'ganador_id': ganadorId,
        'estado_calculado': estadoFinal,
      };
    } catch (e) {
      debugPrint('❌ [VersusRepo] Error al calcular estado de batalla: $e');
      return {
        'ronda': 1,
        'retador_completado_ronda': false,
        'oponente_completado_ronda': false,
        'rondas_ganadas_retador': 0,
        'rondas_ganadas_oponente': 0,
        'ganador_id': null,
        'estado_calculado': estadoDb,
      };
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // FINALIZAR TURNO (Cambio de turno entre jugadores)
  // ═════════════════════════════════════════════════════════════════════

  /// Finaliza el turno del jugador actual y actualiza `turno_actual_id`
  /// en `batallas_versus`.
  ///
  /// Lógica:
  /// - Si el jugador actual es el **retador** (primer turno de la ronda):
  ///   se pasa el turno al oponente (`turno_actual_id = oponenteId`).
  /// - Si el jugador actual es el **oponente** (segundo turno de la ronda):
  ///   se pone `turno_actual_id = null`, indicando que ambos jugadores
  ///   terminaron la ronda y está lista para evaluación.
  ///
  /// Parámetros:
  /// - [batallaId]: ID de la batalla.
  /// - [jugadorActualId]: ID del jugador que acaba de terminar.
  /// - [oponenteId]: ID del otro jugador.
  /// - [isChallenger]: true si el jugador actual es el retador.
  /// - [rondaActual]: Número de la ronda actual (1, 2 o 3).
  Future<void> finalizarTurno({
    required String batallaId,
    required String jugadorActualId,
    required String oponenteId,
    required bool isChallenger,
    required int rondaActual,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isChallenger) {
        // Retador terminó → pasar turno al oponente
        updates['turno_actual_id'] = oponenteId;
        debugPrint(
          '🔄 [VersusRepo] Turno pasado al oponente $oponenteId '
          '(Ronda $rondaActual, Batalla $batallaId)',
        );
      } else {
        // Oponente terminó → ambos completaron la ronda
        updates['turno_actual_id'] = null;
        debugPrint(
          '🔄 [VersusRepo] Ambos jugadores completaron la ronda $rondaActual '
          '(Batalla $batallaId). Esperando evaluación.',
        );
      }

      await _supabase
          .from('batallas_versus')
          .update(updates)
          .eq('id', batallaId);

      // ────────────────────────────────────────────────────────────────────────
      // EVALUACIÓN DE RONDA — Llamada a Supabase RPC
      // ────────────────────────────────────────────────────────────────────────
      if (!isChallenger) {
        await _supabase.rpc('evaluar_ronda_versus', params: {
          'p_batalla_id': batallaId,
        });
        debugPrint('✅ [VersusRepo] Ronda evaluada via RPC para batalla: $batallaId');
      }
      // ────────────────────────────────────────────────────────────────────────

    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al finalizar turno: ${e.message}');
      throw VersusException(
        'No se pudo finalizar el turno: ${e.message}',
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

        final tipoPregunta = row['tipo_pregunta'] as String? ?? 'multiple_choice';

        return VersusQuestion(
          id: row['id'].toString(),
          questionType: tipoPregunta,
          questionText: row['pregunta_texto'] as String,
          options: options,
          correctOptionIndex: correctIndex,
          correctAnswer: correctAnswer,
          authorName: datosExtra['author_name'] as String?,
          extraData: datosExtra,
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

  /// Rechaza o cancela una batalla pendiente y devuelve las monedas al retador.
  Future<void> rechazarBatalla(String batallaId) async {
    try {
      // 1. Obtener la batalla para saber quién es el retador y la apuesta
      final battleRes = await _supabase
          .from('batallas_versus')
          .select('retador_id, apuesta_monedas, estado')
          .eq('id', batallaId)
          .maybeSingle();

      if (battleRes != null && battleRes['estado'] == 'pendiente') {
        final retadorId = battleRes['retador_id'] as String;
        final bet = (battleRes['apuesta_monedas'] as num?)?.toInt() ?? 50;

        // 2. Actualizar el estado de la batalla a cancelada
        await _supabase
            .from('batallas_versus')
            .update({'estado': 'cancelada'})
            .eq('id', batallaId);

        // 3. Regresar las monedas al retador
        final retRes = await _supabase
            .from('perfiles')
            .select('monedas')
            .eq('id', retadorId)
            .maybeSingle();
        if (retRes != null) {
          final coins = (retRes['monedas'] as num?)?.toInt() ?? 0;
          await _supabase
              .from('perfiles')
              .update({'monedas': coins + bet})
              .eq('id', retadorId);
          debugPrint('💸 [VersusRepo] Monedas devueltas al retador ($bet) tras rechazo.');
        }
      }

      debugPrint('🚫 [VersusRepo] Batalla rechazada: $batallaId');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al rechazar batalla: ${e.message}');
      throw VersusException(
        'No se pudo rechazar la batalla: ${e.message}',
        code: e.code,
      );
    }
  }



  /// Realiza un update dummy para gatillar el stream de Realtime de Supabase
  Future<void> touchBatalla(String batallaId) async {
    try {
      await _supabase
          .from('batallas_versus')
          .update({'estado': 'activa'})
          .eq('id', batallaId);
      debugPrint('⚡ [VersusRepo] Batalla tocada para refresco Realtime: $batallaId');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VersusRepo] Error al tocar batalla: ${e.message}');
    }
  }
}
