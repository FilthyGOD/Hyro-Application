import 'package:flutter/material.dart';

/// Modo de Batalla en Versus
enum BattleMode {
  sameSubject, // Misma Materia (Ambos con los apuntes del retador)
  clashSubjects, // Choque de Materias (Cada jugador con sus propios apuntes)
}

extension BattleModeExtension on BattleMode {
  String get title {
    switch (this) {
      case BattleMode.sameSubject:
        return 'Misma Materia';
      case BattleMode.clashSubjects:
        return 'Choque de Materias';
    }
  }

  String get description {
    switch (this) {
      case BattleMode.sameSubject:
        return 'Ambos responden las preguntas con los apuntes del retador.';
      case BattleMode.clashSubjects:
        return 'Tú usas tus apuntes y tu rival usará los suyos en la batalla.';
    }
  }

  /// Convierte el enum al valor que se guarda en la columna `modo_batalla` de Supabase.
  String get toDb {
    switch (this) {
      case BattleMode.sameSubject:
        return 'misma_materia';
      case BattleMode.clashSubjects:
        return 'cruzado';
    }
  }

  /// Crea un BattleMode desde el valor de la columna `modo_batalla` de Supabase.
  static BattleMode fromDb(String value) {
    switch (value) {
      case 'misma_materia':
        return BattleMode.sameSubject;
      case 'cruzado':
        return BattleMode.clashSubjects;
      default:
        return BattleMode.sameSubject;
    }
  }
}

/// Estado de la Partida Versus
enum VersusStatus {
  yourTurn,
  waitingOpponent,
  completed,
}

/// Información del Jugador
class VersusPlayer {
  final String id;
  final String username;
  final String? avatarUrl;
  final int sombreroId;
  final int cosmeticoId;
  final int trajeId;
  final int level;

  const VersusPlayer({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.sombreroId = 0,
    this.cosmeticoId = 0,
    this.trajeId = 0,
    this.level = 1,
  });

  /// Crea un VersusPlayer desde los datos de la tabla `perfiles`
  /// con join a `mascota_cosmeticos`.
  ///
  /// El formato esperado es el que retorna:
  /// ```sql
  /// SELECT id, nombre_usuario, nivel,
  ///        mascota_cosmeticos(sombrero, cara, traje)
  /// FROM perfiles WHERE id = '...'
  /// ```
  factory VersusPlayer.fromProfileData(Map<String, dynamic> json) {
    // Parsear cosméticos — puede venir como List o Map
    final rawCosmeticos = json['mascota_cosmeticos'];
    Map<String, dynamic> cosmeticData = {};
    if (rawCosmeticos is List && rawCosmeticos.isNotEmpty) {
      cosmeticData = Map<String, dynamic>.from(rawCosmeticos.first as Map);
    } else if (rawCosmeticos is Map) {
      cosmeticData = Map<String, dynamic>.from(rawCosmeticos);
    }

    return VersusPlayer(
      id: json['id'] as String,
      username: json['nombre_usuario'] as String? ?? 'Usuario',
      sombreroId: (cosmeticData['sombrero'] as num?)?.toInt() ?? 100,
      cosmeticoId: (cosmeticData['cara'] as num?)?.toInt() ?? 200,
      trajeId: (cosmeticData['traje'] as num?)?.toInt() ?? 300,
      level: (json['nivel'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Modelo de Partida Versus (Duelo)
class VersusMatch {
  final String id;
  final VersusPlayer localPlayer;
  final VersusPlayer opponent;
  final BattleMode battleMode;
  final String subjectName;
  final Color subjectColor;
  final int betCoins;
  final VersusStatus status;
  final int currentRound; // 1, 2 o 3 (3 es desempate)
  final int localRoundsWon;
  final int opponentRoundsWon;
  final DateTime lastActivity;
  // IDs de categoría y tarea para referenciar las preguntas
  final String? categoriaRetadorId;
  final String? categoriaOponenteId;
  final String? tareaRetadorId;
  final String? tareaOponenteId;
  // Estado crudo de la BD para lógica interna
  final String? estadoDb;
  // Indica si el usuario local es el retador (creador del duelo)
  final bool isChallenger;
  final String? ganadorId;
  // UUID del jugador que debe responder en este momento
  final String? turnoActualId;
  final bool premioReclamado;

  const VersusMatch({
    required this.id,
    required this.localPlayer,
    required this.opponent,
    required this.battleMode,
    required this.subjectName,
    this.subjectColor = const Color(0xFF00F2FF),
    this.betCoins = 50,
    required this.status,
    this.currentRound = 1,
    this.localRoundsWon = 0,
    this.opponentRoundsWon = 0,
    required this.lastActivity,
    this.categoriaRetadorId,
    this.categoriaOponenteId,
    this.tareaRetadorId,
    this.tareaOponenteId,
    this.estadoDb,
    required this.isChallenger,
    this.ganadorId,
    this.turnoActualId,
    this.premioReclamado = false,
  });

  /// Crea un VersusMatch a partir de una fila cruda de `batallas_versus`
  /// y los perfiles ya resueltos del retador y el oponente.
  ///
  /// [row]: Fila de la tabla `batallas_versus`.
  /// [currentUserId]: ID del usuario actual para determinar quién es "local".
  /// [localProfile]: Datos del perfil del usuario local (desde `perfiles`).
  /// [opponentProfile]: Datos del perfil del oponente (desde `perfiles`).
  factory VersusMatch.fromSupabase({
    required Map<String, dynamic> row,
    required String currentUserId,
    required VersusPlayer localPlayer,
    required VersusPlayer opponentPlayer,
    String subjectName = 'Sin materia',
    Color subjectColor = const Color(0xFF00F2FF),
  }) {
    final isRetador = row['retador_id'] == currentUserId;
    final estado = row['estado'] as String? ?? 'pendiente';
    final premioReclamado = row['premio_reclamado'] == true;

    // ── Determinar turno usando turno_actual_id como fuente de verdad ──
    final turnoActualId = row['turno_actual_id']?.toString();

    VersusStatus status;
    if (estado == 'completada' || estado == 'cancelada') {
      status = VersusStatus.completed;
    } else if (estado == 'pendiente') {
      status = isRetador ? VersusStatus.waitingOpponent : VersusStatus.yourTurn;
    } else {
      // Estado 'activa': turno_actual_id dicta de quién es el turno
      if (turnoActualId == currentUserId) {
        status = VersusStatus.yourTurn;
      } else if (turnoActualId != null) {
        status = VersusStatus.waitingOpponent;
      } else {
        // turno_actual_id == null → ambos terminaron, esperando evaluación
        status = VersusStatus.waitingOpponent;
      }
    }

    final rRetador = (row['rondas_ganadas_retador'] as num?)?.toInt() ?? 0;
    final rOponente = (row['rondas_ganadas_oponente'] as num?)?.toInt() ?? 0;

    // Leer ronda_actual directamente de la BD si existe
    final rondaActualDb = (row['ronda_actual'] as num?)?.toInt() ?? 1;

    return VersusMatch(
      id: row['id'].toString(),
      localPlayer: localPlayer,
      opponent: opponentPlayer,
      battleMode: BattleModeExtension.fromDb(row['modo_batalla'] as String? ?? 'misma_materia'),
      subjectName: subjectName,
      subjectColor: subjectColor,
      betCoins: (row['apuesta_monedas'] as num?)?.toInt() ?? 50,
      status: status,
      currentRound: rondaActualDb,
      localRoundsWon: isRetador ? rRetador : rOponente,
      opponentRoundsWon: isRetador ? rOponente : rRetador,
      lastActivity: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      categoriaRetadorId: row['categoria_retador_id']?.toString(),
      categoriaOponenteId: row['categoria_oponente_id']?.toString(),
      tareaRetadorId: row['tarea_retador_id']?.toString(),
      tareaOponenteId: row['tarea_oponente_id']?.toString(),
      estadoDb: estado,
      isChallenger: isRetador,
      ganadorId: row['ganador_id']?.toString(),
      turnoActualId: turnoActualId,
      premioReclamado: premioReclamado,
    );
  }
}

/// Modelo de Pregunta para el Combate
class VersusQuestion {
  final String id;
  final String questionType; // 'multiple_choice', 'true_false', 'drag_drop'
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? correctAnswer; // for drag_drop or true_false
  final String? authorName; // 'Tus apuntes' o 'Apuntes de [Oponente]'
  final Map<String, dynamic> extraData; // Any extra data

  const VersusQuestion({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.correctAnswer,
    this.authorName,
    this.extraData = const {},
  });
}
