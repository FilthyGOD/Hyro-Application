// Modelos de datos para el sistema de amigos.

/// Entrada del ranking semanal — incluye datos de cosméticos para renderizar la mascota.
class RankingEntry {
  final String usuarioId;
  final String nombreUsuario;
  final int minutosSemanales;
  final double horasSemanales;
  final int sombrero;
  final int cosmetico; // 'cosmetico' en BD → 'cara' en Rive
  final int traje;     // 'traje' en BD → 'cuerpo' en Rive
  final bool isCurrentUser;

  const RankingEntry({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.minutosSemanales,
    required this.horasSemanales,
    required this.sombrero,
    required this.cosmetico,
    required this.traje,
    this.isCurrentUser = false,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final uid = json['usuario_id'] as String;
    return RankingEntry(
      usuarioId: uid,
      nombreUsuario: json['nombre_usuario'] as String? ?? 'Usuario',
      minutosSemanales: (json['minutos_semanales'] as num?)?.toInt() ?? 0,
      horasSemanales: (json['horas_semanales'] as num?)?.toDouble() ?? 0.0,
      sombrero: (json['sombrero'] as num?)?.toInt() ?? 100,
      cosmetico: (json['cosmetico'] as num?)?.toInt() ?? 200,
      traje: (json['traje'] as num?)?.toInt() ?? 300,
      isCurrentUser: uid == currentUserId,
    );
  }
}

/// Solicitud de amistad pendiente recibida.
class FriendRequest {
  final String id; // ID de la fila en tabla amistades
  final String usuarioId; // Quién envió la solicitud
  final String nombreUsuario;
  final DateTime solicitadoEn;

  const FriendRequest({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.solicitadoEn,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    // La consulta hace join con perfiles, así que traemos los datos del solicitante
    final perfilData = json['perfiles'] as Map<String, dynamic>?;
    return FriendRequest(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      nombreUsuario: perfilData?['nombre_usuario'] as String? ?? 'Usuario',
      solicitadoEn: DateTime.parse(json['solicitado_en'] as String),
    );
  }
}

/// Resultado de búsqueda de un usuario por código de amigo.
class SearchResult {
  final String usuarioId;
  final String nombreUsuario;
  final int codigoAmigo;
  final bool alreadyFriends;
  final bool requestPending;

  const SearchResult({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.codigoAmigo,
    this.alreadyFriends = false,
    this.requestPending = false,
  });

  SearchResult copyWith({
    bool? alreadyFriends,
    bool? requestPending,
  }) {
    return SearchResult(
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      codigoAmigo: codigoAmigo,
      alreadyFriends: alreadyFriends ?? this.alreadyFriends,
      requestPending: requestPending ?? this.requestPending,
    );
  }
}

/// Resultado de búsqueda por nombre (pantalla de búsqueda estilo Duolingo).
class UserSearchResult {
  final String id;
  final String nombreUsuario;
  final int codigoAmigo;

  const UserSearchResult({
    required this.id,
    required this.nombreUsuario,
    required this.codigoAmigo,
  });

  /// Formato completo: NombreUsuario#Código
  String get displayTag => '$nombreUsuario#$codigoAmigo';

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      nombreUsuario: json['nombre_usuario'] as String? ?? 'Usuario',
      codigoAmigo: (json['codigo_amigo'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Perfil completo para la vista previa de un usuario tercero.
class UserProfilePreview {
  final String id;
  final String nombreUsuario;
  final int codigoAmigo;
  final int nivel;
  final int experiencia;
  final int rachaActual;
  final int rachaMaxima;
  final int minutosEnfoqueTotal;
  final int sombrero;
  final int cosmetico;
  final int traje;

  const UserProfilePreview({
    required this.id,
    required this.nombreUsuario,
    required this.codigoAmigo,
    required this.nivel,
    required this.experiencia,
    required this.rachaActual,
    required this.rachaMaxima,
    required this.minutosEnfoqueTotal,
    required this.sombrero,
    required this.cosmetico,
    required this.traje,
  });

  /// Formato completo: NombreUsuario#Código
  String get displayTag => '$nombreUsuario#$codigoAmigo';

  /// Horas totales de enfoque (conversión de minutos a horas).
  double get horasTotales => minutosEnfoqueTotal / 60.0;

  /// XP requerida para el siguiente nivel.
  int get xpForNextLevel => nivel * 100;

  /// Progreso de nivel (0.0 – 1.0).
  double get levelProgress {
    final required = xpForNextLevel;
    if (required <= 0) return 0.0;
    return (experiencia / required).clamp(0.0, 1.0);
  }

  factory UserProfilePreview.fromJson(Map<String, dynamic> json) {
    final rawCosmeticos = json['mascota_cosmeticos'];
    Map<String, dynamic> cosmeticData = {};
    if (rawCosmeticos is List && rawCosmeticos.isNotEmpty) {
      cosmeticData = Map<String, dynamic>.from(rawCosmeticos.first as Map);
    } else if (rawCosmeticos is Map) {
      cosmeticData = Map<String, dynamic>.from(rawCosmeticos);
    }

    return UserProfilePreview(
      id: json['id'] as String,
      nombreUsuario: json['nombre_usuario'] as String? ?? 'Usuario',
      codigoAmigo: (json['codigo_amigo'] as num?)?.toInt() ?? 0,
      nivel: (json['nivel'] as num?)?.toInt() ?? 1,
      experiencia: (json['experiencia'] as num?)?.toInt() ?? 0,
      rachaActual: (json['racha_actual'] as num?)?.toInt() ?? 0,
      rachaMaxima: (json['racha_maxima'] as num?)?.toInt() ?? 0,
      minutosEnfoqueTotal: (json['minutos_enfoque_total'] as num?)?.toInt() ?? 0,
      sombrero: (cosmeticData['sombrero'] as num?)?.toInt() ?? 100,
      cosmetico: (cosmeticData['cara'] as num?)?.toInt() ?? 200,
      traje: (cosmeticData['traje'] as num?)?.toInt() ?? 300,
    );
  }
}

/// Estado de la relación entre el usuario actual y un perfil visitado.
enum RelationshipStatus {
  /// No hay relación previa
  none,
  /// El usuario actual envió solicitud
  requestSent,
  /// El usuario visitado envió solicitud al actual
  requestReceived,
  /// Ya son amigos confirmados
  friends,
  /// El usuario está bloqueado
  blocked,
}

/// Información completa de la relación incluyendo el ID de la fila de amistad.
class RelationshipInfo {
  final RelationshipStatus status;
  final String? friendshipId; // ID de la fila en tabla amistades (para update/delete)
  final String? blockerId; // ID del usuario que bloqueó

  const RelationshipInfo({
    required this.status,
    this.friendshipId,
    this.blockerId,
  });

  const RelationshipInfo.none()
      : status = RelationshipStatus.none,
        friendshipId = null,
        blockerId = null;
}

/// Representa un regalo recibido pendiente de confirmación.
class GiftWithDetails {
  final String id;
  final String remitenteId;
  final String remitenteNombre;
  final int objetoId;
  final String objetoNombre;
  final DateTime enviadoEn;

  const GiftWithDetails({
    required this.id,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.objetoId,
    required this.objetoNombre,
    required this.enviadoEn,
  });
}

