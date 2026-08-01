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
  // IDs de categoría para referenciar las preguntas
  final String? categoriaRetadorId;
  final String? categoriaOponenteId;
  // Estado crudo de la BD para lógica interna
  final String? estadoDb;
  // Indica si el usuario local es el retador (creador del duelo)
  final bool isChallenger;

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
    this.estadoDb,
    required this.isChallenger,
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

    VersusStatus status;
    if (estado == 'completada' || estado == 'cancelada') {
      status = VersusStatus.completed;
    } else {
      // Para 'pendiente' o 'activa':
      // Si eres el retador (creador), estás esperando (que acepten o que jueguen).
      // Si eres el oponente, es tu turno (para aceptar o para jugar).
      status = isRetador ? VersusStatus.waitingOpponent : VersusStatus.yourTurn;
    }

    final rondasRetador = (row['rondas_ganadas_retador'] as num?)?.toInt() ?? 0;
    final rondasOponente = (row['rondas_ganadas_oponente'] as num?)?.toInt() ?? 0;

    // Calcular la ronda actual basándose en rondas completadas
    final rondasJugadas = rondasRetador + rondasOponente;
    int currentRound = rondasJugadas + 1;
    if (currentRound > 3) currentRound = 3;

    return VersusMatch(
      id: row['id'].toString(),
      localPlayer: localPlayer,
      opponent: opponentPlayer,
      battleMode: BattleModeExtension.fromDb(row['modo_batalla'] as String? ?? 'misma_materia'),
      subjectName: subjectName,
      subjectColor: subjectColor,
      betCoins: (row['apuesta_monedas'] as num?)?.toInt() ?? 50,
      status: status,
      currentRound: currentRound,
      localRoundsWon: isRetador ? rondasRetador : rondasOponente,
      opponentRoundsWon: isRetador ? rondasOponente : rondasRetador,
      lastActivity: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      categoriaRetadorId: row['categoria_retador_id']?.toString(),
      categoriaOponenteId: row['categoria_oponente_id']?.toString(),
      estadoDb: estado,
      isChallenger: isRetador,
    );
  }
}

/// Modelo de Pregunta para el Combate
class VersusQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? authorName; // 'Tus apuntes' o 'Apuntes de [Oponente]'

  const VersusQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.authorName,
  });
}
