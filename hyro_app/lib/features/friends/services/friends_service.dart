import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friends_models.dart';


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

    debugPrint(
      '🔍 [FriendsService] Buscando: nombre="$nombre", código=$codigo',
    );

    // Usamos ilike para búsqueda case-insensitive del nombre
    final response =
        await _supabase
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
  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // Verificar que no exista ya una relación (en cualquier dirección)
    final existing =
        await _supabase
            .from('amistades')
            .select('id, estado')
            .or(
              'and(usuario_id.eq.$currentUserId,amigo_id.eq.$targetUserId),and(usuario_id.eq.$targetUserId,amigo_id.eq.$currentUserId)',
            )
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
    final response =
        await _supabase
                .from('amistades')
                .select(
                  'id, usuario_id, solicitado_en, perfiles!amistades_usuario_id_fkey(nombre_usuario)',
                )
                .eq('amigo_id', userId)
                .eq('estado', 'pendiente')
                .order('solicitado_en', ascending: false)
            as List<dynamic>;

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
    final response =
        await _supabase
                .from('amistades')
                .select('usuario_id, amigo_id')
                .eq('estado', 'aceptada')
                .or('usuario_id.eq.$userId,amigo_id.eq.$userId')
            as List<dynamic>;

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
    final response =
        await _supabase
                .from('v_ranking_semanal')
                .select(
                  'usuario_id, nombre_usuario, minutos_semanales, horas_semanales, sombrero, cosmetico, traje',
                )
                .inFilter('usuario_id', allIds)
                .order('minutos_semanales', ascending: false)
            as List<dynamic>;

    return response.cast<Map<String, dynamic>>();
  }

  /// Verifica si ya existe una relación entre dos usuarios.
  Future<Map<String, dynamic>?> checkExistingRelation(
    String userId1,
    String userId2,
  ) async {
    final response =
        await _supabase
            .from('amistades')
            .select('id, estado')
            .or(
              'and(usuario_id.eq.$userId1,amigo_id.eq.$userId2),and(usuario_id.eq.$userId2,amigo_id.eq.$userId1)',
            )
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
        'cara': cosmetico,
        'traje': traje,
      });
    } catch (e) {
      debugPrint('⚠️ Error sincronizando cosméticos: $e');
    }
  }

  /// Obtiene los IDs de usuarios que han bloqueado al usuario actual.
  Future<Set<String>> getUsersWhoBlockedMe(String userId) async {
    final response = await _supabase
        .from('bloqueos')
        .select('bloqueador_id')
        .eq('bloqueado_id', userId)
        as List<dynamic>;

    return response.map((row) => row['bloqueador_id'] as String).toSet();
  }

  // ─── Búsqueda por Nombre (estilo Duolingo) ────────────────────────

  /// Busca usuarios cuyo nombre_usuario coincida parcialmente con [query]
  /// usando ilike. Excluye al usuario actual y usuarios que bloquearon al actual.
  Future<List<Map<String, dynamic>>> searchUsersByName(
    String query,
    String currentUserId,
  ) async {
    // 1. Obtener IDs de usuarios que bloquearon al actual
    final blockedMeIds = await getUsersWhoBlockedMe(currentUserId);

    // 2. Buscar usuarios con ilike
    final response =
        await _supabase
                .from('perfiles')
                .select('id, nombre_usuario, codigo_amigo')
                .ilike('nombre_usuario', '%$query%')
                .neq('id', currentUserId)
                .limit(20)
            as List<dynamic>;

    // 3. Filtrar en el cliente los que nos bloquearon
    final results =
        response
            .cast<Map<String, dynamic>>()
            .where((user) => !blockedMeIds.contains(user['id'] as String))
            .toList();

    return results;
  }

  /// Obtiene los IDs de usuarios bloqueados (en ambas direcciones).
  Future<Set<String>> getBlockedUserIds(String userId) async {
    final response =
        await _supabase
                .from('bloqueos')
                .select('bloqueador_id, bloqueado_id')
                .or('bloqueador_id.eq.$userId,bloqueado_id.eq.$userId')
            as List<dynamic>;

    final blockedIds = <String>{};
    for (final row in response) {
      final bloqueadorId = row['bloqueador_id'] as String;
      final bloqueadoId = row['bloqueado_id'] as String;
      if (bloqueadorId == userId) {
        blockedIds.add(bloqueadoId);
      } else {
        blockedIds.add(bloqueadorId);
      }
    }
    return blockedIds;
  }

  // ─── Perfil de Usuario (Vista Previa) ─────────────────────────────

  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    final response =
        await _supabase
            .from('perfiles')
            .select(
              'id, nombre_usuario, codigo_amigo, nivel, experiencia, '
              'racha_actual, racha_maxima, minutos_enfoque_total, '
              'mascota_cosmeticos(sombrero, cara, traje)',
            )
            .eq('id', userId)
            .maybeSingle();

    if (response != null) {
      final rawCosmeticos = response['mascota_cosmeticos'];
      bool isEmpty = true;
      if (rawCosmeticos is List && rawCosmeticos.isNotEmpty) {
        isEmpty = false;
      } else if (rawCosmeticos is Map && rawCosmeticos.isNotEmpty) {
        isEmpty = false;
      }

      if (isEmpty) {
        try {
          final rankingData = await _supabase
              .from('v_ranking_semanal')
              .select('sombrero, cosmetico, traje')
              .eq('usuario_id', userId)
              .maybeSingle();

          if (rankingData != null) {
            response['mascota_cosmeticos'] = [
              {
                'sombrero': rankingData['sombrero'],
                'cara': rankingData['cosmetico'], // Map 'cosmetico' in view to 'cara' in model
                'traje': rankingData['traje'],
              }
            ];
          }
        } catch (e) {
          debugPrint('⚠️ Error en fallback de cosméticos de ranking: $e');
        }
      }
    }

    return response;
  }

  // ─── Estado de Relación ───────────────────────────────────────────

  /// Determina el estado de relación completo entre dos usuarios.
  /// Consulta amistades y bloqueos para devolver un mapa con la info.
  Future<Map<String, dynamic>> getRelationshipStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    // 1. Verificar bloqueos
    final block =
        await _supabase
            .from('bloqueos')
            .select('bloqueador_id')
            .or(
              'and(bloqueador_id.eq.$currentUserId,bloqueado_id.eq.$targetUserId),'
              'and(bloqueador_id.eq.$targetUserId,bloqueado_id.eq.$currentUserId)',
            )
            .maybeSingle();

    if (block != null) {
      return {
        'status': 'blocked',
        'friendshipId': null,
        'blockerId': block['bloqueador_id'] as String?,
      };
    }

    // 2. Verificar amistad
    final friendship =
        await _supabase
            .from('amistades')
            .select('id, estado, usuario_id, amigo_id')
            .or(
              'and(usuario_id.eq.$currentUserId,amigo_id.eq.$targetUserId),'
              'and(usuario_id.eq.$targetUserId,amigo_id.eq.$currentUserId)',
            )
            .maybeSingle();

    if (friendship == null) {
      return {'status': 'none'};
    }

    final estado = friendship['estado'] as String;
    final friendshipId = friendship['id'] as String;
    final senderUserId = friendship['usuario_id'] as String;

    if (estado == 'aceptada') {
      return {'status': 'friends', 'friendshipId': friendshipId};
    }

    if (estado == 'pendiente') {
      if (senderUserId == currentUserId) {
        return {'status': 'requestSent', 'friendshipId': friendshipId};
      } else {
        return {'status': 'requestReceived', 'friendshipId': friendshipId};
      }
    }

    // Estado 'rechazada' se trata como sin relación (permite re-enviar)
    return {'status': 'none'};
  }

  // ─── Acciones de Bloqueo y Eliminación ────────────────────────────

  /// Bloquea a un usuario. Inserta en la tabla bloqueos.
  Future<void> blockUser(String blockerId, String blockedId) async {
    await _supabase.from('bloqueos').insert({
      'bloqueador_id': blockerId,
      'bloqueado_id': blockedId,
    });

    // Si existe una amistad, eliminarla
    final friendship =
        await _supabase
            .from('amistades')
            .select('id')
            .or(
              'and(usuario_id.eq.$blockerId,amigo_id.eq.$blockedId),'
              'and(usuario_id.eq.$blockedId,amigo_id.eq.$blockerId)',
            )
            .maybeSingle();

    if (friendship != null) {
      await _supabase.from('amistades').delete().eq('id', friendship['id']);
    }
  }

  /// Elimina una amistad confirmada.
  Future<void> removeFriend(String friendshipId) async {
    await _supabase.from('amistades').delete().eq('id', friendshipId);
  }

  /// Desbloquea a un usuario. Elimina de la tabla bloqueos.
  Future<void> unblockUser(String blockerId, String blockedId) async {
    await _supabase
        .from('bloqueos')
        .delete()
        .eq('bloqueador_id', blockerId)
        .eq('bloqueado_id', blockedId);
  }

  /// Realiza la compra de un regalo y lo registra en Supabase.
  Future<void> sendGift({
    required String senderId,
    required String recipientId,
    required int itemId,
    required int price,
  }) async {
    // 1. Obtener monedas actuales del remitente
    final profileRes = await _supabase
        .from('perfiles')
        .select('monedas')
        .eq('id', senderId)
        .single();
    final currentCoins = (profileRes['monedas'] as num).toInt();

    if (currentCoins < price) {
      throw Exception('Monedas insuficientes');
    }

    // 2. Descontar las monedas del perfil
    await _supabase
        .from('perfiles')
        .update({'monedas': currentCoins - price})
        .eq('id', senderId);

    // 3. Insertar el regalo pendiente
    await _supabase.from('regalos').insert({
      'remitente_id': senderId,
      'destinatario_id': recipientId,
      'objeto_id': itemId,
      'estado': 'pendiente',
    });
  }

  final Map<String, String> _senderNamesCache = {};
  final Map<int, String> _itemNamesCache = {};

  Future<String> _getSenderName(String userId) async {
    if (_senderNamesCache.containsKey(userId)) {
      return _senderNamesCache[userId]!;
    }
    try {
      final res = await _supabase
          .from('perfiles')
          .select('nombre_usuario')
          .eq('id', userId)
          .maybeSingle();
      final name = res?['nombre_usuario'] as String? ?? 'Usuario';
      _senderNamesCache[userId] = name;
      return name;
    } catch (e) {
      return 'Usuario';
    }
  }

  Future<String> _getItemName(int itemId) async {
    if (_itemNamesCache.containsKey(itemId)) {
      return _itemNamesCache[itemId]!;
    }
    try {
      final res = await _supabase
          .from('objetos_tienda')
          .select('nombre')
          .eq('id', itemId)
          .maybeSingle();
      final name = res?['nombre'] as String? ?? 'Objeto';
      _itemNamesCache[itemId] = name;
      return name;
    } catch (e) {
      switch (itemId) {
        case 401: return 'Protector de Racha';
        default: return 'Objeto';
      }
    }
  }

  /// Retorna un Stream con los regalos recibidos pendientes en tiempo real.
  Stream<List<GiftWithDetails>> getPendingGiftsStream(String currentUserId) {
    return _supabase
        .from('regalos')
        .stream(primaryKey: ['id'])
        .eq('destinatario_id', currentUserId)
        .asyncMap((rawGifts) async {
          final List<GiftWithDetails> detailedGifts = [];
          for (final gift in rawGifts) {
            // Filter by pending state client-side since stream eq cannot be chained
            if (gift['estado'] != 'pendiente') continue;

            final senderId = gift['remitente_id'] as String;
            final itemId = (gift['objeto_id'] as num).toInt();
            
            final senderName = await _getSenderName(senderId);
            final itemName = await _getItemName(itemId);
            
            detailedGifts.add(GiftWithDetails(
              id: gift['id'] as String,
              remitenteId: senderId,
              remitenteNombre: senderName,
              objetoId: itemId,
              objetoNombre: itemName,
              enviadoEn: DateTime.parse(gift['enviado_en'] as String),
            ));
          }
          return detailedGifts;
        });
  }

  /// Acepta el regalo recibido llamando a la RPC.
  Future<void> acceptGift(String giftId) async {
    await _supabase.rpc('aceptar_regalo', params: {'p_regalo_id': giftId});
  }

  /// Rechaza el regalo recibido llamando a la RPC.
  Future<void> rejectGift(String giftId) async {
    await _supabase.rpc('rechazar_regalo', params: {'p_regalo_id': giftId});
  }
}
