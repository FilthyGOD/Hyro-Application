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
