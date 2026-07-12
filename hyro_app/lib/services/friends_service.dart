import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para operaciones de Supabase relacionadas con amigos y cosméticos.
class FriendsService {
  final _supabase = Supabase.instance.client;

  // ─── Búsqueda de Usuario ──────────────────────────────────────────

  /// Busca un usuario usando el formato "Nombre#Código".
  /// Retorna los datos del perfil o null si no se encuentra.
  Future<Map<String, dynamic>?> searchUserByCode(String query) async {
    // Validar y parsear el formato Nombre#Código
    final hashIndex = query.lastIndexOf('#');
    if (hashIndex == -1 || hashIndex == query.length - 1) {
      throw ArgumentError('Formato inválido. Usa: Nombre#Código');
    }

    final nombre = query.substring(0, hashIndex).trim();
    final codigoStr = query.substring(hashIndex + 1).trim();
    final codigo = int.tryParse(codigoStr);

    if (nombre.isEmpty || codigo == null) {
      throw ArgumentError('Formato inválido. Usa: Nombre#Código');
    }

    debugPrint('🔍 [FriendsService] Buscando: nombre="$nombre", código=$codigo');

    // Usamos ilike para búsqueda case-insensitive del nombre
    final response = await _supabase
        .from('perfiles')
        .select('id, nombre_usuario, codigo_amigo')
        .ilike('nombre_usuario', nombre)
        .eq('codigo_amigo', codigo)
        .maybeSingle();

    debugPrint('🔍 [FriendsService] Resultado: $response');

    return response;
  }

  // ─── Solicitudes de Amistad ───────────────────────────────────────

  /// Envía una solicitud de amistad (insert con estado 'pendiente').
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    // Verificar que no exista ya una relación (en cualquier dirección)
    final existing = await _supabase
        .from('amistades')
        .select('id, estado')
        .or('and(usuario_id.eq.$currentUserId,amigo_id.eq.$targetUserId),and(usuario_id.eq.$targetUserId,amigo_id.eq.$currentUserId)')
        .maybeSingle();

    if (existing != null) {
      final estado = existing['estado'] as String;
      if (estado == 'aceptada') {
        throw Exception('Ya son amigos');
      } else if (estado == 'pendiente') {
        throw Exception('Ya existe una solicitud pendiente');
      }
      // Si fue rechazada, permitimos reenviar actualizando el registro
      await _supabase
          .from('amistades')
          .update({
            'estado': 'pendiente',
            'usuario_id': currentUserId,
            'amigo_id': targetUserId,
            'solicitado_en': DateTime.now().toUtc().toIso8601String(),
            'aceptado_en': null,
          })
          .eq('id', existing['id']);
      return;
    }

    await _supabase.from('amistades').insert({
      'usuario_id': currentUserId,
      'amigo_id': targetUserId,
      'estado': 'pendiente',
    });
  }

  /// Obtiene las solicitudes de amistad pendientes recibidas por el usuario.
  /// Hace join con perfiles para obtener el nombre del solicitante.
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    final response = await _supabase
        .from('amistades')
        .select('id, usuario_id, solicitado_en, perfiles!amistades_usuario_id_fkey(nombre_usuario)')
        .eq('amigo_id', userId)
        .eq('estado', 'pendiente')
        .order('solicitado_en', ascending: false) as List<dynamic>;

    return response.cast<Map<String, dynamic>>();
  }

  /// Acepta una solicitud de amistad.
  Future<void> acceptRequest(String friendshipId) async {
    await _supabase
        .from('amistades')
        .update({
          'estado': 'aceptada',
          'aceptado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', friendshipId);
  }

  /// Rechaza una solicitud de amistad.
  Future<void> rejectRequest(String friendshipId) async {
    await _supabase
        .from('amistades')
        .update({'estado': 'rechazada'})
        .eq('id', friendshipId);
  }

  // ─── Lista de Amigos / Ranking ────────────────────────────────────

  /// Obtiene los IDs de amigos confirmados del usuario.
  Future<List<String>> getConfirmedFriendIds(String userId) async {
    final response = await _supabase
        .from('amistades')
        .select('usuario_id, amigo_id')
        .eq('estado', 'aceptada')
        .or('usuario_id.eq.$userId,amigo_id.eq.$userId') as List<dynamic>;

    final friendIds = <String>{};
    for (final row in response) {
      final uid = row['usuario_id'] as String;
      final aid = row['amigo_id'] as String;
      if (uid == userId) {
        friendIds.add(aid);
      } else {
        friendIds.add(uid);
      }
    }
    return friendIds.toList();
  }

  /// Obtiene el ranking semanal filtrado por amigos confirmados + el usuario actual.
  /// Consulta la vista v_ranking_semanal.
  Future<List<Map<String, dynamic>>> getFriendsRanking(String userId) async {
    // 1. Obtener IDs de amigos confirmados
    final friendIds = await getConfirmedFriendIds(userId);

    // 2. Construir la lista de IDs a consultar (amigos + usuario actual)
    final allIds = [...friendIds, userId];

    if (allIds.isEmpty) return [];

    // 3. Consultar la vista de ranking semanal filtrando por esos IDs
    final response = await _supabase
        .from('v_ranking_semanal')
        .select('usuario_id, nombre_usuario, minutos_semanales, horas_semanales, sombrero, cosmetico, traje')
        .inFilter('usuario_id', allIds)
        .order('minutos_semanales', ascending: false) as List<dynamic>;

    return response.cast<Map<String, dynamic>>();
  }

  /// Verifica si ya existe una relación entre dos usuarios.
  Future<Map<String, dynamic>?> checkExistingRelation(String userId1, String userId2) async {
    final response = await _supabase
        .from('amistades')
        .select('id, estado')
        .or('and(usuario_id.eq.$userId1,amigo_id.eq.$userId2),and(usuario_id.eq.$userId2,amigo_id.eq.$userId1)')
        .maybeSingle();
    return response;
  }

  // ─── Sincronización de Cosméticos ─────────────────────────────────

  /// Upsert de cosméticos de la mascota en Supabase.
  /// Mapeo: sombrero→sombrero, cara(Rive)→cosmetico(BD), cuerpo(Rive)→traje(BD)
  Future<void> syncCosmetics(
    String userId, {
    required int sombrero,
    required int cosmetico,
    required int traje,
  }) async {
    try {
      await _supabase.from('mascota_cosmeticos').upsert({
        'usuario_id': userId,
        'sombrero': sombrero,
        'cosmetico': cosmetico,
        'traje': traje,
      });
    } catch (e) {
      debugPrint('⚠️ Error sincronizando cosméticos: $e');
    }
  }
}
